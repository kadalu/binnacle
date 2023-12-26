# frozen_string_literal: true

require 'kadalu/binnacle/utils'

module Kadalu::Binnacle
  module_function

  module Plugins
    module_function

    # Register a new plugin to configure the
    # Store or to add new behaviour.
    # @example
    #   Binnacle::Plugin.register "use_node" do |node_name
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def register(name, &plugin_block)
      define_method(name) do |*args, **kwargs, &block|
        t1 = Time.now

        data = plugin_block.call(*args, **kwargs, &block)

        # If the plugin is just setting the store key
        return nil if data.nil? || !data.key?(:ok)

        data[:name] = name
        data[:duration_seconds] = Time.now - t1

        Utils.task_and_line(data)
        Utils.node_or_container_label(data)
        data[:task_number] = Store.inc(:count)
        Utils.response(data)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end

  def default_config(key, value)
    Store.default_value(key, value)
  end

  def register_plugin(name, &plugin_block)
    Plugins.register(name, &plugin_block)
  end

  default_config(:response, 'stdout')
end
