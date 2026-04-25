# typed: strict
# frozen_string_literal: true

require 'active_record'
require 'active_support/core_ext/object/json'

require_relative 'jsonb_operations/version'
require_relative 'jsonb_operations/arel'

Arel::Nodes::Node.include(JsonbOperations::Arel::NodeMethods)
Arel::Attributes::Attribute.include(JsonbOperations::Arel::NodeMethods)

require_relative 'jsonb_operations/active_record'
