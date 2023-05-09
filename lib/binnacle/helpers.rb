# frozen_string_literal: true

# Module with the collection of binnacle keywords
# and helper utilities
module Binnacle
  extent self

  def caller_line_number
    loc = caller_locations[1]
    "#{loc.path}:#{loc.lineno}"
  end

  def response(data)
    flag = Store.get(:response)

    if flag == 'return'
      return data
    elsif flag == 'stdout'
      puts "#{data.to_json}\n\n"
    else
      warn "#{data.to_json}\n\n"
    end

    exit 1 if Store.get(:exit_on_not_ok) && !data[:ok]

    # If output key exists in the response then
    # return it. It may be used by the caller.
    # Like: `data = run "cat ~/report.csv"`
    data.key?(:output) ? data[:output] : nil
  end

  # Register a new plugin to configure the
  # Store or to add new behaviour.
  # @example
  #   Binnacle.register_plugin "use_node" do |node_name
  def register_plugin(name, &plugin_block)
    define_method(name) do |*args, **kwargs, &block|
      t1 = Time.now

      data = plugin_block.call(*args, **kwargs, &block)

      # If the plugin is just setting the store key
      return nil if data.nil? || !data.key?(:ok)

      data[:duration_seconds] = Time.now - t1
      data[:line] = caller_line_number

      response(data)
    end
  end
end
