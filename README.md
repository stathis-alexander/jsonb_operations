# jsonb_operations

Arel nodes and ActiveRecord chain methods for PostgreSQL JSON(B) operators. See the PostgreSQL
[Json Functions and Operators](https://www.postgresql.org/docs/18/functions-json.html) documentation for more detail.

## Install

```ruby
gem 'jsonb_operations'
```

## ActiveRecord usage

### Predicate operators

Seven JSONB predicates chain off `where`. Three column shapes are accepted:
nested-hash kwargs (Rails-style with reflections), `'table.column'`, or an
Arel attribute.

```ruby
User.where.contains(data: { role: 'admin' })
# WHERE "users"."data" @> '{"role":"admin"}'

User.joins(:posts).where.contains(posts: { data: { published: true } })
# INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE "posts"."data" @> '{"published":true}'

User.where.contained_by(data: { role: 'admin', age: 30 })
# WHERE "users"."data" <@ '{"role":"admin","age":30}'

User.where.contains_key(data: 'email')
# WHERE "users"."data" ? 'email'

User.where.contains_any_key(data: %w[email phone])
# WHERE "users"."data" ?| ARRAY['email', 'phone']

User.where.contains_all_keys(data: %w[email phone])
# WHERE "users"."data" ?& ARRAY['email', 'phone']

User.where.path_exists(data: '$.profile.name')
# WHERE "users"."data" @? '$.profile.name'

User.where.path_match(data: '$.age > 21')
# WHERE "users"."data" @@ '$.age > 21'
```

### Fetch operators (`where.json_*(...).<comparator>(...)`)

Six fetch operators return a `JsonbExpression` that finalises into a relation
via a comparator or a JSONB predicate. Path ops take an array leaf in the
kwargs form.

```ruby
User.where.json_field_text(data: 'age').greater_than(21)
# WHERE "users"."data" ->> 'age' > 21

User.where.json_field_text(data: 'name').matches('Alice%')
# WHERE "users"."data" ->> 'name' ILIKE 'Alice%'

User.where.json_field_text(data: 'role').included_in(%w[admin editor])
# WHERE "users"."data" ->> 'role' IN ('admin', 'editor')

User.where.json_field_text(data: 'age').between(18..65)
# WHERE "users"."data" ->> 'age' BETWEEN 18 AND 65

User.where.json_path_text(data: %w[profile name]).equals('Alice')
# WHERE "users"."data" #>> ARRAY['profile', 'name'] = 'Alice'

User.where.json_path('users.data', 'profile').contains(admin: true)
# WHERE "users"."data" #> ARRAY['profile'] @> '{"admin":true}'

User.where.json_field(data: 'profile').contains(admin: true)
# WHERE "users"."data" -> 'profile' @> '{"admin":true}'

User.where.json_field(data: 'profile').contains_all_keys('email', 'phone')
# WHERE "users"."data" -> 'profile' ?& ARRAY['email', 'phone']
```

Available comparators: `equals`, `not_equals`, `greater_than`,
`greater_than_or_equal_to`, `less_than`, `less_than_or_equal_to`, `between`,
`included_in`, `not_included_in`, `matches`, `does_not_match`. Plus all 7
JSONB predicates (`contains`, `contained_by`, `contains_key`, `contains_any_key`,
`contains_all_keys`, `path_exists`, `path_match`).

### Arel node methods (for SELECT / ORDER / UPDATE)

Every operator is available on `Arel::Attributes::Attribute` and
`Arel::Nodes::Node`, so the value-producing fetch and mutation operators work
in any clause:

```ruby
User.select(User.arel_table[:data].json_field_text('name'))
# SELECT "users"."data" ->> 'name' FROM "users"

User.order(User.arel_table[:data].json_field_text('created_at').desc)
# SELECT "users".* FROM "users" ORDER BY "users"."data" ->> 'created_at' DESC

User.update_all(data: User.arel_table[:data].concat(active: true))
# UPDATE "users" SET "data" = "users"."data" || '{"active":true}'

User.update_all(data: User.arel_table[:data].delete_path('profile', 'private'))
# UPDATE "users" SET "data" = "users"."data" #- ARRAY['profile', 'private']
```

### Sorbet

`JsonbOperations` comes with a Tapioca compiler that defines all the RBI signatures needed for Sorbet. By default,
Tapioca will load and run the compiler. If using the `only:` configuration option for Tapioca, then you will need to
add the compiler for it to take effect:

```yml
gem:
  # ...
dsl:
  only:
    # ...
    JsonbOperations
    # ...
```

## Local development

Requires `asdf`, `docker`, and `direnv`.

```bash
asdf install
just setup
```

PostgreSQL database settings are defined in environment variables set in `.env` using `direnv`.
