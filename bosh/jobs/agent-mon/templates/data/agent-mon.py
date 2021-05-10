#agent-mon
import json
import time
import traceback

import sys
for n in ['lib/base', 'lib/utils']:
    sys.path.append('/var/vcap/packages/monit_ng/%s' % n)

from emitter import Emitter
import constants
from logger import LoggerFactory
from metrics import Metrics

class AgentMon:

    logger = LoggerFactory.loggerA(constants.logpath)
    eget = Emitter(constants.influxurl, constants.logpath)
    epost = Emitter("%s%s" % (constants.localserver, constants.metrics_api), constants.logpath)

    @classmethod
    def ls(cls, filepath):
        try:
            with open(filepath) as fr:
                content = json.load(fr)
                if type(content) != type([]):
                    raise Exception("content from %s doesn't match.. should be []" % filepath)
                return content
        except Exception as e:
            cls.logger.error("failed to read from json file. %s" % e)
            raise Exception("failed to read from json file. %s" % e)

    @classmethod
    def find(cls, list):
        raw = {}
        intervals = {}
        targets = {}
        for n in list:
            sql = "select instance from /^%s$/  where instance =~ /^%s$/ limit 1" % (
                n['metrics'],
                n['instances']
            )
            param = {
                'u': constants.influxuser,
                'p': constants.influxpass,
                'q': sql
            }
            cls.logger.debug("%s" % param)
            raw[n['metrics']] = json.loads(cls.eget.get(param))
            intervals[n['metrics']] = n['interval'] if 'interval' in n.keys() else 0
            targets[n['metrics']] = n['target']

        rlt = {}
        currtime = time.time()
        for k in raw.keys():
            for r in raw[k]:
                timestamp_index = r['columns'].index('time')
                instance_index = r['columns'].index('instance')
                name = r['name']
                timestamp = r['points'][0][timestamp_index]
                instance = r['points'][0][instance_index]
                rlt[name] = {
                    'timestamp': timestamp / 1000,
                    'instance': instance,
                    'interval': intervals[k],
                    'target': targets[k],
                    'current': int(currtime)
                }

        return rlt

    '''
    {
        "metrics.bmxcn.CYP.infra.dbbackup_archive":{
            "current":1509678541,
            "instance":"default",
            "interval":360,
            "target":"bmxcn.allenvs.selftest",
            "timestamp":1509678301998007
        },
        "metrics.bmxcn.CYP.infra.diegodbbackup":{
            "current":1509678541,
            "instance":"diego",
            "interval":360,
            "target":"bmxcn.allenvs.selftest",
            "timestamp":1509668551398057
        }
    }
    '''
    @classmethod
    def checktm(cls, found):
        for n in found.keys():
            i = found[n]
            sql = "select instance from /^%s$/ where instance = '%s' limit 10" % (n, i['instance'])
            cls.logger.debug(sql)
            param = {
                'u': constants.influxuser,
                'p': constants.influxpass,
                'q': sql
            }
            rlt = json.loads(cls.eget.get(param))
            if len(rlt) == 0: 
                raise Exception("failed to get data from %s" % sql)
            
            raw = []
            index = rlt[0]['columns'].index('time')
            for m in range(0, len(rlt[0]['points'])-1):
                raw.append(rlt[0]['points'][m][index]  - rlt[0]['points'][m+1][index])
                
            found[n]['interval'] = int(min(raw) / 1000 * 1.2) 
            cls.logger.debug("use interval: %s selected from %s" % (found[n]['interval'], raw))
            
        return found
    
    @classmethod
    def sort(cls,  found):
        metrics = []
        for n in found.keys():
            i = found[n]
            metric = Metrics.a(
                i['target'],
                -1 if i['current'] - i['timestamp'] > i['interval'] else 0,
                constants.pin_code,
                "%s-%s" % (n, i['instance']),
                "updated %s seconds ago" % (i['current'] - i['timestamp'])
            )
            metrics.append(metric)

        return Metrics.merge(metrics)

    @classmethod
    def post(cls, data):
        rlt = []
        for n in data.values():
            r = cls.epost.post(json.dumps(n))
            rlt.append(r)

        return rlt

if __name__ == "__main__":
    while True:
        try:
            filepath = constants.monit_json
            l = AgentMon.ls(filepath)
            AgentMon.logger.info("Loading configuration:")
            AgentMon.logger.info(json.dumps(l, separators=(',', ":"), indent=4, sort_keys=True))

            r = AgentMon.find(l)
            AgentMon.logger.info("Queried result from influx:")
            AgentMon.logger.info(json.dumps(r, separators=(',', ":"), indent=4, sort_keys=True))

            c = AgentMon.checktm(r)
            AgentMon.logger.info("Checked result with timestamp: ")
            AgentMon.logger.info(json.dumps(c, separators=(',', ":"), indent=4, sort_keys=True))

            s = AgentMon.sort(r)
            AgentMon.logger.info("Migrated result as metrics:")
            AgentMon.logger.info(json.dumps(s, separators=(',', ":"), indent=4, sort_keys=True))

            c = AgentMon.post(s)
            AgentMon.logger.info("Posted metrics to marmot backend:")
            AgentMon.logger.info(c)

        except Exception as e:
            AgentMon.logger.error("Failed to do check in AgentMon's work loop. %s" % e)
            AgentMon.logger.error(traceback.format_exc())

        time.sleep(60)

