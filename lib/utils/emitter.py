
import sys
if sys.version_info.major != 2:
    raise ImportError("Cannot run with python3")

import json
import urllib2
import urllib
from urllib2 import URLError
from logger import LoggerFactory

class Emitter:

    def __init__(self, url, logpath='./logfile'):
        self.url = url
        self.logger = LoggerFactory.loggerA(logpath)
        self.logger.info("emitter instance is created: logpath: %s" % logpath)

    # data should be a string
    def post(self, data="", params=None):

        #logger.info("about to send data: %s" % data)
        try:
            params = {"Content-Type": "application/json"} if params == None else params

            request = urllib2.Request(self.url, data, params)
            response = urllib2.urlopen(request)

            self.logger.info("success to post data %s %s " % (self.url, data))
            return response.getcode()
        except URLError as e:
            self.logger.error("failed to post data to marmot: %d, %s" % (e.code, e))
            raise Exception("failed to post data to marmot: %d, %s" % (e.code, e))

    def get(self, param=""):
        '''url = constants.influxurl
        param = {
            'u': constants.influxuser,
            'p': constants.influxpass,
            'q': sql
        }'''
        self.logger.info("http request(%s, %s)" % (self.url, param))
        try:
            response = urllib2.urlopen("%s?%s" % (self.url, urllib.urlencode(param)))
            self.logger.info("code: %d" % (response.code))
            content = response.read()
            self.logger.info("content: %s" % json.dumps(content))
            return content
        except urllib2.HTTPError as e:
            self.logger.error("failed to do http request, urllib2.HTTPError: %d, %s" % (e.code, e))
            raise Exception("failed to do http request, urllib2.HTTPError: %d, %s" % (e.code, e))

if __name__ == "__main__":
    sys.path.append("../base")
    
    from metrics import Metrics
    import random
    
    pin_code = 'kd2!r0c$'

    '''
    {"kd2!r0c$": {"data_array": [{"metrics": [{"status": "0", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.ys1.sampleApp-default", "details": "updated 60 seconds ago", "duration": "0"}, {"status": "-1", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.allenvs.fortigate.fg-cl03.reachable-ssh", "details": "updated 342551 seconds ago", "duration": "0"}, {"status": "-1", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.dedi02.sampleApp-default", "details": "updated 4227456 seconds ago", "duration": "0"}, {"status": "0", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.dedi01.sampleApp-default", "details": "updated 33 seconds ago", "duration": "0"}, {"status": "0", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.yf.sampleApp-default", "details": "updated 5 seconds ago", "duration": "0"}, {"status": "-1", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.allenvs.fortigate.fg-cl01.reachable-ssh", "details": "updated 342534 seconds ago", "duration": "0"}, {"status": "0", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.allenvs.qradar.reachable-172.16.11.14", "details": "updated 51 seconds ago", "duration": "0"}, {"status": "0", "attachments": [], "timestamp": "1508726153263", "instance": "metrics.bmxcn.CYP.sampleApp-default", "details": "updated 16 seconds ago", "duration": "0"}], "sn": "1508726153.263880-0.905035", "target": "bmxcn.allenvs.selftest"}], "pin_code": "kd2!r0c$"}}
    '''
    m1 = Metrics.a("bmxcn.allenvs.selftest", "%f" % random.random(), pin_code, "for-test")
    m2 = Metrics.a("bmxcn.allenvs.selftest", "%f" % random.random(), pin_code, "for-prod")
    merged = Metrics.merge([m1, m2])
    data = Metrics.formattedString(merged[pin_code])
    print(data)

    emitter1 = Emitter('http://172.17.0.148:8080/MarmotCollector/api/v1/metrics')
    emitter2 = Emitter("http://172.17.0.147:8086/db/marmot/series")
    
    rlt = emitter1.post(data)
    print("return result: %d" % rlt)

    param = {
        'u': 'romarmot',
        'p': 'Read_0nly',
        'q': 'select value from "metrics.bmxcn.CYP.sampleApp" limit 10'
    }
    rlt = emitter2.get(param)
    print(rlt)
