# Introduction: Philosophy and Features

*Note: This readme is a work in progress and subject to frequent change.*

Pre-requisite knowledge:
1. Understanding of CKB structures (cell model, script, transaction)
2. Knowledge of ruby language
3. Understanding of the difference between generator code and verification code

Meiosis is a framework for writing generator code that for Nervos CKB. DApps on the CKB are divided into generators and verifiers. Generators create new state and submit it to the blockchain (CKB). Verifiers are the scripts, or smart contracts, that validate the submitted state according to predefined business rules by the DApp developer.

`ckb-sdk-ruby` is included as a local directory rather than a gem due to rapid development on the official repo. It will be removed and replaced with the gem in the near future.

## On-Chain Subscriptions

Meiosis allows you to subscribe to on-chain events with subscriptions. Meiosis' main thread runs in an event loop. Subscriptions to on-chain events allow you to define callbacks when those events occur. This is particularly useful when constructing a series of transactions, where subsequent transactions depend on successful confirmation of earlier ones.

See the udt demo for a demonstration of this.


```
transaction = transaction.send
# Once the transaction has been processed, the block will execute.
transaction.on_processed do |result|
  p result

end
# This logs first
puts "hello"
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
