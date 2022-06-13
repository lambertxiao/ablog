---
author: "Lambert Xiao"
title: "[Writing]使用libp2p来构建点对点网络"
date: "2022-06-13"
summary: "在filecoin中发现这个库，读读源码，学习学习"
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---


## libp2p能干嘛

1. 网络中的节点发现

    可以用来发现p2p网络中的其他节点以及维护其他节点的状态

2. 数据传输

    p2p网络中节点间数据的传输，并支持多种传输层协议，如TCP、UDP、QUIC等。在传输时还有传输通道加密的功能

## libp2p是如何支持多种传输协议的

libp2p定义了一个统一的格式，举例如下

- /ip4/127.0.0.1/tcp/8080
- /ip4/127.0.0.1/udp/8090
- /ip4/192.168.0.1/tcp/8080/p2p/QmcEPrat8ShnCph8WjkREzt5CPXF2RwhYxYBALDcLC1iV6

    含义为，对方使用ip4网络，地址为192.168.0.1，tcp协议，监听在8080端口，是一个p2p节点，节点id为QmcEPrat8ShnCph8WjkREzt5CPXF2RwhYxYBALDcLC1iV6

## libp2p如何创建一个节点

```go
func makeRandomHost(t *testing.T, port int) (host.Host, error) {
	priv, _, err := crypto.GenerateKeyPair(crypto.RSA, 2048)
	require.NoError(t, err)

	return New([]Option{
		ListenAddrStrings(fmt.Sprintf("/ip4/127.0.0.1/tcp/%d", port)),
		Identity(priv),
		DefaultTransports,
		DefaultMuxers,
		DefaultSecurity,
		NATPortMap(),
	}...)
}
```

可以看出，构建node时，需要传递一些配置:

1. 包含node的网络地址、协议、私钥
2. 管理数据传输的transport
3. 管理连接多路复用的muxer
4. 管理连接传输安全的security
5. 管理网络穿透的natManager

```go
// DefaultTransports are the default libp2p transports.
//
// Use this option when you want to *extend* the set of transports used by
// libp2p instead of replacing them.
var DefaultTransports = ChainOptions(
	Transport(tcp.NewTCPTransport),
	Transport(quic.NewTransport),
	Transport(ws.New),
)
```

默认支持3种transport，tcp、quic、websocket

```go
var DefaultMuxers = Muxer("/yamux/1.0.0", yamux.DefaultTransport)
```

默认的连接多路复用器是yamux

## 创建一个node后，libp2p做了什么

