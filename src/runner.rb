require "open3"

module BinnacleTestsRunner
  @@dry_run = false
  @@tests_count = 0
  @@node = "local"
  @@remote_plugin = "ssh"
  @@exit_on_not_ok = false
  @@ssh_user = "root"
  @@ssh_sudo = false
  @@ssh_port = 22
  @@ssh_pem_file = "~/.ssh/id_rsa"
  @@emit_stdout = false

  def self.emit_stdout=(val)
    @@emit_stdout = val
  end

  def self.emit_stdout?
    @@emit_stdout
  end

  # set ssh user
  def self.ssh_user=(user)
    @@ssh_user = user
  end

  def self.ssh_user
    @@ssh_user
  end

  # set ssh port
  def self.ssh_port=(port)
    @@ssh_port = port
  end

  def self.ssh_port
    @@ssh_port
  end

  # Set the ssh sudo flag
  def self.ssh_sudo=(val)
    @@ssh_sudo = val
  end

  def self.ssh_sudo?
    @@ssh_sudo
  end

  # set the ssh_pem_file path
  def self.ssh_pem_file=(pem_file)
    @@ssh_pem_file = pem_file
  end

  def self.ssh_pem_file
    @@ssh_pem_file
  end

  # Only for getting the number of tests
  def self.dry_run?
    @@dry_run
  end

  # Set the dry run flag
  def self.dry_run=(val)
    @@dry_run = val
  end

  # Set node
  def self.node=(node)
    @@node = node
  end

  # Remote plugin ssh or docker
  def self.remote_plugin=(plugin)
    @@remote_plugin = plugin
  end

  def self.node
    @@node
  end

  def self.remote_plugin
    @@remote_plugin
  end

  def self.exit_on_not_ok=(flag)
    @@exit_on_not_ok = flag
  end

  def self.exit_on_not_ok?
    @@exit_on_not_ok
  end

  def self.inc_counter
    @@tests_count += 1
  end

  def self.tests_count
    @@tests_count
  end

  def self.escaped_cmd(cmd)
    cmd.gsub("'", %Q['"'"'])
  end

  def self.escaped_ssh_cmd(cmd)
    cmd = "/bin/bash -c '#{escaped_cmd(cmd)}'"
    cmd = @@ssh_sudo ? "sudo #{cmd}" : cmd

    escaped_cmd(cmd)
  end

  # If node is not local then add respective prefix
  # to ssh or docker exec
  def self.full_cmd(cmd)
    return cmd if @@node == "local"

    if @@remote_plugin == "ssh"
      "ssh #{@@ssh_user}@#{@@node} -i #{@@ssh_pem_file} -p #{@@ssh_port} '#{escaped_ssh_cmd(cmd)}'"
    elsif @@remote_plugin == "docker"
      "docker exec -i #{@@node} /bin/bash -c '#{escaped_cmd(cmd)}'"
    else
      cmd
    end
  end

  # Execute the command and return the status.
  # Execute and Stream STDOUT and STDERR
  # Based on the blog: https://nickcharlton.net/posts/ruby-
  # subprocesses-with-stdout-stderr-streams.html
  def self.execute(cmd, &block)
    Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
      # read each stream from a new thread
      { :out => stdout, :err => stderr }.each do |key, stream|
        Thread.new do
          until (line = stream.gets).nil? do
            if key == :out
              yield line.chomp, nil, nil
            else
              yield nil, line.chomp, nil
            end
          end
        end
      end

      thread.join
      status = thread.value

      yield nil, nil, status.exitstatus
    end
  rescue Exception
    yield nil, "Unknown Command", -1
  end

  def self.print_test_state(ok_msg, test_id, msg)
    printf("%-6s %3d - %s\n", ok_msg, test_id, msg)
  end

  def self.OK_NOT_OK(test_name, cmd, ok, diagnostic=nil)
    out_desc = "node=#{@@node} cmd=\"#{test_name} #{cmd}\""

    ok_msg = ok ? "ok" : "not ok"
    self.print_test_state(ok_msg, self.tests_count, out_desc)

    if !diagnostic.nil? && diagnostic != ""
      puts "# #{diagnostic.split("\n").join("\n# ")}"
    end
  end

  def self.OK(cmd, diagnostic=nil)
    OK_NOT_OK(caller_locations(1,1)[0].label, cmd, true, diagnostic)
  end

  def self.NOT_OK(cmd, diagnostic=nil)
    OK_NOT_OK(caller_locations(1,1)[0].label, cmd, false, diagnostic)
  end

  def self.CMD_OK_NOT_OK(cmd, ret, expect_ret = 0)
    test_cmd_name = caller_locations(1,1)[0].label.gsub("block in ", "")
    out_desc = "node=#{@@node} cmd=\"#{test_cmd_name} #{cmd}\""
    out_desc += " expect_ret=#{expect_ret}" if expect_ret != 0

    if ret == expect_ret
      self.print_test_state("ok", self.tests_count, out_desc)
    else
      self.print_test_state("not ok", self.tests_count, out_desc)
    end
  end
end
