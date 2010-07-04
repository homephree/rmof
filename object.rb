# Object classes for metamodelling

class Instance
  def initialize( *classifier)
    @classifier= classifier
  end
  def classifier
    @classifier
  end
end