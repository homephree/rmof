require "test/unit"

require 'typesafety'

module M1
  class Cz
    Typesafety.typesafe Cz
  end
  Typesafety.association [:class, Cz, 3..5], [:other, Cz, 1..1]
end

class TestAgain < Test::Unit::TestCase
  def test_class_named_attribute
    
    c1= M1::Cz.new
    c2= M1::Cz.new
    
    Typesafety.associate :class, [c1], :other, [c2]
    puts c1.class
    puts c2.class
    assert_equal([c1], c2.class)
    
    assert_raise(Typesafety::SyntaxException) {  c1.__validate}
    Typesafety.associate :class, [c1], :other, [c2]
  end
end