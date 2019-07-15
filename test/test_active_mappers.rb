require 'minitest/autorun'
require 'active_mappers'
require 'mocha/minitest'

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
    @id = id
    @name = name
    @friend = friend
  end
end

class Friend
  attr_accessor :id, :name, :friend

  def initialize(id, name, friend = nil)
    @id = id
    @name = name
    @friend = friend
  end
end

class ActiveMappersTest < Minitest::Test
  def test_can_render_a_list_of_resources
    users = []
    5.times { users << User.new('123', 'Michael', nil) }

    mapped_users = UserMapper.with(users)

    assert_equal 5, mapped_users[:users].size
    assert_equal '123', mapped_users[:users][0][:id]
  end

  def test_can_render_a_single_resource
    user = User.new('123', 'Michael', nil)
    assert_equal user.id, UserMapper.with(user)[:user][:id]
  end

  def test_each_can_be_used_to_declare_custom_attrs
    user = User.new('123', 'Michael', nil)
    assert_equal 'lol', UserMapper.with(user)[:user][:lol]
  end

  def test_each_can_be_chained
    user = User.new('123', 'Michael', nil)
    assert_equal 'lola', UserMapper.with(user)[:user][:lola]
  end

  class FriendLolMapper < ActiveMappers::Base
    attributes :name

    scope :lol do
      attributes :id
    end
  end

  class FriendShipLolMapper < ActiveMappers::Base
    attributes :name
    relation :friend, FriendLolMapper, scope: :lol

    scope :admin do
      attributes :id
    end
  end

  class FriendShipMapper < ActiveMappers::Base
    attributes :name
    relation :friend, FriendShipMapper

    scope :admin do
      attributes :id
    end
  end

  def test_relation_can_query_other_mapper
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('User'))

    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)
    assert_equal 'Nicolas', FriendShipMapper.with(user, root: :user)[:user][:friend][:name]
  end

  def test_relation_returns_correct_data_for_empty_has_many_association
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('User'))

    user = User.new('123', 'Michael', [nil])

    assert_equal 0, FriendShipMapper.with(user, root: :user)[:user][:friend].size
  end

  def test_relation_takes_optional_hash
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('Friend'))

    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)
    mapper = FriendShipLolMapper.with(user, root: :user)[:user]

    assert_equal 'Nicolas', mapper[:friend][:name]
    assert_equal '124', mapper[:friend][:id]
    assert_nil mapper[:id]
  end

  class Car
    attr_accessor :id, :name, :driver

    def initialize(id, name, driver = nil)
      @id = id
      @name = name
      @driver = driver
    end
  end

  class Driver
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  class CarMapper < ActiveMappers::Base
    attributes :car_id, :car_name
    relation :driver
  end

  class DriverMapper < ActiveMappers::Base
    attributes :id, :name
  end

  def test_relation_mapper_declaration_can_be_implicit
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('ActiveMappersTest::Driver'))

    driver = Driver.new('124', 'Nicolas')
    car = Car.new('124', 'r5', driver)

    assert CarMapper.with(car, root: :car)[:car].key?(:driver)
    assert_equal 'Nicolas', CarMapper.with(car, root: :car)[:car][:driver][:name]
  end

  def test_relation_declaration_can_be_implicit_for_has_many_association
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('ActiveMappersTest::Driver'))

    driver1 = Driver.new('124', 'Nicolas')
    driver2 = Driver.new('124', 'John')
    car = Car.new('123', 'Polo', [driver1, driver2])

    assert CarMapper.with(car, root: :car)[:car].key?(:driver)
    assert_equal 2, CarMapper.with(car, root: :car)[:car][:driver].size
  end

  ################################################

  class Human
    attr_accessor :id, :name, :cat

    def initialize(id, name, cat = nil)
      @id = id
      @name = name
      @cat = cat
    end
  end

  class Cat
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  class HumanMapper < ActiveMappers::Base
    attributes :id, :name
    relation :cat
  end

  class CatMapper
  end

  def test_returns_should_be_a_mapper_error_when_invalid_mapper
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('ActiveMappersTest::Cat'))

    cat = Cat.new('124', 'Nathan')
    human = Human.new('124', 'Aniss', cat)

    error = assert_raises RuntimeError do
      HumanMapper.with(human)
    end
    assert_equal "'ActiveMappersTest::CatMapper' should be a mapper", error.message
  end

  ################################################

  class Owner
    attr_accessor :id, :name, :dog

    def initialize(id, name, dog = nil)
      @id = id
      @name = name
      @dog = dog
    end
  end

  class Dog
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  class OwnerMapper < ActiveMappers::Base
    attributes :id, :name
    relation :dogsq
  end

  def test_wrong_relation_declaration_returns_undefined_relation_error
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new(nil))

    dog = Dog.new('321', 'Lassie')
    owner = Owner.new('123', 'Michael', dog)

    error = assert_raises RuntimeError do
      OwnerMapper.with(owner)
    end
    assert_match 'undefined relation : dogsq', error.message
  end

  ################################################

  class Computer
    attr_accessor :id, :name, :mouse

    def initialize(id, name, mouse = nil)
      @id = id
      @name = name
      @mouse = mouse
    end
  end

  class Mouse
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  class ComputerMapper < ActiveMappers::Base
    attributes :id, :name
    relation :dogsq
  end

  def test_missing_relation_mapper_returns_undefined_mapper_error
    reflection = Struct.new(:class_name)
    Class.any_instance.stubs(:reflect_on_association).returns(reflection.new('Mouse'))

    mouse = Mouse.new('321', 'logitech')
    computer = Computer.new('123', 'macbook1', mouse)

    error = assert_raises RuntimeError do
      ComputerMapper.with(computer)
    end
    assert_equal "undefined mapper: '::MouseMapper'", error.message
  end

  ################################################

  class BusinessSectorMapper < ActiveMappers::Base
    relation :children, BusinessSectorMapper
  end

  def test_mapper_called_with_nil_returns_nil
    assert BusinessSectorMapper.with(nil).key?(:'activesTest/BusinessSector')
    assert_nil BusinessSectorMapper.with(nil)[:'activesTest/BusinessSector']
    assert_nil BusinessSectorMapper.with(nil, rootless: true)
    assert_equal [], BusinessSectorMapper.with([nil])[:'activesTest/BusinessSectors']
    assert_equal [], BusinessSectorMapper.with([nil], rootless: true)
  end

  class ProfileMapper < ActiveMappers::Base
    delegate :name, to: :friend
  end
  def test_delegate_can_remap_attributes
    friend = Friend.new('124', 'Nicolas', nil)
    user = User.new('123', 'Michael', friend)
    assert_equal 'Nicolas', ProfileMapper.with(user, root: :user)[:user][:name]
  end

  class RootLessMapper < ActiveMappers::Base
    attributes :name
  end
  def test_rootless_can_remove_root
    user = User.new('123', 'Michael', nil)
    assert_equal 'Michael', RootLessMapper.with(user, rootless: true)[:name]
  end

  class CamelKeyMapper < ActiveMappers::Base
    attributes :name
  end
  def test_root_keys_are_correctly_camelized
    user = User.new('123', 'Michael', nil)
    assert CamelKeyMapper.with([user])[:'activesTest/CamelKeys'].is_a? Array
    assert_equal 'Michael', CamelKeyMapper.with(user)[:'activesTest/CamelKey'][:name]
  end

  class EmptyMapper < ActiveMappers::Base
  end
  def test_mapper_raises_nothing_when_nothing_is_declared
    user = User.new('123', 'Michael', nil)
    assert_equal [{}], EmptyMapper.with([user], rootless: true)
  end
  
  class WithContextMapper < ActiveMappers::Base
    each do |user, context|
      { context: context }
    end
  end
  def test_can_pass_a_context_on_mapper
    user = User.new('123', 'Michael', nil)

    assert_equal 'coucou', WithContextMapper.with(user, context: 'coucou', rootless: true)[:context]
  end

  def test_core_extensions_work_as_expected
    params = {
      first_name: 'Nathan',
      emails: [{
        email_private: 'nathan@orange.fr',
        email_professional: 'nathan@fidme.com'
      }],
      secret: {
        password: 'azerty',
        password_confirmation: 'azerty',
        password_history: [
          passwords: {
            first_password: 'qwerty',
            actual_password: 'azerty'
          }
        ]
      }
    }
    response = params.to_lower_camel_case
    assert_equal 'Nathan', response[:firstName]
    assert_equal 'nathan@fidme.com', response[:emails][0][:emailProfessional]
    assert_equal 'azerty', response[:secret][:passwordConfirmation]
    assert_equal 'qwerty', response[:secret][:passwordHistory][0][:passwords][:firstPassword]
  end
end
