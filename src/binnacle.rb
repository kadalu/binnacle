require "open3"
require 'optparse'

# Deployed version is single file, so no
# loading required.
begin
  require "./runner"
  require "./plugins"
rescue LoadError
end

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
      exit 1
    end

    total_tests = out.strip.to_i

    # First line TAP output
    puts "1..#{total_tests}" if opts.verbose

    cmd = "ruby #{__FILE__} #{opts.test_file} --runner"
    start_time = Time.now

    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      outlines = []
      stdout_and_stderr.each do |line|
        # Print output/error only in verbose mode
        puts line if opts.verbose
        outlines << line
      end
      status = wait_thr.value

      if status.success?
        parser = TapParser.new(outlines)
        # If test file exited early on error. Not all the required
        # tests are executed
        if parser.total != total_tests
          STDERR.puts "Number of tests output not matching the Test plan.  " \
                      "available_tests=#{total_tests} executed=#{parser.total}"
          STDERR.puts "Result: FAIL"
          exit 1
        end
        # Print the summary
        puts "TOTAL: #{parser.total}  PASSED: #{parser.passed}  " \
             "FAILED: #{parser.failed}  SKIPPED: #{parser.skipped}  " \
             "TODOs: #{parser.todos}"

        if parser.total == parser.passed
          puts "Result: PASS"
        else
          puts "Result: FAIL"
        end
      else
        puts "Failed to execute #{opts.test_file}"
        puts err
        STDERR.puts "Result: FAIL"
        exit 1
      end
      end_time = Time.now

      puts "DURATION: #{end_time - start_time} seconds"
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
    end

    opt_parser.parse!(ARGV)

    if ARGV.size < 1
      STDERR.puts "Test file is not specified"
      exit 1
    end

    args.test_file = ARGV[0]
    return args
  end
end

options = Binnacle.args
if options.runner
  include BinnacleTestPlugins
  BinnacleTestsRunner.dry_run = options.dry_run

  load File.expand_path(options.test_file)

  puts BinnacleTestsRunner.tests_count if BinnacleTestsRunner.dry_run?
else
  Binnacle.run(options)
end
