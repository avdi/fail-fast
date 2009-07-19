$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module FailFast
  VERSION = '1.1.0'

  class AssertionFailureError < Exception
  end

  module Assertions

    # Assert that no +values+ are nil or false.  Returns the last value.
    def assert(*values, &block)
      iterate_and_return_last(values, block) do |v|
        raise_assertion_error unless v
      end
    end

    # The opposite of #assert.
    def deny(*values)
      assert(*values.map{ |v| !v})
      assert(yield(*values)) if block_given?
      values.last
    end

    # Assert that no +values+ are nil.  Returns the last value.
    def assert_exists(*values, &block)
      iterate_and_return_last(values, block) {  |value| deny(value.nil?) }
    end

    # Assert that +values+ are collections that contain at least one element.
    # Returns the last value.
    def assert_one_or_more(*values, &block)
      iterate_and_return_last(values, block) do |value|
        assert_exists(value)
        deny(value.kind_of?(String))
        deny(value.empty?)
      end
    end

    # Assert that +hash+ exists, responds to #[], and contains a non-nil value
    # for all +keys+.  Returns +hash+.
    def assert_keys(hash, *keys)
      assert_exists(hash)
      assert(hash.respond_to?(:[]))
      values = keys.inject([]) { |vals, k| vals << assert_exists(hash[k]) }
      assert(yield(*values)) if block_given?
      hash
    end

    # Assert that +hash+ exists, responds to #[], and has no keys other than
    # +keys+.  Returns +hash+.
    def assert_only_keys(hash, *keys)
      assert_exists(hash)
      assert(hash.respond_to?(:[]))
      values = hash.inject([]) { |vals, (k, v)| 
        assert(keys.include?(k)); vals << hash[k] 
      }
      assert(yield(*values)) if block_given?
      hash
    end

    # Assert that +object+ responds to +messages+.  Returns +object+.
    def assert_respond_to(object, *messages)
      messages.each do |message|
        assert(object.respond_to?(message))
      end
      assert(yield(object)) if block_given?
      object
    end

    private

    def iterate_and_return_last(values, block = nil)
      values.each { |v| yield(v) }
      if block
        raise_assertion_error unless block.call(*values)
      end
      values.last
    end

    def raise_assertion_error
      error = FailFast::AssertionFailureError.new
      backtrace = caller
      trimmed_backtrace = []
      trimmed_backtrace.unshift(backtrace.pop) until
        backtrace.last.include?(__FILE__)
      error.set_backtrace(trimmed_backtrace)
      raise error
    end

  end
end
