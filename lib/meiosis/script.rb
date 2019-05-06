module Meiosis
  class Script
    attr_accessor :binary_hash, :args
    def initialize(script_args, binary_hash=nil)
      if !script_args.instance_of?(Array)
        raise "First argument must be an array"
      end
      self.args = script_args
      self.binary_hash = binary_hash ? binary_hash : Meiosis::Config.api.system_script_cell_hash
    end

    def script_structure()
      if ENV["always_success"]
        {
          version: 0,
          binary_hash: "0x0000000000000000000000000000000000000000000000000000000000000001",
          args: []
        }
      else
        {
          binary_hash: self.binary_hash,
          args: self.args
        }
    end
    end
  end

end
