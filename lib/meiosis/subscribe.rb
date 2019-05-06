module Meiosis
  class Subscription
    @@subscriptions = Queue.new
    @@results = Queue.new
    @@class_barrier = Mutex.new
    attr_accessor :thread
    attr_reader :ready, :result, :checks, :pending, :callback, :id
    def self.subscriptions
      @@subscriptions
    end

    def self.results
       @@results
    end

    def self.class_barrier
      @@class_barrier
    end

    def self.remove_subscription(subscription_object)
      new_subs = Queue.new
      while !@@subscriptions.empty?
        curr = @@subscriptions.pop
        if curr != self
          new_subs.push(curr)
        end
      end
      @@subscriptions = new_subs
    end

    def ==(other)
      other.instace_of?(self.class) && self.id == other.id
    end

    def !=(other)
      !self == other
    end

    def initialize(event_name, event_check, &cback)
      puts "Initializing new subscription"
      @id = SecureRandom.uuid()
      @@subscriptions << self
      @callback = cback
      @ready = false
      subscribe_to(event_name, event_check)
    end

    def subscribe_to(event_name, event_check)
        puts "THREAD COMPARISON"
        p Thread.current == Thread.main
        @event_check = event_check
        @thread = Thread.new do
          Thread.abort_on_exception=true
          result = event_check.call
          @result = result
          @@results.push(self)
          @ready = true
          @result
        end
    end

    def safe_access(&blk)
      @@class_barries.synchronize {blk.call}
    end
  end
end


# Workflow for subscribing to an event:

# When a subscription is initiated, a new thread is spawned
# This thread will poll until it returns a truthy value
# Once it returns a truthy value, it will modify subscriptions and results
