module BinnacleTestPlugins
  # Two ways to set the node
  # Using as Block
  #
  # ```
  # NODE "node1.example.com" do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # NODE "node1.example.com"
  # TEST "stat /var/www/html/index.html"
  # ```
  def NODE(node)
    if !block_given?
      BinnacleTestsRunner.set_node node
      return
    end

    prev = BinnacleTestsRunner.node
    BinnacleTestsRunner.set_node node
    yield
  ensure
    BinnacleTestsRunner.set_node = prev if !prev.nil?
  end

  # Two ways to set the remote plugin
  # Using as Block
  #
  # ```
  # REMOTE_PLUGIN "docker" do
  #   TEST "stat /var/www/html/index.html"
  # end
  # ```
  #
  # or without block
  #
  # ```
  # REMOTE_PLUGIN "docker"
  # TEST "stat /var/www/html/index.html"
  # ```
  def REMOTE_PLUGIN(plugin)
    if !block_given?
      BinnacleTestsRunner.set_remote_plugin plugin
      return
    end

    prev = BinnacleTestsRunner.remote_plugin
    BinnacleTestsRunner.set_remote_plugin plugin
    yield
  ensure
    BinnacleTestsRunner.set_remote_plugin prev if !prev.nil?
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

    return if BinnacleTestsRunner.dry_run?

    expect_ret = 0
    cmd = args[0]
    if args.size > 1
      expect_ret = args[0]
      cmd = args[1]
    end

    ret, out, err = BinnacleTestsRunner.execute(cmd)
    BinnacleTestsRunner.CMD_OK_NOT_OK(cmd, ret, out, err, expect_ret)
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
      BinnacleTestsRunner.CMD_OK_NOT_OK(cmd, ret, out, err, expect_ret)
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
end
