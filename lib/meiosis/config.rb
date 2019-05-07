module Meiosis
  class Config
    class << self
      attr_accessor :wallet, :api
      attr_reader :privkey
      def init(env_vars)
        if !env_vars["privkey"]
          @privkey = SecureRandom.random_bytes(32)
          @keyclass = Secp256k1::PrivateKey.new({privkey: @privkey})
        else
          @privkey = env_vars["privkey"]
          @keyclass = Secp256k1::PrivateKey.new({privkey: env_vars["privkey"]})
        end
        @api = Meiosis::API.new
        @wallet = Meiosis::Wallet.new(api, privkey)

        if ENV["always_success"]
          @wallet.lock = {
              binary_hash: "0x0000000000000000000000000000000000000000000000000000000000000001",
              args: [],
              version: 0
            }
        end

        if !api.system_script_cell
          wallet.install_system_script_cell(env_vars["system_script_cell_path"])
        end
      end
    end
  end

  class Runner
    @@stop_scheduled = false
    @@setup_routine = nil
    @@subscriber = Meiosis::Subscription
    @@setup_checked = false

    def self.setup_routine
      @@setup_routine
    end

    def self.run
      while true
        check_for_setup unless @@setup_checked
        break if stop_scheduled?
        check_for_subscription_results
        break if stop_scheduled?
      end
    end

    def self.setup &blk
      @@setup_routine = blk
    end

    def self.check_for_setup
      @@setup_routine.call if @@setup_routine
      @@setup_checked = true
    end

    def self.stop_scheduled?
      @@stop_scheduled
    end

    def self.check_for_subscription_results
        while !@@subscriber.results.empty?
            res = @@subscriber.results.pop
            cback = res.callback
            cback.call(res.result)
            @@subscriber.remove_subscription(res)
        end
    end

    def self.stop
      @@stop_scheduled = true
    end

  end
end
