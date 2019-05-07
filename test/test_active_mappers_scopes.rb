require 'minitest/autorun'
require 'active_mappers'
require 'mocha/minitest'


class NamespacesTest < Minitest::Test
  class ScopeOtherMapper < ActiveMappers::Base
    attributes :name

    scope :coucou do
      attributes :lol
      relation :friend, ScopeMapper
    end
  end

  class ScopeMapper < ActiveMappers::Base
    attributes :name

    scope :admin do
      attributes :id
      relation :friend, ScopeOtherMapper
    end
  end

  class BusinessSectorMapper < ActiveMappers::Base
    attributes :name, :id

    scope :admin do
      relation :children, BusinessSectorMapper
    end
  end

  class RewardMapper < ActiveMappers::Base
    attributes :name, :id

    scope :and_stamps do
      relation :stamps, BusinessSectorMapper
    end
  end

  class StampMapper < ActiveMappers::Base
    attributes :name, :id

    scope :and_reward do
      relation :reward, RewardMapper
      sleep 5
    end
  end

  class BusinessSector
    attr_accessor :id, :name, :children

    def initialize(id, name, children = nil)
      @id, @name, @children = id, name, children
    end
  end
  def test_scopes_allow_to_scope_dsl_declarations
    reflection = Struct.new(:class_name)

    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new("Friend"))
    user2 = User.new('124', 'Nathan', nil)
    user = User.new('123', 'Michael', user2)

    assert_equal '123', ::NamespacesTest::ScopeMapper.with(user, rootless: true, scope: :admin)[:id]
    assert_nil ::NamespacesTest::ScopeMapper.with(user, rootless: true)[:id]
  end

  def test_scopes_allow_to_scope_dsl_multiple_times_without_failing
    bs1 = BusinessSector.new('124', 'Hôtellerie', [])
    bs2 = BusinessSector.new('125', 'Restauration', [bs1])

    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new("Children"))

    mapper1 = BusinessSectorMapper.with(bs2, rootless: true, scope: :admin)
    mapper2 = BusinessSectorMapper.with(bs1, rootless: true)

    assert_equal '124', mapper1[:children][0][:id]
    assert_nil mapper2[:children]
  end

  def test_scopes_fail_safely
    user = User.new('123', 'Michael', nil)

    exception = assert_raises(RuntimeError) {
      ::NamespacesTest::ScopeMapper.with(user, scope: :dza)
    }
    assert exception.message.include?('Scope named dza has not been declared')
  end
end
