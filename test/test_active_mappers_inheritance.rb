require 'minitest/autorun'
require 'active_mappers'
require 'mocha/minitest'

class InheritanceMapper < ActiveMappers::Base
  attributes :id
end

class InheritedMapper < InheritanceMapper
  attributes :name
end

class OtherInheritedMapper < InheritanceMapper
  attributes :friend
end

class DoubleInheritedMapper < InheritedMapper
  attributes :friend
end

class InheritanceMappersTest < Minitest::Test
  def test_classes_can_be_inherited
    user = User.new(1, 'Michael', 'lol')

    assert_equal ({ id: 1 }), InheritanceMapper.with(user, rootless: true)
    assert_equal ({ id: 1, name: 'Michael' }), InheritedMapper.with(user, rootless: true)
    assert_equal ({ id: 1, friend: 'lol', name: 'Michael' }), DoubleInheritedMapper.with(user, rootless: true)
    assert_equal ({ id: 1, friend: 'lol' }), OtherInheritedMapper.with(user, rootless: true)
  end
end
