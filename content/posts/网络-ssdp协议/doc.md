---
author: "Lambert Xiao"
title: "网络-ssdp协议"
date: "2022-06-21"
summary: "基于udp+http协议，在upnp中被使用到"
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
mermaid: true
---

## 协议介绍

ssdp协议是实现UpNp的协议之一，它使用的传输层协议是UDP，应用层协议则是类HTTP（这种协议组合又称为HTTPU)。

## 工作原理

### 设备查询(ssdp:discover)

当一个控制端加入网络的时候，它会想要知道网络里当前其余设备的信息，此时它会通过向多播地址发起 `ssdp:discover` 请求来查询设备信息

> 多播地址一般固定为 `239.255.255.250:1900`，这个组播地址不属于任何服务器或个人，它有点类似一个微信群号，任何成员（组播源）往微信群（组播IP）发送消息（组播数据），这个群里的成员（组播接收者）都会接收到此消息。
#### 流程示意

{{<mermaid>}}
sequenceDiagram
    participant 控制端
    participant 多播地址
    控制端 ->> 多播地址: 发送M-SEARCH请求(ssdp:discover)
    多播地址 ->> 控制端: 响应设备信息
{{</mermaid>}}

> 控制端发送的是UDP的多播包，只发一次，但会有很多地址都收到这个包

#### 协议格式

请求：

```http
M-SEARCH * HTTP/1.1
S: uuid:ijklmnop-7dec-11d0-a765-00a0c91e6bf6
Host: 239.255.255.250:1900
Man: "ssdp:discover"
ST: ge:fridge
MX: 3
```

响应：

```http
HTTP/1.1 200 OK
Cache-Control: max-age= seconds until advertisement expires
S: uuid:ijklmnop-7dec-11d0-a765-00a0c91e6bf6
Location: URL for UPnP description for root device
Cache-Control: no-cache="Ext",max-age=5000ST:ge:fridge
```

### 设备在线消息(ssdp:alive)

当有新设备加入网络时，它应当向一个特定的多播地址使用`NOTIFY`方法发送`ssdp:alive`消息，以宣布自己的在线

#### 流程示意

{{<mermaid>}}
sequenceDiagram
    participant 设备
    participant 多播地址
    设备 ->> 多播地址: 发送NOTIFY请求(ssdp:alive)
{{</mermaid>}}

> NOTIFY请求不会有响应

#### 协议格式

```
NOTIFY * HTTP/1.1HOST: 239.255.255.250:1900CACHE-CONTROL: max-age = seconds until advertisement expiresLOCATION: URL for UPnP description for root deviceNT: search targetNTS: ssdp:aliveUSN: advertisement UUID
```

### 设备离线通知(ssdp:byebye)

当一个设备准备从网络中下线时，它应当向一个特定的多播地址使用`NOTIFY`方法发送`ssdp:byebye`消息，以说明自己准备要离线了。

> 如果设备超时未发送ssdp:alive消息也会被视为下线

#### 流程示意

{{<mermaid>}}
sequenceDiagram
    participant 设备
    participant 多播地址
    设备 ->> 多播地址: 发送NOTIFY请求(ssdp:byebye)
{{</mermaid>}}


#### 协议格式

```
NOTIFY * HTTP/1.1
HOST: 239.255.255.250:1900NT: search target
NTS: ssdp:byebye
USN: advertisement UUID
```

## 代码实现节选

> 代码实现节选自goupnp, https://github.com/huin/goupnp

