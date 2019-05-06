
module Meiosis
  class Cell
    attr_accessor :type_args, :capacity, :out_point
    attr_reader :data, :type, :lock
    def initialize()
      @type_args = []
      @data = {}
    end

    def type=(script)
      if !script.instance_of?(Meiosis::Script)
        raise "Lock must be an instance of the Script class"
      end
      @type = script
    end

    def type_args=(args)
      if !args.instance_of?(Array)
        raise "Must set args as an array"
      end
      @type_args = args
    end

    def lock=(script)
      if !script.instance_of?(Meiosis::Script)
        raise "Lock must be an instance of the Script class"
      end
      @lock = script
    end

    def self.find_one(cell_outpoint)
      cell_info = Meiosis::Config.api.get_live_cell(cell_outpoint)[:cell]
      new_cell = self.new
      new_cell.data = cell_info[:data]
      cell_lock
    end

    def self.find(filter)
      results = []
      results = results.map do |cell_data|
        return self.new(cell_data)
      end
      results
    end

    # @param cellData HashMap {<field_name> : {bytes: <num_of_bytes>, value: <value_in_field>}, }
    def data=(data_map)
      if data_map.instance_of? Hash
        data_map.keys.each do |field_name|
          define_singleton_method("#{field_name}=".to_sym) do |field_value|
            instance_variable_set("@#{field_name}", field_value)
          end
          define_singleton_method("#{field_name}".to_sym) do
            instance_variable_get("@#{field_name}")
          end
          define_singleton_method("#{field_name}_bin".to_sym) do
            Meiosis::Utils.convert_to_binary(instance_variale_get("#@#{field_name}"))
          end
          self.send("#{field_name}=", data_map[field_name])
          @data[field_name] = data_map[field_name]
        end
      else
        @data = data_map
      end
    end

    def json
      json_struct =  {
          lock: @lock.script_structure,
        }

      if @capacity
        json_struct[:capacity] = @capacity
      end

      if @data.instance_of?(Hash)
        json_struct[:data] = @data.values.pack("Q<")
      elsif @data.instance_of?(Array)
        json_struct[:data] = @data.pack("Q<")
      else
        json_struct[:data] = @data
      end

      if @type
        json_struct[:type] = @type.script_structure
      end

      json_struct
    end

    def commit()
      transaction = Meiosis::Transaction.new(0, [], [self])
      transaction.build
      transaction.send
    end

    def set_capacity_to_minimum
      @capacity = min_capacity
    end

    def is_valid_output
      @capacity && @capacity >= min_capacity && @lock
    end

    def min_capacity
      Meiosis::Utils.calculate_cell_min_capacity(json)
    end
  end
end
