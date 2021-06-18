require "json"

class Metrics
  attr_reader :total, :passed, :duration_seconds,
              :total_files, :passed_files,
              :index_duration_seconds, :files

  def initialize
    @total = 0
    @passed = 0
    @duration_seconds = 0
    @speed_tpm = 0
    @total_files = 0
    @passed_files = 0
    @index_duration_seconds = 0
    @files = []
    @files_index = {}
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
      :ok => false,
      :duration_seconds => 0,
      :speed_tpm => 0,
      :index_duration_seconds => index_duration_seconds,
      :error => ""
    }

    # Return the index of this file
    @total_files - 1
  end

  def file(test_file)
    idx = @files_index[test_file]
    @files[idx]
  end

  def file_error(test_file, error)
    idx = @files_index[test_file]
    @files[idx][:error] = error
  end

  def speed_tpm
    return 0 if @duration_seconds == 0

    (@total * 60 / @duration_seconds.to_f).round
  end

  def ok
    @total == @passed
  end

  def failed
    @total - @passed
  end

  def failed_files
    @total_files - @passed_files
  end

  def file_completed(test_file, passed, duration_seconds)
    idx = @files_index[test_file]
    @files[idx][:passed] = passed
    @files[idx][:duration_seconds] = duration_seconds
    if duration_seconds > 0
      @files[idx][:speed_tpm] = (@files[idx][:total] * 60 / duration_seconds.to_f).round
    end
    @files[idx][:failed] = @files[idx][:total] - passed
    @files[idx][:ok] = @files[idx][:total] == passed

    @passed += passed
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
      :files => @files
    }.to_json
  end
end
