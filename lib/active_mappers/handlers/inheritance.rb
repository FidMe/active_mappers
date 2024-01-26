module ActiveMappers
  module Handlers
    class Inheritance
      def initialize(subclass, klass)
        @subclass = subclass
        @klass = klass
      end

      def handle
        return nil if regular_inheritance?

        @klass.class_variables.each do |var_name|
          dsl_values = @subclass.class_variable_get(var_name)

          dsl_values[@subclass.name] = dsl_values[@klass.name].dup
        end
      end

      private

      def regular_inheritance?
        @klass == ActiveMappers::Base
      end
    end
  end
end
