require "test/unit"

require_relative 'rmof'
require_relative 'rmof_example'

class TestAgain < Test::Unit::TestCase
  include TestClasses
  def test_class_named_attribute


    left= [Left.new]
    right= [Right.new]
    #cardinality of association on C1 is wrong, but c2 is ok
    RMOF.link :_2_left_to_1_right, :left, left, :right, right

    validation_errors= left[0].__complete
    assert_equal( [], validation_errors, validation_errors.report_rmof_errors)

    validation_errors= right[0].__complete
    assert( validation_errors.find{|e| e[:error]== :cardinality}, validation_errors.report_rmof_errors)

    left= multiples 2, Left
    RMOF.link :_2_5_left_to_1_right, :left, left, :right, right
    validation_errors= left[0].__complete
    assert_equal( [], validation_errors, validation_errors.report_rmof_errors)

    validation_errors= right[0].__complete
    assert_equal( [], validation_errors, validation_errors.report_rmof_errors)

    assert_equal(left, right[0].left)  
    left.each{|theleft| assert_equal(right, theleft.right)}
  end
  
end