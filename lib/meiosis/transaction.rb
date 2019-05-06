module Meiosis
  class Transaction
    attr_accessor :inputs, :outputs, :deps, :version, :fee, :input_sig, :hash
    attr_reader :serialized_self, :status
    # @inputs array of cell outpoints
    # @outputs array of <Cell> instances
    def initialize(version=0, inputs=[], outputs=[], deps=[Meiosis::Config.api.system_script_cell])
      @inputs = inputs
      @version = version
      @outputs = outputs
      @deps = deps
      @fee = nil
      @status = "Unconfirmed"
    end

    def build()
      validate_outputs
      i = gather_inputs
      inputs = i.inputs

      input_capacities = i.capacities

      formatted_outputs = outputs.map do |output_cell|
        output_cell.json
      end

      if input_capacities > @total_input_capacity
        outputs << {
          capacity: input_capacities - @total_input_capacity,
          data: "0x",
          lock: Meiosis::Config.wallet.lock
        }
      end

      @serialized_self = {
        version: 0,
        deps: [Meiosis::Config.api.system_script_out_point],
        inputs: CKB::Utils.sign_sighash_all_inputs(inputs, formatted_outputs, Meiosis::Config.wallet.privkey),
        outputs: formatted_outputs,
        witnesses: []
      }
    end

    def send
     result = Meiosis::Config.wallet.send_tx(serialized_self)
     self.hash = result
     self
    end

    def self.find_one(hash_of_tx)
      Meiosis::Config.wallet.get_transaction(hash_of_tx)
    end


    def validate_outputs
      outputs.each_with_index do |cell, idx|
        if !cell.is_valid_output
          p cell.json
          raise "Output cell #{idx} is not valid. Ensure that you have set a lock, a capacity, and that capacity >= its minimum capacity"
        end
      end
    end

    def fee
      @fee ? @fee : self.class.calculate_fee
    end

    def gather_inputs()
      capacity_sums = {total: 0, minimum: 0}
      outputs.each do |cell|
        capacity_sums[:total] += cell.capacity
        capacity_sums[:minimum] += cell.min_capacity
      end
      @total_input_capacity = capacity_sums[:total]
      @min_input_capacity = capacity_sums[:minimum]
      self.class.gather_inputs(@total_input_capacity, @min_input_capacity)
    end

    def on_processed(name, &blk)
      tx_hash = hash
      tx_ready_check = Proc.new do
        t1 = Time.now
        puts "Calling Proc"
        tx_result = api.get_transaction(tx_hash)
        while !tx_result
          while  Time.now - t1 >= 5
            puts "READY CHECK"
            t1 = Time.now
            tx_result = api.get_transaction(tx_hash)
          end
        end
        tx_result
      end
      subscription = Meiosis::Subscription.new(name, tx_ready_check) do |result|
        blk.call(result)
      end
    end

    def api
      Meiosis::Config.api
    end
    def self.gather_inputs(capacity, min_capacity)
      raise "capacity cannot be less than #{min_capacity}" if capacity < min_capacity
      input_capacities = 0
      inputs = []
      Meiosis::Config.wallet.get_unspent_cells.each do |cell|
        input = {
          previous_output: cell[:out_point],
          args: [Meiosis::Config.wallet.lock[:binary_hash]],
          valid_since: 0
        }
        inputs << input
        input_capacities += cell[:capacity]

        break if input_capacities >= capacity && input_capacities - (input_capacities - capacity) >= min_capacity
      end
      raise "Not enough capacity!" if input_capacities < capacity
      OpenStruct.new(inputs: inputs, capacities: input_capacities)
    end

    def self.calculate_fee
      0
    end
  end
end
