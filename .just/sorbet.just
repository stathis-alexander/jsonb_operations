set working-directory := '..'

check:
    bundle exec srb tc

gems:
    bundle exec tapioca gems

dsl:
    bundle exec tapioca dsl

generate: gems dsl
