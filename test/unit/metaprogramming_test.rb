# Demonstrate the concepts required to adorn 'Class' such that type-safety
# Mechanisms can be optionally added to Class instances within Ruby.
#
# Reqquired features:
# Add class methods to any class (for attribute, operation) making it an EMOF metaclass
# Create methods with instance scope using those generated class methods

# Object Module attributes instance_variable_get instance_variable_defined? instance_variable_set
require "test/unit"

RESULTS= {}
class Class 
  class BlownUp < Exception; end
  RESULTS[ :Class_eval_scope]= self
  #We don't expect this to be cast
  def initialize
    RESULTS[:Class_initialize_scope]= self
  end
  #This will become a class scope method of any class
  def class_method item
    RESULTS[:Class_method_self]= self 
    @items=[] if items.nil?
    @items<< item
    att=  "@#{item}".to_sym
    define_method( item.to_sym) do   
      RESULTS[ item+"_get"]= instance_variable_get "@#{item}".to_sym
      instance_variable_get att
    end
    define_method( "#{item}=".to_sym) do |val|
      RESULTS[ item+"_set"]= val
      instance_variable_set att, val
    end
    define_method( :blowup) do
      raise BlownUp
    end
  end
  def items; @items; end
  @eigenclass= 
  class<< self
    RESULTS[:Class_eigenclass_eval_scope]= self
    def class_static item
      RESULTS[:Class_eigenclass_method_scope]= self
      RESULTS[:Class_eigenclass_method_argument]= item
    end
    self
  end
  def eigenclass; @eigenclass; end
  class_static :Class_static_method_call
end

class Meta
  class_method "m"
end

class TestMetaProgramming < Test::Unit::TestCase
  def test_class_methods
    assert_nil(RESULTS[ :Class_initialize_scope], "class's initialize is not called on speciication of a class instance")
    assert_equal( Class, RESULTS[:Class_eval_scope].class, "Class' scope is Class")
    assert_equal( "Meta", RESULTS[:Class_method_self].to_s, "The class method belongs to the class instance")
    assert_equal( Class.eigenclass, RESULTS[:Class_eigenclass_eval_scope], "Class' eigenclass has scope of Class::Class")
    assert_equal( Class, RESULTS[:Class_eigenclass_method_scope] , "invoking a static on Class stores Class")
    assert_equal( :Class_static_method_call, RESULTS[:Class_eigenclass_method_argument], "The argument for the \
    invocation on the eigenclass scopd method is the static invocation within Class")
    assert( Meta.items.include?( "m"), "the 'items' test array should have the method name for each added method")
    self.class.module_eval %q{
      class Beta < Meta
        class_method "b"
      end
    }
    assert_equal(Beta, RESULTS[:Class_method_self], 
    "changed from the previous invocation, the class scope method should now contain the latest instrumented class instance - beta")
    assert( Beta.items.include?( "b"), "the 'items' test array should have the method name for each added method")
    assert( !Meta.items.include?( "b"), "Only the specific class instance should have the items for that class")
    m= Meta.new
    m.m= 1
    assert_equal(1, m.m)
    assert_equal(1, RESULTS["m_get"])
    assert_equal(1, RESULTS["m_set"])
    b= Beta.new
    b.b= 2
    b.m= 3
    assert_equal(1, m.m)
    assert_equal(2, b.b)
    assert_equal(3, b.m)
    assert_equal(3, RESULTS["m_get"])
    blownup=false
    begin
      m.blowup
    rescue Class::BlownUp => blownup; end
    puts blownup.class
    assert( blownup , "Should be able to get a regular exception from manufactured method")
  end
end

# Distinguish between class and instance attributes.
class One
  @val =1
  RESULTS[:aClass_eval_scope]= self
  def initialize
    @val=2
    puts "init"
    RESULTS[:aClass_method_scope]= self
  end
  def val; @val; end
  def One.val; @val; end
end

class TestMetaProgramming < Test::Unit::TestCase
  def test_one
    one= One.new
    assert_equal( 2, one.val)
    assert_equal( 1, One.val)
    puts RESULTS
  end
end

# module methods implemented in classes?

module M
  def M.meta cls
    RESULTS[:M_meta]= self
    class << cls
      def meta item
        RESULTS[:cls_meta]= self
        att=  "@#{item}".to_sym
        define_method( item.to_sym) do   
          RESULTS[ "#{item}_get".to_sym]= instance_variable_get att
          instance_variable_get att
        end
        define_method( "#{item}=".to_sym) do |val|
          RESULTS[ "#{item}_set"]= val
          instance_variable_set att, val
        end
      end
    end
  end
end
class C
  M.meta self
  meta :c

end

class TestMetaProgramming < Test::Unit::TestCase
  def test_import_statics
    assert_equal(M, RESULTS[:M_meta], "Meta-fied C")
    assert_equal(C, RESULTS[:cls_meta], "Meta-fied C")
    c= C.new
    c.c= 1
    assert_equal(nil, RESULTS[:c_get], "not yet recorded setting c")
    assert_equal(nil, RESULTS[:c_set], "record setting c")
    assert_equal(1, c.c, "get the value back")
    assert_equal(1, RESULTS[:c_get], "record setting c")
  end
end


class TestMetaProgramming < Test::Unit::TestCase
  def test_extending_Class
    begin
      self.class.module_eval %q{
        class Metaclass < Class
        end
      }
    rescue Exception => e
    end
    assert(e, "We expect to fail to define a Class derivative")
  end
end

class E
  @eigenclass= 
  class<< self;self;end
  def E.eigenclass2; @eigenclass; end
end

class TestMetaProgramming < Test::Unit::TestCase
  def test_normal_eigenclass_tricks
    assert E.eigenclass2
    E.class_eval <<-END
    def another_method
    end
    END
    e=E.new
    assert e.methods.include?( "another_method")
    assert !e.methods.include?( "some_another_method")
  end
end


class AtAt
  @@at=:at
  def at
    @@at
  end
end

class TestMetaProgramming < Test::Unit::TestCase
  def test_atat
    assert_equal(:at, AtAt.new.at)
  end
end

module MF
  module_function
  def f1
    self
  end
end

module MF2
  include MF
  module_function
  def f2
    f1
  end
end


class TestModuleFn < Test::Unit::TestCase
  def test_mf
    assert_equal(MF, MF.f1)
  end
  include MF
  def test_mf2
    assert_equal(self, f1)
  end
  class CMF
    include MF
    alias was_f1 f1
    def f1
      was_f1
    end
  end
  def test_mf3
    cmf= CMF.new
    assert_equal(cmf, cmf.f1)
  end
  include MF2
  def test_mf2
    assert_raise(NameError) {  MF2.f2}
  end
end