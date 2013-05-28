require 'rake/testtask'
require 'bundler/setup'
Bundler.require(:default)

require './app'
require 'resque/tasks'

task "resque:setup" do
  ENV['QUEUE'] = '*'
end

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
