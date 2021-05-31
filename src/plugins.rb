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
    BinnacleTestsRunner.inc_counter

    return "" if BinnacleTestsRunner.dry_run?

    expect_ret = 0
    cmd = args[0]
    if args.size > 1
      expect_ret = args[0]
      cmd = args[1]
    end

    ret, out, err = BinnacleTestsRunner.execute(cmd)
    BinnacleTestsRunner.CMD_OK_NOT_OK(cmd, ret, out, err, expect_ret)

    out
  end

  # Test the output of any command matches the given value
  #
  # ```
  # EXPECT 42, "echo 42"
  # ```
  def EXPECT(expect_value, cmd)
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    ret, out, err = BinnacleTestsRunner.execute(cmd)

    if ret != 0
      BinnacleTestsRunner.CMD_OK_NOT_OK(cmd, ret, out, err, 0)
    else
      if "#{expect_value}" == out.strip
        BinnacleTestsRunner.OK(cmd)
      else
        BinnacleTestsRunner.NOT_OK(
          cmd,
          "\"#{expect_value}\"(Expected) != \"#{out.strip}\"(Actual)"
        )
      end
    end
  end

  # If value is String then evaluate it else return as is
  def value_from_expr(value, title, fail_message)
    if value.is_a? String
      begin
        value = eval(value)
      rescue Exception => ex
        fail_message += "\n#{ex.message}"
        BinnacleTestsRunner.NOT_OK(title, fail_message)
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
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    value = value_from_expr(value, title, fail_message)
    return if value.nil?

    if value
      BinnacleTestsRunner.OK(title)
    else
      BinnacleTestsRunner.NOT_OK(title, fail_message)
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
    BinnacleTestsRunner.inc_counter

    return if BinnacleTestsRunner.dry_run?

    value = value_from_expr(value, title, fail_message)
    return if value.nil?

    if !value
      BinnacleTestsRunner.OK(title)
    else
      BinnacleTestsRunner.NOT_OK(title, fail_message)
    end
  end
end
