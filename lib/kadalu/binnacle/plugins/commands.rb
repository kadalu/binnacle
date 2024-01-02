# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Kadalu
  module Binnacle
    # Two ways to set the command_mode
    # Using as Block
    #
    # ```
    # command_mode "docker" do
    #   command_test "stat /var/www/html/index.html"
    # end
    # ```
    #
    # or without block
    #
    # ```
    # command_mode "docker"
    # command_test "stat /var/www/html/index.html"
    # ```
    register_plugin 'command_mode' do |plugin, &block|
      Store.set(:command_mode, plugin, &block)
    end

    # For backward compatibility
    register_plugin 'USE_REMOTE_PLUGIN' do |plugin, &block|
      Store.set(:command_mode, plugin, &block)
    end

    default_config(:command_mode, 'local')

    # Two ways to set the node
    # Using as Block
    #
    # ```
    # command_node "node1.example.com" do
    #   command_test "stat /var/www/html/index.html"
    # end
    # ```
    #
    # or without block
    #
    # ```
    # command_node "node1.example.com"
    # command_test "stat /var/www/html/index.html"
    # ```
    register_plugin 'command_node' do |value, &block|
      Store.set(:node_name, value, &block)
    end

    # For backward compatibility
    register_plugin 'USE_NODE' do |value, &block|
      Store.set(:node_name, value, &block)
    end

    register_plugin 'command_container' do |value, &block|
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

    register_plugin 'command_sudo' do |value: true, &block|
      Store.set(:sudo, value, &block)
    end

    default_config(:sudo, false)

    # For backward compatibility
    register_plugin 'USE_SSH_SUDO' do |value: true, &block|
      Store.set(:sudo, value, &block)
    end

    register_plugin 'command_ssh_user' do |value, &block|
      Store.set(:ssh_user, value, &block)
    end

    default_config(:ssh_user, 'root')

    # For backward compatibility
    register_plugin 'USE_SSH_USER' do |value, &block|
      Store.set(:ssh_user, value, &block)
    end

    register_plugin 'command_ssh_pem_file' do |value, &block|
      Store.set(:ssh_pem_file, value, &block)
    end

    # For backward compatibility
    register_plugin 'USE_SSH_PEM_FILE' do |value, &block|
      Store.set(:ssh_pem_file, value, &block)
    end

    default_config(:ssh_pem_file, '~/.ssh/id_rsa')

    register_plugin 'command_ssh_port' do |value, &block|
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
    # command_run "ls /etc/hosts"
    # ```
    #
    # or for any specific return code
    #
    # ```
    # command_run 1, "ls /non/existing"
    # ```
    #
    # To ignore errors, use `nil` return code
    #
    # ```
    # command_run nil, "ls /non/existing"
    # ```
    register_plugin 'command_run' do |*args, **_kwargs|
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
        data = Plugins.command_run(nil, cmd)
      end

      data
    end

    # Test any command for its return code
    #
    # ```
    # command_test "ls /etc/hosts"
    # ```
    #
    # or for any specific return code
    #
    # ```
    # command_test 1, "ls /non/existing"
    # ```
    #
    # To ignore errors, use `nil` return code
    #
    # ```
    # command_test nil, "ls /non/existing"
    # ```
    register_plugin 'command_test' do |*args, **_kwargs|
      data = {}
      Store.set(:response, 'return') do
        data = Plugins.command_run(*args)
      end

      data
    end

    register_plugin 'TEST' do |*args, **_kwargs|
      data = {}
      Store.set(:response, 'return') do
        data = Plugins.command_run(*args)
      end

      data
    end

    register_plugin 'command_expect' do |expect_value, cmd|
      data = {}
      Store.set(:response, 'return') do
        # TODO: If expect_value is multiline or a variable is given
        data = Plugins.command_run(0, cmd)
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
        data = Plugins.command_expect(expect_value, cmd)
      end

      data
    end
  end
end
# rubocop:enable Metrics/ModuleLength
