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

  register_plugin 'enable_debug' do |value: true, &block|
    Store.set(:debug, value, &block)
  end

  # Test any command for its return code
  #
  # ```
  # run "ls /etc/hosts"
  # ```
  #
  # or for any specific return code
  #
  # ```
  # run 1, "ls /non/existing"
  # ```
  #
  # To ignore errors, use `nil` return code
  #
  # ```
  # run nil, "ls /non/existing"
  # ```
  register_plugin 'run' do |*args|
    expect_ret = 0
    cmd = args[0]
    if args.size > 1
      expect_ret = args[0]
      cmd = args[1]
    end

    data = {
      expect_ret: expect_ret,
      ok: true
    }

    out = []
    Utils.execute(cmd) do |stdout_line, stderr_line, ret|
      unless stdout_line.nil?
        out << stdout_line
        puts "# #{stdout_line}" if Store.get(:debug)
      end
      warn "# #{stderr_line}" unless stderr_line.nil?

      unless ret.nil?
        data[:ret] = ret
        data[:ok] = ret == expect_ret unless expect_ret.nil?
      end
    end

    data[:output] = out.join
    data
  end

  # For Backward compatibility. Ignores errors
  register_plugin 'RUN' do |cmd|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.run(nil, cmd)
    end

    data
  end

  # Test any command for its return code
  #
  # ```
  # test "ls /etc/hosts"
  # ```
  #
  # or for any specific return code
  #
  # ```
  # test 1, "ls /non/existing"
  # ```
  #
  # To ignore errors, use `nil` return code
  #
  # ```
  # test nil, "ls /non/existing"
  # ```
  register_plugin 'test' do |*args|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.run(*args)
    end

    data
  end

  register_plugin 'TEST' do |*args|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.run(*args)
    end

    data
  end

  register_plugin 'expect' do |expect_value, cmd|
    data = {}
    Store.set(:response, 'return') do
      # TODO: If expect_value is multiline or a variable is given
      data = Plugins.run(0, cmd)
    end

    if data[:ok] && data[:output] != expect_value.to_s
      puts <<-MSG
        Expected:
        --
        #{expect_value}
        --
        Actual:
        --
        #{data[:output]}
        --
      MSG
      data[:ok] = false
    end

    data
  end

  register_plugin 'EXPECT' do |expect_value, cmd|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.expect(expect_value, cmd)
    end

    data
  end
end
