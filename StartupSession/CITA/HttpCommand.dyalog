﻿:Class HttpCommand
⍝ General HTTP Commmand utility
⍝ Documentation is found at https://dyalog.github.io/HttpCommand

    ⎕ML←⎕IO←1
    :field public Command←''                       ⍝ HTTP command
    :field public URL←''                           ⍝ requested resource
    :field public Params←''                        ⍝ request parameters
    :field public Headers←0 2⍴⊂''                  ⍝ request headers - name, value
    :field public ContentType←''                   ⍝ request content-type
    :field public Cookies←⍬                        ⍝ request cookies - vector of namespaces
    :field public Result                           ⍝ command result namespace
    :field public WaitTime←30                      ⍝ seconds to wait for a response before timing out
    :field public SuppressHeaders←0                ⍝ set to 1 to suppress HttpCommand-supplied default request headers

    :field public Cert←⍬                           ⍝ X509 instance if using HTTPS
    :field public SSLFlags←32                      ⍝ SSL/TLS flags - 32 = accept cert without checking it
    :field public Priority←'NORMAL:!CTYPE-OPENPGP' ⍝ default GnuTLS priority string
    :field public PublicCertFile←''                ⍝ if not using an X509 instance, this is the client public certificate file
    :field public PrivateKeyFile←''                ⍝ if not using an X509 instance, this is the client private key file

    :field public RequestOnly←0                    ⍝ set to 1 if you only want to return the generated HTTP request, but not actually send it
    :field public Outfile←''                       ⍝ name of file to send payload to (or to buffer to when streaming) and optional '/append'/'replace'
    :field public MaxRedirections←10               ⍝ set to 0 if you don't want to follow any redirected references, ¯1 for unlimited
    :field public KeepAlive←1                      ⍝ default to not close client connection

    :field public shared Debug←0                   ⍝ set to 1 to disable trapping

    :field public shared CongaRef←''               ⍝ user-supplied reference to Conga library
    :field public shared LDRC                      ⍝ HttpCommand-set reference to Conga after CongaRef has been resolved

    :field public readonly shared ValidFormUrlEncodedChars←'&=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~*+~%'

    :field Client←''                               ⍝ Conga client ID
    :field Public HostSecure←''                    ⍝ when a client is made, its host and secure settings are saved so that if either changes, we close the previous client

    ∇ r←Version
    ⍝ Return the current version
      :Access public shared
      r←'HttpCommand' '4.0' '2021-09-10'
    ∇

    ∇ make
    ⍝ No argument constructor
      :Access public
      :Implements constructor
      Result←initResult #.⎕NS''
    ∇

    ∇ make1 args;settings;invalid
    ⍝ Constructor arguments - [Command URL Params Headers Cert SSLFlags Priority]
      :Access public
      :Implements constructor
      args←(eis⍣({9.1≠⎕NC⊂,'⍵'}⊃args)⊢args)
      :Select {⊃⎕NC⊂,'⍵'}⊃args
      :Case 2.1 ⍝ array
          Command URL Params Headers Cert SSLFlags Priority←7↑args,(⍴args)↓Command URL Params Headers Cert SSLFlags Priority
      :Case 9.1 ⍝ namespace
          :If 0∊⍴invalid←(settings←args.⎕NL ¯2.1)~(⎕NEW⊃⊃⎕CLASS ⎕THIS).⎕NL ¯2.2
              args{⍎⍵,'←⍺⍎⍵'}¨settings
          :Else ⋄ ('Invalid HttpCommand setting(s): ',,⍕invalid)⎕SIGNAL 11
          :EndIf
      :Else ⋄ 'Invalid constructor argument'⎕SIGNAL 11
      :EndSelect
      Result←initResult #.⎕NS''
    ∇

    ∇ {ns}←initResult ns
    ⍝ initialize the namespace result
      :Access shared
      ns.(Command URL rc msg HttpVer HttpStatus HttpMessage Headers Data PeerCert Redirections Cookies)←'' '' ¯1 '' ''⍬''(0 2⍴⊂'')''⍬(0⍴⊂'')⍬
    ∇

    ∇ Goodbye
      :Implements destructor
      {}{0::'' ⋄ LDRC.Names'.'⊣LDRC.Close ⍵}⍣(~0∊⍴Client)⊢Client
    ∇

    ∇ r←Config
    ⍝ Returns current configuration
      :Access public
      r←↑{6::⍵'not set' ⋄ ⍵(⍎⍵)}¨⎕THIS⍎'⎕NL ¯2.2'
    ∇

    ∇ r←Run
    ⍝ Attempt to run the HTTP command
      :Access public
      r←(Cert SSLFlags Priority PublicCertFile PrivateKeyFile)(Command HttpCmd)URL Params Headers
    ∇

    ∇ {r}←setDisplayFormat r
    ⍝ set the display format for the namespace result for most HttpCommand commands
      r.⎕DF 1⌽'][rc: ',(⍕r.rc),' | msg: "',r.msg,'"',(r.rc≥0)/' | HTTP Status: ',(⍕r.HttpStatus),' "',r.HttpMessage,'" | ⍴Data: ',⍕⍴r.Data
    ∇

    ∇ r←{requestOnly}Get args;hc;Result
    ⍝ Shared method to perform an HTTP GET request
    ⍝ args - [URL Params Headers Cert SSLFlags Priority]
      :Access public shared
      :If 0=⎕NC'requestOnly' ⋄ requestOnly←0 ⋄ :EndIf
      :Trap Debug↓0
          :Select ⊃{⎕NC⊂,'⍵'}⊃args
          :Case 9.1 ⋄ hc←⎕NEW ⎕THIS args ⍝ don't need to set Command (defaults to 'GET')
          :Case 2.1 ⋄ hc←⎕NEW ⎕THIS((⊂'GET'),eis args)
          :Else ⋄ 'Invalid right argument'{⍺ ⎕SIGNAL ⍵}11
          :EndSelect
      :Else
          →∆EXIT⊣r←¯1 bail ⎕DMX.EM
      :EndTrap
      hc.RequestOnly←requestOnly
      r←hc.Run
     ∆EXIT:
    ∇

    ∇ r←{requestOnly}Do args;hc
    ⍝ Shared method to perform any HTTP request
    ⍝ args - [Command URL Params Headers Cert SSLFlags Priority]
      :Access public shared
      :If 0=⎕NC'requestOnly' ⋄ requestOnly←0 ⋄ :EndIf
      :Trap Debug↓0
          hc←⎕NEW ⎕THIS(eis⍣({9.1≠⎕NC⊂,'⍵'}⊃args)⊢args)
      :Else
          →∆EXIT⊣r←¯1 bail ⎕DMX.EM
      :EndTrap
      hc.RequestOnly←requestOnly
      r←hc.Run
     ∆EXIT:
    ∇

    ∇ r←{requestOnly}GetJSON args;cmd;Result
    ⍝ Shared method to perform an HTTP request with JSON data as the request and response payloads
    ⍝ args - [Command URL Params Headers Cert SSLFlags Priority]
      :Access public shared
      :If 0=⎕NC'requestOnly' ⋄ requestOnly←0 ⋄ :EndIf
      :Trap Debug↓0
          cmd←⎕NEW ⎕THIS(eis⍣({9.1≠⎕NC⊂,'⍵'}⊃args)⊢args)
      :Else
          →∆EXIT⊣r←¯1 bail ⎕DMX.EM
      :EndTrap
      cmd.RequestOnly←requestOnly
      cmd.ContentType←'application/json'
     
      :If 0∊⍴cmd.Command ⋄ cmd.Command←(1+0∊⍴cmd.Params)⊃'POST' 'GET' ⋄ :EndIf
      :If ~0∊⍴cmd.Params
          :Trap Debug↓0
              cmd.Params←1 ⎕JSON cmd.Params
          :Else
              r←cmd.Result
              →∆DONE⊣r.(rc msg)←¯1 'Could not convert parameters to JSON format'
          :EndTrap
      :EndIf
      r←cmd.Run
      →requestOnly⍴∆EXIT
     
      :If r.rc=0
          →∆DONE⍴⍨204=r.HttpStatus ⍝ exit if "no content" HTTP status
          :If 200=r.HttpStatus
              :If ∨/'application/json'⍷lc r.Headers Lookup'content-type'
                  :Trap Debug↓0
                      r.Data←⎕JSON r.Data
                  :Else ⋄ →∆DONE⊣r.(rc msg)←1 'Could not convert response payload to JSON format'
                  :EndTrap
              :Else ⋄ →∆DONE⊣r.(rc msg)←2 'Response content-type is not application/json'
              :EndIf
          :Else ⋄ →∆DONE⊣r.(rc msg)←3 'HTTP failure'
          :EndIf
      :EndIf
      →∆EXIT
     ∆DONE: ⍝ reset ⎕DF if messages have changed
      setDisplayFormat r
     ∆EXIT:
    ∇

    ∇ ns←rc bail msg
    ⍝ Called if ⎕NEW fails
      ns←initResult #.⎕NS''
      ns.(rc msg)←rc msg
      setDisplayFormat ns
    ∇

    ∇ r←Init r;ref;root;nc;class;n;ns;congaCopied
      ⍝↓↓↓ Check if LDRC exists (VALUE ERROR (6) if not), and is LDRC initialized? (NONCE ERROR (16) if not)
      :Hold 'HttpCommandInit'
          :If {6 16 999::1 ⋄ ''≡LDRC:1 ⋄ 0⊣LDRC.Describe'.'}''
              LDRC←''
              :If 9=#.⎕NC'Conga' ⋄ {#.Conga.X509Cert.LDRC←''}⍬ ⋄ :EndIf ⍝ if #.Conga exists, reset X509Cert.LDRC reference
              :If ~0∊⍴CongaRef  ⍝ did the user supply a reference to Conga?
                  LDRC←ResolveCongaRef CongaRef
                  →∆END↓⍨0∊⍴r.msg←(''≡LDRC)/'CongaRef (',(⍕CongaRef),') does not point to a valid instance of Conga'
              :Else
                  :For root :In ##.## #
                      ref nc←root{1↑¨⍵{(×⍵)∘/¨⍺ ⍵}⍺.⎕NC ⍵}ns←'Conga' 'DRC'
                      :If 9=⊃⌊nc ⋄ :Leave ⋄ :EndIf
                  :EndFor
                  :If 9=⊃⌊nc
                      LDRC←ResolveCongaRef root⍎∊ref
                      →∆END↓⍨0∊⍴r.msg←(''≡LDRC)/(⍕root),'.',(∊ref),' does not point to a valid instance of Conga'
                      →∆COPY↓⍨{999::0 ⋄ 1⊣LDRC.Describe'.'}'' ⍝ it's possible that Conga was saved in a semi-initialized state
                  :Else
     ∆COPY:
                      class←⊃⊃⎕CLASS ⎕THIS
                      congaCopied←0
                      :For n :In ns
                          :Trap Debug↓0
                              n class.⎕CY dyalogRoot,'ws/conga'
                              LDRC←ResolveCongaRef class⍎n
                              →∆END↓⍨0∊⍴r.msg←(''≡LDRC)/n,' was copied from [DYALOG]/ws/conga, but is not valid'
                              congaCopied←1
                              :Leave
                          :EndTrap
                      :EndFor
                      →∆END↓⍨0∊⍴r.msg←(~congaCopied)/'Neither Conga nor DRC were successfully copied from [DYALOG]/ws/conga'
                  :EndIf
              :EndIf
          :EndIf
     ∆END:
      :EndHold
    ∇

    ∇ LDRC←ResolveCongaRef CongaRef;z;failed
    ⍝ CongaRef could be a charvec, reference to the Conga or DRC namespaces, or reference to an iConga instance
      LDRC←'' ⋄ failed←0
      :Select ⎕NC⊂'CongaRef' ⍝ what is it?
      :Case 9.1 ⍝ namespace?  e.g. CongaRef←DRC or Conga
     ∆TRY:
          :Trap Debug↓0
              :If ∨/'.Conga'⍷⍕CongaRef ⋄ LDRC←CongaRef.Init'HttpCommand' ⍝ is it Conga?
              :ElseIf 0≡⊃CongaRef.Init'' ⋄ LDRC←CongaRef ⍝ DRC?
              :Else ⋄ →∆EXIT⊣LDRC←''
              :End
          :Else ⍝ if HttpCommand is reloaded and re-executed in rapid succession, Conga initialization may fail, so we try twice
              :If failed ⋄ →∆EXIT⊣LDRC←''
              :Else ⋄ →∆TRY⊣failed←1
              :EndIf
          :EndTrap
      :Case 9.2 ⍝ instance?  e.g. CongaRef←Conga.Init ''
          LDRC←CongaRef ⍝ an instance is already initialized
      :Case 2.1 ⍝ variable?  e.g. CongaRef←'#.Conga'
          :Trap Debug↓0
              LDRC←ResolveCongaRef(⍎∊⍕CongaRef)
          :EndTrap
      :EndSelect
     ∆EXIT:
    ∇

    ∇ (rc secureParams)←CreateSecureParams(cert flags priority public private);nmt;msg;t
    ⍝ called by HttpCommand
    ⍝ certs is:
    ⍝    [1] X509Cert instance or (PublicCertFile PrivateKeyFile)
    ⍝    [2] SSL flags
    ⍝    [3] GnuTLS priority
    ⍝    [4] PublicCertFile
    ⍝    [5] PrivateKeyFile
    ⍝ if certs is empty, check PublicCertFile and PrivateKeyFile
     
      LDRC.X509Cert.LDRC←LDRC ⍝ make sure the X509 instance points to the right LDRC
     
      :If 0∊⍴cert ⍝ if X509 (or public private) not supplied
     ∆CHECK:
          :If ∨/nmt←(~0∊⍴)¨public private ⍝ either file name not empty?
              :If ∧/nmt ⍝ if so, both need to be non-empty
                  :If ∨/t←{0::1 ⋄ ~⎕NEXISTS ⍵}¨public private ⍝ either file not exist?
                      →∆FAIL⊣msg←'Not found',4↓∊{' and ',(∊⍕⍵),' "',(∊⍕⍎⍵),'"'}¨t/'PublicCertFile' 'PrivateKeyFile'
                  :EndIf
                  :Trap Debug↓0
                      cert←⊃LDRC.X509Cert.ReadCertFromFile public
                  :Else ⋄ →∆FAIL⊣msg←'Unable to decode PublicCertFile "',(∊⍕public),'" as certificate'
                  :EndTrap
                  cert.KeyOrigin←'DER'private
              :Else ⋄ →∆FAIL⊣msg←(⊃nmt/'PublicCertFile' 'PrivateKeyFile'),' is empty' ⍝ both must be specified
              :EndIf
          :Else
              cert←⎕NEW LDRC.X509Cert
          :EndIf
      :ElseIf 2=⍴cert ⍝ 2-element vector of public/private file names?
          public private←cert
          →∆CHECK
      :ElseIf {0::1 ⋄ 'X509Cert'≢{⊃⊢/'.'(≠⊆⊢)⍵}⍕⎕CLASS ⍵}cert
          →∆FAIL⊣msg←'Invalid certificate parameter'
      :EndIf
      secureParams←('x509'cert)('SSLValidation'flags)('Priority'priority)
      →rc←0
     ∆FAIL:(rc secureParams)←¯1 msg ⍝ failure
    ∇

    ∇ r←certs(cmd HttpCmd)args;url;parms;hdrs;urlparms;p;b;secure;port;host;path;auth;req;err;chunked;done;data;datalen;header;headerlen;rc;donetime;formContentType;ind;len;obj;evt;dat;z;contentType;msg;timedOut;certfile;keyfile;secureParams;simpleChar;defaultPort;cookies;domain;t
    ⍝ issue an HTTP command
    ⍝ certs - X509Cert|(PublicCertFile PrivateKeyFile) SSLValidation Priority PublicCertFile PrivateKeyFile
    ⍝ args  - [1] URL in format [HTTP[S]://][user:pass@]url[:port][/path[?query_string]]
    ⍝         {2} parameters is using POST - either a namespace or URL-encoded string
    ⍝         {3} HTTP headers in form {↑}(('hdr1' 'val1')('hdr2' 'val2'))
    ⍝         {4} cookies in form {↑}(('cookie1' 'val1')('cookie2' 'val2'))
    ⍝ Makes secure connection if left arg provided or URL begins with https:
     
    ⍝ Result: namespace containing (conga return code) (HTTP Status) (HTTP headers) (HTTP body) [PeerCert if secure]
     
      :If 0∊⍴cmd ⋄ cmd←'GET' ⋄ :EndIf
     
      args←eis args
      (url parms hdrs cookies)←args,(⍴args)↓''(#.⎕NS'')'' ''
     
      r←Result
     
    ⍝ Do some cursory parameter checking
      →∆END↓⍨0∊⍴r.msg←'No URL specified'/⍨0∊⍴url ⍝ exit early if no URL
      →∆END↓⍨0∊⍴r.msg←'URL is not a simple character vector'/⍨~isSimpleChar url
      →∆END↓⍨0∊⍴r.msg←'Headers are not character'/⍨~(0∊⍴hdrs)∨⍥(1∘↑)isChar hdrs
      →∆END↓⍨0∊⍴r.msg←'Cookies are not character'/⍨~(0∊⍴hdrs)∨⍥(1∘↑)isChar cookies
      hdrs←{0::¯1 ⋄ 0∊t←⍴⍵:0 2⍴⊂'' ⋄ 3=|≡⍵:↑eis∘,¨⍵ ⋄ 2=≢t:⍵ ⋄ ((0.5×t),2)⍴⍵}hdrs
      →∆END↓⍨0∊⍴msg←'Improper header format'/⍨¯1≡hdrs
     
      :If ~RequestOnly ⋄ →∆END↓⍨0∊⍴(Init r).msg ⋄ :EndIf  ⍝ don't bother initializing Conga if only returning request
     
      url←,url
      cmd←uc,cmd
     
     ∆GET:
     
      (secure host path urlparms)←parseURL url
      secure∨←⍲/{0∊⍴⍵}¨certs[1 4] ⍝ we're secure if URL begins with https/wss (checked by parseURL), or we have a cert or a PublicCertFile
      secureParams←''
      :If secure>RequestOnly ⍝ don't bother generating certificate if only returning request
          :If 0≠⊃(rc secureParams)←CreateSecureParams certs
              →∆END⊣r.msg←secureParams
          :EndIf
      :EndIf
     
      :If '@'∊host ⍝ Handle user:password@host...
          auth←'Authorization: Basic ',(Base64Encode(¯1+p←host⍳'@')↑host),NL
          host←p↓host
      :Else ⋄ auth←''
      :EndIf
     
      :If defaultPort←(≢host)<ind←host⍳':' ⍝ then if there's no port specified in the host
          port←(1+secure)⊃80 443 ⍝ use the default HTTP/HTTPS port
      :Else
          :If 0=port←⊃toInt ind↓host ⋄ →∆END⊣r.msg←'Invalid host/port - ',host ⋄ :EndIf
          host↑⍨←ind-1
      :EndIf
     
      :If 0∊⍴host ⋄ →∆END⊣r.msg←'No host specified' ⋄ :EndIf
     
      :If ~(port>0)∧(port≤65535)∧port=⌊port ⋄ →∆END⊣r.msg←'Invalid port - ',⍕port ⋄ :EndIf
     
      r.(Secure Host Path)←secure(lc host)({{'/',¯1↓⍵/⍨⌽∨\'/'=⌽⍵}⍵↓⍨'/'=⊃⍵}path)
     
      hdrs←makeHeaders hdrs
      :If ~SuppressHeaders
          hdrs←'User-Agent'(hdrs addHeader)'Dyalog/Conga'
          hdrs←'Accept'(hdrs addHeader)'*/*'
          :If '∘???∘'≡hdrs Lookup'cookie' ⍝ if the user has specified a cookie header, it takes precedence
          :AndIf ~0∊⍴cookies←r applyCookies Cookies
              hdrs←'Cookie'(hdrs addHeader)formatCookies cookies
          :EndIf
      :EndIf
     
      :If ~0∊⍴parms                  ⍝ if we have any parameters
          :If (⊆cmd)∊'GET' 'HEAD'    ⍝ if the command is GET or HEAD
              :If {2≠⎕NC'⍵':0 ⋄ 1≥|≡⍵}parms ⍝ simple vector or scalar and not a reference
                  parms←⍕parms       ⍝ deal with possible numeric
              :Else
                  parms←UrlEncode parms
              :EndIf
              urlparms,←(0∊⍴urlparms)↓'&',parms
              parms←''
          :Else    ⍝ not a GET or HEAD command
              ⍝↓↓↓ specify the default content type (if not already specified)
              :If ~SuppressHeaders
                  hdrs←'Content-Type'(hdrs addHeader)formContentType←'application/x-www-form-urlencoded'
              :EndIf
              contentType←hdrs Lookup'Content-Type'
              simpleChar←{1<≢⍴⍵:0 ⋄ (⎕DR ⍵)∊80 82}parms
              :Select ⊃';'(≠⊆⊢)contentType
              :Case formContentType
                  :If simpleChar ⍝ if simple character, parms is assumed to already be
                      :If ~∧/parms∊ValidFormUrlEncodedChars
                          →∆END⊣r.msg←'Params is not a valid URLEncoded string'
                      :EndIf
                  :Else
                      parms←UrlEncode parms
                  :EndIf
              :Case 'application/json'
                  :If ~simpleChar ⍝ if it's a simple charvec, assume it's already JSON format
                      parms←1 ⎕JSON parms
                  :EndIf
              :EndSelect
              :If ~SuppressHeaders
                  hdrs←'Content-Length'(hdrs addHeader)⍴parms
              :EndIf
          :EndIf
      :EndIf
     
     
⍝↓↓↓ If using HEAD method, don't indicate we accept compressed responses
⍝    this way content-length in the response reflects the actual size of the response
⍝    The user can always add the header manually if he wants the compressed size
      :If SuppressHeaders<'HEAD'≢cmd ⋄ hdrs←'Accept-Encoding'(hdrs addHeader)'gzip, deflate' ⋄ :EndIf
     
      req←cmd,' ',(path,(0∊⍴urlparms)↓'?',urlparms),' HTTP/1.1',NL,(~SuppressHeaders)/'Host: ',host,((~defaultPort)/':',⍕port),NL
      req,←fmtHeaders hdrs
      req,←(~SuppressHeaders)/auth
     
      donetime←⌊⎕AI[3]+1000×WaitTime ⍝ time after which we'll time out
     
      :If RequestOnly
          →∆EXIT⊣r←req,NL,parms
      :EndIf
     
      :If ~0∊⍴Client                    ⍝ do we have a client already?
      :AndIf HostSecure≢r.(Host Secure) ⍝ did we change host or secure?
          {}{0::'' ⋄ LDRC.Close ⍵}Client     ⍝ if so, close the client
          HostSecure←r.(Host Secure)    ⍝ and capture the new settings
      :EndIf
     
      :If 0=⊃(err Client)←2↑rc←LDRC.Clt''host port'http' 100000,secureParams ⍝ 100,000 is max receive buffer size
     
          {}LDRC.SetProp Client'DecodeBuffers' 15 ⍝ set advanced HTTP parsing
     
          :If 0=⊃rc←LDRC.Send Client(req,NL,parms)
              (timedOut done data datalen headerlen header chunked)←0 0 ⍬ 0 0 ⍬ 0
     
              :Repeat
                  :If ~done←0≠err←1⊃rc←LDRC.Wait Client 5000            ⍝ Wait up to 5 secs
                      (err obj evt dat)←4↑rc
                      :Select evt
                      :Case 'HTTPHeader'
                          :If 1=≡dat ⋄ →∆END⊣r.(Data msg)←dat'Conga failed to parse the response HTTP header' ⍝ HTTP header parsing failed?
                          :Else
                              r.(HttpVersion HttpStatus HttpMessage)←3↑dat
                              header←4⊃dat
                              datalen←⊃toInt{'∘???∘'≡⍵:'¯1' ⋄ ⍵}header Lookup'Content-Length' ⍝ ¯1 if no content length not specified
                              chunked←∨/'chunked'⍷header Lookup'Transfer-Encoding'
                              done←(cmd≡'HEAD')∨chunked<datalen<1
                           ⍝↓↓↓ hack to deal with HTTP/1.0 behavior of no content-length and no transfer-encoding
                           ⍝    see item 7 under https://tools.ietf.org/html/rfc7230#section-3.3.3
                              :If chunked<datalen=¯1
                              :AndIf ∨/'close'⍷header Lookup'Connection' ⍝←←← not sure this is necessary
                                  :Repeat
                                      rc←LDRC.Wait Client 50
                                  :Until 100≠⊃rc
                                  :If 0=⊃rc
                                  :AndIf rc[3]∊'BlkLast' 'HTTPBody' ⋄ data←4⊃rc
                                  :EndIf
                              :EndIf
                          :EndIf
                      :Case 'HTTPBody' ⋄ data←dat ⋄ done←1
                      :Case 'HTTPChunk'
                          :If 1=≡dat ⋄ →∆END⊣r.(Data msg)←dat'Conga failed to parse the response HTTP chunk' ⍝ HTTP chunk parsing failed?
                          :Else ⋄ data,←1⊃dat
                          :EndIf
                      :Case 'HTTPTrailer'
                          :If 2≠≢⍴dat ⋄ →∆END⊣r.(Data msg)←dat'Conga failed to parse the response HTTP trailer' ⍝ HTTP trailer parsing failed?
                          :Else ⋄ header⍪←dat ⋄ done←1
                          :EndIf
                      :Case 'HTTPFail' ⋄ →∆END⊣r.(Data msg)←dat'Conga failed to parse the HTTP reponse'
                      :Case 'Timeout' ⋄ timedOut←done←⎕AI[3]>donetime
                      :Case 'Error' ⋄ →∆END⊣r.msg←'Conga error processing your request: ',,⍕rc
                      :Else ⋄ →∆END⊣r.msg←'*** Unhandled Conga event type - ',evt ⍝ This shouldn't happen
                      :EndSelect
                  :ElseIf 100=err ⋄ timedOut←done←⎕AI[3]>donetime ⍝ timeout?
                  :Else ⋄ r.msg←'Conga wait error ',,⍕rc ⍝ some other error (very unlikely)
                  :EndIf
              :Until done
     
              :If timedOut ⋄ →∆END⊣r.(rc msg)←(⊃rc)'Request timed out before server responded'
              :EndIf
              :If 0=err
                  r.HttpStatus←toInt r.HttpStatus
                  :Trap Debug↓0 ⍝ If any errors occur, abandon conversion
                      :Select z←header Lookup'content-encoding' ⍝ was the response compressed?
                      :Case '∘???∘' ⍝ no content-encoding header, do nothing
                      :Case 'deflate'
                          data←120 ¯100{(2×⍺≡2↑⍵)↓⍺,⍵}83 ⎕DR data ⍝ append 120 156 signature because web servers strip it out due to IE
                          data←fromutf8 256|¯2(219⌶)data
                      :Case 'gzip' ⋄ data←fromutf8 256|¯3(219⌶)83 ⎕DR data
                      :Else ⋄ r.msg←'Unhandled content-encoding: ',z
                      :EndSelect
     
                      :If 0<≢'charset\s*=\s*utf-8'⎕S'&'⍠1⊢header Lookup'content-type'
                          data←'UTF-8'⎕UCS ⎕UCS data ⍝ Convert from UTF-8
                          data←(65279=⎕UCS⊃data)↓data ⍝ drop off BOM, if any
                      :EndIf
                  :EndTrap
                  (domain path)←r.(Host Path)
                  Cookies←Cookies updateCookies r.Cookies←parseCookies header domain(extractPath path) ⍝!!!
                  :If (r.HttpStatus∊301 302 303 307 308)>0=MaxRedirections ⍝ if redirected and allowing redirections
                      :If MaxRedirections<.=¯1,≢r.Redirections ⋄ →∆END⊣r.(rc msg)←¯1('Too many redirections (',(⍕MaxRedirections),')')
                      :Else
                          :If '∘???∘'≢url←header Lookup'location' ⍝ if we were redirected use the "location" header field for the URL
                              r.Redirections,←t←#.⎕NS''
                              t.Headers←header
                              t.(URL HttpVersion HttpStatus HttpMessage)←r.(URL HttpVersion HttpStatus HttpMessage)
                              (secure domain path urlparms)←parseURL url
                              {}LDRC.Close Client
                              cmd←(1+303=r.HttpStatus)⊃cmd'GET' ⍝ 303 (See Other) is always followed by a 'GET'. See https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/303
                              →∆GET
                          :Else ⋄ r.msg←'Redirection detected, but no "location" header supplied.' ⍝ should never happen from a properly functioning server
                          :EndIf
                      :EndIf
                  :EndIf
                  :If secure
                  :AndIf 0=⊃z←LDRC.GetProp Client'PeerCert' ⋄ r.PeerCert←2⊃z
                  :EndIf
              :EndIf
              r.(Headers Data)←header data
          :Else ⋄ r.msg←'Conga connection failed ',,⍕1↓rc
          :EndIf
      :Else ⋄ r.msg←'Conga client creation failed ',,⍕1↓rc
      :EndIf
      r.rc←1⊃rc ⍝ set the return code to the Conga return code
     ∆END:
      {}{0::⍬ ⋄ LDRC.Close⍣(~KeepAlive)⊢Client}⍬
      setDisplayFormat r
     ∆EXIT:
    ∇

    NL←⎕UCS 13 10
    fromutf8←{0::(⎕AV,'?')[⎕AVU⍳⍵] ⋄ 'UTF-8'⎕UCS ⍵} ⍝ Turn raw UTF-8 input into text
    utf8←{3=10|⎕DR ⍵: 256|⍵ ⋄ 'UTF-8' ⎕UCS ⍵}
    sint←{⎕io←0 ⋄ 83=⎕DR ⍵:⍵ ⋄ 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 ¯128 ¯127 ¯126 ¯125 ¯124 ¯123 ¯122 ¯121 ¯120 ¯119 ¯118 ¯117 ¯116 ¯115 ¯114 ¯113 ¯112 ¯111 ¯110 ¯109 ¯108 ¯107 ¯106 ¯105 ¯104 ¯103 ¯102 ¯101 ¯100 ¯99 ¯98 ¯97 ¯96 ¯95 ¯94 ¯93 ¯92 ¯91 ¯90 ¯89 ¯88 ¯87 ¯86 ¯85 ¯84 ¯83 ¯82 ¯81 ¯80 ¯79 ¯78 ¯77 ¯76 ¯75 ¯74 ¯73 ¯72 ¯71 ¯70 ¯69 ¯68 ¯67 ¯66 ¯65 ¯64 ¯63 ¯62 ¯61 ¯60 ¯59 ¯58 ¯57 ¯56 ¯55 ¯54 ¯53 ¯52 ¯51 ¯50 ¯49 ¯48 ¯47 ¯46 ¯45 ¯44 ¯43 ¯42 ¯41 ¯40 ¯39 ¯38 ¯37 ¯36 ¯35 ¯34 ¯33 ¯32 ¯31 ¯30 ¯29 ¯28 ¯27 ¯26 ¯25 ¯24 ¯23 ¯22 ¯21 ¯20 ¯19 ¯18 ¯17 ¯16 ¯15 ¯14 ¯13 ¯12 ¯11 ¯10 ¯9 ¯8 ¯7 ¯6 ¯5 ¯4 ¯3 ¯2 ¯1[utf8 ⍵]}
    lc←(819⌶) ⍝ lower case conversion
    uc←1∘lc   ⍝ upper case conversion
    ci←{(lc ⍺)⍺⍺ lc ⍵} ⍝ case insensitive operator
    deb←' '∘(1↓,(/⍨)1(⊢∨⌽)0,≠) ⍝ delete extraneous blanks
    dlb←{(+/∧\' '=⍵)↓⍵} ⍝ delete leading blanks
    dltb←{⌽dlb⌽dlb ⍵} ⍝ delete leading and trailing blanks
    iotaz←((≢⊣)(≥×⊢)⍳)
    splitOnFirst←{(⍺↑⍨¯1+p)(⍺↓⍨p←⌊/⍺⍳⍵)} ⍝ split ⍺ on first occurrence of ⍵ (removing first ⍵)
    splitOn←≠⊆⊣ ⍝ split ⍺ on all ⍵ (removing ⍵)
    h2d←{⎕IO←0 ⋄ 16⊥'0123456789abcdef'⍳lc ⍵} ⍝ hex to decimal
    d2h←{⎕IO←0 ⋄ '0123456789ABCDEF'[16(⊥⍣¯1)⍵]} ⍝ decimal to hex
    getchunklen←{¯1=len←¯1+⊃(NL⍷⍵)/⍳⍴⍵:¯1 ¯1 ⋄ chunklen←h2d len↑⍵ ⋄ (⍴⍵)<len+chunklen+4:¯1 ¯1 ⋄ len chunklen}
    toInt←{0∊⍴⍵:⍬ ⋄ ~3 5∊⍨10|⎕DR t←1⊃2⊃⎕VFI ⍕⍵:⍬ ⋄ t≠⌊t:⍬ ⋄ t} ⍝ simple char to int
    makeHeaders←{0∊⍴⍵:0 2⍴⊂'' ⋄ 2=⍴⍴⍵:⍵ ⋄ ↑2 eis ⍵} ⍝ create header structure [;1] name [;2] value
    fmtHeaders←{0∊⍴⍵:'' ⋄ ∊{0∊⍴2⊃⍵:'' ⋄ NL,⍨(firstCaps 1⊃⍵),': ',⍕2⊃⍵}¨↓⍵} ⍝ formatted HTTP headers
    firstCaps←{1↓{(¯1↓0,'-'=⍵) (819⌶)¨ ⍵}'-',⍵} ⍝ capitalize first letters e.g. Content-Encoding
    addHeader←{'∘???∘'≡⍺⍺ Lookup ⍺:⍺⍺⍪⍺ ⍵ ⋄ ⍺⍺} ⍝ add a header unless it's already defined
    setHeader←{(≢⍺⍺)<i←⍺⍺(⍳ci)eis ⍺:⍺⍺⍪⍺ ⍵ ⋄ ⍺⍺⊣⍺⍺[i;2]←⊆,⍵}
    tableGet←{⍺[;2]/⍨⍺[;1](≡ ci)¨⊂⍵}
    endsWith←{∧/⍺=⍵↑⍨-≢⍺}
    beginsWith←{∧/⍺=⍵↑⍨≢⍺}
    extractPath←{⍵↑⍨1⌈¯1+⊢/⍸'/'=⍵}∘,
    isChar←{1≥|≡⍵:0 2∊⍨10|⎕DR {⊃⍣(0∊⍴⍵)⊢⍵}⍵ ⋄ ∧/∇¨⍵}
    isSimpleChar←{1≥|≡⍵: isChar ⍵ ⋄ 0}

    ∇ r←dyalogRoot
      :Access Public Shared
      r←{⍵,('/\'∊⍨⊢/⍵)↓'/'}{0∊⍴t←2 ⎕NQ'.' 'GetEnvironment' 'DYALOG':⊃1 ⎕NPARTS⊃2 ⎕NQ'.' 'GetCommandLineArgs' ⋄ t}''
    ∇

    ∇ (secure host path urlparms)←parseURL url;path;p
      :Access Public Shared
    ⍝ parses a URL and returns
    ⍝   secure - Boolean whether running HTTPS or not based on leading http://
    ⍝   host - domain or IP address
    ⍝   path - path on the host for the requested resource, if any
    ⍝   urlparms - URL query string, if any
      (url urlparms)←2↑(url splitOnFirst'?'),⊂''
      p←⍬⍴1+⍸<\'//'⍷url
      secure←(lc(p-2)↑url)beginsWith'https:'
      url←p↓url                          ⍝ Remove HTTP[s]:// if present
      (host path)←url splitOnFirst'/'    ⍝ Extract host and path from url
      path←'/',∊(⊂'%20')@(=∘' ')⊢path    ⍝ convert spaces in path name to %20
    ∇

    ∇ r←parseHttpDate date;d
    ⍝ Parses a RFC 7231 format date (Ddd, DD Mmm YYYY hh:mm:ss GMT)
    ⍝ returns Extended IDN format
    ⍝ this function does almost no validation of its input, we expect a properly formatted date
    ⍝ ill-formatted dates return ⍬
      :Access public shared
      :Trap 0
          d←{⍵⊆⍨⍵∊⎕A,⎕D}uc date
          r←1 0 1 1 1 1\toInt¨d[4 2 5 6 7]
          r[2]←(3⊃d)⍳⍨12 3⍴'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'
          r←TStoIDN r
      :Else
          r←⍬
      :EndTrap
    ∇

    ∇ idn←TStoIDN ts
    ⍝ Convert timestamp to extended IDN format
      :Access public shared
      idn←(2 ⎕NQ'.' 'DateToIDN'(3↑ts))+(24 60 60 1000⊥4↑3↓ts)÷86400000
    ∇

    ∇ ts←IDNtoTS idn
    ⍝ Convert extended IDN to timestamp
      :Access public shared
      ts←3↑2 ⎕NQ'.' 'IDNToDate'(⌊idn)
      ts,←⌊0.5+24 60 60 1000⊤86400000×1|⍬⍴idn
    ∇

    ∇ idn←Now
    ⍝ Return extended IDN for current time
      :Access public shared
      idn←TStoIDN ⎕TS
    ∇

    ∇ cookies←parseCookies(headers host path);cookie;segs;setcookie;seg;value;name;domain
    ⍝ Parses set-cookie headers into cookie array
      :Access public shared ⍝ remove this after testing!!!
      cookies←⍬
      :For setcookie :In headers tableGet'set-cookie'
          segs←dltb¨¨2↑¨'='splitOnFirst⍨¨dltb¨setcookie splitOn';'
          (cookie←#.⎕NS'').(Name Value Domain Path HttpOnly Secure Expires SameSite Other)←'' ''host'' 0 0 '' '' ''
          →∆NEXT⍴⍨0∊≢¨cookie.(Name Value)←⊃segs
          :For name value :In 1↓segs
              :Select lc name
              :Case 'expires'
                  :If ''≡cookie.Expires ⍝ if Expires was set already from MaxAge, MaxAge takes precedence
                      →∆NEXT⍴⍨0∊⍴cookie.Expires←parseHttpDate value ⍝ ignore cookies with invalid expires dates
                  :EndIf
              :Case 'max-age' ⍝ specifies number of seconds after which cookie expires
                  cookie.Expires←Now+TStoIDN 1899 12 31 0 0,toInt value
              :Case 'domain' ⍝ RCF 6265 Sec. 5.2.3
                  →∆NEXT⍴⍨0∊⍴domain←lc value ⍝ cookies with empty domain values are ignored
                  :If domain≢host
                  :AndIf host endsWith domain←('.'=⊃domain)↓'.',domain
                      cookie.Domain←domain
                  :Else ⋄ →∆NEXT
                  :EndIf
              :Case 'path' ⍝ RCF 6265 Sec. 5.2.4
                  :If '/'=⊃value ⋄ cookie.Path←value ⋄ :EndIf
              :Case 'secure' ⋄ cookie.Secure←1
              :Case 'httponly' ⋄ cookie.HttpOnly←1
              :Case 'samesite' ⋄ cookie.SameSite←value
              :Else ⋄ cookie.Other,←⊂dltb¨name value ⍝ catch all in case something else was sent with cookie
              :EndSelect
          :EndFor
          cookies,←cookie
     ∆NEXT:
      :EndFor
    ∇

      NotExpired←{
          0∊⍴⍵.Expires:1
          Now≤⍵.Expires
      }

      domainMatch←{
      ⍝ ⍺ - host, ⍵ - cookie domain
          ⍺≡⍵:1
          (⍺ endsWith ⍵)∧'.'=⊃⍵
      }

      pathMatch←{
      ⍝ ⍺ - requested path, ⍵ - cookie path
          ⍺ beginsWith ⍵
      }

    ∇ cookies←cookies updateCookies new;cookie;ind
    ⍝ update internal cookies based on result of ParseCookies
      :Access public shared
      :If 0∊⍴cookies
          cookies←new
      :Else
          :For cookie :In new
              :If 0≠ind←cookies.Name iotaz⊂cookie.Name
                  :If 0∊⍴cookie.Value ⍝ deleted cookie?
                      cookie←(ind≠⍳≢cookies)/cookies
                  :Else
                      cookies[ind]←cookie
                  :EndIf
              :Else
                  cookies,←cookie
              :EndIf
          :EndFor
      :EndIf
      :If ~0∊⍴cookies
          cookies/⍨←NotExpired¨cookies ⍝ remove any expired cookies
      :EndIf
    ∇

    ∇ r←state applyCookies cookies;mask
    ⍝ return which cookies to send based on current request and
      :Access public shared
      r←⍬
      →0⍴⍨0∊⍴mask←1⍴⍨≢cookies ⍝ exit if no cookies
      →0↓⍨∨/mask∧←cookies.Secure≤state.Secure ⍝ HTTPS only filter
      →0↓⍨∨/mask←mask\state.Host∘domainMatch¨mask/cookies.Domain
      →0↓⍨∨/mask←mask\state.Path∘pathMatch¨mask/cookies.Path
      →0↓⍨∨/mask←mask\NotExpired¨mask/cookies
      r←mask/cookies
    ∇

    ∇ r←formatCookies cookies
      r←2↓∊cookies.('; ',Name,'=',Value)
    ∇

    ∇ r←table Lookup name
    ⍝ lookup a name/value-table value by name, return '∘???∘' if not found
      :Access Public Shared
      r←table{(⍺[;2],⊂'∘???∘')⊃⍨⍺[;1](⍳ci)eis ⍵}name
    ∇

    ∇ name AddHeader value
    ⍝ add a header unless it's already defined
      :Access public
      Headers←makeHeaders Headers
      Headers←name(Headers addHeader)value
    ∇

    ∇ name SetHeader value;ind
    ⍝ set a header value, overwriting any existing one
      :Access public
      Headers←makeHeaders Headers
      ind←Headers[;1](⍳ci)eis name
      Headers↑⍨←ind⌈≢Headers
      Headers[ind;]←name value
    ∇

    ∇ RemoveHeader name
    ⍝ remove a header
      :Access public
      Headers←makeHeaders Headers
      Headers⌿⍨←Headers[;1](≢¨ci)eis name
    ∇

    ∇ r←{a}eis w;f
    ⍝ enclose if simple
      :Access public shared
      f←{⍺←1 ⋄ ,(⊂⍣(⍺=|≡⍵))⍵}
      :If 0=⎕NC'a' ⋄ r←f w
      :Else ⋄ r←a f w
      :EndIf
    ∇

      base64←{(⎕IO ⎕ML)←0 1            ⍝ from dfns workspace - Base64 encoding and decoding as used in MIME.
          chars←'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
          bits←{,⍉(⍺⍴2)⊤⍵}             ⍝ encode each element of ⍵ in ⍺ bits, and catenate them all together
          part←{((⍴⍵)⍴⍺↑1)⊂⍵}          ⍝ partition ⍵ into chunks of length ⍺
          0=2|⎕DR ⍵:2∘⊥∘(8∘↑)¨8 part{(-8|⍴⍵)↓⍵}6 bits{(⍵≠64)/⍵}chars⍳⍵  ⍝ decode a string into octets
          four←{                       ⍝ use 4 characters to encode either
              8=⍴⍵:'=='∇ ⍵,0 0 0 0     ⍝   1,
              16=⍴⍵:'='∇ ⍵,0 0         ⍝   2
              chars[2∘⊥¨6 part ⍵],⍺    ⍝   or 3 octets of input
          }
          cats←⊃∘(,/)∘((⊂'')∘,)        ⍝ catenate zero or more strings
          cats''∘four¨24 part 8 bits ⍵
      }

    ∇ r←{cpo}Base64Encode w
    ⍝ Base64 Encode
    ⍝ Optional cpo (code points only) suppresses UTF-8 translation
    ⍝ if w is numeric (single byte integer), skip any conversion
      :Access public shared
      :If 83=⎕DR w ⋄ r←base64 w
      :ElseIf 0=⎕NC'cpo' ⋄ r←base64'UTF-8'⎕UCS w
      :Else ⋄ r←base64 ⎕UCS w
      :EndIf
    ∇

    ∇ r←{cpo}Base64Decode w
    ⍝ Base64 Decode
    ⍝ Optional cpo (code points only) suppresses UTF-8 translation
      :Access public shared
      :If 0=⎕NC'cpo' ⋄ r←'UTF-8'⎕UCS base64 w
      :Else ⋄ r←⎕UCS base64 w
      :EndIf
    ∇

    ∇ r←DecodeHeader buf;len;d
      ⍝ Decode HTTP Header
      r←0(0 2⍴⊂'')
      :If 0<len←¯1+⊃{((NL,NL)⍷⍵)/⍳⍴⍵}buf
          d←(⍴NL)↓¨{(NL⍷⍵)⊂⍵}NL,len↑buf
          d←↑{((p-1)↑⍵)((p←⍵⍳':')↓⍵)}¨d
          d[;1]←lc¨d[;1]
          d[;2]←dlb¨d[;2]
          r←(len+4)d
      :EndIf
    ∇

    ∇ r←{name}UrlEncode data;⎕IO;format;noname;xlate;hex
      ⍝ data is one of:
      ⍝      - a simple character vector (no name supplied)
      ⍝      - an even number of name/data character vectors
      ⍝       'name' 'fred' 'type' 'student' > 'name=fred&type=student'
      ⍝      - a namespace containing variable(s) to be encoded
      ⍝ cpo is an option switch to send Unicode code points
      ⍝ r    is a character vector of the URLEncoded data
     
      :Access Public Shared
      ⎕IO←0
      format←{
          1=≡⍵:⍺(,⍕⍵)
          ↑⍺∘{⍺(,⍕⍵)}¨⍵
      }
      :If 0=⎕NC'name' ⋄ name←'' ⋄ :EndIf
      noname←0
      :If 9.1=⎕NC⊂'data'
          data←⊃⍪/{0∊⍴t←⍵.⎕NL ¯2:'' ⋄ ⍵{⍵ format ⍺⍎⍵}¨t}data
      :Else
          :Select |≡data
          :CaseList 0 1
              :If 1≥|≡data
                  noname←0∊⍴name
                  data←name(,data)
              :EndIf
          :Case 3 ⍝ nested name/value pairs (('abc' '123')('def' '789'))
              data←⊃,/data
          :EndSelect
      :EndIf
      hex←'%',¨,∘.,⍨⎕D,6↑⎕A
      xlate←{
          i←⍸~⍵∊'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~*'
          0∊⍴i:⍵
          ∊({⊂∊hex['UTF-8'⎕UCS ⍵]}¨⍵[i])@i⊢⍵
      }
      data←xlate¨data
      r←noname↓¯1↓∊data,¨(⍴data)⍴'=&'
    ∇

    ∇ r←UrlDecode r;rgx;rgxu;i;j;z;t;m;⎕IO;lens;fill
      :Access public shared
      ⎕IO←0
      ((r='+')/r)←' '
      rgx←'[0-9a-fA-F]'
      rgxu←'%[uU]',(4×⍴rgx)⍴rgx ⍝ 4 characters
      r←(rgxu ⎕R{{⎕UCS 16⊥⍉16|'0123456789ABCDEF0123456789abcdef'⍳⍵}2↓⍵.Match})r
      :If 0≠⍴i←(r='%')/⍳⍴r
      :AndIf 0≠⍴i←(i≤¯2+⍴r)/i
          z←r[j←i∘.+1 2]
          t←'UTF-8'⎕UCS 16⊥⍉16|'0123456789ABCDEF0123456789abcdef'⍳z
          lens←⊃∘⍴¨'UTF-8'∘⎕UCS¨t  ⍝ UTF-8 is variable length encoding
          fill←i[¯1↓+\0,lens]
          r[fill]←t
          m←(⍴r)⍴1 ⋄ m[(,j),i~fill]←0
          r←m/r
      :EndIf
    ∇

    ∇ r←Documentation
    ⍝ return full documentation
      :Access public shared
      r←'See https://github.com/Dyalog/HttpCommand'
    ∇

    ∇ r←Upgrade;z;vers;url;repository
    ⍝ loads the latest version from GitHub
      :Access public shared
      repository←'HttpCommand' ⍝ eventually we won't need to fall back to library-conga
     ∆TRY:
      url←'https://raw.githubusercontent.com/Dyalog/',repository,'/master/HttpCommand.dyalog'
      z←Get url
      :If z.rc≠0
          r←z.(rc msg)
      :ElseIf (z.HttpStatus=404)∧
          repository←'library-conga'
          →∆TRY
      :ElseIf z.HttpStatus≠200
          r←¯1(⍕z)
      :Else
          {}LDRC.Close'.' ⍝ close Conga
          LDRC←''         ⍝ reset local reference so that Conga gets reloaded
          :Trap 0
              vers←⍕¨(##.⎕FIX{⍵⊆⍨~⍵∊⎕UCS 13 10 65279}z.Data).Version Version
              r←0(deb⍕(1+≡/vers)⊃(⍕,'Upgraded to' 'from',⍪vers)('Already using the most current version: ',1⊃vers))
          :Else
              r←¯1('Could not ⎕FIX new HttpCommand: ',2↓∊': '∘,¨⎕DMX.(EM Message))
          :EndTrap
      :EndIf
    ∇
:EndClass
