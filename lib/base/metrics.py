#metrics
import json
import time
import random

class Metrics:
    
    @classmethod
    def merge(cls, metrics):
        merged = {}
        for n in metrics:
            if not n['pin_code'] in merged.keys():
                merged[n['pin_code']] = {
                    'pin_code': n['pin_code'], 
                    'data_array': []
                }
            done = False
            for m in merged[n['pin_code']]['data_array']:
                if m['target'] == n['data']['target']:
                    done = True
                    m['metrics'] += n['data']['metrics']
            if not done:
                merged[n['pin_code']]['data_array'].append(n['data'])
                
        return merged
                
    # status should be a string
    @classmethod
    def a(cls, target, status, pin_code, instance="Default", details='', sn=None, timestamp=None, duration=0, attachment=[]):
        metric = {
            "pin_code": "%s" % pin_code,
            "data": {
                "sn": sn if sn != None else "%f-%f" % (time.time(), random.random()),
                "target": target,
                "metrics": [
                    {
                        "instance": instance,
                        "status": "%s" % status,
                        "details": details,
                        "timestamp": "%d" % (int(time.time()*1000) if timestamp == None else timestamp * 1000),
                        "duration": "%d" % duration,
                        "attachments": attachment
                    }
                ]
            }
        }
        
        return metric
    
    @classmethod
    def to_json(cls, string):
        return json.loads(string)
    
    @classmethod
    def to_str(cls, obj):
        return json.dumps(obj)
        
    @classmethod
    def formattedString(cls, obj):
        return json.dumps(obj, separators=(',',':'), indent=4, sort_keys=True)
        
if __name__ == "__main__":
    m1 = Metrics.a("a.b.c.d", 0, "123")
    m2 = Metrics.a("a.b.c.d", 1, "123")
    m3 = Metrics.a("1.2.3.4", 2, "234")
    m4 = Metrics.a("1.2.3.4", 3, "123")
    
    for n in [m1, m2, m3, m4]:
        print(n)
    merged = Metrics.merge([m1, m2, m3, m4])
    print(Metrics.formattedString(merged))