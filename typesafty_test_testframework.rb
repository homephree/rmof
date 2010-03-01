require "test/unit"
require "typesafety"

class TestLibraryFileName < Test::Unit::TestCase
  include Typesafety

  def setup
  end

  # take map of name to array of error maps
  def validate_errors validation_errors
    error_tests= {:type=>"TYPE", :cardinality=>"CARDINALITY", :meta_wrapper=> "METAWRAPPER"}

    # make sure everything that produced an error was marked appropriately
    validation_errors.each_pair do |name, errs|
      if []== errs then
        assert( name.to_s=~/OK/, "expected naming 'OK': \n#{errs.inspect}")
      else
        assert( !(name.to_s=~/OK/), "unexpected naming 'OK': \n#{name} : #{errs.inspect}")
        errs.each do |er|
          assert_equal Hash, er.class, er.inspect
          assert name == er[:name], er.inspect
          ert= er[:error]
          if error_tests[ert]
            naming_excerpt= error_tests[ert]	
            assert name.to_s=~/#{naming_excerpt}/, 
            "expected naming_excerpt #{naming_excerpt}: \n#{er.inspect}"
          else
            flunk "unknown error '#{er[:error]}' - #{er.inspect}"
          end
        end
        # make sure if the name contains an err string then the err is in the array with the same name
        error_tests.each_pair do|ert,naming_excerpt|
          if name.to_s=~/#{naming_excerpt}/ then
            have_this_error_with_name= errs.select{ |er| er[:error]==ert  }
            assert( have_this_error_with_name.length>0, 
            "should have an error of '#{ert}' in #{errs.inspect}\n" \
            "errs:\n#{errs.report_typesafety_errors}")
          end
        end
      end
    end
  end

  def test_validation_test_rig
    validation_errors= {
      :oneOK => [],
      :oneTYPE => [
        {:name =>:oneTYPE, :error => :type} 
      ],
      :oneTYPECARDINALITY => [ 
        {:name => :oneTYPECARDINALITY, :error =>  :cardinality},
        {:name => :oneTYPECARDINALITY, :error =>  :type}
      ]
    }
    validate_errors validation_errors 
  end

  def test_validation_methods
    validation_errors={}
    valid= lambda do |*args|
      validation_errors[args[1]] = validate( *args)
    end
    valid.call(  [], :empty01stringOK, String, {:multiplicity => 0..1})
    valid.call(  [""], :onestring01stringOK, String, {:multiplicity => 0..1})
    valid.call(  [1], :oneint01intOK, Integer, {:multiplicity => 0..1})
    valid.call(  [1,2,3], :threeintOKTYPE, Integer, {:multiplicity => 0..3})
    valid.call(  [1,2,3], :threeintOK, Integer, {:multiplicity => 3..3})
    valid.call(  [1,2,3], :threeintOK, Integer, {:multiplicity => 0..100})
    valid.call(  [1,2,3], :threeintOK, Integer, {:multiplicity => 3..100})
    valid.call(  (1..10000).to_a, :threeintOK, Integer, {:multiplicity => 0..STAR})

    valid.call(  [1], :oneinttwostringsTYPECARDINALITY, String, {:multiplicity => 2..2})
    valid.call(  [], :emptyoneintCARDINALITY, Integer, {:multiplicity => 1..1})

    valid.call(  [1], :oneint2stringTYPECARDINALITY, String, {:multiplicity => 2..2})
    valid.call(  [], :emptyoneintCARDINALITY, Integer, {:multiplicity => 1..1})
    valid.call(  [1,2], :twoint2stringTYPE, String, {:multiplicity => 2..2})
    valid.call(  [1,2,3], :threeint2intCARDINALITY, Integer, {:multiplicity => 2..2})

    valid.call(  nil, :nonilsMETAWRAPPER, String, {:multiplicity => 1..1})
    valid.call(  1, :noprimitivesMETAWRAPPER, String, {:multiplicity => 1..1})

    validate_errors validation_errors
  end

  def test_cardinality

    assert_equal(1..1, expand_multiplicity_shorthand( 1, DEFAULT_ASSOCIATION_CONDITIONS))
    assert_equal(0..STAR, expand_multiplicity_shorthand( STAR, DEFAULT_ASSOCIATION_CONDITIONS))

  end
end
