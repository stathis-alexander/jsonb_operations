# typed: strict
# frozen_string_literal: true

RSpec.describe JsonbOperations::ActiveRecord::WhereChain do
  describe '#contains' do
    before do
      User.create!(data: { role: 'admin', age: 30 })
      User.create!(data: { role: 'user',  age: 25 })
    end

    it 'filters via nested-hash kwargs on the primary table' do
      expect(User.where.contains(data: { role: 'admin' }).count).to eq(1)
    end

    it 'filters via the string column form' do
      expect(User.where.contains('users.data', { role: 'admin' }).count).to eq(1)
    end

    it 'filters via an Arel attribute' do
      expect(User.where.contains(User.arel_table[:data], { role: 'admin' }).count).to eq(1)
    end

    it 'filters across a single joined association' do
      admin = User.find_by!('data @> ?', { role: 'admin' }.to_json)
      admin.posts.create!(data: { published: true })
      admin.posts.create!(data: { published: false })

      result = User.joins(:posts).where.contains(posts: { data: { published: true } })
      expect(result.count).to eq(1)
      expect(result.first).to eq(admin)
    end

    it 'filters across multiple joined associations' do
      admin = User.find_by!('data @> ?', { role: 'admin' }.to_json)
      post = admin.posts.create!(data: {})
      post.comments.create!(data: { score: 5 })
      post.comments.create!(data: { score: 1 })

      result = User.joins(posts: :comments).where.contains(posts: { comments: { data: { score: 5 } } })
      expect(result.count).to eq(1)
    end
  end

  describe '#contained_by' do
    before do
      User.create!(data: { role: 'admin' })
      User.create!(data: { role: 'admin', age: 30 })
    end

    it 'matches rows whose JSON is a subset of the given value' do
      result = User.where.contained_by(data: { role: 'admin', age: 30, extra: true })
      expect(result.count).to eq(2)
    end

    it 'matches no rows when the value omits a present key' do
      result = User.where.contained_by(data: { role: 'admin' })
      expect(result.count).to eq(1)
    end
  end

  describe '#contains_key' do
    before do
      User.create!(data: { email: 'a@example.com' })
      User.create!(data: { phone: '555-0100' })
    end

    it 'matches rows whose top-level JSON contains the key' do
      expect(User.where.contains_key(data: 'email').count).to eq(1)
    end

    it 'works via the string column form' do
      expect(User.where.contains_key('users.data', 'phone').count).to eq(1)
    end
  end

  describe '#contains_any_key' do
    before do
      User.create!(data: { email: 'a@example.com' })
      User.create!(data: { phone: '555-0100' })
      User.create!(data: { other: 'x' })
    end

    it 'matches rows that have any of the listed keys (kwargs leaf is array)' do
      expect(User.where.contains_any_key(data: %w[email phone]).count).to eq(2)
    end

    it 'matches rows that have any of the listed keys (variadic positional)' do
      expect(User.where.contains_any_key('users.data', 'email', 'phone').count).to eq(2)
    end
  end

  describe '#contains_all_keys' do
    before do
      User.create!(data: { email: 'a@example.com', phone: '555-0100' })
      User.create!(data: { email: 'b@example.com' })
    end

    it 'matches rows that have every listed key (kwargs leaf is array)' do
      expect(User.where.contains_all_keys(data: %w[email phone]).count).to eq(1)
    end

    it 'matches rows that have every listed key (variadic positional)' do
      expect(User.where.contains_all_keys('users.data', 'email', 'phone').count).to eq(1)
    end
  end

  describe '#path_exists' do
    before do
      User.create!(data: { profile: { name: 'Alice' } })
      User.create!(data: { profile: nil })
      User.create!(data: {})
    end

    it 'matches rows where the JSONPath returns at least one item' do
      expect(User.where.path_exists(data: '$.profile.name').count).to eq(1)
    end
  end

  describe '#path_match' do
    before do
      User.create!(data: { age: 30 })
      User.create!(data: { age: 18 })
    end

    it 'matches rows where the JSONPath predicate is true' do
      expect(User.where.path_match(data: '$.age > 21').count).to eq(1)
    end
  end

  describe 'chaining further conditions onto the returned relation' do
    before do
      User.create!(data: { role: 'admin', email: 'a@x' })
      User.create!(data: { role: 'admin' })
      User.create!(data: { role: 'user', email: 'b@x' })
    end

    it 'AND-combines two jsonb predicate chains' do
      result = User.where.contains(data: { role: 'admin' }).where.contains_key(data: 'email')
      expect(result.count).to eq(1)
    end

    it 'preserves a prior standard where when a jsonb predicate is appended' do
      target_id = User.find_by!('data @> ?', { role: 'admin', email: 'a@x' }.to_json).id
      result = User.where(id: target_id).where.contains_key(data: 'email')
      expect(result.count).to eq(1)
    end

    it 'preserves a prior jsonb predicate when a standard where is appended' do
      result = User.where.contains(data: { role: 'admin' }).where('id > ?', 0)
      expect(result.count).to eq(2)
    end

    it 'AND-combines a fetch chain with a standard where' do
      User.delete_all
      User.create!(data: { age: 30, email: 'a@x' })
      User.create!(data: { age: 30 })
      result = User.where.json_field_text(data: 'age').equals('30').where.contains_key(data: 'email')
      expect(result.count).to eq(1)
    end
  end

  describe 'argument validation' do
    it 'raises when kwargs are mixed with a positional column' do
      expect do
        User.where.contains('users.data', data: { x: 1 })
      end.to raise_error(ArgumentError, /cannot mix positional column with keyword args/)
    end

    it 'raises when more than one column key is given at a level' do
      expect do
        User.where.contains(data: { x: 1 }, posts: { data: {} })
      end.to raise_error(ArgumentError, /expected exactly one column or association key/)
    end

    it 'raises for an unknown column or association name' do
      expect do
        User.where.contains(nope: 'x')
      end.to raise_error(ArgumentError, /no column or association `nope`/)
    end

    it 'raises for an association ref without a nested hash' do
      expect do
        User.where.contains(posts: 'x')
      end.to raise_error(ArgumentError, /association `posts` requires a nested hash/)
    end

    it 'raises for an unsupported column reference type' do
      expect do
        User.where.contains(:data, { x: 1 })
      end.to raise_error(ArgumentError, /unsupported column reference/)
    end

    it 'raises for a string column without a table prefix' do
      expect do
        User.where.contains('data', { x: 1 })
      end.to raise_error(ArgumentError, /expected 'table.column'/)
    end
  end
end
