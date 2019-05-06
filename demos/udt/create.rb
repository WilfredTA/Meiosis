require_relative '../../lib/meiosis.rb'
asset_definition_script = File.read("./scripts/definitions/aminos_asset.rb")
api = Meiosis::Config.api
wallet = Meiosis::Config.wallet
pubkey = wallet.get_pubkey
runner = Meiosis::Runner
lock = wallet.lock_binary


# This code runs first on the first iteration of the event loop. All of your synchronous code should be wrapped in this. Event subscriptions
# can be initialized within this block our outside of it: it doesn't matter
runner.setup do
  #Create new type cell
  udt_type_cell = Meiosis::Cell.new

  # Lock script is just the default lock of the wallet
  udt_lock_script = Meiosis::Script.new([lock])

  # Smart Contract source code added to cell data field
  udt_type_cell.data = asset_definition_script

  #Set the cell's lock script
  udt_type_cell.lock = udt_lock_script

  #Offer up minimum necessary capacity to store the cell
  udt_type_cell.capacity = udt_type_cell.min_capacity


  # Name of token and amount of tokens
  token_info = {
    name: "aminos",
    amount: 5101
  }

  # Commit type cell to CKB. This submits a tx to the blockchain
  type_tx = udt_type_cell.commit

  # Add an event handler for when the tx has been processed (i.e., it's not just waiting in the pool)
  # This is necessary because the state cell that will store the token depends on the type cell to exist so that it can
  # reference that cell
  type_tx.on_processed('type_cell') do |result|

    # Once type cell is confirmed, create account cell
    udt_state_cell = Meiosis::Cell.new
    udt_state_cell.data = [token_info[:amount]]

    # Use default wallet lock for now (would be a custom script if you wanted to do something like an ICO)
    udt_state_cell.lock = Meiosis::Script.new([lock])

    # Here we pass the ruby source code as the first argument. This will be executed by the system cell that processes ruby code.
    # Note that the point of waiting for type cell creation to complete was so we could reference the source code in another cell.
    # Or at the very least retrieve it and reuse it. But for the sake of simplicity, we are taking advantage of the source code being available locally.
    # The contract code expects the name of the token and pubkey of the creator as arguments, so we pass those in as well.
    udt_state_cell.type = Meiosis::Script.new([asset_definition_script, token_info[:name], pubkey])

    # We then follow the same pattern of offering up the minimum necessary bytes to store this data
    udt_state_cell.capacity = udt_state_cell.min_capacity

    # Submit the cell creation transaction to the blockchain
    state_tx = udt_state_cell.commit


    # Once account cell is confirmed, log both live cells
    state_tx.on_processed('state_cell') do |result|
      puts "Finished processing state and type cell"

      puts "Type cell: "
      p api.get_live_cell({hash: type_tx.hash, index: 0})

      puts "\n State cell"
      p api.get_live_cell({hash: state_tx.hash, index: 0})
      # Schedule the main thread to terminate
      runner.stop
    end
  end
end

# Finally, we tell Meiosis to execute our code. This invocation will be unnecessary in the near future and occur automatically
runner.run
