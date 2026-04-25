# typed: strict
# frozen_string_literal: true

module JsonbOperations::ActiveRecord::WhereChain
  include Kernel

  #: (*untyped, **untyped) -> untyped
  def contains(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: true) { |attr, rhs| attr.contains(rhs) }
  end

  #: (*untyped, **untyped) -> untyped
  def contained_by(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: true) { |attr, rhs| attr.contained_by(rhs) }
  end

  # -- mirrors PostgreSQL ? / ?| / ?& operators

  #: (*untyped, **untyped) -> untyped
  def contains_key(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: true) { |attr, rhs| attr.contains_key(rhs) }
  end

  #: (*untyped, **untyped) -> untyped
  def contains_any_key(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: false) { |attr, rhs| attr.contains_any_key(*rhs) }
  end

  #: (*untyped, **untyped) -> untyped
  def contains_all_keys(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: false) { |attr, rhs| attr.contains_all_keys(*rhs) }
  end

  #: (*untyped, **untyped) -> untyped
  def path_exists(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: true) { |attr, rhs| attr.path_exists(rhs) }
  end

  #: (*untyped, **untyped) -> untyped
  def path_match(*args, **kwargs)
    apply_jsonb_predicate(args, kwargs, single: true) { |attr, rhs| attr.path_match(rhs) }
  end

  # ── Fetch operators (value-producing — return a JsonbExpression) ─────

  #: (*untyped, **untyped) -> JsonbOperations::ActiveRecord::JsonbExpression
  def json_element(*args, **kwargs)
    build_jsonb_expression(args, kwargs, single: true) { |attr, rhs| attr.json_element(rhs) }
  end

  #: (*untyped, **untyped) -> JsonbOperations::ActiveRecord::JsonbExpression
  def json_field(*args, **kwargs)
    build_jsonb_expression(args, kwargs, single: true) { |attr, rhs| attr.json_field(rhs) }
  end

  #: (*untyped, **untyped) -> JsonbOperations::ActiveRecord::JsonbExpression
  def json_element_text(*args, **kwargs)
    build_jsonb_expression(args, kwargs, single: true) { |attr, rhs| attr.json_element_text(rhs) }
  end

  #: (*untyped, **untyped) -> JsonbOperations::ActiveRecord::JsonbExpression
  def json_field_text(*args, **kwargs)
    build_jsonb_expression(args, kwargs, single: true) { |attr, rhs| attr.json_field_text(rhs) }
  end

  #: (*untyped, **untyped) -> JsonbOperations::ActiveRecord::JsonbExpression
  def json_path(*args, **kwargs)
    build_jsonb_expression(args, kwargs, single: false) { |attr, rhs| attr.json_path(*rhs) }
  end

  #: (*untyped, **untyped) -> JsonbOperations::ActiveRecord::JsonbExpression
  def json_path_text(*args, **kwargs)
    build_jsonb_expression(args, kwargs, single: false) { |attr, rhs| attr.json_path_text(*rhs) }
  end

  private

  #: (Array[untyped], Hash[Symbol, untyped], single: bool) { (untyped, untyped) -> untyped } -> JsonbOperations::ActiveRecord::JsonbExpression
  def build_jsonb_expression(args, kwargs, single:, &block)
    scope = send(:instance_variable_get, :@scope)
    attr, rhs = resolve_jsonb_target(args, kwargs, scope.klass, single: single)
    JsonbOperations::ActiveRecord::JsonbExpression.new(scope, yield(attr, rhs))
  end

  #: (Array[untyped], Hash[Symbol, untyped], single: bool) { (untyped, untyped) -> untyped } -> untyped
  def apply_jsonb_predicate(args, kwargs, single:, &block)
    scope = send(:instance_variable_get, :@scope)
    attr, rhs = resolve_jsonb_target(args, kwargs, scope.klass, single: single)
    scope.where!(yield(attr, rhs))
    scope
  end

  #: (Array[untyped], Hash[Symbol, untyped], untyped, single: bool) -> [untyped, untyped]
  def resolve_jsonb_target(args, kwargs, klass, single:)
    if kwargs.empty?
      column, *operands = args
      [resolve_jsonb_column(column), single ? operands.first : operands]
    else
      raise ArgumentError, 'cannot mix positional column with keyword args' if !args.empty?

      walk_jsonb_kwargs(kwargs, klass)
    end
  end

  #: (untyped) -> untyped
  def resolve_jsonb_column(column)
    case column
    when ::Arel::Attributes::Attribute
      column
    when ::String
      table_name, col = column.split('.', 2)
      raise ArgumentError, "expected 'table.column', got #{column.inspect}" if col.nil?

      ::Arel::Table.new(table_name)[col]
    else
      raise ArgumentError, "unsupported column reference: #{column.inspect}"
    end
  end

  #: (Hash[Symbol, untyped], untyped) -> [untyped, untyped]
  def walk_jsonb_kwargs(kwargs, klass)
    raise ArgumentError, 'expected exactly one column or association key' if kwargs.size != 1

    key, value = kwargs.first
    if klass.columns_hash.key?(key.to_s)
      [klass.arel_table[key], value]
    else
      reflection = klass._reflect_on_association(key)
      raise ArgumentError, "no column or association `#{key}` on #{klass}" if reflection.nil?
      raise ArgumentError, "association `#{key}` requires a nested hash" if !value.is_a?(::Hash)

      walk_jsonb_kwargs(value.transform_keys(&:to_sym), reflection.klass)
    end
  end
end
