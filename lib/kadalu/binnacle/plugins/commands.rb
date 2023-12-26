# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Kadalu::Binnacle
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

  default_config(:remote_plugin, 'ssh')

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

  # For backward compatibility
  register_plugin 'EMIT_STDOUT' do |value: true, &block|
    Store.set(:debug, value, &block)
  end

  register_plugin 'exit_on_not_ok' do |value: true, &block|
    Store.set(:exit_on_not_ok, value, &block)
  end

  # For backward compatibility
  register_plugin 'EXIT_ON_NOT_OK' do |value: true, &block|
    Store.set(:exit_on_not_ok, value, &block)
  end

  default_config(:exit_on_not_ok, false)

  register_plugin 'use_sudo' do |value: true, &block|
    Store.set(:sudo, value, &block)
  end

  default_config(:sudo, false)

  # For backward compatibility
  register_plugin 'USE_SSH_SUDO' do |value: true, &block|
    Store.set(:sudo, value, &block)
  end

  register_plugin 'use_ssh_user' do |value, &block|
    Store.set(:ssh_user, value, &block)
  end

  default_config(:ssh_user, 'root')

  # For backward compatibility
  register_plugin 'USE_SSH_USER' do |value, &block|
    Store.set(:ssh_user, value, &block)
  end

  register_plugin 'use_ssh_pem_file' do |value, &block|
    Store.set(:ssh_pem_file, value, &block)
  end

  # For backward compatibility
  register_plugin 'USE_SSH_PEM_FILE' do |value, &block|
    Store.set(:ssh_pem_file, value, &block)
  end

  default_config(:ssh_pem_file, '~/.ssh/id_rsa')

  register_plugin 'use_ssh_port' do |value, &block|
    Store.set(:ssh_port, value, &block)
  end

  # For backward compatibility
  register_plugin 'USE_SSH_PORT' do |value, &block|
    Store.set(:ssh_port, value, &block)
  end

  default_config(:ssh_port, 22)

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
  register_plugin 'run' do |*args, **kwargs|
    expect_ret = 0
    cmd = args[0]
    if args.size > 1
      expect_ret = args[0]
      cmd = args[1]
    end

    data = { expect_ret: expect_ret, ok: true }

    out = []
    fcmd = Utils.full_cmd(cmd)
    puts "Executing #{fcmd}" if cmd != fcmd

    Utils.execute(fcmd) do |stdout_line, stderr_line, ret|
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
  register_plugin 'test' do |*args, **kwargs|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.run(*args)
    end

    data
  end

  register_plugin 'TEST' do |*args, **kwargs|
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
# rubocop:enable Metrics/ModuleLength
