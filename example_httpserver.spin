{{
  PropTCP Example - AJAX Enabled HTTP Server
  ------------------------------------------
  
  Copyright (c) 2006-2009 Harrison Pham <harrison@harrisonpham.com>
   
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
   
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
   
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  The latest version of this software can be obtained from
  http://hdpham.com/PropTCP and http://obex.parallax.com/
}}

{{
  This demo implements an extremely basic AJAX enabled web server that generates
  RealRandom numbers.  You will probably need to edit the IP settings below.
  The demo is designed to run on the YBOX2 standard hardware setup.

  The webserver supports three 'simultaneous' connections, although only one can be
  serviced at a time.  Basically incoming connections are queued in sockets until
  they can be serviced by the webserver loop.

  Builtin Webpages
  ----------------
  default  - The 'It Works!' web page + AJAX'd RealRandom
  rand.cgi - The raw random number (called by the AJAX javascript)
  img.bin  - The entire 32KB HUB ram binary image (this is useful for speed testing)
  ajax.js  - A compressed cross-browser compatiable AJAX script
}}

CON
  _clkmode = xtal1+pll16x
  _xinfreq = 5_000_000

OBJ
  sock[3]       : "api_telnet_serial"
  str           : "util_strings"
  rr            : "RealRandom"

DAT
  mac_addr      byte    $02, $00, $00, $00, $00, $05    ' device mac address, must be unique

                long
  ip_addr       byte    10, 10, 10, 8                   ' device's ip address
  ip_subnet     byte    255, 255, 255, 0                ' network subnet
  ip_gateway    byte    10, 10, 10, 254                 ' network gateway (router)
  ip_dns        byte    10, 10, 10, 254                 ' network dns

CON

  ' buffer sizes, must be a power of 2
  rxlen = 128
  txlen = 2048

VAR

  long webstack[64]             ' stack for webserver cog

  byte tcp_webrx1[rxlen]        ' buffers for socket 1
  byte tcp_webtx1[txlen]

  byte tcp_webrx2[rxlen]        ' buffers for socket 2
  byte tcp_webtx2[txlen]

  byte tcp_webrx3[rxlen]        ' buffers for socket 3
  byte tcp_webtx3[txlen]

  byte reqstr[32]               ' request string
  byte webbuff[128]             ' incoming header buffer

PUB main

  ' Init the TCP/IP driver
  sock.start(1, 2, 3, 4, -1, 7, @mac_addr, @ip_addr)

  ' Start RealRandom object
  rr.start

  ' Start the webserver cog
  cognew(webserver, @webstack)

  repeat
    waitcnt(0)  

PRI webserver | sockidx

  ' Setup listening sockets
  \sock[0].listen(80, @tcp_webrx1, rxlen, @tcp_webtx1, txlen)
  \sock[1].listen(80, @tcp_webrx2, rxlen, @tcp_webtx2, txlen)
  \sock[2].listen(80, @tcp_webrx3, rxlen, @tcp_webtx3, txlen)

  repeat  
    repeat sockidx from 0 to 2                          ' loop through all the sockets
      if \sock[sockidx].isConnected                     ' is a client connected?
        if \_webThread(sockidx) == 0                    ' process the client connection, check for success
          \sock[sockidx].txflush                        ' flush txbuffer
        \sock[sockidx].close                            ' close socket
      \sock[sockidx].relisten                           ' force socket to listen again, using the previous settings

PRI _webthread(sockidx) | i, j, uri, args

  if _webReadLine(sockidx) == 0                         ' read the first header, quit if it is empty
    return 0

  bytemove(@reqstr, @webbuff, 32)                       ' copy the header to a temporary request string for later processing
    
  ' obtain get arguments
  if (i := str.indexOf(@reqstr, string(".cgi?"))) <> -1 ' was the request for a *.cgi script with arguments?
    args := @reqstr[i + 5]                              ' extract the argument
    if (j := str.indexOf(args, string("="))) <> -1      ' find the end of the argument
      byte[args][j] := 0                                ' string termination
  
  ' read the rest of the headers
  repeat until _webReadLine(sockidx) == 0               ' read the rest of the headers, throwing them away
  
  sock[sockidx].str(string("HTTP/1.0 200 OK",13,10,13,10))                      ' print the HTTP header

  if str.indexOf(@reqstr, string("ajax.js")) <> -1                              ' ajax.js
    sock[sockidx].str(@ajaxjs)
  elseif str.indexOf(@reqstr, string("rand.cgi")) <> -1                         ' rand.cgi
    sock[sockidx].dec(long[rr.random_ptr])
  elseif str.indexOf(@reqstr, string("img.bin")) <> -1                          ' img.bin
    sock[sockidx].txdata(0, 32768)
  else
    ' default page
    sock[sockidx].str(string("<html><body><script language=javascript src=ajax.js></script><b>It Works!<br><br>Random Number:</b><div id=a></div><script language=javascript>ajax('rand.cgi', 'a', 10);</script></body></html>"))
  
  return 0

PRI _webReadLine(sockidx) | i, ch
  repeat i from 0 to 126
    ch := sock[sockidx].rxtime(500)
    if ch == 13
      ch := sock[sockidx].rxtime(500)
    if ch == -1 or ch == 10
      quit
    webbuff[i] := ch

  webbuff[i] := 0

  return i

DAT
ajaxjs  byte  "var ajaxBusy=false;function ajax(a,b,c){if(ajaxBusy){return}ajaxBusy=true;var d;try{d=new XMLHttpRequest()}catch(e){d=new ActiveXObject('Microsoft.XMLHTTP')}var f=function(){if(d.readyState==4){if(b){document.getElementById(b).innerHTML=d.responseText}ajaxBusy=false;if(c>0){setTimeout('ajax(\''+a+'\',\''+b+'\','+c+')',c)}}};d.open('GET',a+'?'+(new Date()).getTime(),true);d.onreadystatechange=f;d.send(null)}"
        byte  0
    