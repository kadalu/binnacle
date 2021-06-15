require "open3"
require 'optparse'

# Deployed version is single file, so no
# loading required.
begin
  require "./runner"
  require "./plugins"
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


module Binnacle
  # Parse Test Anything Protocol output format
  class TapParser
    attr_reader :total, :passed, :failed, :todos, :skipped

    def initialize(lines)
      @lines = lines
      @total = 0
      @passed = 0
      @failed = 0
      @todos = 0
      @skipped = 0
      parse
    end

    # If line starts with ok then successful test
    # If line starts with not ok then failed test
    # If ok/not ok line includes "# todo" or "# skip"
    def parse
      @lines.each do |line|
        @passed += 1 if line.start_with?("ok")
        @failed += 1 if line.start_with?("not ok")
        if line.start_with?("ok") || line.start_with?("not ok")
          if line.include?("#")
            directive = (line.split("#")[-1]).split[0].downcase
            @todos += 1 if directive == "todo"
            @skipped += 1 if directive == "skip"
          end
        end
      end

      @total = @passed + @failed
    end
  end

  def self.run(opts)
    # Dry run and get the count of tests in the given file
    out, err, status = Open3.capture3(
                "ruby #{__FILE__} #{opts.test_file} --runner --dry-run")
    if !status.success?
      STDERR.puts "Failed to execute #{opts.test_file}"
      STDERR.puts err
      STDERR.puts "Result: FAIL"
      exit EXIT_DRY_RUN_FAILED
    end

    total_tests = 0
    out.strip.split("\n").each do |line|
      if line.start_with?(":::")
        total_tests = line.split(":::")[-1].to_i
      end
    end

    if total_tests == -1
      STDERR.puts "Failed to find the Test file #{opts.test_file}"
      exit EXIT_TEST_FILE_NOT_FOUND
    end

    if total_tests == 0
      puts "No tests available"
      exit EXIT_NO_TESTS
    end

    # First line TAP output
    puts "1..#{total_tests}" if opts.verbose

    cmd = "ruby #{__FILE__} #{opts.test_file} --runner"
    start_time = Time.now

    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      outlines = []
      stdout_and_stderr.each do |line|
        # Print output/error only in verbose mode
        if opts.verbose
          if !line.start_with?("#") && !line.start_with?("ok") && !line.start_with?("not ok")
            puts "# #{line}"
          else
            puts line
          end
        end
        outlines << line
      end
      status = wait_thr.value
      duration = Time.now - start_time

      if status.success?
        parser = TapParser.new(outlines)
        # If test file exited early on error. Not all the required
        # tests are executed
        if parser.total != total_tests
          STDERR.puts "Number of tests output not matching the Test plan.  " \
                      "available_tests=#{total_tests} executed=#{parser.total}"
          STDERR.puts "Result: FAIL"
          exit EXIT_TESTS_COUNT_MISMATCH
        end
        # Print the summary
        puts
        puts "TOTAL: #{parser.total}  PASSED: #{parser.passed}  " \
             "FAILED: #{parser.failed}  SKIPPED: #{parser.skipped}  " \
             "TODOs: #{parser.todos}  DURATION: #{duration} seconds"

        exit_code = EXIT_RESULT_PASS
        if parser.total == parser.passed
          puts "Result: PASS"
        else
          puts "Result: FAIL"
          exit_code = EXIT_RESULT_FAIL
        end
        exit exit_code
      else
        puts "Failed to execute #{opts.test_file}"
        puts "DURATION: #{duration} seconds"
        puts err
        STDERR.puts "Result: FAIL"
        exit EXIT_FAILED_TO_EXECUTE
      end
    end
  end

  Options = Struct.new(:verbose, :test_file, :runner, :dry_run)

  def self.args
    args = Options.new("binnacle - Simple Test Framework")
    args.verbose = false
    args.runner = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: binnacle [options] <testfile>"

      opts.on("-v", "--verbose", "Verbose output") do
        args.verbose = true
      end

      opts.on("-r", "--runner", "Run the tests") do
        args.runner = true
      end

      opts.on("--dry-run", "Dry run to get number of tests") do
        args.dry_run = true
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

options = Binnacle.args
if options.runner
  include BinnacleTestPlugins
  BinnacleTestsRunner.dry_run = options.dry_run

  begin
    load File.expand_path(options.test_file)
  rescue LoadError
    # Return -1 so that dry run will validate this
    puts -1
    exit
  end

  puts ":::#{BinnacleTestsRunner.tests_count}" if BinnacleTestsRunner.dry_run?
else
  Binnacle.run(options)
end
