# TypeSafety module 
# Kevin Humphries - Friday, 17 October 2008 17:10
# Objective: add element attributes and methods to ruby classes to allow support
# of element metamodels.
# 
# A element 
# I need to be able to make definitions of the sort:
# :name, type, {multiplicity}, ordered
# 
# Design decision to use collections in _all cases_ for simplicity ( a 'single'
# collection will help)
# TODO instrument array such that it passes through methods to first instance if only one.
# Thursday, 10 June 2010 09:19
# Recent versions add mutliple inheritence via 'generelization' method
# I have equated 'NONE' with null with empty set. This may cause problems but reduces checking.

require 'pp'

module RMOF
  class RMOFException < Exception
    attr :validation_errors, true
    def initialize validation_errors
      self.validation_errors= validation_errors
    end
  end

  STAR= -1
  NONE= []
  VALID_CONDITIONS= {:multiplicity=>1, :ordered=>1, :default=>1, :default_return_parameter=>1, :return=>1}
  DEFAULT_ATTRIBUTE_CONDITIONS= {:multiplicity=>1..1, :ordered=>true, :default=>NONE} #note this default casues an invalid state
  DEFAULT_ASSOCIATION_END_CONDITIONS= {:multiplicity=>0..1, :ordered=>true, :default=>NONE}
  DEFAULT_ASSOCIATION_CONDITIONS= {:multiplicity=>STAR, :ordered=>true}
  DEFAULT_PARAMETER_CONDITIONS= {:multiplicity=>1..1, :ordered=>true}
  NO_RETURN_CONDITIONS= {:multiplicity=>0..0, :ordered=>true, :default=>NONE}
  DEFAULT_RETURN_PARAMETER= [:default_return_parameter,Object, NO_RETURN_CONDITIONS]
  NO_ERRORS= []
  ASSOCIATION_TYPES= {:association=>true, :aggregation=>true, :composition=>true}
  PARAM_NAME= 0
  PARAM_TYPE= 1
  PARAM_CONDITIONS= 2

  module_function

  # make the class element by offering 'attribute' and 'operation' methods in its eigenclass
  def element cls
    cls.class_eval <<-END
    alias ruby_class class
    # complete the transaction on the object; return nil or validation error array
    def __complete
      RMOF.complete self
    end    
    END

    class << cls
      define_method(:element?){true}

      def comment str
        @comments= [] unless instance_variable_defined? :@comments
        @comments<< str
        class_variable_set str, comment
        if method_defined? :__comments then undefine_method :__comments 
        end 
        define_method( :__comments) do  
          @comments
        end 
      end # comment method

      def generalization superClass
        @superClasses= [] unless instance_variable_defined? :@superClass
        @superClasses<< superClass
        instmth= "__inst_#{superClass.name}".gsub(/:/,'_')
        instvar= "@#{instmth}".to_sym
        superClass.instance_methods.each do |method|
          define_method instmth do 
            instance_variable_set( instvar, superClass.new) unless instance_variable_defined? instvar
            instance_variable_get instvar
          end
          #add the method to the class for its generalisations
          unless method_defined? method then
            define_method( method) do |*args|
              inst= self.send instmth
              inst.send method, *args
            end
          end
        end
      end # generalization method

      # define setters, getters and __complete_<name> for attribute
      def attribute name, type, conditions= DEFAULT_ATTRIBUTE_CONDITIONS
        RMOF.complete_conditions conditions, DEFAULT_ATTRIBUTE_CONDITIONS
        at= "@#{name}".to_sym
        getter= "#{name}".to_sym
        setter= "#{name}=".to_sym
        completion= "__complete_#{name}".to_sym
        define_method( getter) do
          if instance_variable_defined? at then instance_variable_get at
          else conditions[:default]
          end
        end
        define_method( setter) do |val|
          instance_variable_set at, val
        end
        define_method( completion) do
          RMOF.validate( self.send(getter), name, type, conditions)
        end
      end # attribute

      # Only support a single return output parameter (but 0..n multiplicity), as required by EMOF
      # Each parameter is the form [name:Symbol, type:Class, {conditions:Hash}]
      def operation name, *parameters, &method
        parameters.each {|p| 
          p[PARAM_CONDITIONS]= RMOF.complete_conditions( p[PARAM_CONDITIONS], DEFAULT_PARAMETER_CONDITIONS)
        }
        returnparams, passedparams= parameters.partition{|p| p[PARAM_CONDITIONS][:return] }
        raise SyntaxException, "only one return param" if returnparams.length >1 
        returnparams= [DEFAULT_RETURN_PARAMETER] if returnparams.length==0
        validation_errors= []
        adorn_error= lambda{|err|err[:owner]=self; err[:operation]=name; err[:parameters]=parameters; err}
        # this is the method itself
        define_method( name) do |*args|
          unless args.length==passedparams.length then 
            raise RMOFException.new([adorn_error[{:error=>:number_of_parameters}]])
          end
          args.each_with_index do |v, i|
            v= v or passedparams[i][PARAM_CONDITIONS][:default]
            errors= RMOF.validate( v, *passedparams[i])
            errors.each{|e| adorn_error[e]}
            validation_errors.concat errors
          end
          unless validation_errors.empty? then raise RMOFException.new( validation_errors) 
          end
          begin
            result= method.call(*args)
          rescue=> ex
            raise RMOFException.new( [adorn_error[{:error=>:exception, :exception=>ex}]])
          end
          validation_errors= RMOF.validate( result, *returnparams[0]) 
          validation_errors.each{|e| adorn_error[e];}
          unless validation_errors.empty? then 
            raise RMOFException.new( validation_errors)
          end
          result
        end # the method declaration method
      end # operation method

    end # eigenclass scope

  end #element method

  def complete_conditions conditions, defaults
    conditions= defaults unless conditions
    conditions[:multiplicity]= expand_multiplicity_shorthand conditions[:multiplicity], defaults[:multiplicity]
    conditions[:default]= conditions[:default] || defaults[:default]
    #todo - merge other conditions?
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
      e[:owner]= metaobject; 
      e[:association]= :attribute
    }
    errors
  end

  # validate the value against the conditions
  # return a hash of errors mapped as :code=> [arg, conditions, message] 
  def validate arg, name, type, conditions
    errors= []
    have_errors= {}
    add_error= lambda do |error_type|
      err= { :error=> error_type, :arg=>arg, :name=> name, :conditions=> conditions }
      errors<< err
      have_errors[error_type]= err
      err
    end
    begin
      conditions.each_key{ |c| 
        unless VALID_CONDITIONS.key? c
          add_error[ :condition].merge!( {:invalid_condition=> c})
        end
      }
      unless arg.kind_of? ::Array   #TO DO allow sets
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
            add_error[ :type]["arg_#{i}".to_sym]= v
          end
        end
      end
    rescue=> ex
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
  # *src: property name, type, conditions= {}
  # *trg: property name, type, conditions= {}
  # kind= :association, :aggregation, :composition
  # name of src may be null (no reverse association)
  # TODO consider syntax check on src, trg etc
  # TODO consider uniqueness on association_name
  def association association_name, src, trg, kind= :association, link_conditions=DEFAULT_ASSOCIATION_CONDITIONS
    src[PARAM_CONDITIONS]= complete_conditions src[PARAM_CONDITIONS], DEFAULT_ASSOCIATION_END_CONDITIONS
    trg[PARAM_CONDITIONS]= complete_conditions trg[PARAM_CONDITIONS], DEFAULT_ASSOCIATION_END_CONDITIONS
    # All emof assocs have defined multiplicity
    unless src[PARAM_NAME].nil? then
      trg[PARAM_TYPE].send( :attribute, *src)
    end
    src[PARAM_TYPE].send( :attribute, *trg)
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
      multiplicity= multiplicity..multiplicity 
    end
    throw "Multiplicity must be Range or int" unless multiplicity.kind_of? Range
    return multiplicity
  end

  def multiples num, type, *init
    (0...num).inject([]){ |p,i| p[i]= type.new( *init); p}
  end

  class Metaclass
    RMOF::element self
  end

end #Typesafe module 

class Range
  def cardinality? number
    if last== -1
      return number >= first
    end
    include? number
  end
end

class Array
  def report_rmof_errors
    s= ""
    self.each{|map|
      s<< "Error: #{map[:name]} - #{map[:error]}\n"
      map.each_pair{ |k,v|
        s<< "  :#{k}=>#{v.inspect}\n"
      }
    }
    s
  end

end
