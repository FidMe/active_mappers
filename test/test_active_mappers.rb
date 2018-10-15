require 'minitest/autorun'
require 'active_mappers'

class UserMapper < ActiveMappers::Base
  attributes :id

  each do
    { lol: 'lol' }
  end

  each do
    { lola: 'lola' }
  end
end

class FriendMapper < ActiveMappers::Base
  attributes :name
end

class User
  attr_accessor :id, :name, :friend

  def initialize(id, name, friend = nil)
    @id, @name, @friend = id, name, friend
  end
end

class Friend
  attr_accessor :id, :name, :friend

  def initialize(id, name, friend = nil)
    @id, @name, @friend = id, name, friend
  end
end

class ActiveMappersTest < Minitest::Test
  def test_can_render_a_list_of_resources
    users = []
    5.times { users << User.new('123', 'Michael', nil) }

    mapped_users = UserMapper.with(users)

    assert_equal 5, mapped_users.size
    assert_equal '123', mapped_users[0][:id]
  end

  def test_can_render_a_single_resource
    user = User.new('123', 'Michael', nil)
    assert_equal user.id, UserMapper.with(user)[:id]
  end

  def test_each_can_be_used_to_declare_custom_attrs
    user = User.new('123', 'Michael', nil)
    assert_equal 'lol', UserMapper.with(user)[:lol]
  end

  def test_each_can_be_chained
    user = User.new('123', 'Michael', nil)
    assert_equal 'lola', UserMapper.with(user)[:lola]
  end

  class FriendShipMapper < ActiveMappers::Base
    attributes :name
    relation :friend
  end
  def test_relation_can_query_other_mapepr
    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)

    assert_equal 'Nicolas', FriendShipMapper.with(user)[:friend][:name]
  end

  class ProfileMapper < ActiveMappers::Base
    delegate :name, to: :friend
  end
  def test_delegate_can_remap_attributes
    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)
    assert_equal 'Nicolas', ProfileMapper.with(user)[:name]
  end
end
