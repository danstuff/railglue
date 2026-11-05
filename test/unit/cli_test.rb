# frozen_string_literal: true

require 'stringio'
require_relative '../test_helper'

class CLITest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @calls = []
    @out = StringIO.new
    @err = StringIO.new
    @config_path = write_config
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def write_config
    raw = TestConfig.raw(apps: TestConfig.app_entries(@dir), port: 8080)
    TestConfig.with_app_dirs(Railglue::ConfigLoader.parse(raw))
    path = File.join(@dir, 'railglue.yml')
    File.write(path, YAML.dump(raw))
    path
  end

  def run_cli(*args, succeed: true)
    runner = lambda do |*argv|
      @calls << argv
      succeed
    end
    cli = Railglue::CLI.new(out: @out, err: @err, runner: runner,
                            output_root: @dir)
    cli.run(['--config', @config_path, *args])
  end

  def compose_file
    File.join(@dir, 'railglue', 'compose.yaml')
  end

  def test_help_without_config
    cli = Railglue::CLI.new(out: @out, err: @err)
    assert_equal 0, cli.run([])
    assert_match 'Usage:', @out.string
  end

  def test_generate
    assert_equal 0, run_cli('generate')
    assert File.file?(compose_file)
    assert_empty @calls
  end

  def test_passes_other_commands_to_compose
    assert_equal 0, run_cli('up', '-d')
    assert_equal [['docker', 'compose', '-f', compose_file, 'up', '-d']],
                 @calls
  end

  def test_compose_failure_sets_exit_status
    assert_equal 1, run_cli('ps', succeed: false)
  end

  def test_rspec
    assert_equal 0, run_cli('rspec', 'blog', 'spec/models')
    assert_equal ['run', '--rm', 'blog', 'railglue-rspec', 'spec/models'],
                 @calls.first.drop(4)
  end

  def test_rspec_unknown_app
    assert_equal 1, run_cli('rspec', 'nope')
    assert_match 'rspec needs an app: shop, admin, blog', @err.string
    assert_empty @calls
  end

  def test_urls
    run_cli('urls')
    assert_equal "shop\thttp://localhost:8080/\n" \
                 "admin\thttp://localhost:8080/admin\n" \
                 "blog\thttp://localhost:8080/news/blog\n", @out.string
  end

  def test_config_errors_are_reported
    File.write(@config_path, 'apps: 3')
    assert_equal 1, run_cli('urls')
    assert_equal "railglue: apps must be a list\n", @err.string
  end

  def test_config_option_needs_value
    cli = Railglue::CLI.new(out: @out, err: @err)
    assert_equal 1, cli.run(['--config'])
  end
end
