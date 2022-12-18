require "open3"
require 'optparse'

# Deployed version is single file, so no
# loading required.
begin
  require "./runner"
  require "./plugins"
  require "./metrics"
rescue LoadError
end

EXIT_RESULT_PASS = 0
EXIT_RESULT_FAIL = 1
EXIT_INVALID_ARGS = 2
EXIT_TESTS_COUNT_MISMATCH = 3
EXIT_DRY_RUN_FAILED = 4
EXIT_TEST_FILE_NOT_FOUND = 5
EXIT_NO_TESTS = 6
EXIT_FAILED_TO_EXECUTE = 7

# Set STDOUT and STDERR sync=true
$stdout.sync = true
$stderr.sync = true

module Binnacle
  def self.tests_count(test_file)
    # Dry run and get the count of tests in the given file
    out, err, status = Open3.capture3(
                "ruby #{__FILE__} #{test_file} --runner --dry-run")

    if !status.success?
      return [-2, "Failed to parse Test file #{test_file}\n#{err}"]
    end

    total_tests = 0
    out.strip.split("\n").each do |line|
      if line.start_with?(":::")
        total_tests = line.split(":::")[-1].to_i
      end
    end

    if total_tests == -1
      return [-1, "Failed to find Test file #{test_file}"]
    end

    [total_tests, ""]
  end

  def self.run(test_file, total_tests, opts)
    # First line TAP output
    if opts.verbose > 0
      puts
      puts
      STDERR.puts "------- STARTED(tests=#{total_tests}, file=\"#{test_file}\")"
    end

    return [0, 0, 0, []] if total_tests <= 0

    cmd_verbose_opts = ((0...opts.verbose).map {|o| "-v"}).join(" ")
    cmd = "ruby #{__FILE__} #{test_file} --runner #{cmd_verbose_opts}"

    passed = 0
    skipped = 0
    failed = 0
    failed_tests = []
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      outlines = []
      summary_line = ""
      stdout_and_stderr.each do |line|
        # New Test started. Print if summary of previous test is not printed
        if line == "===\n"
          if summary_line != ""
            puts summary_line
            summary_line = ""
          end

          next
        end

        # Only print the Test case Summary line
        if line.start_with?("ok")
          summary_line = line
          passed += 1
          next
        elsif line.start_with?("not ok")
          summary_line = line
          failed_tests << line.strip
          failed += 1
          next
        end

        # Print output/error only in verbose mode
        puts(line.start_with?("#") ? line : "# #{line}") if opts.verbose > 0
      end

      # Print the last Test status
      puts summary_line if summary_line != ""

      status = wait_thr.value

      if status.success?
        skipped = total_tests - (passed + failed)
      else
        STDERR.puts "# Failed to execute" if opts.verbose > 0
      end
    end

    [passed, failed, skipped, failed_tests]
  end

  def self.test_files(test_file)
    out_files = []
    if File.directory?(test_file)
      # If the input is directory then get the list
      # of files from that directory and
      # Sort the Test files in alphabetical order.
      # Recursively looks for test files
      files_list = Dir.glob("#{test_file}/*").sort
      files_list.each do |tfile|
        out_files.concat(test_files(tfile))
      end
    elsif test_file.end_with?(".tl")
      # Tests playlist, if a file contains the list of
      # test files, then all the test file paths are collected
      # If the list can contain dir path or test file or a playlist
      File.readlines(test_file).each do |tfile|
        out_files.concat(test_files(tfile))
      end
    elsif test_file.end_with?(".t")
      # Just the test file
      out_files << test_file
    else
      STDERR.puts("Ignored parsing the Unknown file.  file=#{test_file}")
    end

    out_files
  end

  def self.testfile_summary(tmetrics)
    res = tmetrics[:ok] ? "OK" : "NOT OK"

    STDERR.puts
    STDERR.puts "------- COMPLETED(%s, total=%d, passed=%d, failed=%d, skipped=%d, duration=%.2fs, file=\"%s\")" % [
                  res,
                  tmetrics[:total],
                  tmetrics[:passed],
                  tmetrics[:failed],
                  tmetrics[:skipped],
                  tmetrics[:duration_seconds],
                  tmetrics[:file]
                ]
  end

  def self.verbose_summary(metrics)
    metrics.files.each do |tfile|
      puts "%s  %5d  %6d  %5d  %7d  %13.2fs  %10d  %18.2fs  %s" % [
             tfile[:ok] ? "OK    " : "NOT OK",
             tfile[:total],
             tfile[:passed],
             tfile[:failed],
             tfile[:skipped],
             tfile[:duration_seconds],
             tfile[:speed_tpm],
             tfile[:index_duration_seconds],
             tfile[:file]
           ]
    end
    puts "--------------------------------------------------------------------------------------------"
  end

  def self.summary(metrics)
    puts "%s  %5d  %6d  %5d  %7d  %13.2fs  %10d  %18.2fs" % [
           metrics.ok ? "OK    " : "NOT OK",
           metrics.total,
           metrics.passed,
           metrics.failed,
           metrics.skipped,
           metrics.duration_seconds,
           metrics.speed_tpm,
           metrics.index_duration_seconds
         ]

    return if metrics.total_files <= 1

    puts
    puts("Test Files: Total=#{metrics.total_files}  " +
         "Passed=#{metrics.passed_files}  " +
         "Failed=#{metrics.failed_files}")
  end

  def self.failed_tests_summary(metrics)
    failed_test_data = ""
    metrics.files.each do |tfile|
      failed_test_data += "%s\n" % tfile[:file] if tfile[:failed_tests].size > 0
      tfile[:failed_tests].each do |failed_test|
        failed_test_data += "    %s\n" % failed_test
      end
    end
    puts "\n\nFailed Tests:" if failed_test_data != ""
    puts failed_test_data
  end

  def self.run_all(options)
    tfiles = test_files(options.test_file)
    if tfiles.size == 0
      STDERR.puts "No tests Available"
      exit EXIT_NO_TESTS
    end

    metrics = Metrics.new

    # Indexing: Collect number of tests from each test file
    STDERR.print "Indexing test files... " if options.verbose > 0

    index_errors = []
    tfiles.each do |test_file|
      t1 = Time.now
      t_count, err = tests_count(test_file)
      dur = Time.now - t1
      if t_count < 0
        index_errors << err
        metrics.file_ignore(test_file)
      else
        metrics.file_add(test_file, t_count, dur)
      end
    end

    if options.verbose > 0
      STDERR.puts "done.  tests=#{metrics.total}  " +
                  "test_files=#{metrics.total_files}  " +
                  "duration_seconds=#{metrics.index_duration_seconds}"
    end

    # Execution
    metrics.files.each do |tfile|
      test_file = tfile[:file]
      t1 = Time.now
      passed, failed, skipped, failed_tests = run(test_file, tfile[:total], options)
      dur = Time.now - t1
      metrics.file_completed(test_file, passed, failed, skipped, dur, failed_tests)

      # Test file summary if -vv is provided
      testfile_summary(metrics.file(test_file)) if options.verbose > 0
    end

    puts
    puts
    puts "STATUS  TOTAL  PASSED  FAILED  SKIPPED  DURATION(SEC)  SPEED(TPM)  INDEX DURATION(SEC)  FILE"
    puts "============================================================================================"

    # Show full summary if -v
    verbose_summary(metrics) if options.verbose > 0

    # Final Table Summary
    summary(metrics)

    failed_tests_summary(metrics)

    if options.result_json != ""
      File.open(options.result_json, "w") do |json_file|
        json_file.write(metrics.to_json)
      end
    end

    if index_errors.size > 0
      STDERR.puts
      STDERR.puts "Index errors:"
      index_errors.each do |err|
        STDERR.puts err
      end
    end

    puts
    puts "Result: #{metrics.ok ? "Pass" : "Fail"}"
    exit (metrics.ok ? 0 : 1)
  end

  Options = Struct.new(:verbose, :test_file, :runner, :dry_run, :result_json)

  def self.args
    args = Options.new("binnacle - Simple Test Framework")
    args.verbose = 0
    args.runner = false
    args.result_json = ""

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: binnacle [options] <testfile>"

      opts.on("-v", "--verbose", "Verbose output") do
        args.verbose += 1
      end

      opts.on("-r", "--runner", "Run the tests") do
        args.runner = true
      end

      opts.on("--dry-run", "Dry run to get number of tests") do
        args.dry_run = true
      end

      opts.on("--results-json=FILE", "Results JSON file") do |json_file|
        args.result_json = json_file
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end

      opts.on("--version", "Show Version information") do
        puts "Binnacle #{VERSION}"
        exit
      end
    end

    opt_parser.parse!(ARGV)

    if ARGV.size < 1
      STDERR.puts "Test file is not specified"
      exit EXIT_INVALID_ARGS
    end

    args.test_file = ARGV[0]
    return args
  end
end

begin
  options = Binnacle.args
  if options.runner
    include BinnacleTestPlugins
    BinnacleTestsRunner.dry_run = options.dry_run
    BinnacleTestsRunner.emit_stdout = true if options.verbose > 1

    begin
      load File.expand_path(options.test_file)
    rescue LoadError
      # Return -1 so that dry run will validate this
      puts ":::-1"
      exit
    end

    puts ":::#{BinnacleTestsRunner.tests_count}" if BinnacleTestsRunner.dry_run?
  else
    Binnacle.run_all(options)
  end
rescue Interrupt
  STDERR.puts "Exiting.."
  exit 1
end
