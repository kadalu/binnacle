# frozen_string_literal: true

require 'open3'

require 'kadalu/binnacle/store'
require 'kadalu/binnacle/plugins'
require 'kadalu/binnacle/plugins/commands'
require 'kadalu/binnacle/plugins/compare'
require 'kadalu/binnacle/plugins/http'
require 'kadalu/binnacle/messages'

module Kadalu
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
        ok: true,
        file: task_file,
        passed: 0,
        failed: 0,
        tasks: [],
        duration_seconds: 0,
        completed: true
      }

      env = { 'RUBYLIB' => ENV.fetch('RUBYLIB', '') }
      error_msgs = []
      Utils.execute(env, cmd) do |stdout_line, stderr_line, ret|
        unless stdout_line.nil?
          # Only print the Test case Summary line
          if stdout_line.start_with?('{')
            begin
              data = JSON.parse(stdout_line, { symbolize_names: true })
              metrics[:tasks] << data
              Messages.task_summary(data)
              if data[:ok]
                metrics[:passed] += 1
              else
                metrics[:failed] += 1
              end

              next
            rescue JSON::ParserError
            end
          end

          # Print output/error only in verbose mode
          Messages.diagnostic(stdout_line) if opts.verbose.positive?
        end

        unless stderr_line.nil?
          error_msgs << stderr_line
          Messages.diagnostic(stderr_line) if opts.verbose.positive?
        end

        if !ret.nil? && (ret != 0)
          warn "# Failed to execute #{task_file}"
          # Print the error lines only if verbose is not given
          # If verbose is given, then those stderr messages are
          # already printed on the screen.
          error_msgs.each { |line| Messages.diagnostic(line) } if opts.verbose.zero?
          metrics[:completed] = false
          metrics[:ok] = false
        end
      end

      metrics[:ok] = false if (metrics[:failed]).positive?

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
end
