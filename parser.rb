require_relative "rmof"



class Parser
  VISIBILITY= {'+' => 'public', '-' => 'private', '#' => 'protected', '~' => 'package'}
  
  def initialize(text)
    @tokens = text.scan(/\{|\}|\(|\)|\w+|[#{VISIBILITY.keys.collect{|v|"\\#{v}"}}]/)
    print "\{|\}|\(|\)|\w+[#{VISIBILITY.keys.collect{|v|"\\#{v}"}}]"
    @out= ""
    print "tokens: #{@tokens.join(", ")}\n"
  end

  def next_token
    @tokens.shift    
  end
  
  def out text
    @out<< text
  end
  
  def text; @out; end

  def uml
    token = next_token

    if token == nil
      return nil

    elsif token == 'class'
      name= next_token
      out "class #{name} << Metaclass\n"
      if next_token != '{' then raise "Expected close bracket" end
      read_class
      out "end\n"
    else
      raise "Unexpected token: #{token}"
    end
  end
  
  
  def read_class
    token = next_token
    
    if token == 'generalization'
      generalization
      readclass
    elsif token == '}'
      return
    else
      conditions={}
      token= next_token
      print token
      if VISIBILITY.include? token then 
        conditions[:visibility]= VISIBILITY[token]
        token= next_token
      end
      out "#{conditions.inspect}\n"
    end
  end
  
end

