# Introduction: Philosophy and Features

*Note: This readme is a work in progress and subject to frequent change.*

Pre-requisite knowledge:
1. Understanding of CKB structures (cell model, script, transaction)
2. Knowledge of ruby language
3. Understanding of the difference between generator code and verification code

Meiosis is a framework for writing generator code that for Nervos CKB. DApps on the CKB are divided into generators and verifiers. Generators create new state and submit it to the blockchain (CKB). Verifiers are the scripts, or smart contracts, that validate the submitted state according to predefined business rules by the DApp developer.

`ckb-sdk-ruby` is included as a local directory rather than a gem due to rapid development on the official repo. It will be removed and replaced with the gem in the near future.

The goal of Meiosis is currently to provide two things:
1. An intuitive interface for generating and querying the CKB. Instead of an Object-Relational Mapping, it is a prototypical Object-Blockchain Mapping
2. Provide asynchronous programming capabilities in response to on-chain events.

## Object-Blockchain Mapping
Meiosis provides convenience classes for generating and querying CKB state in a familiar ORM-like fashion.

For example:

Query the CKB for a cell that matches specific filters
`Cell.find_one({capacity: 521, lock: my_wallet.lock})`

Or query the CKB for all cells that match specific filters.
`Cell.find({capacity: 100, lock: my_wallet.lock}, limit: 10)`

You can also easily create or update CKB-structures.

Using a Cell as an example again:

```
cell = Cell.find_one({...})
cell.data = <some_new_data> # Put some new data in this cell
cell.capacity = cell.min_capacity # Update capacity you're willing to store in this cell
cell.commit # Save changes to the blockchain
```




## On-Chain Subscriptions

Meiosis allows you to subscribe to on-chain events with subscriptions. Meiosis' main thread runs in an event loop. Subscriptions are achieved by periodically monitoring or polling the blockchain for developer-defined (or built-in) conditions in a separate thread. Once the pre-specified conditions that define the "occurrence" of the event are detected, the main thread is notified and the callback assigned to that event will be executed in the main thread. This is particularly useful when constructing a series of transactions, where subsequent transactions depend on successful confirmation of earlier ones.

See the udt demo for a demonstration of this.

Built-in subscription: `Transaction#on_processed`
```
transaction = transaction.send
# Once the transaction has been processed, the callback will be executed. `Transaction#on_processed' is an example of a built-in event subscription
transaction.on_processed do |result|
  p result

end

# "Hello" will log before result is logged
puts "hello"
```

Or, define your own:

```
#Periodic polling
detect_some_change = Proc.new do
  t1 = Time.now
  some_ckb_data = api.rpc_request(<...>)
  while !check_data_for_target_changes(some_ckb_data)
    while Time.now - t1 >= 5
      t1 = Time.now
      some_ckb_data = api.rpc_request(<...>)
     end
  end
  some_ckb_data
end


# Subscribe to event

change_has_occurred = Subscription.new('some_change', detect_some_change) do |data|
  <do something with this data>
end
```

## Quick Setup

Since both CKB and the Ruby SDK are under rapid development, I have included ckb-sdk-ruby directory within this repo. This will change and use the official, most up-to-date versions once it is more stable.

To acquire & build CKB, follow instructions [here](https://github.com/nervosnetwork/ckb/blob/develop/docs/get-ckb.md)

Locate this file: `ckb/resource/specs/dev.toml`

and copy this into it:

```
name = "ckb"

[genesis]
version = 0
parent_hash = "0x0000000000000000000000000000000000000000000000000000000000000000"
timestamp = 0
txs_commit = "0x0000000000000000000000000000000000000000000000000000000000000000"
txs_proposal = "0x0000000000000000000000000000000000000000000000000000000000000000"
difficulty = "0x100"
uncles_hash = "0x0000000000000000000000000000000000000000000000000000000000000000"

[genesis.seal]
nonce = 0
proof = [0]

[params]
initial_block_reward = 5000000
max_block_cycles = 100000000

[pow]
func = "Dummy"


# the 2-log of the graph size, which is the size in bits of the node
# identifiers
edge_bits = 15

# length of the cycle to be found, must be an even number, a minimum of 12 is
# recommended
cycle_length = 12

# An array list paths to system cell files, which is absolute or relative to
# the directory containing this config file.
[[system_cells]]
path = "cells/always_success"
```

You will also need to follow the directions [here](https://github.com/nervosnetwork/ckb-demo-ruby) to get other necessary dependencies.

Once you get to the part where it instructs you to `install_mruby_cell`, you will not have to worry about this. Instead, you will copy the path to ARGV_SOURCE_ENTRY and store it as an environment variable in your `.env` file as specified below. This will allow Meiosis to initialize the system_script_cell for you upon startup if it does not exist.

Once ckb is compiled and configured, and once other dependencies are installed, open two terminals. In the first, run

`target/release/ckb run`
and in the second:
`target/release/ckb miner`

To run the demo:
`cd Meiosis/demos/udt`
`bundle`
`touch .env`
add this to your `.env` file:
```
  always_success=true
  system_script_cell_path=<path/to/ARGV_SOURCE_ENTRY>
```
then:
`bundle exec ruby create.rb`

To use Meiosis (not gem-ified at the moment):

`cd Meiosis`
`bundle`

and then add this to your project:
`require_relative "path/to/Meiosis/lib/meiosis.rb"`
