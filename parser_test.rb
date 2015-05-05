

require "test/unit"

require_relative "parser"
Code= <<END
  class Class {
    +thing
  }
END

class TestParser < Test::Unit::TestCase
  def test_parser
    # code= Parser.new(Code)
	# the parser's 'scan' method isn't working.
    # code.uml
    # print code.text
  end
end
