# typed: strict
# frozen_string_literal: true

module JsonbOperations::ActiveRecord; end

require_relative 'active_record/jsonb_expression'
require_relative 'active_record/where_chain'

ActiveSupport.on_load(:active_record, yield: true) do
  require 'active_record/relation'

  ActiveRecord::QueryMethods::WhereChain.include(JsonbOperations::ActiveRecord::WhereChain)
end
