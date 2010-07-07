

require "test/unit"

require "parser"
Code= <<END
  class Class {
    +thing
  }
END

class TestParser < Test::Unit::TestCase
  def test_case_name
    code= Parser.new(Code)
    code.uml
    print code.text
  end
end