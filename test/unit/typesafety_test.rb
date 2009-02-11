require "test/unit"

require "#{File.dirname(__FILE__)}/../test_helper"
require  'typesafety'
require  'typesafety_testcases'


class TestTypesafety < Test::Unit::TestCase

  include Typesafety
  STAR= Typesafety::STAR

  include TestClasses
  
  def test_primitives
    validation_errors= validate([""], :aString, String, DEFAULT_ATTRIBUTE_CONDITIONS)
    assert_equal(NO_ERRORS, validation_errors)
    validation_errors= validate([1], :anInteger, Integer, DEFAULT_ATTRIBUTE_CONDITIONS)
    assert_equal(NO_ERRORS, validation_errors)
  end

  def test_basic_validations
    nom= OneAttributeMeta.new
    nom.astring= ["a string"]
    errors= nom.__complete
    assert_equal NO_ERRORS, errors
    assert_equal(["a string"],  nom.astring)
  end

  def test_cardinality
    vc= VariousCards.new
    errors= vc.__complete
    assert_equal(4, errors.select{|e|e[:error]==:cardinality}.length, "Cards - default - four need setting")
    assert_equal(nil, errors.find{|e|e[:error]!=:cardinality}, "no other errors")
    vc.default=  multiples 1, String #the default card is '1' but default value is '[]'
    vc.one=  multiples 1, String
    vc.twoorthree= multiples 2, String
    vc.fivetostar= multiples 5, String
    errors= vc.__complete
    assert_equal(NO_ERRORS, errors, "set the four")
    #too big
    vc.twoorthree= multiples 4, String
    #too small
    vc.fivetostar= multiples 4, String
    errors= vc.__complete
    assert_equal(2, errors.select{|e|e[:error]==:cardinality}.length, "Cards: two out of range")
    assert_equal(nil, errors.find{|e|e[:error]!=:cardinality}, "no other errors")   
  end

  def test_types
    vt= VariousTypes.new
    vt.astring= multiples 1, String
    vt.anint= [1]
    vt.twostrings= multiples 2, String
    errors= vt.__complete
    assert_equal(NO_ERRORS, errors)
    vt.twostrings=[]
    errors= vt.__complete
    assert_equal(1, errors.select{|e|e[:error]==:cardinality}.length, "one card\n"+errors.inspect)
    assert_equal(0, errors.select{|e|e[:error]==:type}.length, "no typesafety\n"+errors.inspect)
    vt.twostrings=[1]
    errors= vt.__complete
    assert_equal(1, errors.select{|e|e[:error]==:cardinality}.length, "one card\n"+errors.inspect)
    assert_equal(1, errors.select{|e|e[:error]==:type}.length, "one type\n"+errors.inspect)
  end

  Typesafety.typesafe ::String
  def test_operations
    omc= OpsMetaclass.new
    
    assert_equal( ["onetwo"], omc.combine(["one"],["two"]))
    # wrong number of params
    begin
      omc.combine([""])
    rescue TypesafetyException=>ex
    end
    assert ex, "must have ex"
    assert_equal 1, ex.validation_errors.size, "one err"
    assert_equal 1,  ex.validation_errors.select{|e|e[:error]=:number_of_parameters}.size, "one num params err"
    # returns when it shouldn't
    begin
      omc.too_many_results([""])
    rescue TypesafetyException=>ex
    end
    assert ex, "must have ex"
    assert_equal 1, ex.validation_errors.size, "one err"
    assert_equal 1,  ex.validation_errors.select{|e|e[:error]==:cardinality}.size, "one num params err:"+ex.validation_errors.inspect
    assert_nothing_raised(Exception){ omc.none}
  end


  def test_deriv
    # make sure derivation works (self scope is correct in invocations to attribute and operation)
    dmc= DerivMetaClass.new
    assert( dmc.methods.include?( "astring"))
    assert( dmc.methods.include?( "anint"))
    assert( dmc.methods.include?( "twostrings"))
  end


  def test_assoc
    association [:pack, Pack, {:cardinality=>1}], [:cards, Card, {:cardinality=>52}]
    cards=[]
    (1..52).each{ cards<< Card.new}
    pack= [Pack.new]  
    pack.each{|p| p.cards=cards}
    cards.each{|c| c.pack=pack}
    pack.each{|p| p.__complete}
    cards.each{|p| p.__complete}
    assert_equal(pack, cards[0].pack)
    assert_equal(cards, pack[0].cards)
    cards.shift
    errors= pack[0].__complete
    assert( errors, "only 51 cards now - not allowed") 
#    pack.each{|p| p.__complete}
#    cards.each{|p| p.__complete}
#    cards.unshift Card.new
#    #link :pack, pack, :cards, cards
#    assert_equal(pack, cards[0].pack)
#    assert_equal(cards, pack[0].cards)

#    association [nil, Whole], [:wheels, Part, 0..20], kind=:composition
#    car= [Whole.new]
#    wheels= (1..4).inject([]){|a,j|a<<Part.new}
#    associate nil, car, :wheels, wheels
#    assert_equal(4, car[0].wheels.length)
#
#    # demontrate overloading class and type
#    assert_not_equal(::Class, Class)
#    association [:class, Class, 1..STAR], [:type, Typed, 0..STAR], :association
#    assert( Class.public_method_defined?( :type) )
#    assert( Typed.public_method_defined?( :class) )
#    clas= multiples 6, Class
#    type= multiples 21, Typed
#    clas[0].type= type
#    type[0].class= clas
#    associate :class, clas[1..3], :type, type[1..8]
#    associate :class, clas[4..5], :type, type[9..20]
#    assert_equal(type[1..8], clas[1].type)
#    clas.each{|t|puts t}
#
#    [[1..3,1..8],[4..5,9..20]].each do |group|
#      group[0].each{ |i| assert_equal(clas[i].type, type[group[1]])}
#      group[1].each{ |i| assert_equal(clas[group[0]], type[i].class)}
#    end
#    assert_not_equal(clas[1..3], type[9].class)
  end

end
