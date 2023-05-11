# frozen_string_literal: true

require 'binnacle/utils'

module Binnacle
  module_function

  module Plugins
    module_function

    # Register a new plugin to configure the
    # Store or to add new behaviour.
    # @example
    #   Binnacle::Plugin.register "use_node" do |node_name
    def register(name, &plugin_block)
      define_method(name) do |*args, **kwargs, &block|
        t1 = Time.now

        data = plugin_block.call(*args, **kwargs, &block)

        # If the plugin is just setting the store key
        return nil if data.nil? || !data.key?(:ok)

        data[:duration_seconds] = Time.now - t1
        data[:line] = Utils.caller_line_number
        data[:node] = Store.get(:node_name)

        Utils.response(data)
      end
    end
  end

  def default_config(key, value)
    Store.default_value(key, value)
  end

  def register_plugin(name, &plugin_block)
    Plugins.register(name, &plugin_block)
  end
end
