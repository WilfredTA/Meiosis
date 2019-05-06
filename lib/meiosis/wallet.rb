module Meiosis
  class Wallet < CKB::Wallet
    def initialize(api, privkey)
      super(api, privkey)
    end

    def get_pubkey
      pubkey
    end

    def get_pubkey_bin
      pubkey_bin
    end

    def lock=(data)
      @lock = data
    end

    def lock_binary
      CKB::Utils.bin_to_hex(CKB::Blake2b.digest(CKB::Blake2b.digest(get_pubkey_bin)))
    end

    def send_tx(tx)
      send_transaction_bin(tx)
    end

    def install_system_script_cell(mruby_cell_filename)
      data = CKB::Utils.bin_to_prefix_hex(File.read(mruby_cell_filename))
      cell_hash = CKB::Utils.bin_to_prefix_hex(CKB::Blake2b.digest(data))
      output = {
        capacity: 0,
        data: data,
        lock: lock
      }
      output[:capacity] = Meiosis::Utils.calculate_cell_min_capacity(output)
      p output[:capacity]

      i = Meiosis::Transaction.gather_inputs(output[:capacity], 0)
      input_capacities = i.capacities

      outputs = [output.merge(capacity: output[:capacity])]

      if input_capacities > output[:capacity]
        outputs << {
          capacity: (input_capacities - output[:capacity]),
          data: "0x",
          lock: lock
        }
      end

      tx = {
        version: 0,
        deps: [],
        inputs: i.inputs,
        outputs: outputs,
        witnesses: []
      }
      hash = api.send_transaction(tx)
      {
        out_point: {
          hash: hash,
          index: 0
        },
        cell_hash: cell_hash
      }
    end
  end
end
