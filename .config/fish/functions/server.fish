function server -d "Start an HTTP server from a directory, \
  optionally specifying the port"
  set ip (ipconfig getifaddr en1 ;or echo "127.0.0.1")
  if [ $argv ]
    set port $argv
  else
    set port 1431
  end
  python -c "import sys
import SimpleHTTPServer
import SocketServer

Handler = SimpleHTTPServer.SimpleHTTPRequestHandler
httpd = SocketServer.TCPServer(('$ip', $port), Handler)
print 'HTTP server started at http://$ip:$port'
print 'Press Ctrl-C to quit.'
try:
  httpd.serve_forever()
except KeyboardInterrupt:
  pass"
end
