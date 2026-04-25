# typed: strict
# frozen_string_literal: true

class JsonbOperations::ActiveRecord::JsonbExpression
  #: (untyped, untyped) -> void
  def initialize(scope, node)
    @scope = scope #: untyped
    @node = node #: untyped
  end

  # ── Standard comparators (fully-qualified names) ─────────────────

  #: (untyped) -> untyped
  def equals(value)
    finalize(@node.eq(value))
  end

  #: (untyped) -> untyped
  def not_equals(value)
    finalize(@node.not_eq(value))
  end

  #: (untyped) -> untyped
  def greater_than(value)
    finalize(@node.gt(value))
  end

  #: (untyped) -> untyped
  def greater_than_or_equal_to(value)
    finalize(@node.gteq(value))
  end

  #: (untyped) -> untyped
  def less_than(value)
    finalize(@node.lt(value))
  end

  #: (untyped) -> untyped
  def less_than_or_equal_to(value)
    finalize(@node.lteq(value))
  end

  #: (untyped) -> untyped
  def between(range)
    finalize(@node.between(range))
  end

  #: (untyped) -> untyped
  def included_in(values)
    finalize(@node.in(values))
  end

  #: (untyped) -> untyped
  def not_included_in(values)
    finalize(@node.not_in(values))
  end

  #: (untyped) -> untyped
  def matches(pattern)
    finalize(@node.matches(pattern))
  end

  #: (untyped) -> untyped
  def does_not_match(pattern) # rubocop:disable Naming/PredicatePrefix -- reads naturally; mirrors Arel's matcher name
    finalize(@node.does_not_match(pattern))
  end

  #: (untyped) -> untyped
  def contains(value)
    finalize(::Arel::Nodes::Jsonb::Contains.new(@node, ::JsonbOperations::Arel::NodeMethods.coerce_rhs(value)))
  end

  #: (untyped) -> untyped
  def contained_by(value)
    finalize(::Arel::Nodes::Jsonb::ContainedBy.new(@node, ::JsonbOperations::Arel::NodeMethods.coerce_rhs(value)))
  end

  # -- mirrors PostgreSQL ? / ?| / ?& operators

  #: (untyped) -> untyped
  def contains_key(key)
    finalize(::Arel::Nodes::Jsonb::HasKey.new(@node, ::Arel::Nodes::Quoted.new(key)))
  end

  #: (*untyped) -> untyped
  def contains_any_key(*keys)
    finalize(::Arel::Nodes::Jsonb::HasAnyKey.new(@node, ::Arel::Nodes::Jsonb::TextArray.new(keys.flatten)))
  end

  #: (*untyped) -> untyped
  def contains_all_keys(*keys)
    finalize(::Arel::Nodes::Jsonb::HasAllKeys.new(@node, ::Arel::Nodes::Jsonb::TextArray.new(keys.flatten)))
  end

  #: (untyped) -> untyped
  def path_exists(jsonpath)
    finalize(::Arel::Nodes::Jsonb::PathExists.new(@node, ::Arel::Nodes::Quoted.new(jsonpath.to_s)))
  end

  #: (untyped) -> untyped
  def path_match(jsonpath)
    finalize(::Arel::Nodes::Jsonb::PathMatch.new(@node, ::Arel::Nodes::Quoted.new(jsonpath.to_s)))
  end

  private

  #: (untyped) -> untyped
  def finalize(predicate)
    @scope.where!(predicate)
    @scope
  end
end
