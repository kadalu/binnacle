module BinnacleTestPlugins
  # Two ways to set the node
  # Using as Block
  #
  # ```
  # USE_NODE "node1.example.com" do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # USE_NODE "node1.example.com"
  # TEST "stat /var/www/html/index.html"
  # ```
  def USE_NODE(node)
    if !block_given?
      BinnacleTestsRunner.node = node
      return
    end

    prev = BinnacleTestsRunner.node
    BinnacleTestsRunner.node = node
    yield
  ensure
    BinnacleTestsRunner.node = prev if !prev.nil?
  end

  # Two ways to set the remote plugin
  # Using as Block
  #
  # ```
  # USE_REMOTE_PLUGIN "docker" do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # USE_REMOTE_PLUGIN "docker"
  # TEST "stat /var/www/html/index.html"
  # ```
  def USE_REMOTE_PLUGIN(plugin)
    if !block_given?
      BinnacleTestsRunner.remote_plugin = plugin
      return
    end

    prev = BinnacleTestsRunner.remote_plugin
    BinnacleTestsRunner.remote_plugin = plugin
    yield
  ensure
    BinnacleTestsRunner.remote_plugin = prev if !prev.nil?
  end

  # Two ways to set the ssh sudo
  # Using as Block
  #
  # ```
  # USE_SSH_SUDO true do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # USE_SSH_SUDO true
  # TEST "stat /var/www/html/index.html"
  # ```
  def USE_SSH_SUDO(flag)
    if !block_given?
      BinnacleTestsRunner.ssh_sudo = flag
      return
    end

    prev = BinnacleTestsRunner.ssh_sudo
    BinnacleTestsRunner.ssh_sudo = flag
    yield
  ensure
    BinnacleTestsRunner.ssh_sudo = prev if !prev.nil?
  end

  # Two ways to set the ssh user
  # Using as Block
  #
  # ```
  # USE_SSH_USER "ubuntu" do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # USE_SSH_USER "ubuntu"
  # TEST "stat /var/www/html/index.html"
  # ```
  def USE_SSH_USER(user)
    if !block_given?
      BinnacleTestsRunner.ssh_user = user
      return
    end

    prev = BinnacleTestsRunner.ssh_user
    BinnacleTestsRunner.ssh_user = user
    yield
  ensure
    BinnacleTestsRunner.ssh_user = prev if !prev.nil?
  end

  # Two ways to set the ssh user
  # Using as Block
  #
  # ```
  # USE_SSH_PEM_FILE "/home/ubuntu/.ssh/id_rsa" do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # USE_SSH_PEM_FILE "/home/ubuntu/.ssh/id_rsa"
  # TEST "stat /var/www/html/index.html"
  # ```
  def USE_SSH_PEM_FILE(pem_file)
    if !block_given?
      BinnacleTestsRunner.ssh_pem_file = pem_file
      return
    end

    prev = BinnacleTestsRunner.ssh_pem_file
    BinnacleTestsRunner.ssh_pem_file = pem_file
    yield
  ensure
    BinnacleTestsRunner.ssh_pem_file = prev if !prev.nil?
  end

  # Two ways to set the remote plugin
  # Using as Block
  #
  # ```
  # EXIT_ON_NOT_OK true do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # EXIT_ON_NOT_OK true
  # TEST "stat /var/www/html/index.html"
  # ```
  def EXIT_ON_NOT_OK(flag)
    if !block_given?
      BinnacleTestsRunner.exit_on_not_ok = flag
      return
    end

    prev = BinnacleTestsRunner.exit_on_not_ok?
    BinnacleTestsRunner.exit_on_not_ok = flag
    yield
  ensure
    BinnacleTestsRunner.exit_on_not_ok = prev if !prev.nil?
  end

  # Two ways to set the STDOUT emit.
  # Using as Block
  #
  # ```
  # EMIT_STDOUT true do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # EMIT_STDOUT true
  # TEST "stat /var/www/html/index.html"
  # ```
  def EMIT_STDOUT(val)
    if !block_given?
      BinnacleTestsRunner.emit_stdout = val
      return
    end

    prev = BinnacleTestsRunner.emit_stdout?
    BinnacleTestsRunner.emit_stdout = val
    yield
  ensure
    BinnacleTestsRunner.emit_stdout = prev if !prev.nil?
  end

  # Test any command for its return code
  #
  # ```
  # TEST "ls /etc/hosts"
  # ```
  #
  # or for any specific return code
  #
  # ```
  # TEST 1, "ls /non/existing"
  # ```
  def TEST(*args)
    caller_line = caller_locations.first
    line = "#{caller_line.path}:#{caller_line.lineno}"
    BinnacleTestsRunner.inc_counter

    return "" if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start

    expect_ret = 0
    cmd = args[0]
    if args.size > 1
      expect_ret = args[0]
      cmd = args[1]
    end

    out = []
    BinnacleTestsRunner.execute(cmd) do |stdout_line, stderr_line, ret|
      unless stdout_line.nil?
        out << stdout_line
        puts "# #{stdout_line}" if BinnacleTestsRunner.emit_stdout?
      end
      STDERR.puts "# #{stderr_line}" unless stderr_line.nil?

      unless ret.nil?
        BinnacleTestsRunner.cmd_test_end(cmd, ret: ret, expect_ret: expect_ret, line: line)
        exit if (BinnacleTestsRunner.exit_on_not_ok? && ret != 0)
      end
    end

    out.join
  end

  # Test the output of any command matches the given value
  #
  # ```
  # EXPECT 42, "echo 42"
  # ```
  def EXPECT(expect_value, cmd)
    caller_line = caller_locations.first
    line = "#{caller_line.path}:#{caller_line.lineno}"
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start
    out = []
    BinnacleTestsRunner.execute(cmd) do |stdout_line, stderr_line, ret|
      unless stdout_line.nil?
        out << stdout_line
        puts "# #{stdout_line}" if BinnacleTestsRunner.emit_stdout?
      end
      STDERR.puts "# #{stderr_line}" unless stderr_line.nil?

      unless ret.nil?
        BinnacleTestsRunner.cmd_test_end(cmd, ret: ret, expect_ret: 0, line: line) if ret != 0
        exit if (BinnacleTestsRunner.exit_on_not_ok? && ret != 0)
      end
    end

    if "#{expect_value}" == out.join
      BinnacleTestsRunner.test_end(cmd, ok: true, line: line)
    else
      BinnacleTestsRunner.test_end(
        cmd,
        ok: false,
        diagnostic: "Expected:\n--\n#{expect_value}\n--\nActual:\n--\n#{out.join}\n--\n",
        line: line
      )
      exit if BinnacleTestsRunner.exit_on_not_ok?
    end
  end

  # If value is String then evaluate it else return as is
  def value_from_expr(value, title, fail_message, line = 0)
    if value.is_a? String
      begin
        value = eval(value)
      rescue Exception => ex
        fail_message += "\n#{ex.message}"
        BinnacleTestsRunner.test_end(title, ok: false, diagnostic: fail_message, line: line)
        return nil
      end
    end

    value
  end

  # Validate if the given expression or value as true
  #
  # ```
  # TRUE 10 == 10, "Test Title", "Optional Fail message"
  # ```
  #
  # ```
  # TRUE "#{value} == 100", "Value is 100", "Actual: #{value}"
  # ```
  def TRUE(value, title, fail_message = "")
    caller_line = caller_locations.first
    line = "#{caller_line.path}:#{caller_line.lineno}"
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start
    value = value_from_expr(value, title, fail_message, line)
    return if value.nil?

    if value
      BinnacleTestsRunner.test_end(title, ok: true, line: line)
    else
      BinnacleTestsRunner.test_end(title, ok: false, diagnostic: fail_message, line: line)
      exit if BinnacleTestsRunner.exit_on_not_ok?
    end
  end

  # Validate if the given expression or value as false
  #
  # ```
  # FALSE 10 == 10, "Test Title", "Optional Fail message"
  # ```
  #
  # ```
  # FALSE "#{value} == 100", "Value is not 100", "Actual: #{value}"
  # ```
  def FALSE(value, title, fail_message = "")
    caller_line = caller_locations.first
    line = "#{caller_line.path}:#{caller_line.lineno}"
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start
    value = value_from_expr(value, title, fail_message)
    return if value.nil?

    if !value
      BinnacleTestsRunner.test_end(title, ok: true, line: line)
    else
      BinnacleTestsRunner.test_end(title, ok: false, diagnostic: fail_message, line: line)
      exit if BinnacleTestsRunner.exit_on_not_ok?
    end
  end

  # Run any command and ignore if any Error
  #
  # ```
  # RUN "rm -rf testdir"
  # RUN "ls /non/existing"
  # ```
  def RUN(cmd)
    return "" if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start
    out = []
    BinnacleTestsRunner.execute(cmd) do |stdout_line, stderr_line, ret|
      unless stdout_line.nil?
        out << stdout_line
        puts "# #{stdout_line}" if BinnacleTestsRunner.emit_stdout?
      end
      STDERR.puts "# #{stderr_line}" unless stderr_line.nil?
    end

    out.join
  end

  # Validate if the given two values are equal
  #
  # ```
  # EQUAL 10, 10, "Test Title"
  # ```
  #
  # ```
  # EQUAL var1, 100, "Value is 100"
  # ```
  def EQUAL(value1, value2, title)
    caller_line = caller_locations.first
    line = "#{caller_line.path}:#{caller_line.lineno}"
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start
    if value1 == value2
      BinnacleTestsRunner.test_end(title, ok: true, line: line)
    else
      fail_message = "Value1:\n--\n#{value1}\n--\n\nValue2:\n--\n#{value2}\n--\n"
      BinnacleTestsRunner.test_end(title, ok: false, diagnostic: fail_message, line: line)
      exit if BinnacleTestsRunner.exit_on_not_ok?
    end
  end

  # Validate if the given two values are not equal
  #
  # ```
  # NOT_EQUAL 10, 11, "Test Title"
  # ```
  #
  # ```
  # NOT_EQUAL var1, 100, "Value is 100"
  # ```
  def NOT_EQUAL(value1, value2, title)
    caller_line = caller_locations.first
    line = "#{caller_line.path}:#{caller_line.lineno}"
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    BinnacleTestsRunner.test_start
    if value1 != value2
      BinnacleTestsRunner.test_end(title, ok: true, line: line)
    else
      fail_message = "value1 and value2 are equal(value1: #{value1})"
      BinnacleTestsRunner.test_end(title, ok: false, diagnostic: fail_message, line: line)
      exit if BinnacleTestsRunner.exit_on_not_ok?
    end
  end
end
