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

    def self.resource_to_mapper(resource, class_from)
      "#{base_namespace(class_from)}::#{resource.class.name}Mapper".constantize
    end

    def self.resource_class_to_mapper(resource_class_name, class_from)
      resource_class_name[0..1] = '' if resource_class_name.start_with?('::')
      
      "#{base_namespace(class_from)}::#{resource_class_name}Mapper".constantize
    rescue NameError
      raise "undefined mapper: '#{base_namespace(class_from)}::#{resource_class_name}Mapper'"
    end

    def initialize(name)
      @name = name
    end

    def remove_ignored_namespace
      Setup.ignored_namespaces.each do |namespace|
        @name.gsub!("#{namespace.to_s.capitalize}::", '')
      end
      @name = @name.split('MapperScope')[0]
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

    def self.base_namespace(class_from)
      base_namespace = class_from.name.split('::')[0] rescue ""
      base_namespace = '' unless Setup.ignored_namespaces.include?(base_namespace.downcase.to_sym)

      base_namespace
    end
  end
end
