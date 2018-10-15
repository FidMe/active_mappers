require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/string/exclude'

class Hash
  def permit(*attributes)
    slice(*attributes)
  end

  def require(key)
    self[key].present? ? self[key] : raise(ActionController::ParameterMissing, key)
  end

  def to_lower_camel_case
    deep_transform_keys do |key|
      key = key.to_s.include?('?') ? "is_#{key.to_s.delete('?')}" : key.to_s
      key.exclude?('_') ? key.to_sym : key.camelize(:lower).to_sym
    end
  end
end
