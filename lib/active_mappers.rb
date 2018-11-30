require 'active_support'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/string'
require_relative 'core_ext/hash'

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
        mapper ||= "::#{resource.send(key).class.name}Mapper".constantize
        { key => mapper.with(path.to_s.split('.').inject(resource, :try), rootless: true) }
      end
    end

    def self.polymorphic(key)
      each do |resource|
        resource_mapper = "::#{resource.send("#{key}_type")}Mapper".constantize
        { key => resource_mapper.with(resource.send(key), rootless: true) }
      end
    end

    def self.acts_as_polymorph
      each do |resource|
        mapper = "::#{resource.class}Mapper".constantize
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
      resource = options[:root] || self.name.gsub('Mapper', '').downcase
      if args.respond_to?(:each)
        { resource.tableize.gsub('/', '_').to_sym => all(args) }
      else
        { resource.to_sym => one(args) }
      end
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
