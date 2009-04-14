
require 'typesafety'

require 'typesafety_testcases'

include TestClasses
require 'pp'

begin
 omc= OpsMetaclass.new
 omc.combine(["one"],["two"])
rescue TypesafetyException => ex
  puts ex.validation_errors.report_typesafety_errors
end