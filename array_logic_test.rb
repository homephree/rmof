require "test/unit"

class Meta
  def ar; @ar; end
  def [](i); @ar[i]; end
  def ar=(v); @ar=v; end
  def []=(i,v); @ar[i]=v; end
end

class MetaTestCase < Test::Unit::TestCase
  def test_case_name
    m= Meta.new
    m.ar=[1,2]
    assert_equal(1, m[0])
    assert_equal(1, m[0])
    assert_equal(2, m[1])
    assert_equal(nil, m[2])
    assert_equal(nil, m[100])
    #faulty use: use a non-array
    m.ar=123
    #bizarre int array accesssor behaviour
    assert_equal(123, m.ar)
    assert_equal(1, m[0])
    assert_equal(1, m[1])
    assert_equal(0, m[2])
  end
end
