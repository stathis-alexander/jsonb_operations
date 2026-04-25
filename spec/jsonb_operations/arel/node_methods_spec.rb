# typed: strict
# frozen_string_literal: true

RSpec.describe JsonbOperations::Arel::NodeMethods do
  # ── Table 9.47 ─────────────────────────────────────────────────────────

  describe '#json_element' do
    it 'builds a FetchElement node and renders the -> operator with an integer' do
      node = User.arel_table[:data].json_element(2)
      expect(node).to be_a(Arel::Nodes::Jsonb::FetchElement)
      expect(node.to_sql).to eq('"users"."data" -> 2')
    end
  end

  describe '#json_field' do
    it 'builds a FetchField node and renders the -> operator with a string key' do
      node = User.arel_table[:data].json_field('name')
      expect(node).to be_a(Arel::Nodes::Jsonb::FetchField)
      expect(node.to_sql).to eq(%q("users"."data" -> 'name'))
    end
  end

  describe '#json_element_text' do
    it 'builds a FetchElementText node and renders the ->> operator with an integer' do
      node = User.arel_table[:data].json_element_text(0)
      expect(node).to be_a(Arel::Nodes::Jsonb::FetchElementText)
      expect(node.to_sql).to eq('"users"."data" ->> 0')
    end
  end

  describe '#json_field_text' do
    it 'builds a FetchFieldText node and renders the ->> operator with a string key' do
      node = User.arel_table[:data].json_field_text('name')
      expect(node).to be_a(Arel::Nodes::Jsonb::FetchFieldText)
      expect(node.to_sql).to eq(%q("users"."data" ->> 'name'))
    end
  end

  describe '#json_path' do
    it 'builds a FetchPath node and renders the #> operator with a TextArray' do
      node = User.arel_table[:data].json_path('a', 'b')
      expect(node).to be_a(Arel::Nodes::Jsonb::FetchPath)
      expect(node.to_sql).to eq(%q("users"."data" #> ARRAY['a', 'b']))
    end

    it 'flattens an array argument' do
      node = User.arel_table[:data].json_path(%w[a b])
      expect(node.to_sql).to eq(%q("users"."data" #> ARRAY['a', 'b']))
    end
  end

  describe '#json_path_text' do
    it 'builds a FetchPathText node and renders the #>> operator with a TextArray' do
      node = User.arel_table[:data].json_path_text('a', 'b')
      expect(node).to be_a(Arel::Nodes::Jsonb::FetchPathText)
      expect(node.to_sql).to eq(%q("users"."data" #>> ARRAY['a', 'b']))
    end
  end

  # ── Table 9.48 ─────────────────────────────────────────────────────────

  describe '#contains' do
    it 'renders the @> operator with a JSON-serialized hash' do
      node = User.arel_table[:data].contains(a: 1)
      expect(node).to be_a(Arel::Nodes::Jsonb::Contains)
      expect(node.to_sql).to eq(%q("users"."data" @> '{"a":1}'))
    end

    it 'renders the @> operator with a JSON-serialized array' do
      node = User.arel_table[:data].contains([1, 2])
      expect(node.to_sql).to eq(%q("users"."data" @> '[1,2]'))
    end

    it 'renders the @> operator with a raw string' do
      node = User.arel_table[:data].contains('{"a":1}')
      expect(node.to_sql).to eq(%q("users"."data" @> '{"a":1}'))
    end

    it 'passes Arel nodes through unchanged' do
      other = Arel::Nodes::Jsonb::FetchField.new(User.arel_table[:data], Arel::Nodes::Quoted.new('inner'))
      node = User.arel_table[:data].contains(other)
      expect(node.to_sql).to eq(%q("users"."data" @> "users"."data" -> 'inner'))
    end
  end

  describe '#contained_by' do
    it 'renders the <@ operator with a JSON-serialized hash' do
      node = User.arel_table[:data].contained_by(a: 1)
      expect(node).to be_a(Arel::Nodes::Jsonb::ContainedBy)
      expect(node.to_sql).to eq(%q("users"."data" <@ '{"a":1}'))
    end
  end

  describe '#contains_key' do
    it 'renders the ? operator' do
      node = User.arel_table[:data].contains_key('name')
      expect(node).to be_a(Arel::Nodes::Jsonb::HasKey)
      expect(node.to_sql).to eq(%q("users"."data" ? 'name'))
    end
  end

  describe '#contains_any_key' do
    it 'renders the ?| operator with a TextArray' do
      node = User.arel_table[:data].contains_any_key('a', 'b')
      expect(node).to be_a(Arel::Nodes::Jsonb::HasAnyKey)
      expect(node.to_sql).to eq(%q("users"."data" ?| ARRAY['a', 'b']))
    end

    it 'flattens an array argument' do
      node = User.arel_table[:data].contains_any_key(%w[a b])
      expect(node.to_sql).to eq(%q("users"."data" ?| ARRAY['a', 'b']))
    end
  end

  describe '#contains_all_keys' do
    it 'renders the ?& operator with a TextArray' do
      node = User.arel_table[:data].contains_all_keys('a', 'b')
      expect(node).to be_a(Arel::Nodes::Jsonb::HasAllKeys)
      expect(node.to_sql).to eq(%q("users"."data" ?& ARRAY['a', 'b']))
    end
  end

  describe '#concat' do
    it 'renders the || operator with a JSON-serialized hash' do
      node = User.arel_table[:data].concat(x: 1)
      expect(node).to be_a(Arel::Nodes::Jsonb::Concat)
      expect(node.to_sql).to eq(%q("users"."data" || '{"x":1}'))
    end
  end

  describe '#delete_key' do
    it 'renders the - operator with a string' do
      node = User.arel_table[:data].delete_key('name')
      expect(node).to be_a(Arel::Nodes::Jsonb::DeleteKey)
      expect(node.to_sql).to eq(%q("users"."data" - 'name'))
    end
  end

  describe '#delete_keys' do
    it 'renders the - operator with a TextArray' do
      node = User.arel_table[:data].delete_keys('a', 'b')
      expect(node).to be_a(Arel::Nodes::Jsonb::DeleteKeys)
      expect(node.to_sql).to eq(%q("users"."data" - ARRAY['a', 'b']))
    end
  end

  describe '#delete_element' do
    it 'renders the - operator with an integer' do
      node = User.arel_table[:data].delete_element(0)
      expect(node).to be_a(Arel::Nodes::Jsonb::DeleteElement)
      expect(node.to_sql).to eq('"users"."data" - 0')
    end
  end

  describe '#delete_path' do
    it 'renders the #- operator with a TextArray' do
      node = User.arel_table[:data].delete_path('a', 'b')
      expect(node).to be_a(Arel::Nodes::Jsonb::DeletePath)
      expect(node.to_sql).to eq(%q("users"."data" #- ARRAY['a', 'b']))
    end
  end

  describe '#path_exists' do
    it 'renders the @? operator' do
      node = User.arel_table[:data].path_exists('$.foo')
      expect(node).to be_a(Arel::Nodes::Jsonb::PathExists)
      expect(node.to_sql).to eq(%q("users"."data" @? '$.foo'))
    end
  end

  describe '#path_match' do
    it 'renders the @@ operator' do
      node = User.arel_table[:data].path_match('$.foo > 0')
      expect(node).to be_a(Arel::Nodes::Jsonb::PathMatch)
      expect(node.to_sql).to eq(%q("users"."data" @@ '$.foo > 0'))
    end
  end

  describe 'chaining methods' do
    it 'composes json_field on a previous json_field result' do
      node = User.arel_table[:data].json_field('a').json_field('b')
      expect(node.to_sql).to eq(%q("users"."data" -> 'a' -> 'b'))
    end

    it 'composes json_field_text on a json_field result' do
      node = User.arel_table[:data].json_field('a').json_field_text('b')
      expect(node.to_sql).to eq(%q("users"."data" -> 'a' ->> 'b'))
    end

    it 'composes json_path on a json_field result' do
      node = User.arel_table[:data].json_field('a').json_path('b', 'c')
      expect(node.to_sql).to eq(%q("users"."data" -> 'a' #> ARRAY['b', 'c']))
    end
  end
end
