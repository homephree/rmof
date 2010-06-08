require 'typesafety'
require "test/unit"

#cheat a little by treating string and int as typesafe
Typesafety.typesafe String
Typesafety.typesafe Integer

module TestClasses
  include Typesafety
  STAR= Typesafety::STAR

  class TypesafeBase
    Typesafety.typesafe self
  end

  class A < TypesafeBase
  end
  class B < A
  end

  class OneAttributeMeta < TypesafeBase
    attribute :astring, String, {:multiplicity=> 0..STAR}
  end

  class VariousCards < TypesafeBase
    attribute :default, String
    attribute :ohone, String, {:multiplicity=> 0..1}
    attribute :one, String, {:multiplicity=> 1}
    attribute :twoorthree, String, {:multiplicity=> 2..3}
    attribute :fivetostar, String, {:multiplicity=> 5..STAR}
    attribute :star, String, {:multiplicity=> STAR}
  end

  class VariousTypes < TypesafeBase
    attribute :astring, String
    attribute :anint, Integer
    attribute :twostrings, String, {:multiplicity=>2}
  end

  class DerivMetaClass < VariousTypes
  end

  class OpsMetaclass < TypesafeBase
    operation :combine, [:one,String], [:two,String], [:result, String, {:return=>true}] do |one, two|
      [one[0]+two[0]]
    end
    #declares no return param but returns one!
    operation :too_many_results, [:one, String] do |one|
      [1]
    end
    operation :none do 
      []
    end
    operation :should_return_empty_set,  [:return,Object, {:multiplicity=>0..0, :return=>true}] do
    end

    @eigenclass= class<< self; self; end
    def OpsMetaclass.eigenclass; @eigenclass; end
  end

  class GamingItem < TypesafeBase
  end
  class Pack < GamingItem
  end
  class Card < GamingItem 
  end
  class Whole < GamingItem
  end
  class Part < GamingItem
  end
  class Class < TypesafeBase
    def initialize 
      @i= (100*rand).to_i
    end
    def to_s; "C2#{@i}{type=#{type.join','}}"; end
  end
  class Typed < TypesafeBase
    def initialize 
      @i= (100*rand).to_i
    end
    def to_s; "T#{@i}"; end
  end

  #  class DerivMetaClass < AttsMetaclass
  #    attribute :derivs, Integer, 1, {:default=>[1]}
  #    operation :simple do;[];end
  #  end
  #  class DerivSibling < AttsMetaclass
  #  end
  #  class DerivSon < DerivMetaClass
  #  end 

  class Left
    Typesafety.typesafe self
  end
  class Right
    Typesafety.typesafe self
  end
  Typesafety.association :_2_left_to_1_right, [:left, Left, {:multiplicity => 2..2}], [:right, Right, {:multiplicity => 1..1}]

end
