require "json"

class Metrics
  attr_reader :total, :passed, :failed, :skipped, :duration_seconds,
              :total_files, :passed_files,
              :index_duration_seconds, :files, :ignored_files

  def initialize
    @total = 0
    @passed = 0
    @failed = 0
    @skipped = 0
    @duration_seconds = 0.0
    @speed_tpm = 0
    @total_files = 0
    @passed_files = 0
    @index_duration_seconds = 0.0
    @files = []
    @ignored_files = []
    @files_index = {}
  end

  def file_ignore(test_file)
    @ignored_files << test_file
  end

  def file_add(test_file, count, index_duration_seconds)
    @files_index[test_file] = @total_files
    @total_files += 1
    @total += count
    @index_duration_seconds += index_duration_seconds

    @files << {
      :file => test_file,
      :total => count,
      :passed => 0,
      :failed => 0,
      :skipped => 0,
      :ok => false,
      :duration_seconds => 0.0,
      :speed_tpm => 0,
      :index_duration_seconds => index_duration_seconds,
      :failed_tests => []
    }

    # Return the index of this file
    @total_files - 1
  end

  def file(test_file)
    idx = @files_index[test_file]
    @files[idx]
  end

  def speed_tpm
    return 0 if @duration_seconds == 0

    (@total * 60 / @duration_seconds.to_f).round
  end

  def ok
    @total == @passed
  end

  def failed_files
    @total_files - @passed_files
  end

  def file_completed(test_file, passed, failed, skipped, duration_seconds, failed_tests)
    idx = @files_index[test_file]
    @files[idx][:passed] = passed
    @files[idx][:duration_seconds] = duration_seconds
    if duration_seconds > 0
      @files[idx][:speed_tpm] = (@files[idx][:total] * 60 / duration_seconds.to_f).round
    end
    @files[idx][:failed] = failed
    @files[idx][:skipped] = skipped
    @files[idx][:ok] = @files[idx][:total] == passed
    @files[idx][:failed_tests] = failed_tests

    @passed += passed
    @failed += failed
    @skipped += skipped
    @passed_files += 1 if @files[idx][:ok]
    @duration_seconds += duration_seconds

    true
  end

  def to_json
    {
      :total => @total,
      :passed => @passed,
      :failed => failed,
      :duration_seconds => @duration_seconds,
      :speed_tpm => speed_tpm,
      :ok => ok,
      :total_files => @total_files,
      :passed_files => @passed_files,
      :failed_files => failed_files,
      :index_duration_seconds => @index_duration_seconds,
      :files => @files,
      :ignored_files => @ignored_files
    }.to_json
  end
end
