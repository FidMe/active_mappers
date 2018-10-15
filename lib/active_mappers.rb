require 'active_support'
require 'active_support/core_ext/object/try'
require_relative 'core_ext/hash'

module ActiveMappers
  class Base
    @@renderers = {}

    def self.attributes(*params)
      each do |resource|
        h = {}
        params.each do |param|
          p param, resource
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
        mapper ||= "::#{resource.send(key).class.name}Mapper".constantize
        { key => mapper.with(path.to_s.split('.').inject(resource, :try)) }
      end
    end

    def self.polymorphic(key)
      each do |resource|
        resource_mapper = "::#{resource.send("#{key}_type")}Mapper".constantize
        { key => resource_mapper.with(resource.send(key)) }
      end
    end

    def self.acts_as_polymorph
      each do |resource|
        mapper = "::#{resource.class}Mapper".constantize
        mapper.with(resource)
      rescue NameError
        raise NotImplementedError, 'No mapper found for this type of resource'
      end
    end

    def self.each(&block)
      @@renderers[name] = (@@renderers[name] || []) << block
    end

    def self.with(args)
      args.respond_to?(:each) ? all(args) : one(args)
    end

    def self.all(collection)
      collection.map { |el| one(el) }
    end

    def self.one(resource)
      renderers = @@renderers[name].map { |renderer| renderer.call(resource) }
      renderers.reduce(&:merge).to_lower_camel_case
    end
  end
end
