
require 'typesafety'

require 'typesafety_example'

include TestClasses
require 'pp'

begin
 omc= OpsMetaclass.new
 omc.combine(["one"],["two"])
 omc.combine([""]) #will cause an exception
 
 puts "OK"
rescue TypesafetyException => ex
  puts ex.validation_errors.report_typesafety_errors
end