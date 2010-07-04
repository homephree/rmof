# EMOF - Ruby EMOF implementation
# Rules - Abstract types are mixins
# Packages are namespace modules
# Concrete and abstract metaclasses are Classes (no distinction is made)
# Simple native RMOF is _not_ element, and abstract classes are not prevented
# from instantiation, so this model is sufficient for bootstraping a type system only.
# This module implements the MOF 2.0 specification, 03-10-04. That spec refers to 
# UML infrastructure core packages, and then identifies modifications via notional model
# import specifications «cobine» or «merge», but EMOF implements the EMOF 'end-state' implementation directly. 
# It is envisaged that an instance of EMOF will be used to implement the more sophisticated
# CMOF mechanisms, including re-use of UML core packages.
# TODO: Type checking, including multiplicity checking. 
# For example, Class.superClass must always be an array as it is [*] relationship. This can be 
# done with a simple override of the setter, although better to include typecheck parameters in 
# the attribute implementation.

require 'rmof' 

module UML
  module Core
    # Ruby-EMOF Typesafe bootstrap
    include RMOF
    class Metaclass < RMOF::Element
    end
    
    def self.association *args
      RMOF.association( *args)
    end

    class Element < Metaclass
    end

    # EMOF Data Types
    class NamedElement < Metaclass
      generalization Element
    end
    
    class Type < Metaclass
      generalization NamedElement
    end

    class DataType < Metaclass
      generalization Type
    end

    class PrimitiveType < Metaclass
      generalization DataType
      def initialize val=nil
        native= val;
      end
      def native; @native; end
      def native= val; check val; @native= val; end
      def check; true; end
    end

    class Boolean < PrimitiveType
      generalization PrimitiveType
    end
    class String < PrimitiveType
      generalization PrimitiveType; 
      def check val
        validate val, String, ""
      end
    end
    class UnlimitedNatural < PrimitiveType
      generalization PrimitiveType
    end
    class Integer < PrimitiveType
      generalization PrimitiveType
    end
    class MultiplicityElement < PrimitiveType
      generalization Element
    end
    FALSE = Boolean.new(false)
    TRUE = Boolean.new(true)
    NULL= String.new("Null")

    class Type
      operation :isInstance, [[:isInstance, Boolean, {:multiplicity => 1, :return => true}]]
    end    

    # EMOF Classes
    class Type
    end

    class Class < Type
      attribute :isAbstract, Boolean, { :multiplicity => 1..1, :default=>[FALSE]}
    end

    class Property < MultiplicityElement
      attribute :isReadOnly, Boolean, { :multiplicity => 1..1, :default=>[FALSE]}
      attribute :default, String
      attribute :isComposite, Boolean, { :multiplicity => 1..1, :default=>[FALSE]}
      attribute :isDerived, Boolean, { :multiplicity => 1..1, :default=>[FALSE]}
      attribute :isID, Boolean
    end

    class Operation < MultiplicityElement
    end

    class Parameter < MultiplicityElement
    end

    ASSOCIATION_TYPES={:association=>true, :aggregation=>true, :composition=>true}
    association nil, [:property, Property, {:multiplicity => 1..1}], [:opposite, Property, {:multiplicity => 0..1}], :association, { :directed=>true}
    association nil, [nil, Class], [:superClass, Class, {:multiplicity => 0..STAR}], :association, {:ordered=>true, :directed=>true}
    association nil, [:class, Class, {:multiplicity => 0..1}], [:ownedAttribute, Property, {:multiplicity => 0..STAR}], :composition, {:ordered=>true, :directed=>true}
    association nil, [:class, Class, {:multiplicity => 0..1}], [:ownedOperation, Operation, {:multiplicity => 0..STAR}], :composition, {:ordered=>true, :directed=>true}
    association nil, [:operation, Operation, {:multiplicity => 1..1}], [:ownedParameter, Parameter, {:multiplicity =>0..STAR}], :composition, {:ordered=>true, :directed=>true}
    association nil, [:operation, Operation, {:multiplicity => 0..STAR}], [:raisedException, Type, {:multiplicity => 0..STAR}], :associate, {:ordered=>true, :directed=>true} #todo associate?

    # EMOF Types
    class Element
    end
    class Object < Element
      operation :getMetaClass, [:getMetaClass, Class, {:multiplicity => 1..1, :return=>true}] do
        [self.class]
      end
      operation :container, [:container, Object, {:multiplicity =>1..1, :return=>true}] do
        #TODO implement container
        [nil]
      end
      #TODO model Boolean
      operation :equals, [:element, Element], [:equals, Boolean, {:multiplicity =>1..1, :return=>true}] do
        #TODO implement equals
        [false]
      end
    end # Object
  end #Core
end # UML   
