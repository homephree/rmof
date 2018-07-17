# rmof

Experiment to model UML metamodels in Ruby.

Works rather well to model meta-object factility (mof) in ruby
 code (rmof) and then create an E-MOF (essential mof) emof implementation
 baed on that. Extend the 'eigenclass' metaclass with custom class 
 methods like 'generalization' and 'attribute'.
 
The model is a bit ponderous, wiht a lot of array types to carry 
additional data, such as 

```ruby 
    association nil, [:property, Property, {:multiplicity => 1..1}], [:opposite, Property, {:multiplicity => 0..1}], :association, { :directed=>true}
```

to define an association between the Property metaclass and itself, 
including labels and multiplicity.

```ruby
      attribute :isReadOnly, Boolean, { :multiplicity => 1..1, :default=>[FALSE]}
```

defines an attribute on `Property` defining its readonly state, and multiplicity of one, and whether it has 
a default. This is in line with E-MOF,

What I think it needs is a way to show that e-mof is exactly the same (in ruby) as the native version.
When an attribtue is created with the attribute keyword the `Property` class does include getter methods
on the class so it is part way there. 

Constructors in `PrimitiveType` taking default values are an example of where the metalevels aren't isomorphic.
We don't have a way to define value constructors there yet. 
