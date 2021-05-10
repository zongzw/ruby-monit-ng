require 'pathname'

class Constant
  # To change this template use File | Settings | File Templates.
  JOB_REPLACE_STR = '#job_name#'

  class << self
    def get_config_folder
      Pathname.new(File.dirname(__FILE__) + "/../../config").realpath
    end

    def get_logs_folder
      Pathname.new(File.dirname(__FILE__) + "/../../logs").realpath
    end

    def get_config_file
      File.join(self.get_config_folder, "monit.yml")
    end

    def get_config_file2
      File.join(self.get_config_folder, "monit2.yml")
    end

    def get_mibs_files
      mibpath = Pathname.new(File.dirname(__FILE__) + "/../../data").realpath
      Dir["#{mibpath}/*.mib"]
    end
  end
end