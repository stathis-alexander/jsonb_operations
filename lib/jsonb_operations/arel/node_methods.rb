# typed: strict
# frozen_string_literal: true

module JsonbOperations::Arel::NodeMethods
  # ── Table 9.47 — json and jsonb operators ──────────────────────────────

  #: (Integer) -> Arel::Nodes::Jsonb::FetchElement
  def json_element(index)
    Arel::Nodes::Jsonb::FetchElement.new(self, Arel::Nodes::Quoted.new(index))
  end

  #: (String) -> Arel::Nodes::Jsonb::FetchField
  def json_field(key)
    Arel::Nodes::Jsonb::FetchField.new(self, Arel::Nodes::Quoted.new(key))
  end

  #: (Integer) -> Arel::Nodes::Jsonb::FetchElementText
  def json_element_text(index)
    Arel::Nodes::Jsonb::FetchElementText.new(self, Arel::Nodes::Quoted.new(index))
  end

  #: (String) -> Arel::Nodes::Jsonb::FetchFieldText
  def json_field_text(key)
    Arel::Nodes::Jsonb::FetchFieldText.new(self, Arel::Nodes::Quoted.new(key))
  end

  #: (*String) -> Arel::Nodes::Jsonb::FetchPath
  def json_path(*path)
    Arel::Nodes::Jsonb::FetchPath.new(self, Arel::Nodes::Jsonb::TextArray.new(path.flatten))
  end

  #: (*String) -> Arel::Nodes::Jsonb::FetchPathText
  def json_path_text(*path)
    Arel::Nodes::Jsonb::FetchPathText.new(self, Arel::Nodes::Jsonb::TextArray.new(path.flatten))
  end

  # ── Table 9.48 — jsonb-only operators ─────────────────────────────────

  #: (untyped) -> Arel::Nodes::Jsonb::Contains
  def contains(other)
    Arel::Nodes::Jsonb::Contains.new(self, jsonb_rhs(other))
  end

  #: (untyped) -> Arel::Nodes::Jsonb::ContainedBy
  def contained_by(other)
    Arel::Nodes::Jsonb::ContainedBy.new(self, jsonb_rhs(other))
  end

  # -- names mirror the ? / ?| / ?& PostgreSQL operators

  #: (String) -> Arel::Nodes::Jsonb::HasKey
  def contains_key(key)
    Arel::Nodes::Jsonb::HasKey.new(self, Arel::Nodes::Quoted.new(key))
  end

  #: (*String) -> Arel::Nodes::Jsonb::HasAnyKey
  def contains_any_key(*keys)
    Arel::Nodes::Jsonb::HasAnyKey.new(self, Arel::Nodes::Jsonb::TextArray.new(keys.flatten))
  end

  #: (*String) -> Arel::Nodes::Jsonb::HasAllKeys
  def contains_all_keys(*keys)
    Arel::Nodes::Jsonb::HasAllKeys.new(self, Arel::Nodes::Jsonb::TextArray.new(keys.flatten))
  end

  #: (untyped) -> Arel::Nodes::Jsonb::Concat
  def concat(other)
    Arel::Nodes::Jsonb::Concat.new(self, jsonb_rhs(other))
  end

  #: (String) -> Arel::Nodes::Jsonb::DeleteKey
  def delete_key(key)
    Arel::Nodes::Jsonb::DeleteKey.new(self, Arel::Nodes::Quoted.new(key))
  end

  #: (*String) -> Arel::Nodes::Jsonb::DeleteKeys
  def delete_keys(*keys)
    Arel::Nodes::Jsonb::DeleteKeys.new(self, Arel::Nodes::Jsonb::TextArray.new(keys.flatten))
  end

  #: (Integer) -> Arel::Nodes::Jsonb::DeleteElement
  def delete_element(index)
    Arel::Nodes::Jsonb::DeleteElement.new(self, Arel::Nodes::Quoted.new(index))
  end

  #: (*String) -> Arel::Nodes::Jsonb::DeletePath
  def delete_path(*path)
    Arel::Nodes::Jsonb::DeletePath.new(self, Arel::Nodes::Jsonb::TextArray.new(path.flatten))
  end

  #: (untyped) -> Arel::Nodes::Jsonb::PathExists
  def path_exists(jsonpath)
    Arel::Nodes::Jsonb::PathExists.new(self, Arel::Nodes::Quoted.new(jsonpath.to_s))
  end

  #: (untyped) -> Arel::Nodes::Jsonb::PathMatch
  def path_match(jsonpath)
    Arel::Nodes::Jsonb::PathMatch.new(self, Arel::Nodes::Quoted.new(jsonpath.to_s))
  end

  class << self
    #: (untyped) -> untyped
    def coerce_rhs(value)
      case value
      when Arel::Nodes::Node
        value
      when Hash, Array
        Arel::Nodes::Quoted.new(value.to_json)
      else
        Arel::Nodes::Quoted.new(value)
      end
    end
  end

  private

  #: (untyped) -> untyped
  def jsonb_rhs(value)
    JsonbOperations::Arel::NodeMethods.coerce_rhs(value)
  end
end
