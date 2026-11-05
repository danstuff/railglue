# frozen_string_literal: true

require_relative '../test_helper'

class GeneratorTest < Minitest::Test
  def test_writes_compose_and_nginx_files
    Dir.mktmpdir do |dir|
      config = TestConfig.build(apps: TestConfig.app_entries(dir),
                                output_root: dir)
      Railglue::Generator.write(TestConfig.with_app_dirs(config))
      assert_match 'services:', File.read(config.compose_path)
      assert_match 'server {', File.read(config.nginx_path)
      assert_equal File.join(dir, 'railglue'), config.output_dir
    end
  end

  def test_missing_submodule_is_reported
    Dir.mktmpdir do |dir|
      config = TestConfig.build(apps: TestConfig.app_entries(dir),
                                output_root: dir)
      error = assert_raises(Railglue::ConfigError) do
        Railglue::Generator.write(config)
      end
      assert_match 'git submodule update --init', error.message
    end
  end
end
