# Demonstrate if it is possible to alter the derviation of 
# a class dynamically. Also to show a clean method for invocation
# of methods in abstractions.
require "test/unit"

class TestLibraryFileName < Test::Unit::TestCase
  def test_case_name
    dervs=[]
    assert_nothing_raised(Exception) {
      self.class.module_eval %q{
        class Base
          def self.inherited subclass
            @dervs=[] unless @dervs
            @dervs<< subclass
          end
          def self.dervs; @dervs; end;
        end
      }
      self.class.module_eval %q{
        class Special < Base
        end
      } 
    }
    assert(Base.dervs.include?(Special), "Registered derivation.")
  end
end
