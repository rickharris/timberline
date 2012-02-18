require 'test/unit'

require 'shoulda'

# include the gem
require 'timberline'

def reset_timberline
  Timberline.redis = nil
  Timberline.instance_variable_set("@config", nil)
  clear_test_db
  Timberline.redis = nil
  Timberline.instance_variable_set("@queue_list", {})
end

# Use database 15 for testing, so we don't risk overwriting any data that's
# actually useful
def clear_test_db
  Timberline.config do |c|
    c.database = 15
  end
  Timberline.redis.flushdb
end

module TestSugar
  module Helpers
    def a(name, &block)
      Context.push(name, &block)
    end

    # Code to be run before the context
    def setup(&block)
      if Context.current_context?
        Context.current_context.setups << block
      else
        warn "Not in a context"
      end
    end

    # Code to be run when the context is finished
    def teardown(&block)
      if Context.current_context?
        Context.current_context.teardowns << block
      else
        warn "Not in a context"
      end
    end

    # Defines an actual test based on the given context
    def it(name, &block)
      build_test(name, &block)
    end

    def build_test(name, &block)
      #build out the full context text

      #build the test name with the context text and the test name

      #define_method test_name do

        #run setups based on the context stack

        #run the test

        #run teardowns based on the context stack
      #end
    end

    def warn(message)
      puts " * Warning: #{message}"
    end
  end

  class Context
    include Helpers

    def initialize(name, &block)
      @name = name
      @block = block

      @setups = []
      @teardowns = []
    end

    def self.push_context(name, &block)
      @@context_stack ||= []

      context = Context.new(name, &block)
      @context_stack.push(context)

      context.build

      @context_stack.pop(context)
    end

    def self.context_stack
      @context_stack
    end

    def self.current_context
      @context_stack.last
    end

    def self.current_context?
      !!@context_stack.last
    end
  end
end

class MiniTest::Unit::TestCase
  include TestSuger::Helpers
end
