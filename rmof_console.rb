
require_relative 'rmof'

require_relative 'rmof_example'

include TestClasses
require 'pp'

begin
 omc= OpsMetaclass.new
 omc.combine(["one"],["two"])
 omc.combine([""]) #will cause an exception
 
 puts "OK"
rescue RMOFException => ex
  puts ex.validation_errors.report_rmof_errors
end