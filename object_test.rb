require "test/unit"

require "object"
require "rmof"

module ObTest
  class Class < RMOF::Metaclass
    attribute :name, String, { :multiplicity => 1..1, :default=>[FALSE]}
  end
end


class TestObject < Test::Unit::TestCase
  def test_object
    _class= ObTest::Class.new
    _class.name= "Class"
    ob= Instance.new( _class)
    assert_equal("Class", ob.classifier[0].name)
  end
end
