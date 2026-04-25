# typed: strict
# frozen_string_literal: true

return if !defined?(ActiveRecord::Base)
return if !defined?(Tapioca::Dsl::Compiler)

# Generates RBI signatures for the JSONB chain methods on every
# ActiveRecord model whose connection adapter is PostgreSQL.
#
# For each such model, two top-level modules are generated containing the
# `where.<op>(...)` signatures, one per WhereChain class. Each WhereChain
# class is then reopened, the corresponding module is `include`d, and a
# nested `JsonbExpression` subclass is emitted whose comparator and JSONB
# predicate methods return the model's relation type.
#
#     class User
#       module GeneratedJsonbRelationMethods
#         sig { ...returns(User::PrivateRelation) } ; def contains(*args, **kwargs); end
#         sig { ...returns(User::PrivateRelationWhereChain::JsonbExpression) } ; def json_field(*args, **kwargs); end
#         # ...
#       end
#
#       class PrivateRelationWhereChain
#         include GeneratedJsonbRelationMethods
#
#         module GeneratedJsonbExpressionMethods
#           sig { ...returns(User::PrivateRelation) } ; def equals(value); end
#           # ...
#         end
#
#         class JsonbExpression < ::JsonbOperations::ActiveRecord::JsonbExpression
#           include GeneratedJsonbExpressionMethods
#         end
#       end
#
#       # …same again for PrivateAssociationRelationWhereChain returning User::PrivateAssociationRelation
#     end
#: [ConstantType = singleton(::ActiveRecord::Base)]
class Tapioca::Dsl::Compilers::JsonbOperations < Tapioca::Dsl::Compiler
  PREDICATE_METHODS = %w[
    contains contained_by contains_key contains_any_key contains_all_keys path_exists path_match
  ].freeze #: Array[String]

  FETCH_METHODS = %w[
    json_element json_field json_element_text json_field_text json_path json_path_text
  ].freeze #: Array[String]

  COMPARATOR_METHODS = %w[
    equals
    not_equals
    greater_than
    greater_than_or_equal_to
    less_than
    less_than_or_equal_to
    between
    included_in
    not_included_in
    matches
    does_not_match
  ].freeze #: Array[String]

  SINGLE_ARG_PREDICATE_METHODS = %w[
    contains contained_by contains_key path_exists path_match
  ].freeze #: Array[String]

  VARIADIC_PREDICATE_METHODS = %w[contains_any_key contains_all_keys].freeze #: Array[String]

  BASE_JSONB_EXPRESSION = '::JsonbOperations::ActiveRecord::JsonbExpression' #: String

  class << self
    # @override
    #: -> T::Enumerable[T::Class[::ActiveRecord::Base]]
    def gather_constants
      ::ActiveRecord::Base.descendants
        .reject(&:abstract_class?)
        .select { |model| model.connection_db_config&.adapter.to_s == 'postgresql' }
    end
  end

  # @override
  #: -> void
  def decorate
    model_name = T.must(constant.name)

    root.create_path(constant) do |model|
      decorate_chain(
        model,
        model_name: model_name,
        chain_class_name: 'PrivateRelationWhereChain',
        relation_type: "#{model_name}::PrivateRelation",
        methods_module_name: 'GeneratedJsonbRelationMethods',
      )
      decorate_chain(
        model,
        model_name: model_name,
        chain_class_name: 'PrivateAssociationRelationWhereChain',
        relation_type: "#{model_name}::PrivateAssociationRelation",
        methods_module_name: 'GeneratedJsonbAssociationRelationMethods',
      )
    end
  end

  private

  #: (RBI::Scope, model_name: String, chain_class_name: String, relation_type: String, methods_module_name: String) -> void
  def decorate_chain(model, model_name:, chain_class_name:, relation_type:, methods_module_name:)
    expression_type = "#{model_name}::#{chain_class_name}::JsonbExpression"

    # Module of `where.<op>(...)` methods for this chain class. Predicate
    # ops return the relation; fetch ops return the chain's nested
    # JsonbExpression.
    methods_module = model.create_module(methods_module_name)
    add_chain_methods(methods_module, PREDICATE_METHODS, return_type: relation_type)
    add_chain_methods(methods_module, FETCH_METHODS,     return_type: expression_type)

    # Reopen the WhereChain class, include the methods module, and nest
    # the JsonbExpression subclass + its methods module inside.
    chain_class = model.create_class(chain_class_name)
    chain_class.create_include("#{model_name}::#{methods_module_name}")

    expression_methods_module = chain_class.create_module('GeneratedJsonbExpressionMethods')
    add_value_methods(expression_methods_module,    COMPARATOR_METHODS,           return_type: relation_type)
    add_value_methods(expression_methods_module,    SINGLE_ARG_PREDICATE_METHODS, return_type: relation_type)
    add_variadic_methods(expression_methods_module, VARIADIC_PREDICATE_METHODS,   return_type: relation_type)

    jsonb_expression_class = chain_class.create_class('JsonbExpression', superclass_name: BASE_JSONB_EXPRESSION)
    jsonb_expression_class.create_include("#{model_name}::#{chain_class_name}::GeneratedJsonbExpressionMethods")
  end

  #: (RBI::Scope, Array[String], return_type: String) -> void
  def add_chain_methods(scope, names, return_type:)
    names.each do |name|
      scope.create_method(
        name,
        parameters: [
          create_rest_param('args', type: 'T.untyped'),
          create_kw_rest_param('kwargs', type: 'T.untyped'),
        ],
        return_type: return_type,
      )
    end
  end

  #: (RBI::Scope, Array[String], return_type: String) -> void
  def add_value_methods(scope, names, return_type:)
    names.each do |name|
      scope.create_method(
        name,
        parameters: [create_param('value', type: 'T.untyped')],
        return_type: return_type,
      )
    end
  end

  #: (RBI::Scope, Array[String], return_type: String) -> void
  def add_variadic_methods(scope, names, return_type:)
    names.each do |name|
      scope.create_method(
        name,
        parameters: [create_rest_param('keys', type: 'T.untyped')],
        return_type: return_type,
      )
    end
  end
end
