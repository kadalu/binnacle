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
    # rubocop:disable Metrics/AbcSize
    def file_completed(task_file, metrics)
      total = metrics[:passed] + metrics[:failed]
      speed_tpm = total * 60 / metrics[:duration_seconds]

      total = '-' unless metrics[:completed]

      fields = [
        ['', (metrics[:failed]).zero? && metrics[:completed] ? 'ok    ' : 'not ok'],
        ['file', task_file],
        ['total', total],
        ['speed_tpm', speed_tpm.to_i]
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

    def fileset_completed(metrics)
      total = metrics[:passed] + metrics[:failed]
      speed_tpm = total * 60 / metrics[:duration_seconds]
      puts
      puts 'STATUS  TOTAL  PASSED  FAILED  DURATION  SPEED(TPM)  FILE'
      puts '=================================================================='
      metrics[:files].each do |data|
        print_data = {
          file_total: data[:completed] ? data[:passed] + data[:failed] : '-',
          ok_msg: data[:ok] && data[:completed] ? 'OK    ' : 'NOT OK',
          passed: data[:passed],
          failed: data[:failed],
          duration: Utils.elapsed_time_humanize(data[:duration_seconds]),
          speed_tpm: speed_tpm.to_i,
          file: data[:file]
        }
        puts format(
          '%<ok_msg>s  %<file_total>5s  %<passed>6d  ' \
          '%<failed>6d  %<duration>8s  %<speed_tpm>10s  %<file>s',
          **print_data
        )
      end
      puts
      puts("Test Files: Total=#{metrics[:passed_files] + metrics[:failed_files]}  " \
           "Passed=#{metrics[:passed_files]}  " \
           "Failed=#{metrics[:failed_files]}")
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
end
