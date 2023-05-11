# frozen_string_literal: true

module Binnacle
  # Two ways to set the remote plugin
  # Using as Block
  #
  # ```
  # use_remote_plugin "docker" do
  #   test "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # use_remote_plugin "docker"
  # test "stat /var/www/html/index.html"
  # ```
  register_plugin 'use_remote_plugin' do |plugin, &block|
    Store.set(:remote_plugin, plugin, &block)
  end

  # For backward compatibility
  register_plugin 'USE_REMOTE_PLUGIN' do |plugin, &block|
    Store.set(:remote_plugin, plugin, &block)
  end

  default_config(:remote_plugin, 'local')

  # Two ways to set the node
  # Using as Block
  #
  # ```
  # use_node "node1.example.com" do
  #   test "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # use_node "node1.example.com"
  # test "stat /var/www/html/index.html"
  # ```
  register_plugin 'use_node' do |value, &block|
    Store.set(:node_name, value, &block)
  end

  # For backward compatibility
  register_plugin 'USE_NODE' do |value, &block|
    Store.set(:node_name, value, &block)
  end

  register_plugin 'use_container' do |value, &block|
    Store.set(:node_name, value, &block)
  end

  default_config(:node_name, 'local')
end
