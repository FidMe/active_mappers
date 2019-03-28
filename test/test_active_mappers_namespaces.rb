class NamespacesTest < Minitest::Test
  def setup
    ActiveMappers::Setup.ignored_namespaces = []
    ActiveMappers::Setup.camelcase_keys = true
    ActiveMappers::Setup.root_keys_transformer = nil
  end
  

  class FriendShipMapper < ActiveMappers::Base
    attributes :name
    relation :friend
    each do 
      {
        coucou: 'coucou'
      }
    end
  end

  class FriendMapper < ActiveMappers::Base
    attributes :name
    each do 
      { mapper: 'ignored FriendMapper' }
    end
  end

  def test_relation_is_model_context_dependant_by_default
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('Friend'))

    ::ActiveMappers::Setup.ignored_namespaces = []

    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)

    assert_nil ::NamespacesTest::FriendShipMapper.with(user, root: :user)[:user][:friend][:mapper]
  end

  def test_relation_is_namespace_context_dependant_for_ignored_namespaces
    ::ActiveMappers::Setup.ignored_namespaces = [:namespacestest]

    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new("Friend"))

    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)

    assert_equal 'ignored FriendMapper', ::NamespacesTest::FriendShipMapper.with(user, root: :user)[:user][:friend][:mapper]
  end
end