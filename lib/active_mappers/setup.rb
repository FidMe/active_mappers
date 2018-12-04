require 'active_support/core_ext/string/inflections'

module ActiveMappers
  class Setup
    @root_keys_transformer = nil
    @camelcase_keys = true
    @ignored_namespaces = []

    class << self
      attr_accessor :root_keys_transformer, :ignored_namespaces, :camelcase_keys
    end

    def self.configure
      yield self
    end
  end
end
