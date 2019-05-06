module Meiosis
  module Utils
    include CKB::Utils

    def self.calculate_script_capacity(script)
      capacity = 1 + (script[:args] || []).map { |arg| arg.bytesize }.reduce(0, &:+)
      if script[:binary_hash]
        capacity += CKB::Utils.hex_to_bin(script[:binary_hash]).bytesize
      end
      capacity
    end

    def self.calculate_cell_min_capacity(output)
      capacity = 8 + output[:data].bytesize + calculate_script_capacity(output[:lock])
      if type = output[:type]
        capacity += calculate_script_capacity(type)
      end
      capacity
    end

    def self.bin_to_prefix_hex(bin)
      "0x#{bin_to_hex(bin)}"
    end

    def self.bin_to_hex(bin)
      bin.unpack1("H*")
    end
  end

end