```go
func (srv *Server) ListenAndServe() error {
	var err error

	var addr *net.UDPAddr
	if addr, err = net.ResolveUDPAddr("udp", srv.Addr); err != nil {
		log.Fatal(err)
	}

	var conn net.PacketConn
	if srv.Multicast {
		if conn, err = net.ListenMulticastUDP("udp", srv.Interface, addr); err != nil {
			return err
		}
	} else {
		if conn, err = net.ListenUDP("udp", addr); err != nil {
			return err
		}
	}

	return srv.Serve(conn)
}

// Serve messages received on the given packet listener to the srv.Handler.
func (srv *Server) Serve(l net.PacketConn) error {
	maxMessageBytes := DefaultMaxMessageBytes
	if srv.MaxMessageBytes != 0 {
		maxMessageBytes = srv.MaxMessageBytes
	}
	for {
		buf := make([]byte, maxMessageBytes)
		n, peerAddr, err := l.ReadFrom(buf)
		if err != nil {
			return err
		}
		buf = buf[:n]

		go func(buf []byte, peerAddr net.Addr) {
			// At least one router's UPnP implementation has added a trailing space
			// after "HTTP/1.1" - trim it.
			buf = trailingWhitespaceRx.ReplaceAllLiteral(buf, crlf)

			req, err := http.ReadRequest(bufio.NewReader(bytes.NewBuffer(buf)))
			if err != nil {
				log.Printf("httpu: Failed to parse request: %v", err)
				return
			}
			req.RemoteAddr = peerAddr.String()
			srv.Handler.ServeMessage(req)
			// No need to call req.Body.Close - underlying reader is bytes.Buffer.
		}(buf, peerAddr)
	}
}
```

上面代码实现了一个UDP的Server，用于作为多播地址端接受设备的消息

```go
// ServeMessage implements httpu.Handler, and uses SSDP NOTIFY requests to
// maintain the registry of devices and services.
func (reg *Registry) ServeMessage(r *http.Request) {
	if r.Method != methodNotify {
		return
	}

	nts := r.Header.Get("nts")

	var err error
	switch nts {
	case ntsAlive:
		err = reg.handleNTSAlive(r)
	case ntsUpdate:
		err = reg.handleNTSUpdate(r)
	case ntsByebye:
		err = reg.handleNTSByebye(r)
	default:
		err = fmt.Errorf("unknown NTS value: %q", nts)
	}
	if err != nil {
		log.Printf("goupnp/ssdp: failed to handle %s message from %s: %v", nts, r.RemoteAddr, err)
	}
}
```

处理具体`ssdp:alive`, `ssdp:byebye`等逻辑

```go
// Registry maintains knowledge of discovered devices and services.
//
// NOTE: the interface for this is experimental and may change, or go away
// entirely.
type Registry struct {
	lock  sync.Mutex
	byUSN map[string]*Entry

	listenersLock sync.RWMutex
	listeners     map[chan<- Update]struct{}
}
```

registry维护了所有发现的device

```go

func (reg *Registry) handleNTSAlive(r *http.Request) error {
	entry, err := newEntryFromRequest(r)
	if err != nil {
		return err
	}

	reg.lock.Lock()
	reg.byUSN[entry.USN] = entry
	reg.lock.Unlock()

	reg.sendUpdate(Update{
		USN:       entry.USN,
		EventType: EventAlive,
		Entry:     entry,
	})

	return nil
}

func newEntryFromRequest(r *http.Request) (*Entry, error) {
	now := time.Now()
	expiryDuration, err := parseCacheControlMaxAge(r.Header.Get("CACHE-CONTROL"))
	if err != nil {
		return nil, fmt.Errorf("ssdp: error parsing CACHE-CONTROL max age: %v", err)
	}

	loc, err := url.Parse(r.Header.Get("LOCATION"))
	if err != nil {
		return nil, fmt.Errorf("ssdp: error parsing entry Location URL: %v", err)
	}

	bootID, err := parseUpnpIntHeader(r.Header, "BOOTID.UPNP.ORG", -1)
	if err != nil {
		return nil, err
	}
	configID, err := parseUpnpIntHeader(r.Header, "CONFIGID.UPNP.ORG", -1)
	if err != nil {
		return nil, err
	}
	searchPort, err := parseUpnpIntHeader(r.Header, "SEARCHPORT.UPNP.ORG", ssdpSearchPort)
	if err != nil {
		return nil, err
	}

	if searchPort < 1 || searchPort > 65535 {
		return nil, fmt.Errorf("ssdp: search port %d is out of range", searchPort)
	}

	return &Entry{
		RemoteAddr:  r.RemoteAddr,
		USN:         r.Header.Get("USN"),
		NT:          r.Header.Get("NT"),
		Server:      r.Header.Get("SERVER"),
		Host:        r.Header.Get("HOST"),
		Location:    *loc,
		BootID:      bootID,
		ConfigID:    configID,
		SearchPort:  uint16(searchPort),
		LastUpdate:  now,
		CacheExpiry: now.Add(expiryDuration),
	}, nil
}
```