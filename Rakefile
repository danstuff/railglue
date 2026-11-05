# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/unit/**/*_test.rb']
  t.warning = true
end

namespace :test do
  desc 'Boot the apps in railglue.yml and check each homepage'
  Rake::TestTask.new(:e2e) do |t|
    t.libs << 'lib'
    t.test_files = FileList['test/e2e/*_test.rb']
    t.warning = true
  end

  desc 'Boot the bundled fixture apps and check routing, DBs and rspec'
  task :fixtures do
    ENV['RAILGLUE_CONFIG'] = File.expand_path('test/fixtures/railglue.yml')
    ENV['RAILGLUE_E2E_FIXTURES'] = '1'
    Rake::Task['test:e2e'].invoke
  end
end

task default: :test
