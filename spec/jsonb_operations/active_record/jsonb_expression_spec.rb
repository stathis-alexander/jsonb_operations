# typed: strict
# frozen_string_literal: true

RSpec.describe JsonbOperations::ActiveRecord::JsonbExpression do
  describe '#json_field_text via WhereChain' do
    before do
      User.create!(data: { name: 'Alice', age: 30 })
      User.create!(data: { name: 'Bob',   age: 25 })
    end

    it 'extracts text and applies equals' do
      expect(User.where.json_field_text(data: 'name').equals('Alice').count).to eq(1)
    end

    it 'extracts text and applies a numeric comparator (PG coerces text → numeric)' do
      expect(User.where.json_field_text(data: 'age').greater_than('25').count).to eq(1)
    end

    it 'works via the string column form' do
      expect(User.where.json_field_text('users.data', 'name').equals('Alice').count).to eq(1)
    end

    it 'works via Arel attribute passthrough' do
      expr = User.where.json_field_text(User.arel_table[:data], 'name')
      expect(expr.equals('Bob').count).to eq(1)
    end
  end

  describe '#json_field via WhereChain' do
    before do
      User.create!(data: { profile: { admin: true } })
      User.create!(data: { profile: { admin: false } })
    end

    it 'extracts a sub-jsonb and applies a JSONB containment predicate' do
      expect(User.where.json_field(data: 'profile').contains(admin: true).count).to eq(1)
    end
  end

  describe '#json_element / #json_element_text via WhereChain' do
    before do
      User.create!(data: [{ x: 1 }, { y: 2 }])
      User.create!(data: [{ z: 3 }])
    end

    it 'extracts an array element via -> and applies a JSONB key-existence predicate' do
      expect(User.where.json_element(data: 0).contains_key('x').count).to eq(1)
    end

    it 'extracts an array element via ->> and equals the text representation' do
      expect(User.where.json_element_text(data: 0).equals('{"z": 3}').count).to eq(1)
    end
  end

  describe '#json_path / #json_path_text via WhereChain' do
    before do
      User.create!(data: { profile: { name: 'Alice', tags: %w[admin] } })
      User.create!(data: { profile: { name: 'Bob',   tags: %w[user] } })
    end

    it 'walks a path via #>> with the kwargs leaf as an array' do
      expect(User.where.json_path_text(data: %w[profile name]).equals('Alice').count).to eq(1)
    end

    it 'walks a path via #> and applies a JSONB predicate on the sub-jsonb' do
      expect(User.where.json_path(data: %w[profile tags]).contains(['admin']).count).to eq(1)
    end

    it 'walks a path via the variadic positional form' do
      expect(User.where.json_path_text('users.data', 'profile', 'name').equals('Bob').count).to eq(1)
    end
  end

  describe 'standard comparators on json_field_text' do
    before do
      User.create!(data: { age: '10' })
      User.create!(data: { age: '20' })
      User.create!(data: { age: '30' })
      User.create!(data: { age: '40' })
    end

    it '#equals' do
      expect(User.where.json_field_text(data: 'age').equals('20').count).to eq(1)
    end

    it '#not_equals' do
      expect(User.where.json_field_text(data: 'age').not_equals('20').count).to eq(3)
    end

    it '#greater_than' do
      expect(User.where.json_field_text(data: 'age').greater_than('20').count).to eq(2)
    end

    it '#greater_than_or_equal_to' do
      expect(User.where.json_field_text(data: 'age').greater_than_or_equal_to('20').count).to eq(3)
    end

    it '#less_than' do
      expect(User.where.json_field_text(data: 'age').less_than('30').count).to eq(2)
    end

    it '#less_than_or_equal_to' do
      expect(User.where.json_field_text(data: 'age').less_than_or_equal_to('30').count).to eq(3)
    end

    it '#between (inclusive range)' do
      expect(User.where.json_field_text(data: 'age').between('20'..'30').count).to eq(2)
    end

    it '#included_in' do
      expect(User.where.json_field_text(data: 'age').included_in(%w[10 40]).count).to eq(2)
    end

    it '#not_included_in' do
      expect(User.where.json_field_text(data: 'age').not_included_in(%w[10 40]).count).to eq(2)
    end

    it '#matches' do
      expect(User.where.json_field_text(data: 'age').matches('2%').count).to eq(1)
    end

    it '#does_not_match' do
      expect(User.where.json_field_text(data: 'age').does_not_match('2%').count).to eq(3)
    end
  end

  describe 'JSONB predicate ops on the adapter' do
    before do
      User.create!(data: { profile: { admin: true,  email: 'a@x' } })
      User.create!(data: { profile: { admin: false, phone: '555' } })
    end

    it '#contains' do
      expect(User.where.json_field(data: 'profile').contains(admin: true).count).to eq(1)
    end

    it '#contained_by' do
      result = User.where.json_field(data: 'profile').contained_by(admin: true, email: 'a@x', extra: 'y')
      expect(result.count).to eq(1)
    end

    it '#contains_key' do
      expect(User.where.json_field(data: 'profile').contains_key('email').count).to eq(1)
    end

    it '#contains_any_key' do
      expect(User.where.json_field(data: 'profile').contains_any_key('email', 'phone').count).to eq(2)
    end

    it '#contains_all_keys' do
      expect(User.where.json_field(data: 'profile').contains_all_keys('admin', 'email').count).to eq(1)
    end

    it '#path_exists' do
      expect(User.where.json_field(data: 'profile').path_exists('$.admin ? (@ == true)').count).to eq(1)
    end

    it '#path_match' do
      expect(User.where.json_field(data: 'profile').path_match('$.admin == true').count).to eq(1)
    end
  end

  describe 'cross-table queries' do
    it 'filters joined post data via nested-hash kwargs' do
      user_a = User.create!(data: {})
      user_a.posts.create!(data: { title: 'hello' })
      user_b = User.create!(data: {})
      user_b.posts.create!(data: { title: 'goodbye' })

      result = User.joins(:posts).where.json_field_text(posts: { data: 'title' }).equals('hello')
      expect(result.distinct.count).to eq(1)
      expect(result.first).to eq(user_a)
    end

    it 'filters across multiple joined associations via nested-hash kwargs' do
      user = User.create!(data: {})
      post = user.posts.create!(data: {})
      post.comments.create!(data: { score: '5' })
      post.comments.create!(data: { score: '1' })

      result = User.joins(posts: :comments)
        .where.json_field_text(posts: { comments: { data: 'score' } })
        .greater_than('3')
      expect(result.distinct.count).to eq(1)
    end
  end
end
