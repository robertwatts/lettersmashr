require 'rake'
require 'rake/testtask'
require 'bundler'
Bundler.setup(:default, :test)

task "resque:setup" do
  require './app'
  require 'resque/tasks'
  ENV['QUEUE'] = '*'
end

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

