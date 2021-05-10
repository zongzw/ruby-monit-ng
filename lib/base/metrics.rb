
require 'json'

class Metrics
  attr_accessor :metricdata

=begin
        The info is a hash contains the following keys/values
        {
            "sn": <sn name>,                    => optional
            "target": <target name>,            => required *
            "instance": <instance>,             => optional
            "status": <status>,                 => required *
            "details": <details>,               => optional
            "timestamp": <timestamp>,           => optional
            "duration": <duration>,             => optional
            "attachments": <attachment list>    => optional
        }
=end
  def initialize(pincode, info)
    raise ArgumentError, "No target appointed for the metrics" if (info[:target] == nil)
    raise ArgumentError, "No status value setted for the metrics" if (info[:status] == nil)

    metric = {
        "pin_code" => "%s" % pincode,
        "data" => {
            "sn" => info[:sn],
            "target" => info[:target],
            "metrics" => [
                {
                    "instance" => info[:instance],
                    "status" => info[:status],
                    "details" => info[:details],
                    "timestamp" => (info[:timestamp] != nil) ? info[:timestamp] : Time.now().to_i() * 1000,
                    "duration" => (info[:duration] != nil) ? info[:duration] : 0,
                    "attachments" => (info[:attachments] != nil) ? info[:attachments] : []
                }
            ]
        }
    }
    @metricdata = metric
  end

  def to_s()
    @metricdata.to_json
  end

=begin
        {
            "<pin_code 1>": {
                "pin_code": <pin_code1>,
                "data_array": [
                    {
                        "sn" => <sn>,
                        "target" => <target>,
                        "metrics" => [
                            {
                                "instance" => <instance1>,
                                ...
                                "attachments" => <attachment>
                            },
                            {
                                "instance" => <instance2>,
                                ...
                                "attachments" => <attachment>
                            }

                        ]
                    },
                    { ... }
                ]
            },
            "<pin_code 2>": {
                "pin_code": <pin_code1>,
                "data_array": [
                    {
                        "sn" => <sn>,
                        "target" => <target>,
                        "metrics" => [
                            {
                                "instance" => <instance>,
                                ...
                            }
                        ]
                    }
                ]
            },
        }
=end
  def self.merge(metrics)
    batchmetrics = {}
    metrics.each do |m|
      pin_code = m.metricdata['pin_code']
      if (batchmetrics[pin_code] == nil)
        batchmetrics[pin_code] = {
            "pin_code" => pin_code,
            "data_array" => []
        }
      end
      #batchmetrics[pin_code]['data_array'] << m.metricdata['data']

      done = false
      batchmetrics[pin_code]['data_array'].each do |item|
        if item['target'] == m.metricdata['data']['target']
          item['metrics'] += m.metricdata['data']['metrics']
          done = true
        end
      end
      if (!done)
        batchmetrics[pin_code]['data_array'] << m.metricdata['data']
      end
    end

    batchmetrics
  end
end