# typed: strict
# frozen_string_literal: true

module JsonbOperations::Arel::Visitors
  include Kernel

  INFIX_OPERATORS = {
    'FetchElement' => ' -> ',
    'FetchField' => ' -> ',
    'FetchElementText' => ' ->> ',
    'FetchFieldText' => ' ->> ',
    'FetchPath' => ' #> ',
    'FetchPathText' => ' #>> ',
    'Contains' => ' @> ',
    'ContainedBy' => ' <@ ',
    'HasKey' => ' ? ',
    'HasAnyKey' => ' ?| ',
    'HasAllKeys' => ' ?& ',
    'Concat' => ' || ',
    'DeleteKey' => ' - ',
    'DeleteKeys' => ' - ',
    'DeleteElement' => ' - ',
    'DeletePath' => ' #- ',
    'PathExists' => ' @? ',
    'PathMatch' => ' @@ ',
  }.freeze #: Hash[String, String]

  INFIX_OPERATORS.each do |node_name, operator|
    define_method(:"visit_Arel_Nodes_Jsonb_#{node_name}") do |o, collector|
      collector = send(:visit, o.left, collector)
      collector << operator
      send(:visit, o.right, collector)
    end
  end

  #: (Arel::Nodes::Jsonb::TextArray, untyped) -> untyped
  def visit_Arel_Nodes_Jsonb_TextArray(o, collector) # rubocop:disable Naming/MethodName -- Arel visitor dispatch requires this exact naming convention
    conn = send(:instance_variable_get, :@connection)
    collector << 'ARRAY['
    o.values.each_with_index do |v, i|
      collector << ', ' if i > 0
      collector << conn.quote(v)
    end
    collector << ']'
    collector
  end
end

Arel::Visitors::PostgreSQL.prepend(JsonbOperations::Arel::Visitors)
