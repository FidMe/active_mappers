require 'minitest/autorun'
require 'active_mappers'

class UserMapper < ActiveMappers::Base
  attributes :id
end

class User
  attr_accessor :id, :name

  def initialize(id, name)
    @id, @name = id, name
  end
end

class ActiveMappersTest < Minitest::Test
  def test_can_render_a_list_of_resources
    users = []
    5.times { users << User.new('123', 'Michael') }

    mapped_users = UserMapper.with(users)

    assert_equal 5, mapped_users.size
    assert_equal '123', mapped_users[0][:id]
  end

  def test_can_render_a_single_resource
    user = User.new('123', 'Michael')
    mapped_user = UserMapper.with(user)

    assert_equal user.id, mapped_user[:id]
  end
end
