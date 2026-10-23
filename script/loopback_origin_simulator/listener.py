"""Test-owned loopback listener for the Phase 182 Simulator harness.

Binds 127.0.0.1 on an ephemeral port, prints the port on the first stdout
line, serves a tiny page whose JavaScript pings /__loaded, and appends one
"GET <path>" line per request to the log file given as argv[1].
"""
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG = sys.argv[1]

PAGE = (
    b"<!doctype html><html><head><meta name='viewport' content='width=device-width'>"
    b"<title>loopback probe</title></head><body><p>loopback probe</p>"
    b"<script>fetch('/__loaded').catch(function(){});</script></body></html>"
)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        with open(LOG, "a") as handle:
            handle.write("GET %s\n" % self.path)
        if self.path == "/__loaded":
            self.send_response(204)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(PAGE)))
        self.end_headers()
        self.wfile.write(PAGE)

    def log_message(self, *args):
        pass


server = HTTPServer(("127.0.0.1", 0), Handler)
print(server.server_address[1], flush=True)
server.serve_forever()
