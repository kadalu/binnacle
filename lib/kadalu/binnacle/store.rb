# frozen_string_literal: true

module Kadalu
  module Binnacle
    # Global config store for Binnacle keywords
    class Store
      @data = {}
      @default_values = {}

      # Add the given key value to the Store
      # Set the value temorarily if the block is given.
      # Following example sets the value for all the future
      # uses till the value changes again.
      #
      # ```
      # Store.set(:node_name, "server1")
      # ```
      #
      # Following example shows the value is set only for the
      # given block.
      #
      # ```
      # Store.set(:node_name, "server1") do
      #   puts "Node name is server1"
      # end
      # ```
      def self.set(name, value, &block)
        if block
          prev_value = get(name)
          @data[name] = value
          block.call
          @data[name] = prev_value
        else
          @data[name] = value
        end

        nil
      end

      def self.hash_set(hash_name, name, value, &block)
        @data[hash_name] = {} unless @data.key?(hash_name)

        if block
          prev_value = @data[hash_name][name]
          @data[hash_name][name] = value
          block.call
          if prev_value
            @data[hash_name][name] = prev_value
          else
            @data[hash_name].delete(name)
          end
        else
          @data[hash_name][name] = value
        end

        nil
      end

      def self.hash_remove(hash_name, name, &block)
        @data[hash_name] = {} unless @data.key?(hash_name)

        if block
          prev_value = @data[hash_name][name]
          @data[hash_name].delete(name) if prev_value
          block.call
          @data[hash_name][name] = prev_value if prev_value
        elsif @data[hash_name].key?(name)
          @data[hash_name].delete(name)
        end

        nil
      end

      def self.inc(name)
        @data[name] = 0 unless @data.key?(name)
        @data[name] += 1
        @data[name]
      end

      # Get the value from the Store for a given key
      def self.get(name)
        value = nil
        value = @default_values[name] if @default_values.key?(name)
        value = @data[name] if @data.key?(name)
        value
      end

      # Remember the previous value before
      # running the block and then set the
      # previous value after running the block.
      # @example
      #
      #  Store.remember [:node_name] do
      #    Store.set :node_name, "new_name"
      #    # implementation
      #  end
      def self.remember(keys, &block)
        values = []
        keys.each do |key|
          values << @data[key]
        end
        resp = block.call
        keys.each_with_index do |key, idx|
          @data[key] = values[idx]
        end

        resp
      end

      def self.default_value(key, value)
        @default_values[key] = value
      end

      # Removes all the key values except the default values
      def self.reset
        @data = {}
      end
    end
  end
end
