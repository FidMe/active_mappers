require 'minitest/autorun'
require 'active_mappers/setup'
require 'active_mappers'

module Admin
  class User
    attr_accessor :name, :first_name

    def initialize(name, first_name)
      @name = name
      @first_name = first_name
    end
  end

  class UserMapper < ActiveMappers::Base
    attributes :name, :first_name
  end
end

class ActiveMappersSetupTest < Minitest::Test
  def teardown
    ActiveMappers::Setup.ignored_namespaces = []
    ActiveMappers::Setup.camelcase_keys = true
    ActiveMappers::Setup.root_keys_transformer = nil
  end

  def test_configure_can_be_used_to_configurate
    ActiveMappers::Setup.configure do |config|
      config.camelcase_keys = false
      config.root_keys_transformer = 'lol'
    end

    assert_equal false, ActiveMappers::Setup.camelcase_keys
    assert_equal 'lol', ActiveMappers::Setup.root_keys_transformer
  end

  def test_namespaces_can_be_ignored
    user = Admin::User.new('Villeneuve', 'Michael')
    mapped_user = Admin::UserMapper.with(user)
    assert mapped_user.key?(:'admin/User')

    ActiveMappers::Setup.ignored_namespaces = [:admin]

    mapped_user = Admin::UserMapper.with(user)
    assert mapped_user.key?(:user)
  end

  def test_can_be_uncamelized
    user = Admin::User.new('Villeneuve', 'Michael')
    mapped_user = Admin::UserMapper.with(user)
    assert_equal 'Michael', mapped_user[:'admin/User'][:firstName]

    ActiveMappers::Setup.camelcase_keys = false

    mapped_user = Admin::UserMapper.with(user)

    assert_equal 'Michael', mapped_user[:'admin/user'][:first_name]
    assert !mapped_user.key?(:'admin/User')
  end

  def test_custom_root_key_transformer_can_be_applied
    user = Admin::User.new('Villeneuve', 'Michael')
    mapped_user = Admin::UserMapper.with(user)
    assert !mapped_user.key?(:lolsalut)

    ActiveMappers::Setup.root_keys_transformer = proc { |_string|
      'lolsalut'
    }

    mapped_user = Admin::UserMapper.with(user)
    assert mapped_user.key?(:lolsalut)
  end
end
