# typed: strict
# frozen_string_literal: true

# rubocop:disable Rails/SkipsModelValidations -- exercising update_all with mutation nodes is the point of this file

RSpec.context 'with JSONB Arel nodes in standard AR clauses' do
  describe 'SELECT' do
    before do
      User.create!(data: { name: 'Alice', age: 30 })
      User.create!(data: { name: 'Bob',   age: 25 })
    end

    it 'projects an extracted text via json_field_text' do
      values = User.select(User.arel_table[:data].json_field_text('name').as('extracted')).map { |u| u['extracted'] }
      expect(values).to contain_exactly('Alice', 'Bob')
    end

    it 'projects a sub-jsonb via json_field' do
      values = User.select(User.arel_table[:data].json_field('age').as('extracted')).map { |u| u['extracted'] }
      expect(values).to contain_exactly(30, 25)
    end

    it 'projects a mutated jsonb via delete_key (mutation node)' do
      target = User.create!(data: { name: 'Carol', secret: 'shh' })
      values = User
        .where(id: target.id)
        .select(User.arel_table[:data].delete_key('secret').as('cleaned'))
        .map { |u| u['cleaned'] }
      expect(values).to eq([{ 'name' => 'Carol' }])
    end

    it 'composes a fetch projection with a where chain on the same column' do
      sql = User.where.contains(data: { name: 'Alice' })
        .select(User.arel_table[:data].json_field_text('age').as('age'))
        .to_sql
      expect(sql).to include(%q("users"."data" ->> 'age' AS age))
      expect(sql).to include(%q(WHERE "users"."data" @> '{"name":"Alice"}'))
    end
  end

  describe 'pluck' do
    before do
      User.create!(data: { name: 'Alice', age: '30' })
      User.create!(data: { name: 'Bob',   age: '25' })
    end

    it 'plucks an extracted text via a fetch node' do
      values = User.pluck(User.arel_table[:data].json_field_text('name'))
      expect(values).to contain_exactly('Alice', 'Bob')
    end

    it 'plucks the result of a mutation node' do
      values = User.pluck(User.arel_table[:data].delete_key('age'))
      expect(values).to contain_exactly({ 'name' => 'Alice' }, { 'name' => 'Bob' })
    end
  end

  describe 'ORDER BY' do
    before do
      User.create!(data: { name: 'Charlie' })
      User.create!(data: { name: 'Alice' })
      User.create!(data: { name: 'Bob' })
    end

    it 'orders ascending by an extracted text' do
      names = User
        .order(User.arel_table[:data].json_field_text('name').asc)
        .pluck(User.arel_table[:data].json_field_text('name'))
      expect(names).to eq(%w[Alice Bob Charlie])
    end

    it 'orders descending by an extracted text' do
      names = User
        .order(User.arel_table[:data].json_field_text('name').desc)
        .pluck(User.arel_table[:data].json_field_text('name'))
      expect(names).to eq(%w[Charlie Bob Alice])
    end
  end

  describe 'UPDATE (mutation nodes)' do
    it 'merges a hash into the column via concat (||)' do
      user = User.create!(data: { name: 'Alice' })
      User.where(id: user.id).update_all(data: User.arel_table[:data].concat(active: true))
      expect(user.reload.data).to eq('name' => 'Alice', 'active' => true)
    end

    it 'removes a top-level key via delete_key (-)' do
      user = User.create!(data: { name: 'Alice', secret: 'shh' })
      User.where(id: user.id).update_all(data: User.arel_table[:data].delete_key('secret'))
      expect(user.reload.data).to eq('name' => 'Alice')
    end

    it 'removes multiple keys via delete_keys (- text[])' do
      user = User.create!(data: { name: 'Alice', a: 1, b: 2, c: 3 })
      User.where(id: user.id).update_all(data: User.arel_table[:data].delete_keys('a', 'b'))
      expect(user.reload.data).to eq('name' => 'Alice', 'c' => 3)
    end

    it 'removes an array element via delete_element (- integer)' do
      user = User.create!(data: %w[x y z])
      User.where(id: user.id).update_all(data: User.arel_table[:data].delete_element(1))
      expect(user.reload.data).to eq(%w[x z])
    end

    it 'removes a nested element via delete_path (#-)' do
      user = User.create!(data: { profile: { name: 'Alice', private: 'shh' } })
      User.where(id: user.id).update_all(data: User.arel_table[:data].delete_path('profile', 'private'))
      expect(user.reload.data).to eq('profile' => { 'name' => 'Alice' })
    end
  end
end

# rubocop:enable Rails/SkipsModelValidations
