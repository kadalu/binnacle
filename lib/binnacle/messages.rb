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
      fields = [
        ['', (metrics[:failed]).zero? ? 'ok    ' : 'not ok'],
        ['file', task_file],
        ['total', metrics[:passed] + metrics[:failed]]
      ]
      metrics.each do |key, value|
        next if %i[duration_seconds tasks].include?(key)

        fields << [key, value]
      end
      fields << [
        'duration',
        Utils.elapsed_time_humanize(metrics[:duration_seconds])
      ]
      print_summary_line('# ####### COMPLETED', fields)
    end

    def task_summary(data)
      fields = []
      data.each do |key, value|
        next if %i[task line duration_seconds].include?(key)

        fields << [key, value.to_s]
      end
      fields.concat(
        [
          ['duration', Utils.elapsed_time_humanize(data[:duration_seconds])],
          ['line', data[:line].to_s],
          ['', data[:task]]
        ]
      )
      print_summary_line(data[:ok] ? 'ok    ' : 'not ok', fields)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
