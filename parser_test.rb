

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
	# the parser's 'scan' method isn't working.
    code.uml
    print code.text
  end
end