```go
// NewNode constructs a new libp2p Host from the Config.
//
// This function consumes the config. Do not reuse it (really!).
func (cfg *Config) NewNode() (host.Host, error) {
	swrm, err := cfg.makeSwarm()
	if err != nil {
		return nil, err
	}

	h, err := bhost.NewHost(swrm, &bhost.HostOpts{
		ConnManager:         cfg.ConnManager,
		AddrsFactory:        cfg.AddrsFactory,
		NATManager:          cfg.NATManager,
		EnablePing:          !cfg.DisablePing,
		UserAgent:           cfg.UserAgent,
		MultiaddrResolver:   cfg.MultiaddrResolver,
		EnableHolePunching:  cfg.EnableHolePunching,
		HolePunchingOptions: cfg.HolePunchingOptions,
		EnableRelayService:  cfg.EnableRelayService,
		RelayServiceOpts:    cfg.RelayServiceOpts,
	})
	if err != nil {
		swrm.Close()
		return nil, err
	}

	if cfg.Relay {
		// If we've enabled the relay, we should filter out relay
		// addresses by default.
		//
		// TODO: We shouldn't be doing this here.
		oldFactory := h.AddrsFactory
		h.AddrsFactory = func(addrs []ma.Multiaddr) []ma.Multiaddr {
			return oldFactory(autorelay.Filter(addrs))
		}
	}

	if err := cfg.addTransports(h); err != nil {
		h.Close()
		return nil, err
	}

	// TODO: This method succeeds if listening on one address succeeds. We
	// should probably fail if listening on *any* addr fails.
	if err := h.Network().Listen(cfg.ListenAddrs...); err != nil {
		h.Close()
		return nil, err
	}

	// Configure routing and autorelay
	var router routing.PeerRouting
	if cfg.Routing != nil {
		router, err = cfg.Routing(h)
		if err != nil {
			h.Close()
			return nil, err
		}
	}

	// Note: h.AddrsFactory may be changed by relayFinder, but non-relay version is
	// used by AutoNAT below.
	var ar *autorelay.AutoRelay
	addrF := h.AddrsFactory
	if cfg.EnableAutoRelay {
		if !cfg.Relay {
			h.Close()
			return nil, fmt.Errorf("cannot enable autorelay; relay is not enabled")
		}

		ar, err = autorelay.NewAutoRelay(h, cfg.AutoRelayOpts...)
		if err != nil {
			return nil, err
		}
	}

	autonatOpts := []autonat.Option{
		autonat.UsingAddresses(func() []ma.Multiaddr {
			return addrF(h.AllAddrs())
		}),
	}
	if cfg.AutoNATConfig.ThrottleInterval != 0 {
		autonatOpts = append(autonatOpts,
			autonat.WithThrottling(cfg.AutoNATConfig.ThrottleGlobalLimit, cfg.AutoNATConfig.ThrottleInterval),
			autonat.WithPeerThrottling(cfg.AutoNATConfig.ThrottlePeerLimit))
	}
	if cfg.AutoNATConfig.EnableService {
		autonatPrivKey, _, err := crypto.GenerateEd25519Key(rand.Reader)
		if err != nil {
			return nil, err
		}
		ps, err := pstoremem.NewPeerstore()
		if err != nil {
			return nil, err
		}

		// Pull out the pieces of the config that we _actually_ care about.
		// Specifically, don't setup things like autorelay, listeners,
		// identify, etc.
		autoNatCfg := Config{
			Transports:         cfg.Transports,
			Muxers:             cfg.Muxers,
			SecurityTransports: cfg.SecurityTransports,
			Insecure:           cfg.Insecure,
			PSK:                cfg.PSK,
			ConnectionGater:    cfg.ConnectionGater,
			Reporter:           cfg.Reporter,
			PeerKey:            autonatPrivKey,
			Peerstore:          ps,
		}

		dialer, err := autoNatCfg.makeSwarm()
		if err != nil {
			h.Close()
			return nil, err
		}
		dialerHost := blankhost.NewBlankHost(dialer)
		if err := autoNatCfg.addTransports(dialerHost); err != nil {
			dialerHost.Close()
			h.Close()
			return nil, err
		}
		// NOTE: We're dropping the blank host here but that's fine. It
		// doesn't really _do_ anything and doesn't even need to be
		// closed (as long as we close the underlying network).
		autonatOpts = append(autonatOpts, autonat.EnableService(dialerHost.Network()))
	}
	if cfg.AutoNATConfig.ForceReachability != nil {
		autonatOpts = append(autonatOpts, autonat.WithReachability(*cfg.AutoNATConfig.ForceReachability))
	}

	autonat, err := autonat.New(h, autonatOpts...)
	if err != nil {
		h.Close()
		return nil, fmt.Errorf("cannot enable autorelay; autonat failed to start: %v", err)
	}
	h.SetAutoNat(autonat)

	// start the host background tasks
	h.Start()

	var ho host.Host
	ho = h
	if router != nil {
		ho = routed.Wrap(h, router)
	}
	if ar != nil {
		return autorelay.NewAutoRelayHost(ho, ar), nil
	}
	return ho, nil
}
```

1. 创建了一个swarm对象，swarm是一个连接复用器，使用同一个channel来管理与其他节点的消息的收发
2. 使用swarm和config对象创建了一个host，host实现了host.Host接口
3. 调用host的network的listen方法，开启服务监听
4. 拿到host对应的peerRouting



## 主要接口定义

### Network

