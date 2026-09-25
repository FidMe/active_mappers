require 'method_source'
require 'ruby2ruby'
require 'ruby_parser'

require 'active_support'
# ⚠️ `blank?` / `present?` sont utilisés par `with` : dans une application Rails ils
# arrivent par le require complet d'ActiveSupport, mais en test ISOLÉ la gem ne charge que
# ce qu'elle déclare — sans cette ligne, toute la suite tombait en
# `NoMethodError: undefined method 'present?'`.
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/string/inflections'
require_relative 'core_ext/hash'
require_relative 'active_mappers/handlers/inheritance'
require_relative 'active_mappers/key_transformer'


module ActiveMappers
  class Base
    @@renderers = {}
    @@inheritance_column = {}

    def self.inherited(subclass)
      Handlers::Inheritance.new(subclass, self).handle
    end

    def self.inheritance_column(val)
      @@inheritance_column[name] = val
    end

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

    # ⚠️ Le bloc capture `context` et le passe au mapper enfant. Sans ça, un mapper rendu
    # comme relation recevait toujours `nil` — alors que `polymorphic` le propageait déjà :
    # l'enfant ne pouvait donc pas savoir pour qui on rendait (app appelante, scope…), et
    # la seule parade était de remonter au parent par l'association.
    #
    # ⚠️ Le contexte est ajouté SOUS `options`, pas par-dessus : un `context:` passé
    # explicitement à la déclaration (`relation :x, Mapper, context: {...}`) reste
    # prioritaire, et celui du parent ne sert que de défaut.
    #
    # ⚠️ On MERGE au lieu d'écrire `options[:context] = context` : `options` est capturé par
    # la closure et partagé par TOUS les rendus de ce mapper. Le muter ferait fuiter le
    # contexte d'un rendu à l'autre entre threads.
    def self.relation(key, mapper = nil, **options)
      path = options[:optional_path] || key
      each do |resource, context|
        mapper_to_use = if mapper
          mapper
        else
          relation_class_name = resource.class&.reflect_on_association(options[:optional_path] || key)&.class_name
          raise "undefined relation : #{key.to_s}" if (mapper.nil? && relation_class_name.nil?)
          KeyTransformer.resource_class_to_mapper(relation_class_name.dup, self)
        end

        raise "'#{mapper_to_use.name}' should be a mapper" unless mapper_to_use.ancestors.map(&:to_s).include?("ActiveMappers::Base")

        { key => mapper_to_use.with(path.to_s.split('.').inject(resource, :try), { context: context }.merge(default_options.merge(options))) }
      end
    end

    def self.polymorphic(key, **options)
      each do |resource, context|
        # Même merge non mutant que `relation` : `options[:context] = context` mutait le
        # hash capturé par la closure, partagé par tous les rendus de ce mapper.
        if polymorphic_resource = resource.send("#{key}_type")
          resource_mapper = "#{KeyTransformer.base_namespace(self)}::#{polymorphic_resource}Mapper".constantize
          { key => resource_mapper.with(resource.send(key), { context: context }.merge(default_options.merge(options))) }
        else
          {}
        end
      end
    end

    def self.acts_as_polymorph(**options)
      each do |resource|
        mapper = KeyTransformer.resource_to_mapper(resource, self)
        mapper.with(resource, default_options.merge(options))
      rescue NameError
        raise NotImplementedError, 'No mapper found for this type of resource'
      end
    end

    def self.each(&block)
      # puts "[l. #{__LINE__}] [#{name}] each"
      @@renderers[name] = (@@renderers[name] || []) << block
    end

    def self.with(args, options = {})
      # puts "[l. #{__LINE__}] WITH - #{name} - #{options}"
      if options[:scope].present? && !name.include?('Scope')
        return evaluate_scopes(args, options)
      end
      response = if options[:rootless]
        args.respond_to?(:each) ? all(args, options) : one(args, options)
      else
        render_with_root(args, options)
      end
      response
    end

    def self.evaluate_scopes(args, options)
      # puts "[l. #{__LINE__}] [#{name}] evaluate_scopes #{options}"
      class_to_call = begin
        "::#{name}Scope#{options[:scope].capitalize}".constantize
      rescue
        if options[:fallback_class]
          options[:fallback_class]
        elsif options[:fallback_on_missing_scope]
          options.delete :scope
          self
        else
          raise("ActiveMappers [#{name}] No scope named #{options[:scope]} found")
        end
      end
      # puts "[l.#{__LINE__}] evaluate_scopes class_to_call -> #{class_to_call}"
      return class_to_call.with(args, options.merge(initial_mapper: self))
    end

    def self.scope(*params, &block)
      # puts "[l.#{__LINE__}] [#{name}] CREATING SCOPE CLASSES (name: #{name} | params: #{params.inspect}) ===> ::#{name}Scope#{params.first.capitalize}"
      raise "ActiveMappers [#{name}] scope must be a block" if block.nil? || !block.respond_to?(:call)
      params.each do |param|
        block_content = Ruby2Ruby.new.process(RubyParser.new.process(block.source).to_a.last)
        eval("class ::#{name}Scope#{param.capitalize} < ::#{name} ; #{block_content}; end")
      end
    end

    def self.render_with_root(args, options = {})
      resource_name = options[:root]
      resource_name ||= KeyTransformer.apply_on(self.name)

      if args.respond_to?(:each)
        { resource_name.to_s.pluralize.to_sym => all(args, options) }
      else
        { resource_name.to_s.singularize.to_sym => one(args, options) }
      end
    end

    def self.all(collection, options = {})
      collection.map { |el| one(el, options) }.compact
    end

    def self.one(resource, options = {})
      # puts "[l.#{__LINE__}] [#{name}] ONE - options: #{options.inspect} - inheritance_column: #{@@inheritance_column[name]}"
      return nil unless resource

      if @@inheritance_column[name] && !options[:fallback_class]
        main_mapper = KeyTransformer.resource_to_mapper(resource, self)
        # puts "[l.#{__LINE__}] [#{name}] ONE - main_mapper #{main_mapper}"
        mapper = options[:scope] ? (KeyTransformer.resource_to_mapper(resource, self, options[:scope]) rescue main_mapper) : main_mapper
        # puts "[l.#{__LINE__}] [#{name}] ONE - mapper #{mapper}"
        if name != mapper&.name
          return mapper.with(resource, options.merge(rootless: true, fallback_class: options[:initial_mapper]))
        end
      end

      return {} if @@renderers[name].nil? # Mapper is empty

      # base_mapper = name.rpartition('::').first

      # renderers = ancestors.select { |it| it.name.start_with?(base_mapper) }.map do |ancestor|
      #   puts "---> #{ancestor.name}"
      #   @@renderers[ancestor.name].map do |renderer|
      #     renderer.call(resource, options[:context])
      #   end.reduce(&:merge)
      # end.reduce(&:merge)

      renderers = @@renderers[name].map do |renderer|
        renderer.call(resource, options[:context])
      end.reduce(&:merge)

      KeyTransformer.format_keys(renderers)
    end

    def self.default_options
      { rootless: true, fallback_on_missing_scope: true }
    end

  end
end
