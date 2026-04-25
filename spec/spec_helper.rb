# typed: strict
# frozen_string_literal: true

require 'jsonb_operations'

# Connect to the local Postgres container (managed via `just docker up`).
ActiveRecord::Base.establish_connection(
  adapter:  'postgresql',
  host:     ENV.fetch('POSTGRES_HOST'),
  port:     ENV.fetch('POSTGRES_PORT').to_i,
  username: ENV.fetch('POSTGRES_USER'),
  password: ENV.fetch('POSTGRES_PASSWORD'),
  database: ENV.fetch('POSTGRES_DB'),
)

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  drop_table :comments, if_exists: true
  drop_table :posts,    if_exists: true
  drop_table :users,    if_exists: true

  create_table :users do |t|
    t.jsonb :data
  end

  create_table :posts do |t|
    t.references :user
    t.jsonb :data
  end

  create_table :comments do |t|
    t.references :post
    t.jsonb :data
  end
end

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.before do
    Comment.delete_all
    Post.delete_all
    User.delete_all
  end
end
