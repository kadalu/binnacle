# frozen_string_literal: true

require 'stringio'

module Binnacle
  module Messages
    module_function

    def bold(txt)
      "\033[1m#{txt}\033[0m"
    end

    def dim(txt)
      "\033[2m#{txt}\033[0m"
    end

    def diagnostic(msg)
      print dim(msg.start_with?('#') ? msg : "# #{msg}")
    end

    def print_summary_line(msg, data)
      s = StringIO.new
      s << bold(msg)
      data.each do |k, v|
        next if v.nil?

        s << (k == '' ? " [#{v}]" : " #{bold(k)}=#{v}")
      end

      puts s.string
    end

    def file_started(task_file)
      puts
      puts
      print_summary_line(
        '# ####### STARTED',
        [
          ['file', task_file]
        ]
      )
    end

    # rubocop:disable Metrics/MethodLength
    def file_completed(task_file, metrics)
      print_summary_line(
        '# ####### COMPLETED',
        [
          ['', (metrics[:failed]).zero? ? 'ok    ' : 'not ok'],
          ['file', task_file],
          ['total', metrics[:passed] + metrics[:failed]],
          ['passed', metrics[:passed]],
          ['failed', metrics[:failed]],
          ['duration', metrics[:duration_seconds]]
        ]
      )
    end

    def task_summary(data)
      print_summary_line(
        data[:ok] ? 'ok    ' : 'not ok',
        [
          (['node', data[:node]] if data.key?(:node)),
          (['container', data[:container]] if data.key?(:container)),
          (['ret', data[:ret]] if data.key?(:ret)),
          (['expect_ret', data[:expect_ret]] if data.key?(:expect_ret)),
          ['duration', data[:duration_seconds]],
          ['line', data[:line]],
          ['', data[:task]]
        ]
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
