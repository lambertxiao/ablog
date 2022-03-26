---
author: "Lambert Xiao"
title: "golang-http2实现"
date: "2022-03-25"
summary: "扒开go源码，看看http2在go里的实现"
tags: ["http2", "网络知识"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 举个例子

### 怎么接收一个http2请求

```go
func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Hello h2c")
	})

	s := &http.Server{
		Addr:    "127.0.0.1:8080",
		Handler: mux,
	}
	log.Fatal(s.ListenAndServeTLS("server.crt", "server.key"))
}

```

需要注意的是，http2是必须和tls一起开启，可看源码 `/go/src/net/http/server.go`

```go
func (c *conn) serve(ctx context.Context) {
	...

	if tlsConn, ok := c.rwc.(*tls.Conn); ok {
		...
		if proto := c.tlsState.NegotiatedProtocol; validNextProto(proto) {
			// 这里的fn就是http2的handler, 通过http2ConfigureServer方法注册
			if fn := c.server.TLSNextProto[proto]; fn != nil {
				h := initALPNRequest{ctx, tlsConn, serverHandler{c.server}}
				c.setState(c.rwc, StateActive, skipHooks)
				fn(c.server, tlsConn, h)
			}
			return
		}
	}

	// HTTP/1.x from here on.
	// 以下走http1.x的逻辑
	...
}
```

通过openssl工具生成证书

```
openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 365 -out server.crt
```

### 怎么发起一个http2请求

```go
func main() {
	client := http.Client{
		Transport: &http.Transport{
			ForceAttemptHTTP2: true,
			TLSClientConfig:   &tls.Config{InsecureSkipVerify: true},
		},
	}
	resp, err := client.Get("https://127.0.0.1:8080")
	if err != nil {
		panic(err)
	}
	rdata, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	fmt.Println(resp.Proto, string(rdata))
}
```

1. 需要自定义一个Transport
2. 打开ForceAttemptHTTP2
3. 由于服务端的整数是自己生成的，所以需要设置跳过校验
4. 最后resp里的proto会是 `HTTP/2.0`

```go
// ForceAttemptHTTP2的定义

type Transport struct {
	...

	// ForceAttemptHTTP2 controls whether HTTP/2 is enabled when a non-zero
	// Dial, DialTLS, or DialContext func or TLSClientConfig is provided.
	// By default, use of any those fields conservatively disables HTTP/2.
	// To use a custom dialer or TLS config and still attempt HTTP/2
	// upgrades, set this to true.
	ForceAttemptHTTP2 bool
}
```


## 源码解析

go中http2相关的源码基本都在 `/go/src/net/http/h2_bundle.go` 文件中


### server端

#### http2Server.ServeConn

```go
func (s *http2Server) ServeConn(c net.Conn, opts *http2ServeConnOpts) {
	baseCtx, cancel := http2serverConnBaseContext(c, opts)
	defer cancel()

	sc := &http2serverConn{
		srv:                         s,
		hs:                          opts.baseConfig(),
		conn:                        c,
		baseCtx:                     baseCtx,
		remoteAddrStr:               c.RemoteAddr().String(),
		bw:                          http2newBufferedWriter(c),
		handler:                     opts.handler(),
		streams:                     make(map[uint32]*http2stream),
		readFrameCh:                 make(chan http2readFrameResult),
		wantWriteFrameCh:            make(chan http2FrameWriteRequest, 8),
		serveMsgCh:                  make(chan interface{}, 8),
		wroteFrameCh:                make(chan http2frameWriteResult, 1), // buffered; one send in writeFrameAsync
		bodyReadCh:                  make(chan http2bodyReadMsg),         // buffering doesn't matter either way
		doneServing:                 make(chan struct{}),
		clientMaxStreams:            math.MaxUint32, // Section 6.5.2: "Initially, there is no limit to this value"
		advMaxStreams:               s.maxConcurrentStreams(),
		initialStreamSendWindowSize: http2initialWindowSize,
		maxFrameSize:                http2initialMaxFrameSize,
		headerTableSize:             http2initialHeaderTableSize,
		serveG:                      http2newGoroutineLock(),
		pushEnabled:                 true,
	}

	s.state.registerConn(sc)
	defer s.state.unregisterConn(sc)

	if sc.hs.WriteTimeout != 0 {
		sc.conn.SetWriteDeadline(time.Time{})
	}

	if s.NewWriteScheduler != nil {
		sc.writeSched = s.NewWriteScheduler()
	} else {
		sc.writeSched = http2NewRandomWriteScheduler()
	}

	// These start at the RFC-specified defaults. If there is a higher
	// configured value for inflow, that will be updated when we send a
	// WINDOW_UPDATE shortly after sending SETTINGS.
	sc.flow.add(http2initialWindowSize)
	sc.inflow.add(http2initialWindowSize)
	sc.hpackEncoder = hpack.NewEncoder(&sc.headerWriteBuf)

	fr := http2NewFramer(sc.bw, c)
	fr.ReadMetaHeaders = hpack.NewDecoder(http2initialHeaderTableSize, nil)
	fr.MaxHeaderListSize = sc.maxHeaderListSize()
	fr.SetMaxReadFrameSize(s.maxReadFrameSize())
	sc.framer = fr

	if tc, ok := c.(http2connectionStater); ok {
		sc.tlsState = new(tls.ConnectionState)
		*sc.tlsState = tc.ConnectionState()
		
		if sc.tlsState.Version < tls.VersionTLS12 {
			sc.rejectConn(http2ErrCodeInadequateSecurity, "TLS version too low")
			return
		}

		if sc.tlsState.ServerName == "" {
			
		}

		if !s.PermitProhibitedCipherSuites && http2isBadCipher(sc.tlsState.CipherSuite) {
			sc.rejectConn(http2ErrCodeInadequateSecurity, fmt.Sprintf("Prohibited TLS 1.2 Cipher Suite: %x", sc.tlsState.CipherSuite))
			return
		}
	}

	if hook := http2testHookGetServerConn; hook != nil {
		hook(sc)
	}
	sc.serve()
}
```

1. 使用http2serverConn对象封装了对conn的管理

#### http2serverConn.serve

```go
func (sc *http2serverConn) serve() {
	sc.serveG.check()
	defer sc.notePanic()
	defer sc.conn.Close()
	defer sc.closeAllStreamsOnConnClose()
	defer sc.stopShutdownTimer()
	defer close(sc.doneServing) // unblocks handlers trying to send

	if http2VerboseLogs {
		sc.vlogf("http2: server connection from %v on %p", sc.conn.RemoteAddr(), sc.hs)
	}

	// server告诉client端当前我的一些设置
	sc.writeFrame(http2FrameWriteRequest{
		write: http2writeSettings{
			{http2SettingMaxFrameSize, sc.srv.maxReadFrameSize()},
			{http2SettingMaxConcurrentStreams, sc.advMaxStreams},
			{http2SettingMaxHeaderListSize, sc.maxHeaderListSize()},
			{http2SettingInitialWindowSize, uint32(sc.srv.initialStreamRecvWindowSize())},
		},
	})
	sc.unackedSettings++

	// Each connection starts with intialWindowSize inflow tokens.
	// If a higher value is configured, we add more tokens.
	if diff := sc.srv.initialConnRecvWindowSize() - http2initialWindowSize; diff > 0 {
		sc.sendWindowUpdate(nil, int(diff))
	}

	// 读取客户端发的前言
	if err := sc.readPreface(); err != nil {
		sc.condlogf(err, "http2: server: error reading preface from client %v: %v", sc.conn.RemoteAddr(), err)
		return
	}
	
	// 这里理应是通过更新conn的状态来出发某些callback
	sc.setConnState(StateActive)
	sc.setConnState(StateIdle)

	if sc.srv.IdleTimeout != 0 {
		sc.idleTimer = time.AfterFunc(sc.srv.IdleTimeout, sc.onIdleTimer)
		defer sc.idleTimer.Stop()
	}

	// 在新的goroutine中处理后面的frame
	go sc.readFrames() // closed by defer sc.conn.Close above

	settingsTimer := time.AfterFunc(http2firstSettingsTimeout, sc.onSettingsTimer)
	defer settingsTimer.Stop()

	// 在主的serve goroutine处理各种事件
	loopNum := 0
	for {
		loopNum++
		select {
		case wr := <-sc.wantWriteFrameCh:
			if se, ok := wr.write.(http2StreamError); ok {
				sc.resetStream(se)
				break
			}
			sc.writeFrame(wr)
		case res := <-sc.wroteFrameCh:
			// 读取上层需要返回的内容，以frame的形式写回给客户端
			sc.wroteFrame(res)
		case res := <-sc.readFrameCh:
			// 这里即为framer读出的frame
			if !sc.processFrameFromReader(res) {
				return
			}
			res.readMore()
			if settingsTimer != nil {
				settingsTimer.Stop()
				settingsTimer = nil
			}
		case m := <-sc.bodyReadCh:
			sc.noteBodyRead(m.st, m.n)
		case msg := <-sc.serveMsgCh:
			switch v := msg.(type) {
			case func(int):
				v(loopNum) // for testing
			case *http2serverMessage:
				switch v {
				case http2settingsTimerMsg:
					sc.logf("timeout waiting for SETTINGS frames from %v", sc.conn.RemoteAddr())
					return
				case http2idleTimerMsg:
					sc.vlogf("connection is idle")
					sc.goAway(http2ErrCodeNo)
				case http2shutdownTimerMsg:
					sc.vlogf("GOAWAY close timer fired; closing conn from %v", sc.conn.RemoteAddr())
					return
				case http2gracefulShutdownMsg:
					sc.startGracefulShutdownInternal()
				default:
					panic("unknown timer")
				}
			case *http2startPushRequest:
				sc.startPush(v)
			default:
				panic(fmt.Sprintf("unexpected type %T", v))
			}
		}

		// If the peer is causing us to generate a lot of control frames,
		// but not reading them from us, assume they are trying to make us
		// run out of memory.
		if sc.queuedControlFrames > sc.srv.maxQueuedControlFrames() {
			sc.vlogf("http2: too many control frames in send queue, closing connection")
			return
		}

		// Start the shutdown timer after sending a GOAWAY. When sending GOAWAY
		// with no error code (graceful shutdown), don't start the timer until
		// all open streams have been completed.
		sentGoAway := sc.inGoAway && !sc.needToSendGoAway && !sc.writingFrame
		gracefulShutdownComplete := sc.goAwayCode == http2ErrCodeNo && sc.curOpenStreams() == 0
		if sentGoAway && sc.shutdownTimer == nil && (sc.goAwayCode != http2ErrCodeNo || gracefulShutdownComplete) {
			sc.shutDownIn(http2goAwayTimeout)
		}
	}
}

```

#### http2serverConn.readFrames

通过framer读取frame后，写入readFrameCh管道，等待主的goroutine处理

```go
// readFrames is the loop that reads incoming frames.
// It takes care to only read one frame at a time, blocking until the
// consumer is done with the frame.
// It's run on its own goroutine.
func (sc *http2serverConn) readFrames() {
	gate := make(http2gate)
	gateDone := gate.Done
	for {
		f, err := sc.framer.ReadFrame()
		select {
		case sc.readFrameCh <- http2readFrameResult{f, err, gateDone}:
		case <-sc.doneServing:
			return
		}
		select {
		case <-gate:
		case <-sc.doneServing:
			return
		}
		if http2terminalReadFrameError(err) {
			return
		}
	}
}
```

#### http2serverConn.processFrameFromReader

```go
func (sc *http2serverConn) processFrameFromReader(res http2readFrameResult) bool {
	sc.serveG.check()
	err := res.err
	if err != nil {
		if err == http2ErrFrameTooLarge {
			sc.goAway(http2ErrCodeFrameSize)
			return true // goAway will close the loop
		}
		clientGone := err == io.EOF || err == io.ErrUnexpectedEOF || http2isClosedConnError(err)
		if clientGone {
			return false
		}
	} else {
		f := res.f
		if http2VerboseLogs {
			sc.vlogf("http2: server read frame %v", http2summarizeFrame(f))
		}
		// 处理具体的frame
		err = sc.processFrame(f)
		if err == nil {
			return true
		}
	}

	switch ev := err.(type) {
	case http2StreamError:
		sc.resetStream(ev)
		return true
	case http2goAwayFlowError:
		sc.goAway(http2ErrCodeFlowControl)
		return true
	case http2ConnectionError:
		sc.logf("http2: server connection error from %v: %v", sc.conn.RemoteAddr(), ev)
		sc.goAway(http2ErrCode(ev))
		return true // goAway will handle shutdown
	default:
		if res.err != nil {
			sc.vlogf("http2: server closing client connection; error reading frame from client %s: %v", sc.conn.RemoteAddr(), err)
		} else {
			sc.logf("http2: server closing client connection: %v", err)
		}
		return false
	}
}
```

#### http2serverConn.processFrame

根据不同的frame类型处理

```go
func (sc *http2serverConn) processFrame(f http2Frame) error {
	sc.serveG.check()

	// First frame received must be SETTINGS.
	if !sc.sawFirstSettings {
		if _, ok := f.(*http2SettingsFrame); !ok {
			return http2ConnectionError(http2ErrCodeProtocol)
		}
		sc.sawFirstSettings = true
	}

	switch f := f.(type) {
	case *http2SettingsFrame:
		// 包含setting信息的frame
		return sc.processSettings(f)
	case *http2MetaHeadersFrame:
		// 
		return sc.processHeaders(f)
	case *http2WindowUpdateFrame:
		return sc.processWindowUpdate(f)
	case *http2PingFrame:
		return sc.processPing(f)
	case *http2DataFrame:
		return sc.processData(f)
	case *http2RSTStreamFrame:
		return sc.processResetStream(f)
	case *http2PriorityFrame:
		return sc.processPriority(f)
	case *http2GoAwayFrame:
		return sc.processGoAway(f)
	case *http2PushPromiseFrame:
		// A client cannot push. Thus, servers MUST treat the receipt of a PUSH_PROMISE
		// frame as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
		return http2ConnectionError(http2ErrCodeProtocol)
	default:
		sc.vlogf("http2: server ignoring frame: %v", f.Header())
		return nil
	}
}
```

#### http2serverConn.processData

这里只展开processData方法看看如何处理frame的数据

```go

func (sc *http2serverConn) processData(f *http2DataFrame) error {
	sc.serveG.check()
	if sc.inGoAway && sc.goAwayCode != http2ErrCodeNo {
		return nil
	}
	data := f.Data()

	id := f.Header().StreamID
	state, st := sc.state(id)
	if id == 0 || state == http2stateIdle {
		return http2ConnectionError(http2ErrCodeProtocol)
	}

	if st == nil || state != http2stateOpen || st.gotTrailerHeader || st.resetQueued {
		// 流量控制
		if sc.inflow.available() < int32(f.Length) {
			return http2streamError(id, http2ErrCodeFlowControl)
		}
	
		sc.inflow.take(int32(f.Length))
		sc.sendWindowUpdate(nil, int(f.Length)) // conn-level

		if st != nil && st.resetQueued {
			return nil
		}
		return http2streamError(id, http2ErrCodeStreamClosed)
	}
	if st.body == nil {
		panic("internal error: should have a body in this state")
	}

	if st.declBodyBytes != -1 && st.bodyBytes+int64(len(data)) > st.declBodyBytes {
		st.body.CloseWithError(fmt.Errorf("sender tried to send more than declared Content-Length of %d bytes", st.declBodyBytes))
		return http2streamError(id, http2ErrCodeProtocol)
	}
	if f.Length > 0 {
		// 流量控制
		if st.inflow.available() < int32(f.Length) {
			return http2streamError(id, http2ErrCodeFlowControl)
		}
		st.inflow.take(int32(f.Length))

		if len(data) > 0 {
			// 将数据写入buf中，等待上层读取
			wrote, err := st.body.Write(data)
			if err != nil {
				sc.sendWindowUpdate(nil, int(f.Length)-wrote)
				return http2streamError(id, http2ErrCodeStreamClosed)
			}
			if wrote != len(data) {
				panic("internal error: bad Writer")
			}
			st.bodyBytes += int64(len(data))
		}

		// Return any padded flow control now, since we won't
		// refund it later on body reads.
		if pad := int32(f.Length) - int32(len(data)); pad > 0 {
			sc.sendWindowUpdate32(nil, pad)
			sc.sendWindowUpdate32(st, pad)
		}
	}
	if f.StreamEnded() {
		st.endStream()
	}
	return nil
}
```

#### http2serverConn.scheduleFrameWrite

frame写回给client时是带有一定策略的, 目前有http2priorityWriteScheduler和http2randomWriteScheduler两种scheduler来调度frame的写回

```go
// scheduleFrameWrite tickles the frame writing scheduler.
//
// If a frame is already being written, nothing happens. This will be called again
// when the frame is done being written.
//
// If a frame isn't being written and we need to send one, the best frame
// to send is selected by writeSched.
//
// If a frame isn't being written and there's nothing else to send, we
// flush the write buffer.
func (sc *http2serverConn) scheduleFrameWrite() {
	sc.serveG.check()
	if sc.writingFrame || sc.inFrameScheduleLoop {
		return
	}
	sc.inFrameScheduleLoop = true
	for !sc.writingFrameAsync {
		if sc.needToSendGoAway {
			sc.needToSendGoAway = false
			sc.startFrameWrite(http2FrameWriteRequest{
				write: &http2writeGoAway{
					maxStreamID: sc.maxClientStreamID,
					code:        sc.goAwayCode,
				},
			})
			continue
		}
		if sc.needToSendSettingsAck {
			sc.needToSendSettingsAck = false
			sc.startFrameWrite(http2FrameWriteRequest{write: http2writeSettingsAck{}})
			continue
		}
		if !sc.inGoAway || sc.goAwayCode == http2ErrCodeNo {
			// 这里应该有类似优先级队列的结构维护着需要写回的数据
			if wr, ok := sc.writeSched.Pop(); ok {
				if wr.isControl() {
					sc.queuedControlFrames--
				}
				sc.startFrameWrite(wr)
				continue
			}
		}
		if sc.needsFrameFlush {
			sc.startFrameWrite(http2FrameWriteRequest{write: http2flushFrameWriter{}})
			sc.needsFrameFlush = false // after startFrameWrite, since it sets this true
			continue
		}
		break
	}
	sc.inFrameScheduleLoop = false
}
```

### client端

#### http2ClientConn.roundTrip

```go
func (cc *http2ClientConn) RoundTrip(req *Request) (*Response, error) {
	resp, _, err := cc.roundTrip(req)
	return resp, err
}


func (cc *http2ClientConn) roundTrip(req *Request) (res *Response, gotErrAfterReqBodyWrite bool, err error) {
    // 检查连接头
	if err := http2checkConnHeaders(req); err != nil {
		return nil, false, err
	}
	if cc.idleTimer != nil {
		cc.idleTimer.Stop()
	}

	trailers, err := http2commaSeparatedTrailers(req)
	if err != nil {
		return nil, false, err
	}
	hasTrailers := trailers != ""

	cc.mu.Lock()
    // 每一个conn里能承载的steam数量被maxConcurrentStreams控制，没有空闲stream时需要等待
	if err := cc.awaitOpenSlotForRequest(req); err != nil {
		cc.mu.Unlock()
		return nil, false, err
	}

	body := req.Body
    // 计算请求的contentLen
	contentLen := http2actualContentLength(req)
	hasBody := contentLen != 0

	// TODO(bradfitz): this is a copy of the logic in net/http. Unify somewhere?
	var requestedGzip bool
	if !cc.t.disableCompression() &&
		req.Header.Get("Accept-Encoding") == "" &&
		req.Header.Get("Range") == "" &&
		req.Method != "HEAD" {
		// Request gzip only, not deflate. Deflate is ambiguous and
		// not as universally supported anyway.
		// See: https://zlib.net/zlib_faq.html#faq39
		//
		// Note that we don't request this for HEAD requests,
		// due to a bug in nginx:
		//   http://trac.nginx.org/nginx/ticket/358
		//   https://golang.org/issue/5522
		//
		// We don't request gzip if the request is for a range, since
		// auto-decoding a portion of a gzipped document will just fail
		// anyway. See https://golang.org/issue/8923
		requestedGzip = true
	}

	// we send: HEADERS{1}, CONTINUATION{0,} + DATA{0,} (DATA is
	// sent by writeRequestBody below, along with any Trailers,
	// again in form HEADERS{1}, CONTINUATION{0,})
    // 头部压缩
	hdrs, err := cc.encodeHeaders(req, requestedGzip, trailers, contentLen)
	if err != nil {
		cc.mu.Unlock()
		return nil, false, err
	}

    // 每个请求有一个独立的stream
	cs := cc.newStream()
	cs.req = req
	cs.trace = httptrace.ContextClientTrace(req.Context())
	cs.requestedGzip = requestedGzip
	bodyWriter := cc.t.getBodyWriterState(cs, body)
	cs.on100 = bodyWriter.on100

	defer func() {
		cc.wmu.Lock()
		werr := cc.werr
		cc.wmu.Unlock()
		if werr != nil {
			cc.Close()
		}
	}()

	cc.wmu.Lock()
	endStream := !hasBody && !hasTrailers

    // 往stream里写入header, 里面会通过conn上的framer往conn里写入
	werr := cc.writeHeaders(cs.ID, endStream, int(cc.maxFrameSize), hdrs)
	cc.wmu.Unlock()
	http2traceWroteHeaders(cs.trace)
	cc.mu.Unlock()

	if werr != nil {
		if hasBody {
			req.Body.Close() // per RoundTripper contract
			bodyWriter.cancel()
		}
        // 移除这个stream，并通过cond broadcase所有等着的请求
		cc.forgetStreamID(cs.ID)
		// Don't bother sending a RST_STREAM (our write already failed;
		// no need to keep writing)
		http2traceWroteRequest(cs.trace, werr)
		return nil, false, werr
	}

	var respHeaderTimer <-chan time.Time
	if hasBody {
        // 如果没有设置timer，则直接开启一个协程执行异步写入操作
        // 否则好像等着一个什么100 continue？？
		bodyWriter.scheduleBodyWrite()
	} else {
        // 没有body写入，则等待response在超时时间内回来
		http2traceWroteRequest(cs.trace, nil)
		if d := cc.responseHeaderTimeout(); d != 0 {
			timer := time.NewTimer(d)
			defer timer.Stop()
			respHeaderTimer = timer.C
		}
	}

	readLoopResCh := cs.resc
	bodyWritten := false
	ctx := req.Context()

	handleReadLoopResponse := func(re http2resAndError) (*Response, bool, error) {
		res := re.res
		if re.err != nil || res.StatusCode > 299 {
			// On error or status code 3xx, 4xx, 5xx, etc abort any
			// ongoing write, assuming that the server doesn't care
			// about our request body. If the server replied with 1xx or
			// 2xx, however, then assume the server DOES potentially
			// want our body (e.g. full-duplex streaming:
			// golang.org/issue/13444). If it turns out the server
			// doesn't, they'll RST_STREAM us soon enough. This is a
			// heuristic to avoid adding knobs to Transport. Hopefully
			// we can keep it.
			bodyWriter.cancel()
			cs.abortRequestBodyWrite(http2errStopReqBodyWrite)
			if hasBody && !bodyWritten {
				<-bodyWriter.resc
			}
		}
		if re.err != nil {
			cc.forgetStreamID(cs.ID)
			return nil, cs.getStartedWrite(), re.err
		}
		res.Request = req
		res.TLS = cc.tlsState
		return res, false, nil
	}

    // 循环处理chan
	for {
		select {
		case re := <-readLoopResCh:
            // 读取response
			return handleReadLoopResponse(re)
		case <-respHeaderTimer:
            // 如果response超时了
			if !hasBody || bodyWritten {
                // 如果没有body，或者body已经写入，则reset stream
				cc.writeStreamReset(cs.ID, http2ErrCodeCancel, nil)
			} else {
                // 终止写入
				bodyWriter.cancel()
				cs.abortRequestBodyWrite(http2errStopReqBodyWriteAndCancel)
				<-bodyWriter.resc
			}
			cc.forgetStreamID(cs.ID)
            // 向上报超时错误
			return nil, cs.getStartedWrite(), http2errTimeout
		case <-ctx.Done():
			if !hasBody || bodyWritten {
				cc.writeStreamReset(cs.ID, http2ErrCodeCancel, nil)
			} else {
				bodyWriter.cancel()
				cs.abortRequestBodyWrite(http2errStopReqBodyWriteAndCancel)
				<-bodyWriter.resc
			}
			cc.forgetStreamID(cs.ID)
			return nil, cs.getStartedWrite(), ctx.Err()
		case <-req.Cancel:
            // 如果请求被取消
			if !hasBody || bodyWritten {
				cc.writeStreamReset(cs.ID, http2ErrCodeCancel, nil)
			} else {
				bodyWriter.cancel()
				cs.abortRequestBodyWrite(http2errStopReqBodyWriteAndCancel)
				<-bodyWriter.resc
			}
			cc.forgetStreamID(cs.ID)
			return nil, cs.getStartedWrite(), http2errRequestCanceled
		case <-cs.peerReset:
            // 如果对端重置
			// processResetStream already removed the
			// stream from the streams map; no need for
			// forgetStreamID.
			return nil, cs.getStartedWrite(), cs.resetErr
		case err := <-bodyWriter.resc:
			bodyWritten = true
			// Prefer the read loop's response, if available. Issue 16102.
			select {
			case re := <-readLoopResCh:
				return handleReadLoopResponse(re)
			default:
			}
			if err != nil {
				cc.forgetStreamID(cs.ID)
				return nil, cs.getStartedWrite(), err
			}
			if d := cc.responseHeaderTimeout(); d != 0 {
				timer := time.NewTimer(d)
				defer timer.Stop()
				respHeaderTimer = timer.C
			}
		}
	}
}
```


#### http2Transport.newClientConn

```go
func (t *http2Transport) newClientConn(c net.Conn, singleUse bool) (*http2ClientConn, error) {
	cc := &http2ClientConn{
		t:                     t,
		tconn:                 c,
		readerDone:            make(chan struct{}),
		nextStreamID:          1,
		maxFrameSize:          16 << 10,           // spec default
		initialWindowSize:     65535,              // spec default
		maxConcurrentStreams:  1000,               // "infinite", per spec. 1000 seems good enough.
		peerMaxHeaderListSize: 0xffffffffffffffff, // "infinite", per spec. Use 2^64-1 instead.
		streams:               make(map[uint32]*http2clientStream),
		singleUse:             singleUse,
		wantSettingsAck:       true,
		pings:                 make(map[[8]byte]chan struct{}),
	}
	if d := t.idleConnTimeout(); d != 0 {
		cc.idleTimeout = d
		cc.idleTimer = time.AfterFunc(d, cc.onIdleTimeout)
	}
	if http2VerboseLogs {
		t.vlogf("http2: Transport creating client conn %p to %v", cc, c.RemoteAddr())
	}

	cc.cond = sync.NewCond(&cc.mu)
	cc.flow.add(int32(http2initialWindowSize))

	// TODO: adjust this writer size to account for frame size +
	// MTU + crypto/tls record padding.

    // 将net.Conn赋给h2c的write buffer
	cc.bw = bufio.NewWriter(http2stickyErrWriter{c, &cc.werr})
    // 将net.Conn赋给h2c的read buffer
	cc.br = bufio.NewReader(c)
    // 将readBuffer同rightBuffer都交给framer管理
	cc.fr = http2NewFramer(cc.bw, cc.br)
	cc.fr.ReadMetaHeaders = hpack.NewDecoder(http2initialHeaderTableSize, nil)
	cc.fr.MaxHeaderListSize = t.maxHeaderListSize()

	// TODO: SetMaxDynamicTableSize, SetMaxDynamicTableSizeLimit on
	// henc in response to SETTINGS frames?
	cc.henc = hpack.NewEncoder(&cc.hbuf)

	if t.AllowHTTP {
		cc.nextStreamID = 3
	}

	if cs, ok := c.(http2connectionStater); ok {
		state := cs.ConnectionState()
		cc.tlsState = &state
	}

	initialSettings := []http2Setting{
		{ID: http2SettingEnablePush, Val: 0},
		{ID: http2SettingInitialWindowSize, Val: http2transportDefaultStreamFlow},
	}
	if max := t.maxHeaderListSize(); max != 0 {
		initialSettings = append(initialSettings, http2Setting{ID: http2SettingMaxHeaderListSize, Val: max})
	}

    // 发送请求前言 "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
	cc.bw.Write(http2clientPreface)
    // 写入初始化设置
	cc.fr.WriteSettings(initialSettings...)
	cc.fr.WriteWindowUpdate(0, http2transportDefaultConnFlow)
	cc.inflow.add(http2transportDefaultConnFlow + http2initialWindowSize)
	cc.bw.Flush()
	if cc.werr != nil {
		cc.Close()
		return nil, cc.werr
	}

	go cc.readLoop()
	return cc, nil
}
```

1. initialWindowSize流量控制窗口的默认大小为65535
2. maxConcurrentStreams最大并发的stream
3. 连接创建后，会写入前言，初始化设置(是否打开serverPush，初始化的窗口大小)
4. 开启readLoop循环读取conn里来的数据

#### http2ClientConn.readLoop

```go
// readLoop runs in its own goroutine and reads and dispatches frames.
func (cc *http2ClientConn) readLoop() {
	rl := &http2clientConnReadLoop{cc: cc}
	defer rl.cleanup()
	cc.readerErr = rl.run()
	if ce, ok := cc.readerErr.(http2ConnectionError); ok {
		cc.wmu.Lock()
		cc.fr.WriteGoAway(0, http2ErrCode(ce), nil)
		cc.wmu.Unlock()
	}
}
```

1. 用http2clientConnReadLoop封装对conn读取的操作

#### http2clientConnReadLoop.run

```go
func (rl *http2clientConnReadLoop) run() error {
	cc := rl.cc
	rl.closeWhenIdle = cc.t.disableKeepAlives() || cc.singleUse
	gotReply := false // ever saw a HEADERS reply
	gotSettings := false
	readIdleTimeout := cc.t.ReadIdleTimeout
	var t *time.Timer
	if readIdleTimeout != 0 {
		t = time.AfterFunc(readIdleTimeout, cc.healthCheck)
		defer t.Stop()
	}
	for {
        // 循环从conn中读取frame
		f, err := cc.fr.ReadFrame()
		if t != nil {
			t.Reset(readIdleTimeout)
		}
		if err != nil {
			cc.vlogf("http2: Transport readFrame error on conn %p: (%T) %v", cc, err, err)
		}
		if se, ok := err.(http2StreamError); ok {
			if cs := cc.streamByID(se.StreamID, false); cs != nil {
				cs.cc.writeStreamReset(cs.ID, se.Code, err)
				cs.cc.forgetStreamID(cs.ID)
				if se.Cause == nil {
					se.Cause = cc.fr.errDetail
				}
				rl.endStreamError(cs, se)
			}
			continue
		} else if err != nil {
			return err
		}
		if http2VerboseLogs {
			cc.vlogf("http2: Transport received %s", http2summarizeFrame(f))
		}
		if !gotSettings {
			if _, ok := f.(*http2SettingsFrame); !ok {
				cc.logf("protocol error: received %T before a SETTINGS frame", f)
				return http2ConnectionError(http2ErrCodeProtocol)
			}
			gotSettings = true
		}
		maybeIdle := false // whether frame might transition us to idle

		switch f := f.(type) {
		case *http2MetaHeadersFrame:
			err = rl.processHeaders(f)
			maybeIdle = true
			gotReply = true
		case *http2DataFrame:
            // 数据frame，
			err = rl.processData(f)
			maybeIdle = true
		case *http2GoAwayFrame:
            // 远端已关闭
			err = rl.processGoAway(f)
			maybeIdle = true
		case *http2RSTStreamFrame:
            // 重置一个stream
			err = rl.processResetStream(f)
			maybeIdle = true
		case *http2SettingsFrame:
            // 可以通过这个frame调整maxFrameSize，maxConcurrentStreams，peerMaxHeaderListSize
			err = rl.processSettings(f)
		case *http2PushPromiseFrame:
            // 直接告诉对端不要发这种frame
			err = rl.processPushPromise(f)
		case *http2WindowUpdateFrame:
            // 底下通过修改window size来实现流量控制
			err = rl.processWindowUpdate(f)
		case *http2PingFrame:
            // 用来保活的心跳包
			err = rl.processPing(f)
		default:
			cc.logf("Transport: unhandled response frame type %T", f)
		}
		if err != nil {
			if http2VerboseLogs {
				cc.vlogf("http2: Transport conn %p received error from processing frame %v: %v", cc, http2summarizeFrame(f), err)
			}
			return err
		}
		if rl.closeWhenIdle && gotReply && maybeIdle {
			cc.closeIfIdle()
		}
	}
}
```

1. 循环从conn中读取frame
2. 针对不同种类的frame有不同的处理

    - MetaHeadersFrame
    - DataFrame
    - GoAwayFrame
    - RSTStreamFrame
    - SettingsFrame
    - PushPromiseFrame
    - WindowUpdateFrame
    - PingFrame

#### http2Framer.ReadFrame

```go
// 固定的frame header长度
const http2frameHeaderLen = 9

// ReadFrame reads a single frame. The returned Frame is only valid
// until the next call to ReadFrame.
//
// If the frame is larger than previously set with SetMaxReadFrameSize, the
// returned error is ErrFrameTooLarge. Other errors may be of type
// ConnectionError, StreamError, or anything else from the underlying
// reader.
func (fr *http2Framer) ReadFrame() (http2Frame, error) {
	fr.errDetail = nil
	if fr.lastFrame != nil {
		fr.lastFrame.invalidate()
	}
    // 先读出frame header
	fh, err := http2readFrameHeader(fr.headerBuf[:], fr.r)
	if err != nil {
		return nil, err
	}
	if fh.Length > fr.maxReadSize {
		return nil, http2ErrFrameTooLarge
	}

    // 读出frame的payload
	payload := fr.getReadBuf(fh.Length)
	if _, err := io.ReadFull(fr.r, payload); err != nil {
		return nil, err
	}
    // 根据frame类型拿到对应的frameParser，处理后拿到frame
	f, err := http2typeFrameParser(fh.Type)(fr.frameCache, fh, payload)
	if err != nil {
		if ce, ok := err.(http2connError); ok {
			return nil, fr.connError(ce.Code, ce.Reason)
		}
		return nil, err
	}

    // 检查frame的顺序以及streamId是否一致
	if err := fr.checkFrameOrder(f); err != nil {
		return nil, err
	}
	if fr.logReads {
		fr.debugReadLoggerf("http2: Framer %p: read %v", fr, http2summarizeFrame(f))
	}
	if fh.Type == http2FrameHeaders && fr.ReadMetaHeaders != nil {
		return fr.readMetaFrame(f.(*http2HeadersFrame))
	}
	return f, nil
}
```



### 主要数据结构

#### server-conn

```go
type http2serverConn struct {
	// Immutable:
	srv              *http2Server
	hs               *Server
	conn             net.Conn
	bw               *http2bufferedWriter // writing to conn
	handler          Handler
	baseCtx          context.Context
	framer           *http2Framer
	doneServing      chan struct{}               // closed when serverConn.serve ends
	readFrameCh      chan http2readFrameResult   // written by serverConn.readFrames
	wantWriteFrameCh chan http2FrameWriteRequest // from handlers -> serve
	wroteFrameCh     chan http2frameWriteResult  // from writeFrameAsync -> serve, tickles more frame writes
	bodyReadCh       chan http2bodyReadMsg       // from handlers -> serve
	serveMsgCh       chan interface{}            // misc messages & code to send to / run on the serve loop
	flow             http2flow                   // conn-wide (not stream-specific) outbound flow control
	inflow           http2flow                   // conn-wide inbound flow control
	tlsState         *tls.ConnectionState        // shared by all handlers, like net/http
	remoteAddrStr    string
	writeSched       http2WriteScheduler

	// Everything following is owned by the serve loop; use serveG.check():
	serveG                      http2goroutineLock // used to verify funcs are on serve()
	pushEnabled                 bool
	sawFirstSettings            bool // got the initial SETTINGS frame after the preface
	needToSendSettingsAck       bool
	unackedSettings             int    // how many SETTINGS have we sent without ACKs?
	queuedControlFrames         int    // control frames in the writeSched queue
	clientMaxStreams            uint32 // SETTINGS_MAX_CONCURRENT_STREAMS from client (our PUSH_PROMISE limit)
	advMaxStreams               uint32 // our SETTINGS_MAX_CONCURRENT_STREAMS advertised the client
	curClientStreams            uint32 // number of open streams initiated by the client
	curPushedStreams            uint32 // number of open streams initiated by server push
	maxClientStreamID           uint32 // max ever seen from client (odd), or 0 if there have been no client requests
	maxPushPromiseID            uint32 // ID of the last push promise (even), or 0 if there have been no pushes
	streams                     map[uint32]*http2stream
	initialStreamSendWindowSize int32
	maxFrameSize                int32
	headerTableSize             uint32
	peerMaxHeaderListSize       uint32            // zero means unknown (default)
	canonHeader                 map[string]string // http2-lower-case -> Go-Canonical-Case
	writingFrame                bool              // started writing a frame (on serve goroutine or separate)
	writingFrameAsync           bool              // started a frame on its own goroutine but haven't heard back on wroteFrameCh
	needsFrameFlush             bool              // last frame write wasn't a flush
	inGoAway                    bool              // we've started to or sent GOAWAY
	inFrameScheduleLoop         bool              // whether we're in the scheduleFrameWrite loop
	needToSendGoAway            bool              // we need to schedule a GOAWAY frame write
	goAwayCode                  http2ErrCode
	shutdownTimer               *time.Timer // nil until used
	idleTimer                   *time.Timer // nil if unused

	// Owned by the writeFrameAsync goroutine:
	headerWriteBuf bytes.Buffer
	hpackEncoder   *hpack.Encoder

	// Used by startGracefulShutdown.
	shutdownOnce sync.Once
}
```

#### client-conn

```go
// ClientConn is the state of a single HTTP/2 client connection to an
// HTTP/2 server.
type http2ClientConn struct {
	t         *http2Transport
	tconn     net.Conn             // 底层的连接
	tlsState  *tls.ConnectionState // nil only for specialized impls
	reused    uint32               // whether conn is being reused; atomic
	singleUse bool                 // whether being used for a single http.Request

	// readLoop goroutine fields:
	readerDone chan struct{} // closed on error
	readerErr  error         // set before readerDone is closed

	idleTimeout time.Duration // 处理超时相关
	idleTimer   *time.Timer

	mu              sync.Mutex // guards following
	cond            *sync.Cond // hold mu; broadcast on flow/closed changes
	flow            http2flow  // conn级别的流量控制窗口
	inflow          http2flow  // conn级别的流量控制窗口
	closing         bool
	closed          bool
	wantSettingsAck bool                          // we sent a SETTINGS frame and haven't heard back
	goAway          *http2GoAwayFrame             // if non-nil, the GoAwayFrame we received
	goAwayDebug     string                        // goAway frame's debug data, retained as a string
	streams         map[uint32]*http2clientStream // client-initiated
	nextStreamID    uint32
	pendingRequests int                       // requests blocked and waiting to be sent because len(streams) == maxConcurrentStreams
	pings           map[[8]byte]chan struct{} // in flight ping data to notification channel
	bw              *bufio.Writer
	br              *bufio.Reader
	fr              *http2Framer // 用来写入stream里的frame
	lastActive      time.Time
	lastIdle        time.Time // time last idle
	// Settings from peer: (also guarded by mu)
	maxFrameSize          uint32 // 最大能写入的frame大小
	maxConcurrentStreams  uint32
	peerMaxHeaderListSize uint64
	initialWindowSize     uint32

	hbuf    bytes.Buffer // HPACK encoder writes into this
	henc    *hpack.Encoder
	freeBuf [][]byte

	wmu  sync.Mutex // held while writing; acquire AFTER mu if holding both
	werr error      // first write error that has occurred
}
```

#### server-stream

```go
// stream represents a stream. This is the minimal metadata needed by
// the serve goroutine. Most of the actual stream state is owned by
// the http.Handler's goroutine in the responseWriter. Because the
// responseWriter's responseWriterState is recycled at the end of a
// handler, this struct intentionally has no pointer to the
// *responseWriter{,State} itself, as the Handler ending nils out the
// responseWriter's state field.
type http2stream struct {
	// immutable:
	sc        *http2serverConn
	id        uint32
	body      *http2pipe       // non-nil if expecting DATA frames
	cw        http2closeWaiter // closed wait stream transitions to closed state
	ctx       context.Context
	cancelCtx func()

	// owned by serverConn's serve loop:
	bodyBytes        int64     // body bytes seen so far
	declBodyBytes    int64     // or -1 if undeclared
	flow             http2flow // limits writing from Handler to client
	inflow           http2flow // what the client is allowed to POST/etc to us
	state            http2streamState
	resetQueued      bool        // RST_STREAM queued for write; set by sc.resetStream
	gotTrailerHeader bool        // HEADER frame for trailers was seen
	wroteHeaders     bool        // whether we wrote headers (not status 100)
	writeDeadline    *time.Timer // nil if unused

	trailer    Header // accumulated trailers
	reqTrailer Header // handler's Request.Trailer
}
```

#### client-stream

```go
// clientStream is the state for a single HTTP/2 stream. One of these
// is created for each Transport.RoundTrip call.
type http2clientStream struct {
	cc            *http2ClientConn // 所属的连接
	req           *Request  // 发起stream的源请求
	trace         *httptrace.ClientTrace // 追踪相关
	ID            uint32 // 唯一id
	resc          chan http2resAndError
	bufPipe       http2pipe // 每次从dataFrame里读到的内容会写到这里
	startedWrite  bool      // started request body write; guarded by cc.mu
	requestedGzip bool // 是否经由gzip压缩过
	on100         func() // optional code to run if get a 100 continue response

	flow        http2flow // guarded by cc.mu 用来控制流量窗口的大小
	inflow      http2flow // guarded by cc.mu 用来控制流量窗口的大小
	bytesRemain int64     // -1 means unknown; owned by transportResponseBody.Read
	readErr     error     // sticky read error; owned by transportResponseBody.Read
	stopReqBody error     // if non-nil, stop writing req body; guarded by cc.mu
	didReset    bool      // whether we sent a RST_STREAM to the server; guarded by cc.mu

	peerReset chan struct{} // closed on peer reset
	resetErr  error         // populated before peerReset is closed

	done chan struct{} // closed when stream remove from cc.streams map; close calls guarded by cc.mu

	// owned by clientConnReadLoop:
	firstByte    bool  // got the first response byte
	pastHeaders  bool  // got first MetaHeadersFrame (actual headers)
	pastTrailers bool  // got optional second MetaHeadersFrame (trailers)
	num1xx       uint8 // number of 1xx responses seen

	trailer    Header  // accumulated trailers
	resTrailer *Header // client's Response.Trailer
}
```

#### frames

frame-header

```go
// A FrameHeader is the 9 byte header of all HTTP/2 frames.
//
// See http://http2.github.io/http2-spec/#FrameHeader
type http2FrameHeader struct {
	valid bool // caller can access []byte fields in the Frame

	// Type is the 1 byte frame type. There are ten standard frame
	// types, but extension frame types may be written by WriteRawFrame
	// and will be returned by ReadFrame (as UnknownFrame).
	Type http2FrameType

	// Flags are the 1 byte of 8 potential bit flags per frame.
	// They are specific to the frame type.
	Flags http2Flags

	// Length is the length of the frame, not including the 9 byte header.
	// The maximum size is one byte less than 16MB (uint24), but only
	// frames up to 16KB are allowed without peer agreement.
	Length uint32

	// StreamID is which stream this frame is for. Certain frames
	// are not stream-specific, in which case this field is 0.
	StreamID uint32
}
```

##### settings-frame

```go
// A SettingsFrame conveys configuration parameters that affect how
// endpoints communicate, such as preferences and constraints on peer
// behavior.
//
// See http://http2.github.io/http2-spec/#SETTINGS
type http2SettingsFrame struct {
	http2FrameHeader
	p []byte
}
```

##### meta-headers

```go
// A MetaHeadersFrame is the representation of one HEADERS frame and
// zero or more contiguous CONTINUATION frames and the decoding of
// their HPACK-encoded contents.
//
// This type of frame does not appear on the wire and is only returned
// by the Framer when Framer.ReadMetaHeaders is set.
type http2MetaHeadersFrame struct {
	*http2HeadersFrame

	// Fields are the fields contained in the HEADERS and
	// CONTINUATION frames. The underlying slice is owned by the
	// Framer and must not be retained after the next call to
	// ReadFrame.
	//
	// Fields are guaranteed to be in the correct http2 order and
	// not have unknown pseudo header fields or invalid header
	// field names or values. Required pseudo header fields may be
	// missing, however. Use the MetaHeadersFrame.Pseudo accessor
	// method access pseudo headers.
	Fields []hpack.HeaderField

	// Truncated is whether the max header list size limit was hit
	// and Fields is incomplete. The hpack decoder state is still
	// valid, however.
	Truncated bool
}
```

##### window-update

```go
// A WindowUpdateFrame is used to implement flow control.
// See http://http2.github.io/http2-spec/#rfc.section.6.9
type http2WindowUpdateFrame struct {
	http2FrameHeader
	Increment uint32 // never read with high bit set
}
```

##### ping

```go
// A PingFrame is a mechanism for measuring a minimal round trip time
// from the sender, as well as determining whether an idle connection
// is still functional.
// See http://http2.github.io/http2-spec/#rfc.section.6.7
type http2PingFrame struct {
	http2FrameHeader
	Data [8]byte
}
```

##### data

```go
// A DataFrame conveys arbitrary, variable-length sequences of octets
// associated with a stream.
// See http://http2.github.io/http2-spec/#rfc.section.6.1
type http2DataFrame struct {
	http2FrameHeader
	data []byte
}
```

##### rst-stream

```go
// A RSTStreamFrame allows for abnormal termination of a stream.
// See http://http2.github.io/http2-spec/#rfc.section.6.4
type http2RSTStreamFrame struct {
	http2FrameHeader
	ErrCode http2ErrCode
}
```

##### priority

```go
// A PriorityFrame specifies the sender-advised priority of a stream.
// See http://http2.github.io/http2-spec/#rfc.section.6.3
type http2PriorityFrame struct {
	http2FrameHeader
	http2PriorityParam
}
```

##### go-away

```go
// A GoAwayFrame informs the remote peer to stop creating streams on this connection.
// See http://http2.github.io/http2-spec/#rfc.section.6.8
type http2GoAwayFrame struct {
	http2FrameHeader
	LastStreamID uint32
	ErrCode      http2ErrCode
	debugData    []byte
}
```

##### push-promise

```go
// A PushPromiseFrame is used to initiate a server stream.
// See http://http2.github.io/http2-spec/#rfc.section.6.6
type http2PushPromiseFrame struct {
	http2FrameHeader
	PromiseID     uint32
	headerFragBuf []byte // not owned
}
```
