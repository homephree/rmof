require "test/unit"

require 'emof'
require 'typesafety'

class TestEmof < Test::Unit::TestCase
  include EMOF
  include Typesafety

  def test_meta_semantics
    # just to clarify the point. Many languages couldn't cope with substituting 'Class' in the default namespace!
    assert_not_equal(Class, ::Class, "new class metaclass should be distinct from native class")
  end

  def test_defaults
    prop=Property.new
    assert( !prop.isReadOnly[0].native, "prop defaults to unique")
  end

  # spot check the basic classes pkg
  def test_classes
    assert( Class.public_method_defined?( :isAbstract) )
    assert( Class.superclass== Type)
    # check derivation
    assert( Class.public_method_defined?( :superClass) )
    base1, base2, deriv= Class.new, Class.new, Class.new
    deriv.superClass= [base1, base2]
    assert( deriv.superClass.size==2, "Class can have multiple superclasses.")
    # of course superClass can be any type (but this will fail when I implement type checking)
    assert_raise(SyntaxException) { deriv.superClass= 4}
    #
    prop1, prop2, *props= multiples 10, Property
    associate :property, [prop1], :opposite, [prop2]
    assert_raise( RangeException, "prop 0..1") { associate :property, [prop1], :opposite, props }
    # super
    class1, *more_classed= multiples 10, Class
    associate nil, [class1], :superClass, more_classed
    assert_equal( more_classed, class1.superClass)
    associate nil, [class1], :superClass, []
    assert_equal( [], class1.superClass, "no supers")
    assert_raise( SyntaxException, "superClass has no reciprocal attribute") do
      associate :class, [class1], :superClass, more_classed
    end
    #
    associate :class, [class1], :ownedAttribute, props
    #
    ops= multiples 10, Operation
    associate :class, [class1], :ownedOperation, ops
    assert_equal(ops, class1.ownedOperation)
    associate :class, [], :ownedOperation, ops
    assert_equal( [], ops.inject([]){|a,o| a|o.class})
    # this will 'break; the relationship with class, which should be null but isn't
    # because the owned-end relationships 
    assert_not_equal([], class1.ownedOperation)
  end

  def test_print_example
    #  use case for printer
    document, printer= Class.new, Class.new
    print= Operation.new
    theDoc, thePriority= [Parameter.new, Parameter.new]
    print.ownedParameter= [theDoc]
    theDoc.operation= [print]
    printer.ownedOperation= [print]
    print_queues= multiples 100, Property
    print_queues[0].default= [String.new( "default_queue")]
    print_queues[0].isComposite= [TRUE]
    print.raisedException= []
    printer.ownedAttribute= print_queues
    assert_equal( [theDoc], printer.ownedOperation[0].ownedParameter)
    assert_nothing_raised(Exception) { print.raisedException= multiples 5, Type }
    assert_equal(5, print.raisedException.length)
    assert_nothing_raised(Exception) { (0..49).each{ |i|print_queues[i].opposite= [print_queues[i+50]]} }
    assert_raise(TypeException, "can't raise operations!") { print.raisedException= [Operation.new] }
  end
  
  def _test_types
    date= Type.new
    today= TypedElement.new
    today.type= date
    assert_equal(today.type, date)
    date.name= "Date"
    assert_equal(date.name, "Date")
    assert( date.isInstance( today))
    comments= [Comment.new, Comment.new]
    comments[0].body= "This is a date"
    today.ownedComment= [comments]
    comments.each{|c|c.annotatedElement= today}
    assert( today.kind_of?( Element))
  end

  def _test_package
    pk= [Package.new, Package.new, Package.new]
    pk[0].nestingPackage= [pk[1]]
  end


  def _test_data_types
    colours= Enumeration.new
    lits= %w[red, green, blue]
    lits.collect{|name|;EnumerationLiteral.new.name=name}
  end

  def _test_isInstance
    assert( Type.public_method_defined?( :isInstance))
    assert( Class.superclass==Type)
    animal= Class.new
    animal.name= "Animal"
    human= Class.new
    human.name= "Human"
    human.superClass<<animal
    fred= TypedElement.new
    fred.type= human
    ananimal = TypedElement.new
    ananimal.type= animal
    assert_equal(1, human.superClass.size, "human has one superclass")
    assert_equal(human, fred.type, "fred is a human.")
    assert( human.isInstance(fred), "fred is human.")
    assert( animal.isInstance(fred), "fred is animal.")
    assert( !human.isInstance(ananimal), "animal not a human")
  end
end