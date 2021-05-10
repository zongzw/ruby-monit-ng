# metrics service
import threading
import inspect
import time
#import signal

import sys
for n in ['lib/base', 'lib/utils']:
    sys.path.append('/var/vcap/packages/monit_ng/%s' % n)

import constants
from emitter import Emitter
from logger import LoggerFactory
from cache import Cache

try:
  from SimpleHTTPServer import SimpleHTTPRequestHandler as Handler
  from SocketServer import TCPServer as Server
except ImportError:
  from http.server import SimpleHTTPRequestHandler as Handler
  from http.server import HTTPServer as Server

# Read port selected by the cloud for our application
PORT = int(constants.port)
# Change current directory to avoid exposure of control files

logpath = constants.logpath
logger = LoggerFactory.loggerA(logpath)
metrics = Cache()
emitter = Emitter(constants.collector, logpath)
logger.info("starting metrics-service")

def post_thr():
    global metrics
    logger.info("start post thread...")
    while True:
        logger.debug("working loop for post data")
        try:
            data = metrics.wait_and_pop()
            rlt = emitter.post(data)
            logger.info("Post data: %s: result: %d" % (data,  rlt))
        except Exception as e:
            time.sleep(0.01)
            logger.error("Error accur:")
            logger.error("In %s, error: %s" % (inspect.stack()[0][3], e))

'''
def sighandler(signum, frame):
    logger.info("recv signal number %d" % signum)
'''

class MyHandler(Handler):
    def __init__(self, request, client_address, server):
        logger.debug("working here.")

        Handler.__init__(self, request,  client_address, server)

    def do_GET(self):
        global metrics
        code = 200
        if self.path == constants.metrics_api:
            self.send_response(code)
            self.send_header("Content-type", "text/html")
            self.end_headers()

            self.wfile.write("cache: %s\n" % metrics.listall())

    def do_POST(self):
        global metrics
        code = 200

        try:
            content_len = int(self.headers.getheader('content-length', 0))
            post_body = self.rfile.read(content_len)
            logger.info("data: %s" % post_body)
        except Exception as e:
            logger.error("Failed to get reuqest content: %s" % e.message)
            code = 400

        try:
            if self.path == constants.metrics_api:
                metrics.append(post_body)
        except Exception as e:
            logger.error("Failed to handle request: %s" % e.message)
            code = 406

        try:
            self.send_response(code)
            self.send_header("Content-type", "text/html")
            self.end_headers()

            self.wfile.write("%s\n" % post_body)

        except Exception as e:
            logger.error("Failed to response: %s" % e.message)

'''
signal.signal(signal.SIGINT, sighandler)
signal.signal(signal.SIGTERM, sighandler)
'''

threads = []

try:
    logger.info("Creating new threads.")
    thr = threading.Thread(target=post_thr)
    threads.append(thr)
    thr.start()
except Exception as e:
    logger.error("Failed to create thread instance")
    logger.error("message: %s" % e)

httpd = Server(("", PORT), MyHandler)
try:
    logger.info("Start serving at port %i" % PORT)
    httpd.serve_forever()
except KeyboardInterrupt:
    logger.error("server stop: KeyboardInterrupt")

httpd.server_close()
for n in threads:
    n.join()
