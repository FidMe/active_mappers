require 'active_support'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'
require_relative 'core_ext/hash'
require_relative 'active_mappers/key_transformer'

module ActiveMappers
  class Base
    @@renderers = {}

    def self.attributes(*params)
      each do |resource|
        h = {}
        params.each do |param|
          h[param] = resource.try(param)
        end
        h
      end
    end

    def self.delegate(*params)
      delegator = params.last[:to]
      params.pop
      each do |resource|
        h = {}
        params.each do |param|
          h[param] = delegator.to_s.split('.').inject(resource, :try).try(param)
        end
        h
      end
    end

    def self.relation(key, mapper = nil, optional_path = nil)
      path = optional_path || key
      each do |resource|
        mapper_to_use = mapper || KeyTransformer.resource_to_mapper(resource.send(key), self)
        { key => mapper_to_use.with(path.to_s.split('.').inject(resource, :try), rootless: true) }
      end
    end

    def self.polymorphic(key)
      each do |resource|
        resource_mapper = "#{KeyTransformer.base_namespace(self)}::#{resource.send("#{key}_type")}Mapper".constantize
        { key => resource_mapper.with(resource.send(key), rootless: true) }
      end
    end

    def self.acts_as_polymorph
      each do |resource|
        mapper = KeyTransformer.resource_to_mapper(resource, self)
        mapper.with(resource, rootless: true)  
      rescue NameError
        raise NotImplementedError, 'No mapper found for this type of resource'
      end
    end

    def self.each(&block)
      @@renderers[name] = (@@renderers[name] || []) << block
    end

    def self.with(args, options = {})
      if options[:rootless]
        args.respond_to?(:each) ? all(args) : one(args)
      else
        render_with_root(args, options)
      end
    end

    def self.render_with_root(args, options = {})
      resource_name = options[:root]
      resource_name ||= KeyTransformer.apply_on(self.name)
      
      if args.respond_to?(:each)
        { resource_name.to_s.pluralize.to_sym => all(args) }
      else
        { resource_name.to_s.singularize.to_sym => one(args) }
      end
    end

    def self.all(collection)
      collection.map { |el| one(el) }
    end

    def self.one(resource)
      return {} if @@renderers[name].nil? # Mapper is empty
      renderers = @@renderers[name].map do |renderer|
        renderer.call(resource)
      end.reduce(&:merge)

      KeyTransformer.format_keys(renderers)
    end
  end
end
