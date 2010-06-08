# TypeSafety module 
# Kevin Humphries - Friday, 17 October 2008 17:10
# Objective: add typesafe attributes and methods to ruby classes to allow support
# of typesafe metamodels.
# 
# A typesafe 
# I need to be able to make definitions of the sort:
# :name, type, {multiplicity}, ordered
# 
# Design decision to use collections in _all cases_ for simplicity ( a 'single'
# collection will help)
# I shall not attempt to model multiple inheritence as this isn't required for EMOF.
# That means that a separate model to implementation strategy will be required for 'real'
# MOF.
# TODO instrument array such that it passes through methods to first instance if only one.

require 'pp'

module Typesafety
  class TypesafetyException < Exception
    attr :validation_errors, true
    def initialize validation_errors
      self.validation_errors= validation_errors
    end
  end

  STAR= -1
  DEFAULT_VALUE= []
  VALID_CONDITIONS= {:multiplicity=>1, :ordered=>1, :default=>1, :default_return_parameter=>1, :return=>1}
  DEFAULT_ATTRIBUTE_CONDITIONS= {:multiplicity=>1..1, :ordered=>true, :default=>DEFAULT_VALUE}
  DEFAULT_ASSOCIATION_END_CONDITIONS= {:multiplicity=>STAR, :ordered=>true, :default=>DEFAULT_VALUE}
  DEFAULT_ASSOCIATION_CONDITIONS= {:multiplicity=>STAR, :ordered=>true}
  DEFAULT_PARAMETER_CONDITIONS= {:multiplicity=>1..1, :ordered=>true, :default=>DEFAULT_VALUE}
  NO_RETURN_CONDITIONS= {:multiplicity=>0..0, :ordered=>true, :default=>DEFAULT_VALUE}
  DEFAULT_RETURN_PARAMETER= [:default_return_parameter,Object, NO_RETURN_CONDITIONS]
  NO_ERRORS= []
  ASSOCIATION_TYPES={:association=>true, :aggregation=>true, :composition=>true}

  module_function

  # make the class typesafe by offering 'attribute' and 'operation' methods in its eigenclass
  def typesafe cls
    cls.class_eval <<-END
    alias ruby_class class
    # complete the transaction on the object; return nil or validation error array
    def __complete
      Typesafety.complete self
    end
    END

    class << cls
      define_method(:metatype?){true}

      # define setters, getters and __complete_<name> for attribute
      def attribute name, type, conditions= DEFAULT_ATTRIBUTE_CONDITIONS
        Typesafety.complete_conditions conditions, DEFAULT_ATTRIBUTE_CONDITIONS
        at= "@#{name}".to_sym
        getter= "#{name}".to_sym
        setter= "#{name}=".to_sym
        completion= "__complete_#{name}".to_sym
        define_method( getter) do
          instance_variable_get at
        end
        define_method( setter) do |val|
          instance_variable_set at, val
        end
        define_method( completion) do
          # I check typesafety and apply defaults
          # result is list of one or more errors or nil
          val= instance_variable_get at
          defaulted_val= Typesafety.default( val, name, type, conditions)
          if val!=defaulted_val  then instance_variable_set at, defaulted_val
          end
          Typesafety.validate( defaulted_val, name, type, conditions)
        end
      end # attribute

      # Only support a single return output parameter (but 0..n multiplicity), as required by EMOF
      # Each parameter is the form [name:Symbol, type:Class, {conditions:Hash}]
      def operation name, *parameters, &method
        returns= DEFAULT_RETURN_PARAMETER
        passedparams=[]
        # clean up param spec - find returns directives, expand multiplicity and default conditions
        parameters.each do |p|
          p[2]= p[2] || DEFAULT_PARAMETER_CONDITIONS
          Typesafety.complete_conditions p[2], DEFAULT_PARAMETER_CONDITIONS
          if( p[2][:return]) then 
            if returns[0] != :default_return_parameter then raise SyntaxException, "only one return param"
            end
            returns= p
          else passedparams<< p
          end
        end
        # this is the method itself
        validation_errors= []
        adorn_error= lambda{|err|err[:owner]=self; err[:operation]=name; err[:parameters]=parameters;err}
        define_method( name) do |*args|
          unless args.length==passedparams.length then 
            raise TypesafetyException.new([adorn_error[{:error=>:number_of_parameters}]])
          end
          args.each_with_index do |v, i|
            v= Typesafety.default( v, *passedparams[i])
            errors= Typesafety.validate v, *passedparams[i]
            errors.each{|e| adorn_error[e]}
            validation_errors.concat errors
          end
          unless validation_errors.empty? then raise TypesafetyException.new( validation_errors) 
          end
          begin
            result= method.call(*args)
          rescue => ex
            raise TypesafetyException.new( [adorn_error[{:error=>:exception, :exception=>ex}]])
          end
          validation_errors= Typesafety.validate( result, *returns) 
          validation_errors.each{|e| adorn_error[e];}
          unless validation_errors.empty? then 
            raise TypesafetyException.new( validation_errors)
          end
          result
        end # the method declaration method
      end # operation method
    end # eigenclass scope
  end #typesafe method

  def complete_conditions conditions, defaults
    conditions= defaults unless conditions
    conditions[:multiplicity]= expand_multiplicity_shorthand conditions[:multiplicity], defaults[:multiplicity]
    conditions[:default]= conditions[:default] || defaults[:default]
    conditions
  end

  # wrap the object at the end of a set of state changes - a transaction closure
  # this calls __complete_<attribute> for each attribute
  # return a list of errors - empty if none
  def complete metaobject
    errors= []
    completors= metaobject.methods.select{|m| m=~/__complete_/}
    completors.each{ |completor| errors.concat( metaobject.send(completor))}
    errors.each{ |e| 
      #e[:owner]=metaobject; 
      e[:association]= :attribute}
    errors
  end

  # check the value and return the value or it's defaulted value.
  # if the value is nil then the return is the default, or an empty array if the conditions have no such default
  # types are not validated however.
  # default is determined from conditions[:default]
  def default val, name, type, conditions
    if val== nil and conditions[:default]
      conditions[:default]
    elsif val== nil
      []
    else
      val
    end
  end

  # validate the value against the conditions
  # return a hash of errors mapped as :code => [arg, conditions, message] 
  def validate arg, name, type, conditions
    errors= []
    have_errors={}
    add_error= lambda do |error_type|
      err=  { :error => error_type, :arg=>arg, :name=> name, :conditions=> conditions }
      errors<< err
      have_errors[error_type]=err
      err
    end
    begin
      conditions.each_key{ |c| 
        unless VALID_CONDITIONS.key? c
          add_error[ :condition].merge!( {:invalid_condition => c})
        end
      }
      unless arg.kind_of? ::Array  
        add_error[ :meta_wrapper]
      end
      unless name.kind_of? ::Symbol  
        add_error[ :meta_name]
      end
      unless type.kind_of? ::Class  
        add_error[ :meta_type]
      end
      unless conditions[:multiplicity].kind_of? ::Range  
        add_error[ :meta_multiplicity]
      end
      unless conditions.kind_of? ::Hash  
        add_error[ :meta_context]
      end
      if have_errors.empty? then
        unless conditions[:multiplicity].cardinality? arg.length 
          add_error[ :cardinality]
        end
        arg.each_with_index do |v,i|
          unless v.kind_of? type 
            add_error[ :type]["arg_#{i}".to_sym]=v
          end
        end
      end
    rescue => ex
      (add_error[:exception])[:exception]= ex
    end
    return errors
  end

  # Implement an association by putting corresponding owned-ends on each class
  # So src gets an attribute  of name trg and vice versa
  # src name may be null, meaning a unidirectional relationship. In such cases
  # reverse associations cannot be tested. In some cases MOF gives a source multiplicity
  # but no name. In this case use an appropriate assoc-end name based on the src name.
  # association_name : symbol
  # *src: property name, type, conditions={}
  # *trg: property name, type, conditions={}
  # kind= :association, :aggregation, :composition
  # name of src may be null (no reverse association)
  # TODO consider syntax check on src, trg etc
  # TODO consider uniqueness on association_name
  def association association_name, src, trg, kind= :association, link_conditions=DEFAULT_ASSOCIATION_END_CONDITIONS
    src[2]= complete_conditions src[2], DEFAULT_ASSOCIATION_CONDITIONS
    trg[2]= complete_conditions trg[2], DEFAULT_ASSOCIATION_CONDITIONS
    # All emof assocs have defined multiplicity
    unless src[0].nil? then
      trg[1].send( :attribute, *src)
    end
    src[1].send( :attribute, *trg)
  end

  # associate each source with each trg
  # We use an owned association, so there needs to be an attribute on src for target, and
  # optionally vice-versa
  # todo - register validation required on old ends
  # -- params
  # [association_name] optional (not currently used)
  # [src_end] optional symbol identifying source end, also owned end attribute of target referring to src
  # [src] non optional reference to src object being associated with target
  # [trg_end] non optional symbol identifying target end, also owned end attribute of src reference to target
  # [trg] non optional reference to target object being associated with src
  
  def link association_name, src_end, src, trg_end, trg
    trg_setter= "#{trg_end}=".to_sym
    if src_end
      src_setter= "#{src_end}=".to_sym
      trg.each do |t| 
        old_src= t.send src_end
        old_src= old_src - src if old_src
        t.send src_setter, src
      end
    end
    src.each do |s|
      old_trg= s.send trg_end
      old_trg= old_trg - trg if old_trg
      s.send trg_setter, trg
    end
  end

  def expand_multiplicity_shorthand multiplicity, default
    if nil== multiplicity then 
      multiplicity= default
    end
    if multiplicity==STAR then 
      multiplicity= 0..STAR
    end
    if multiplicity.kind_of? Integer then 
      multiplicity = multiplicity..multiplicity 
    end
    throw "Multiplicity must be Range or int" unless multiplicity.kind_of? Range
    return multiplicity
  end

  CONTEXT_INDEX_ARG=0
  CONTEXT_INDEX_NAME=1
  CONTEXT_INDEX_TYPE=2
  CONTEXT_INDEX_CONDITIONS=3
  CONTEXT_INDEX_EXCEPTION=4
  CONTEXT_INDEX_MAX=4


  def multiples num, type, *init
    (0...num).inject([]){ |p,i| p[i]= type.new( *init); p}
  end

end #Typesafe module 

class Range
  def cardinality? number
    if last == -1
      return number >= first
    end
    include? number
  end
end

class Array
  def report_typesafety_errors
    s=""
    self.each{|map|
      s<< "Error: #{map[:name]} - #{map[:error]}\n"
      map.each_pair{ |k,v|
        s<< "  :#{k}=>#{v.inspect}\n"
      }
    }
    s
  end

end
