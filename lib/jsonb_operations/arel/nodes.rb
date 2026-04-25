# typed: strict
# frozen_string_literal: true

# https://www.postgresql.org/docs/18/functions-json.html
module Arel::Nodes::Jsonb
  # ── Table 9.47 — json and jsonb operators ─────────────────────────────

  # column -> integer  →  n'th array element (jsonb)
  class FetchElement < Arel::Nodes::Binary; end

  # column -> text  →  object field by key (jsonb)
  class FetchField < Arel::Nodes::Binary; end

  # column ->> integer  →  n'th array element as text
  class FetchElementText < Arel::Nodes::Binary; end

  # column ->> text  →  object field as text
  class FetchFieldText < Arel::Nodes::Binary; end

  # column #> text[]  →  sub-object at path (jsonb)
  class FetchPath < Arel::Nodes::Binary; end

  # column #>> text[]  →  sub-object at path as text
  class FetchPathText < Arel::Nodes::Binary; end

  # ── Table 9.48 — jsonb-only operators ────────────────────────────────

  # column @> jsonb  →  left contains right
  class Contains < Arel::Nodes::Binary; end

  # column <@ jsonb  →  left is contained in right
  class ContainedBy < Arel::Nodes::Binary; end

  # column ? text  →  key or element exists at top level
  class HasKey < Arel::Nodes::Binary; end

  # column ?| text[]  →  any of the given keys exist
  class HasAnyKey < Arel::Nodes::Binary; end

  # column ?& text[]  →  all of the given keys exist
  class HasAllKeys < Arel::Nodes::Binary; end

  # column || jsonb  →  concatenate two jsonb values
  class Concat < Arel::Nodes::Binary; end

  # column - text  →  delete key/value pair or matching string element
  class DeleteKey < Arel::Nodes::Binary; end

  # column - text[]  →  delete all matching keys or array elements
  class DeleteKeys < Arel::Nodes::Binary; end

  # column - integer  →  delete array element at index
  class DeleteElement < Arel::Nodes::Binary; end

  # column #- text[]  →  delete field or element at path
  class DeletePath < Arel::Nodes::Binary; end

  # column @? jsonpath  →  does path return any item?
  class PathExists < Arel::Nodes::Binary; end

  # column @@ jsonpath  →  jsonpath predicate check
  class PathMatch < Arel::Nodes::Binary; end

  # ── Miscellaneous ───────────────────────────────────────────────────────

  # Renders a Ruby array as a PostgreSQL ARRAY['a', 'b'] expression.
  class TextArray < Arel::Nodes::Node
    #: () -> Array[String]
    def values
      @values
    end

    #: (untyped values) -> void
    def initialize(values)
      super()
      @values = Array(values).map(&:to_s) #: Array[String]
    end

    #: (untyped other) -> bool
    def ==(other)
      return false if !other.is_a?(TextArray)

      values == other.values
    end
    alias_method :eql?, :==

    #: () -> Integer
    def hash
      values.hash
    end
  end
end
