# frozen_string_literal: true

require 'json'
require 'open3'

# Module with the collection of binnacle keywords
# and helper utilities
module Binnacle
  module Utils
    module_function

    def caller_line_number
      loc = caller_locations[1]
      "#{loc.path}:#{loc.lineno}"
    end

    def print_output(data, flag)
      if flag == 'stdout'
        puts "#{data.to_json}\n\n"
      else
        warn "#{data.to_json}\n\n"
      end
    end

    def response(data)
      flag = Store.get(:response)

      return data if flag == 'return'

      output = nil
      if data.key?(:output)
        output = data[:output]
        data.delete(:output)
      end

      print_output(data, flag)

      exit 1 if Store.get(:exit_on_not_ok) && !data[:ok]

      # If output key exists in the response then
      # return it. It may be used by the caller.
      # Like: `data = run "cat ~/report.csv"`
      output
    end

    def escaped_cmd(cmd)
      cmd.gsub("'", %('"'"'))
    end

    def escaped_ssh_cmd(cmd)
      cmd = "/bin/bash -c '#{escaped_cmd(cmd)}'"
      cmd = @@ssh_sudo ? "sudo #{cmd}" : cmd

      escaped_cmd(cmd)
    end

    # If node is not local then add respective prefix
    # to ssh or docker exec
    def full_cmd(cmd)
      return cmd if Store.get(:node_name) == 'local'

      if Store.get(:remote_plugin) == 'ssh'
        "ssh #{Store.get(:ssh_user)}@#{Store.get(:node_name)} " \
        "-i #{Store.get(:ssh_pem_file)} -p #{Store.get(:ssh_port)} " \
        "'#{escaped_ssh_cmd(cmd)}'"
      elsif Store.get(:remote_plugin) == 'docker'
        "docker exec -i #{Store.get(:node_name)} /bin/bash -c '#{escaped_cmd(cmd)}'"
      else
        cmd
      end
    end

    # Execute the command and return the status.
    # Execute and Stream STDOUT and STDERR
    # Based on the blog: https://nickcharlton.net/posts/ruby-
    # subprocesses-with-stdout-stderr-streams.html
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def execute(cmd)
      Open3.popen3(full_cmd(cmd)) do |_stdin, stdout, stderr, thread|
        stdout_t = Thread.new do
          until (line = stdout.gets).nil?
            yield line, nil, nil
          end
        end
        stderr_t = Thread.new do
          until (line = stderr.gets).nil?
            yield nil, line, nil
          end
        end

        [stdout_t, stderr_t, thread].each(&:join)
        status = thread.value

        yield nil, nil, status.exitstatus
      end
    rescue StandardError => e
      yield nil, "Unknown Command (#{e})", -1
    end
    # rubocop:enable Metrics/AbcSize

    def task_files_from_path(task_file)
      out_files = []
      if File.directory?(task_file)
        # If the input is directory then get the list
        # of files from that directory and
        # Sort the Task files in alphabetical order.
        # Recursively looks for task files
        files_list = Dir.glob("#{task_file}/*").sort
        files_list.each do |tfile|
          out_files.concat(task_files_from_path(tfile))
        end
      elsif task_file.end_with?('.tl')
        # Tasks playlist, if a file contains the list of
        # task files, then all the task file paths are collected
        # If the list can contain dir path or task file or a playlist
        File.readlines(task_file).each do |tfile|
          out_files.concat(task_files_from_path(tfile))
        end
      elsif task_file.end_with?('.t')
        # Just the task file
        out_files << task_file
      else
        warn("Ignored parsing the Unknown file.  file=#{task_file}")
      end

      out_files
    end
    # rubocop:enable Metrics/MethodLength
  end
end
