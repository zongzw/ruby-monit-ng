This project is an implementation set of marmot agents, used to monitor the following modules currently:
  fortigate:
  switch:
  procstats:
  ntp:
  qradar:

To add a new monitoring module:
  1. Module's Type:
    Each module to be monitored need to be assigned a type name.
    The type name is identified to indicate source files to load/execute.
    To start the monitoring process for one module:
      add parameters to command line: --module '<type name>', i.e.
        ruby monit_ng.rb --config /path/to/monit.yml --module fortigate

    Type name in config(yml) file is like this:
          monit_objects:
          - type: fortigate
            ...
    In the code, it will decide which .rb file to load and which register instance to create.

    so summarized:
    1. the parameter appointed in command line need to be same with 'type name' in config file.
    2. the 'type name' in the config file should be same with the file names under lib/server/registrars.
    3. the class name in lib/server/registrars/*.rb is the first-character-captalized 'type name', such as
        fortigate - Fortigate, ntp - Ntp ...

  2. Registrar
    Files under lib/server/registrars are called registrar responding for
    1. parse config files
    2. register kinds of agents to agent-engine according to the configuration

    so summarized:
    1. how to structure the config file depends on the feature of the to-be-monitored modules.
    2. implement the function register_agents, in which create agent instances and register it.

  3. Agent
    Agent is where to do the work, including collecting data, and sort out the data to marmot-needed format.

    so summarized:
    1. implement the function work and migrate for each agent.

  4. Base Functions
    For getting/collecting information, kinds of getting ways are encapsulated into Get.
    Add any new get if necessary.

  5. Server Framework
    Refer to lib/server/agent-engine.rb to find the way how to start agent to work and collect/send information to marmot.

Moved to bluemix-china-landing-team @ 20160801