require 'securerandom'
require 'dotenv'
require 'thread'
require_relative '../ckb-sdk-ruby/lib/ckb.rb'
require_relative './meiosis/subscribe.rb'
require_relative './meiosis/api.rb'
require_relative './meiosis/utils.rb'
require_relative './meiosis/wallet.rb'
require_relative './meiosis/config'
require_relative './meiosis/script'
require_relative './meiosis/transaction'
require_relative './meiosis/cell'



Meiosis::Config.init(Dotenv.load)
