require 'minitest/autorun'
require 'active_mappers'
require 'mocha/minitest'

class ScopeOtherMapper < ActiveMappers::Base
  attributes :name

  scope :coucou do
    attributes :lol
  end
end

class ScopeMapper < ActiveMappers::Base
  attributes :name

  scope :admin do
    attributes :id
    relation :friend, ::ScopeOtherMapper
  end
end

class BusinessSectorMapper < ActiveMappers::Base
  attributes :name, :id

  scope :admin do
    relation :children, ::BusinessSectorMapper
  end
end

class RewardMapper < ActiveMappers::Base
  attributes :name, :id

  scope :and_stamps do
    relation :stamps, ::BusinessSectorMapper
  end
end

class StampMapper < ActiveMappers::Base
  attributes :name, :id

  scope :and_reward do
    relation :reward, ::RewardMapper
  end
end

class BusinessSector
  attr_accessor :id, :name, :children

  def initialize(id, name, children = nil)
    @id = id
    @name = name
    @children = children
  end
end

class Requirement
  attr_accessor :id, :content_type, :content_id, :content

  def initialize(id, content_type, content_id)
    @id = id
    @content_type = content_type
    @content_id = content_id
    @content = @content_type.constantize.new(@content_id, 12.5) if @content_id
  end
end

class Ticket
  attr_accessor :id, :price

  def initialize(id, price)
    @id = id
    @price = price
  end
end

class RequirementMapper < ActiveMappers::Base
  attributes :id
  polymorphic :content
  scope :admin do
    polymorphic :content, scope: :admin
  end
end

class TicketMapper < ActiveMappers::Base
  attributes :id
  each do |ticket, context|
    { context: context }
  end
  scope :admin do
    attributes :price
  end
end



class CreditableOfUser
  attr_accessor :id, :points
  def initialize(id, points)
    @id = id
    @points = points
  end
end

class StampableOfUser
  attr_accessor :id, :position, :number
  def initialize(id, position, number)
    @id = id
    @position = position
    @number = number
  end
end

class ScannableOfUser
  attr_accessor :id, :value
  def initialize(id, value)
    @id = id
    @value = value
  end
end

class OfUserMapper < ActiveMappers::Base
  acts_as_polymorph
  attributes :id

  scope :admin do
    acts_as_polymorph(scope: :admin)
  end
end

class CreditableOfUserMapper < ActiveMappers::Base
  scope :admin do
    attributes :points
  end
end

class StampableOfUserMapper < ActiveMappers::Base
  scope :admin do
    each do |item|
      { calculate: item.position * item.number }
    end
  end
end

class ScannableOfUserMapper < ActiveMappers::Base
  attributes :value
end



class NamespacesTest < Minitest::Test
  def test_scopes_allow_to_scope_dsl_declarations
    reflection = Struct.new(:class_name)

    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('Friend'))
    user2 = User.new('124', 'Nathan', nil)
    user = User.new('123', 'Michael', user2)

    assert_equal '123', ::ScopeMapper.with(user, rootless: true, scope: :admin)[:id]
    assert_nil ::ScopeMapper.with(user, rootless: true)[:id]
  end

  def test_scopes_allow_to_scope_dsl_multiple_times_without_failing
    bs1 = BusinessSector.new('124', 'Hôtellerie', [])
    bs2 = BusinessSector.new('125', 'Restauration', [bs1])

    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('Children'))

    mapper1 = BusinessSectorMapper.with(bs2, rootless: true, scope: :admin)
    mapper2 = BusinessSectorMapper.with(bs1, rootless: true)

    assert_equal '124', mapper1[:children][0][:id]
    assert_nil mapper2[:children]
  end

  def test_polymorphic_scope
    requirement = Requirement.new('1', 'Ticket', '1')

    mapper = RequirementMapper.with(requirement)[:requirement]
    mapper_admin = RequirementMapper.with(requirement, scope: :admin)[:requirement]

    assert !mapper[:content].key?(:price),      'RequirementMapper with no scope admin should not return price'
    assert mapper_admin[:content].key?(:price), 'RequirementMapper with admin scope should return price'
    assert_equal requirement.content.price, mapper_admin[:content][:price]
  end

  def test_polymorphic_scope_with_context
    requirement = Requirement.new('1', 'Ticket', '1')

    mapper = RequirementMapper.with(requirement, context: { key: 'value' })[:requirement]
    assert_equal 'value', mapper[:content][:context][:key]
  end

  def test_scopes_fail_safely
    user = User.new('123', 'Michael', nil)

    exception = assert_raises(RuntimeError) do
      ScopeMapper.with(user, scope: :dza)
    end
    assert exception.message.include?('No scope named dza found')
  end

  def test_acts_as_polymorph_with_scope
    c = CreditableOfUser.new('123', 100)
    s = StampableOfUser.new('456', 2, 10)
    v = ScannableOfUser.new('789', '0000000001')

    [c, s, v].each do |item|
      map = OfUserMapper.with(item)[:ofUser]
      assert !map.key?(:points)
      assert !map.key?(:calculate)
    end

    map = OfUserMapper.with(c, scope: :admin)[:ofUser]
    assert_equal '123', map[:id]
    assert_equal 100, map[:points]

    map = OfUserMapper.with(s, scope: :admin)[:ofUser]
    assert_equal '456', map[:id]
    assert_equal 20, map[:calculate]

    map = OfUserMapper.with(v, scope: :admin)[:ofUser]
    assert_equal '789', map[:id]
    assert_equal '0000000001', map[:value]
  end

end
