
require_relative  'rmof'
require_relative  'rmof_example'


class TestRMOF < Test::Unit::TestCase

  include RMOF
  STAR= RMOF::STAR

  include TestClasses
  
  def test_primitives
    validation_errors= validate([""], :aString, String, DEFAULT_ATTRIBUTE_CONDITIONS)
    assert_equal(NO_ERRORS, validation_errors)
    validation_errors= validate([1], :anInteger, Integer, DEFAULT_ATTRIBUTE_CONDITIONS)
    assert_equal(NO_ERRORS, validation_errors)
  end
  
  def test_attributes
#    assert( VariousCards.attributes[:gooddefaultcard])
  end

  def test_basic_validations
    nom= OneAttributeMeta.new
    nom.astring= ["a string"]
    errors= nom.__complete
    assert_equal NO_ERRORS, errors
    assert_equal(["a string"],  nom.astring)
  end

  private 
  def test_vc vc
    errors= vc.__complete
    wrongdefcards= [:fivetostar,:twoorthree,:one]
    gooddefcards= [:ohone,:gooddefcard,:star]
    allatts= wrongdefcards + gooddefcards # I need to cater for multiply derived types - see deriv tests
    oneofours=lambda{|e|allatts.include?(e)}
    assert_equal(wrongdefcards.length, errors.select{|e|e[:error]== :cardinality and wrongdefcards.include?(e[:name])}.length, 
    "Cards - default - fivetostart invalid default - #{errors.inspect}")
    assert(errors.find{|e|e[:error]== :cardinality and e[:name]=:fivetostar}, "Cards - default - fivetostart invalid default - #{errors.inspect}")
    assert_equal(nil, errors.find{|e|e[:error]!= :cardinality}, "no other errors")
    vc.one=  multiples 1, String, "1"
    vc.twoorthree= multiples 2, String, "23"
    vc.fivetostar= multiples 6, String, "5*"
    errors= vc.__complete
    #all ok
    assert_equal(NO_ERRORS, errors.select{|e|oneofours[e[:name]]}, "set the bad cards")
    #check values
    assert( ["one","two"] == vc.gooddefaultcard )
    assert( ["1"]== vc.one, vc.one.inspect)
    assert( ["23","23"]== vc.twoorthree, vc.twoorthree.inspect)
    assert( ["5*","5*","5*","5*","5*","5*"]== vc.fivetostar, vc.fivetostar.inspect)
    #too big
    vc.twoorthree= multiples 4, String
    #too small
    vc.fivetostar= multiples 4, String
    errors= vc.__complete
    assert_equal(2, errors.select{|e|e[:error]== :cardinality}.length, "Cards: two out of range #{errors.inspect}")
    assert_equal(nil, errors.find{|e|e[:error]!= :cardinality and oneofours[e[:name]]}, "no other errors")
    # put it back to a valid state
    vc.twoorthree= multiples 2, String, "23"
    vc.fivetostar= multiples 6, String, "5*"
    errors= vc.__complete
    assert_equal(NO_ERRORS, errors.select{|e|oneofours[e[:name]]}, "reset the bad cards")
  end 
  public
  
  def test_cardinality
    vc= VariousCards.new
    test_vc vc
  end

  private
  def test_vt vt
    allatts= [ :astring,:anint,:custom,:twostrings]
    oneofours=lambda{|e|allatts.include?(e)}
    vt.astring= multiples 1, String
    vt.anint= [1]
    vt.twostrings= multiples 2, String
    errors= vt.__complete
    assert_equal(NO_ERRORS, errors.select{|e|oneofours[e[:error]]})
    vt.twostrings=[]
    errors= vt.__complete
    assert_equal(1, errors.select{|e|e[:error]==:cardinality and oneofours[e[:name]]}.length, "one card\n"+errors.inspect)
    assert_equal(0, errors.select{|e|e[:error]==:type and oneofours[e[:name]]}.length, "no rmof\n"+errors.inspect)
    vt.twostrings=[1]
    errors= vt.__complete
    assert_equal(1, errors.select{|e|e[:error]==:cardinality and oneofours[e[:name]]}.length, "one card\n"+errors.inspect)
    assert_equal(1, errors.select{|e|e[:error]==:type and oneofours[e[:name]]}.length, "one type\n"+errors.inspect)
    #fix it
    vt.twostrings=["1","2"]
    errors= vt.__complete
    assert_equal(NO_ERRORS, errors.select{|e|oneofours[e[:error]]})    
  end
  public
  
  def test_types
    vt= VariousTypes.new
    test_vt vt
  end

  private
  def test_op omc  
    assert_equal( ["onetwo"], omc.combine(["one"],["two"]))
    # wrong number of params
    begin
      omc.combine([""])
    rescue RMOFException=>ex
    end
    assert ex, "must have ex"
    assert_equal 1, ex.validation_errors.size, "one err"
    assert_equal 1,  ex.validation_errors.select{|e|e[:error]=:number_of_parameters}.size, "one num params err"
    # returns when it shouldn't
    begin
      omc.too_many_results([""])
    rescue RMOFException=>ex
    end
    assert ex, "must have ex"
    assert_equal 1, ex.validation_errors.size, "one err"
    assert_equal 1,  ex.validation_errors.select{|e|e[:error]==:cardinality}.size, "one num params err:"+ex.validation_errors.inspect
    assert_nothing_raised(Exception){ omc.none}
  end
  public
  
  RMOF.element ::String
  def test_operations
    omc = OpsMetaclass.new
    test_op omc
  end


  def test_deriv
    # make sure derivation works (self scope is correct in invocations to attribute and operation)
    dmc= DerivMetaClass.new
    test_vc dmc
    test_vt dmc
    test_op dmc
    errors = dmc.__complete
    assert_equal(NO_ERRORS, errors, "no errors in dmc after all tests")
  end


  def test_assoc
    association :pack_of_cards, [:pack, Pack, {:multiplicity=>1}], [:cards, Card, {:multiplicity=>52}]
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
    pack[0].cards= cards
    errors= pack[0].__complete
    assert( errors.find {|e| e[:error]== :cardinality}, "only 51 cards now - not allowed\n"+ errors.report_rmof_errors) 
    pack.each{|p| p.__complete}
    cards.each{|p| p.__complete}
    cards.unshift Card.new
    link :pack_of_cards, :pack, pack, :cards, cards
    assert_equal(pack, cards[0].pack)
    assert_equal(cards, pack[0].cards)

    #this association is unidirectional
    association :car, [nil, Whole], [:wheels, Part, {:multiplicity => 0..20}], kind=:composition
    car= [Whole.new]
    wheels= multiples 4, Part
    link :car, nil, car, :wheels, wheels
    assert_equal(4, car[0].wheels.length)
    assert_equal(0, wheels[0].methods.select{|m| m=~/car/}.length, "wheel doesn't know what car its on")

    # demontrate overloading class and type
    assert_not_equal(::Class, Class)
    association :superclass, [:class, Class, {:multiplicity =>1..STAR}], [:type, Typed, {:multiplicity =>1..STAR}], :association
    assert( Class.public_method_defined?( :type) )
    assert( Typed.public_method_defined?( :class) )
    clas= multiples 6, Class
    type= multiples 21, Typed
    clas[0].type= type
    type[0].class= clas
    link :superclass, :class, clas[1..3], :type, type[1..8]
    link :superclass, :class, clas[4..5], :type, type[9..20]
    assert_equal(type[1..8], clas[1].type)
    clas.each{|t|puts t}

    [[1..3,1..8],[4..5,9..20]].each do |group|
      group[0].each{ |i| assert_equal(clas[i].type, type[group[1]])}
      group[1].each{ |i| assert_equal(clas[group[0]], type[i].class)}
    end
    assert_not_equal(clas[1..3], type[9].class)
  end

end
