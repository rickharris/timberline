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
      name = "a " << name
      Context.push(name, &block)
    end

    def and(name, &block)
      name = "and " << name
      Context.push(name, &block)
    end

    def that(name, &block)
      name = "that " << name
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
      test_name = Context.build_test_name(name)

      define_method test_name, &block
    end

    def warn(message)
      puts " * Warning: #{message}"
    end
  end

  class Context
    include Helpers

    attr_reader :name, :setups, :teardowns

    def initialize(name, &block)
      @name = name
      @block = block

      @setups = []
      @teardowns = []
    end

    def build
      @block.call
    end

    def self.setup
      @context_stack.each do |context|
        context.setups.each do |setup|
          setup()
        end
      end
    end

    def self.teardown
      @context_stack.each do |context|
        context.teardowns.each do |teardown|
          teardown()
        end
      end
    end

    def self.build_test_name(name="")
      full_name = "test "
      @context_stack.each do |context|
        full_name << context.name << " "
      end
      full_name << name
      full_name.gsub(/\W+/, '_').downcase
    end

    def self.push(name, &block)
      @context_stack ||= []

      context = Context.new(name, &block)
      @context_stack.push(context)

      context.build

      @context_stack.pop
    end

    def self.context_stack
      @context_stack
    end

    def self.current_context
      @context_stack.last
    end

    def self.current_context?
      !@context_stack.empty?
    end
  end
end

class MiniTest::Unit::TestCase
  extend TestSugar::Helpers
  # TODO: figure out how to get the setup and teardown stuff to run. Should just
  # be figuring out how to hook into TestSugar::Context.setup and
  # TestSugar::Context.teardown.
end
