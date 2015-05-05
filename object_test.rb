require "test/unit"

require_relative "rmof"
include RMOF

module ObTest
  class Class < RMOF::Element
    attribute :name, String, { :multiplicity => 1..1}
  end
end


class TestObject < Test::Unit::TestCase
  def test_object
    _class= ObTest::Class.new
    _class.name= "Class"
    ob= RMOF::Instance.new( _class)
    assert_equal("Class", ob.classifier[0].name)
  end
end
