require_relative 'setup'

module ActiveMappers
  class KeyTransformer
    def self.apply_on(name)
      new(name)
        .remove_ignored_namespace
        .apply_root_key_transform
    end

    def self.format_keys(hash)
      Setup.camelcase_keys ? hash.to_lower_camel_case : hash
    end

    def initialize(name)
      @name = name
    end

    def remove_ignored_namespace
      Setup.ignored_namespaces.each do |namespace|
        @name.gsub!("#{namespace.to_s.capitalize}::", '')
      end
      self
    end

    def apply_root_key_transform
      camel_transformer = proc do |key|
        key.gsub('Mapper', '').tableize.camelize(:lower).gsub('::', '/')
      end

      snake_transformer = proc do |key|
        key.gsub('Mapper', '').tableize
      end

      transformer = Setup.camelcase_keys ? camel_transformer : snake_transformer

      (Setup.root_keys_transformer || transformer).call(@name)
    end
  end
end
