
require 'rake/testtask'

 Rake::TestTask.new('test') do |t|
	# can use deep paths as: 'test/**/tc_*.rb'
	  t.pattern = '*_test.rb'
	  t.warning = true
end

task :default => [:test]
