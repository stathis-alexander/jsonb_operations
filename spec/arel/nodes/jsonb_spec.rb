# typed: strict
# frozen_string_literal: true

RSpec.describe Arel::Nodes::Jsonb do
  describe described_class::TextArray do
    it 'renders a single element' do
      expect(described_class.new(['x']).to_sql).to eq("ARRAY['x']")
    end

    it 'renders multiple elements joined with commas' do
      expect(described_class.new(%w[a b c]).to_sql).to eq("ARRAY['a', 'b', 'c']")
    end

    it 'coerces non-string values to strings' do
      expect(described_class.new([1, 2]).to_sql).to eq("ARRAY['1', '2']")
    end

    it 'escapes single quotes' do
      expect(described_class.new(["it's"]).to_sql).to eq("ARRAY['it''s']")
    end

    it 'is value-equal to another TextArray with the same values' do
      first = described_class.new(%w[a b])
      second = described_class.new(['a', 'b'])
      expect(first).to eq(second)
    end

    it 'hashes equally for equal values' do
      first = described_class.new(%w[a b])
      second = described_class.new(['a', 'b'])
      expect(first.hash).to eq(second.hash)
    end
  end

  describe described_class::FetchElement do
    it 'renders the -> operator with an integer' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new(0)).to_sql).to eq('"users"."data" -> 0')
    end
  end

  describe described_class::FetchField do
    it 'renders the -> operator with a string key' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('name')).to_sql).to eq(%q("users"."data" -> 'name'))
    end
  end

  describe described_class::FetchElementText do
    it 'renders the ->> operator with an integer' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new(0)).to_sql).to eq('"users"."data" ->> 0')
    end
  end

  describe described_class::FetchFieldText do
    it 'renders the ->> operator with a string key' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('name')).to_sql).to eq(%q("users"."data" ->> 'name'))
    end
  end

  describe described_class::FetchPath do
    it 'renders the #> operator with a TextArray' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Jsonb::TextArray.new(%w[a b])).to_sql).to eq(%q("users"."data" #> ARRAY['a', 'b']))
    end
  end

  describe described_class::FetchPathText do
    it 'renders the #>> operator with a TextArray' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Jsonb::TextArray.new(%w[a b])).to_sql).to eq(%q("users"."data" #>> ARRAY['a', 'b']))
    end
  end

  describe described_class::Contains do
    it 'renders the @> operator' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('{"a":1}')).to_sql).to eq(%q("users"."data" @> '{"a":1}'))
    end
  end

  describe described_class::ContainedBy do
    it 'renders the <@ operator' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('{"a":1}')).to_sql).to eq(%q("users"."data" <@ '{"a":1}'))
    end
  end

  describe described_class::HasKey do
    it 'renders the ? operator' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('name')).to_sql).to eq(%q("users"."data" ? 'name'))
    end
  end

  describe described_class::HasAnyKey do
    it 'renders the ?| operator with a TextArray' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Jsonb::TextArray.new(%w[a b])).to_sql).to eq(%q("users"."data" ?| ARRAY['a', 'b']))
    end
  end

  describe described_class::HasAllKeys do
    it 'renders the ?& operator with a TextArray' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Jsonb::TextArray.new(%w[a b])).to_sql).to eq(%q("users"."data" ?& ARRAY['a', 'b']))
    end
  end

  describe described_class::Concat do
    it 'renders the || operator' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('{"a":1}')).to_sql).to eq(%q("users"."data" || '{"a":1}'))
    end
  end

  describe described_class::DeleteKey do
    it 'renders the - operator with a string' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('name')).to_sql).to eq(%q("users"."data" - 'name'))
    end
  end

  describe described_class::DeleteKeys do
    it 'renders the - operator with a TextArray' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Jsonb::TextArray.new(%w[a b])).to_sql).to eq(%q("users"."data" - ARRAY['a', 'b']))
    end
  end

  describe described_class::DeleteElement do
    it 'renders the - operator with an integer' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new(0)).to_sql).to eq('"users"."data" - 0')
    end
  end

  describe described_class::DeletePath do
    it 'renders the #- operator with a TextArray' do
      expect(described_class.new(User.arel_table[:data], Arel::Nodes::Jsonb::TextArray.new(%w[a b])).to_sql).to eq(%q("users"."data" #- ARRAY['a', 'b']))
    end
  end

  describe described_class::PathExists do
    it 'renders the @? operator' do
      node = described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('$.foo'))
      expect(node.to_sql).to eq(%q("users"."data" @? '$.foo'))
    end
  end

  describe described_class::PathMatch do
    it 'renders the @@ operator' do
      node = described_class.new(User.arel_table[:data], Arel::Nodes::Quoted.new('$.foo > 0'))
      expect(node.to_sql).to eq(%q("users"."data" @@ '$.foo > 0'))
    end
  end

  describe 'composition' do
    it 'composes nested fetch operators with parens via the visitor' do
      inner = described_class::FetchField.new(User.arel_table[:data], Arel::Nodes::Quoted.new('a'))
      outer = described_class::FetchField.new(inner, Arel::Nodes::Quoted.new('b'))
      expect(outer.to_sql).to eq(%q("users"."data" -> 'a' -> 'b'))
    end
  end
end
