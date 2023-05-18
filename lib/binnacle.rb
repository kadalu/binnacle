# frozen_string_literal: true

require 'open3'

require 'binnacle/store'
require 'binnacle/plugins'
require 'binnacle/plugins/commands'
require 'binnacle/plugins/compare'
require 'binnacle/messages'

module Binnacle
  module_function

  # Runs the given task file as a child process.
  # This is to prevent exiting the main process if the
  # child process exits. Collect the task file metrics and
  # return to the caller in the end.
  # rubocop: disable Metrics/AbcSize
  # rubocop: disable Metrics/CyclomaticComplexity
  # rubocop: disable Metrics/MethodLength
  # rubocop: disable Metrics/PerceivedComplexity
  def start(task_file, opts)
    t1 = Time.now

    # First line TAP output
    Messages.file_started(task_file)

    cmd_verbose_opts = ((0...opts.verbose).map { |_o| '-v' }).join(' ')
    wide_opts = opts.wide ? '-w' : ''
    cmd = "#{$PROGRAM_NAME} #{task_file} --runner #{cmd_verbose_opts} #{wide_opts}"

    metrics = {
      file: task_file,
      passed: 0,
      failed: 0,
      tasks: [],
      duration_seconds: 0,
      completed: true
    }

    env = { 'RUBYLIB' => ENV.fetch('RUBYLIB', '') }
    Open3.popen2e(env, cmd) do |_stdin, stdout_and_stderr, wait_thr|
      stdout_and_stderr.each do |line|
        # Only print the Test case Summary line
        if line.start_with?('{')
          data = JSON.parse(line, { symbolize_names: true })
          metrics[:tasks] << data
          Messages.task_summary(data)
          if data[:ok]
            metrics[:passed] += 1
          else
            metrics[:failed] += 1
          end

          next
        end

        # Print output/error only in verbose mode
        Messages.diagnostic(line) if opts.verbose.positive?
      end

      status = wait_thr.value

      unless status.success?
        warn '# Failed to execute'
        metrics[:completed] = false
      end
    end

    metrics[:duration_seconds] = Time.now - t1
    Messages.file_completed(task_file, metrics)
    metrics
  end
  # rubocop: enable Metrics/AbcSize
  # rubocop: enable Metrics/CyclomaticComplexity
  # rubocop: enable Metrics/MethodLength
  # rubocop: enable Metrics/PerceivedComplexity

  def runner(task_file, args)
    Store.set(:debug, args.verbose == 2)
    Store.set(:wide, args.wide)

    full_path = File.expand_path(task_file)

    begin
      load full_path
    rescue LoadError
      exit
    end
  end
end
