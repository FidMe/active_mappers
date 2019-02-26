class NamespacesTest < Minitest::Test
  class ScopeMapper < ActiveMappers::Base
    attributes :name

    scope :admin do
      attributes :id
    end
  end

  def test_scopes_allow_to_scope_dsl_declarations
    user = User.new('123', 'Michael', nil)

    assert_equal '123', ::NamespacesTest::ScopeMapper.with(user, rootless: true, scope: :admin)[:id]
    assert_nil ::NamespacesTest::ScopeMapper.with(user, rootless: true)[:id]
  end

  def test_scopes_fail_safely
    user = User.new('123', 'Michael', nil)

    exception = assert_raises(RuntimeError) {
      ::NamespacesTest::ScopeMapper.with(user, scope: :dza)
    }
    assert exception.message.include?('Scope named dza has not been declared')
  end
end