```go
// Network is the interface used to connect to the outside world.
// It dials and listens for connections. it uses a Swarm to pool
// connections (see swarm pkg, and peerstream.Swarm). Connections
// are encrypted with a TLS-like protocol.
type Network interface {
	Dialer
	io.Closer

	// SetStreamHandler sets the handler for new streams opened by the
	// remote side. This operation is threadsafe.
	SetStreamHandler(StreamHandler)

	// NewStream returns a new stream to given peer p.
	// If there is no connection to p, attempts to create one.
	NewStream(context.Context, peer.ID) (Stream, error)

	// Listen tells the network to start listening on given multiaddrs.
	Listen(...ma.Multiaddr) error

	// ListenAddresses returns a list of addresses at which this network listens.
	ListenAddresses() []ma.Multiaddr

	// InterfaceListenAddresses returns a list of addresses at which this network
	// listens. It expands "any interface" addresses (/ip4/0.0.0.0, /ip6/::) to
	// use the known local interfaces.
	InterfaceListenAddresses() ([]ma.Multiaddr, error)

	// ResourceManager returns the ResourceManager associated with this network
	ResourceManager() ResourceManager
}
```

代表一个抽象的网络层，可以开启网络监听，并使用预设好的handler处理其他node的请求

### Host

```go
type Host interface {
    // ID returns the (local) peer.ID associated with this Host
    ID() peer.ID

    // Peerstore returns the Host's repository of Peer Addresses and Keys.
    Peerstore() peerstore.Peerstore

    // Returns the listen addresses of the Host
    Addrs() []ma.Multiaddr

    // Networks returns the Network interface of the Host
    Network() network.Network

    // Mux returns the Mux multiplexing incoming streams to protocol handlers
    Mux() protocol.Switch

    // Connect ensures there is a connection between this host and the peer with
    // given peer.ID. Connect will absorb the addresses in pi into its internal
    // peerstore. If there is not an active connection, Connect will issue a
    // h.Network.Dial, and block until a connection is open, or an error is
    // returned. // TODO: Relay + NAT.
    Connect(ctx context.Context, pi peer.AddrInfo) error

    // SetStreamHandler sets the protocol handler on the Host's Mux.
    // This is equivalent to:
    //   host.Mux().SetHandler(proto, handler)
    // (Threadsafe)
    SetStreamHandler(pid protocol.ID, handler network.StreamHandler)

    // SetStreamHandlerMatch sets the protocol handler on the Host's Mux
    // using a matching function for protocol selection.
    SetStreamHandlerMatch(protocol.ID, func(string) bool, network.StreamHandler)

    // RemoveStreamHandler removes a handler on the mux that was set by
    // SetStreamHandler
    RemoveStreamHandler(pid protocol.ID)

    // NewStream opens a new stream to given peer p, and writes a p2p/protocol
    // header with given ProtocolID. If there is no connection to p, attempts
    // to create one. If ProtocolID is "", writes no header.
    // (Threadsafe)
    NewStream(ctx context.Context, p peer.ID, pids ...protocol.ID) (network.Stream, error)

    // Close shuts down the host, its Network, and services.
    Close() error

    // ConnManager returns this hosts connection manager
    ConnManager() connmgr.ConnManager

    // EventBus returns the hosts eventbus
    EventBus() event.Bus
}
```

### PeerRouting

```go
// PeerRouting is a way to find address information about certain peers.
// This can be implemented by a simple lookup table, a tracking server,
// or even a DHT.
type PeerRouting interface {
	// FindPeer searches for a peer with given ID, returns a peer.AddrInfo
	// with relevant addresses.
	FindPeer(context.Context, peer.ID) (peer.AddrInfo, error)
}
```

可以根据peerId找到peer

### AutoNAT

```go
// AutoNAT is the interface for NAT autodiscovery
type AutoNAT interface {
	// Status returns the current NAT status
	Status() network.Reachability
	// PublicAddr returns the public dial address when NAT status is public and an
	// error otherwise
	PublicAddr() (ma.Multiaddr, error)
	io.Closer
}
```
