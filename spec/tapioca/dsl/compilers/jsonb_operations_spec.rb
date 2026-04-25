# typed: strict
# frozen_string_literal: true

require 'tapioca/internal'
Dir.glob("#{Tapioca::LIB_ROOT_DIR}/tapioca/dsl/compilers/*.rb").each { |f| require f }
Gem.find_files('tapioca/dsl/compilers/*.rb').each { |f| require f }

RSpec.describe Tapioca::Dsl::Compilers::JsonbOperations do
  # Pipeline.run yields each (constant, RBI::File) and returns whatever the
  # block returns; we collect the rendered RBI strings keyed by constant name.
  define_method(:run_compiler) do |*constants|
    pipeline = Tapioca::Dsl::Pipeline.new(
      requested_constants: constants,
      requested_compilers: [described_class],
    )
    pipeline.run { |constant, rbi_file| [constant.name, rbi_file.string] }.to_h
  end

  describe 'against a PG-connected model' do
    let(:rbi) { run_compiler(User).fetch('User') }

    it 'wraps WhereChain methods in a model-level module included in the chain class' do
      expect(rbi).to include('module GeneratedJsonbRelationMethods')
      expect(rbi).to include('class PrivateRelationWhereChain')
      expect(rbi).to include('include User::GeneratedJsonbRelationMethods')
    end

    it 'gives every predicate operator a sig returning the model relation' do
      JsonbOperations::ActiveRecord::WhereChain
        .instance_methods(false)
        .grep_v(/^json_/)
        .each do |op|
          expect(rbi).to match(
            /sig \{ params\(args: T\.untyped, kwargs: T\.untyped\)\.returns\(User::PrivateRelation\) \}\s+def #{op}\(\*args, \*\*kwargs\); end/,
          )
        end
    end

    it 'gives every fetch operator a sig returning the per-chain JsonbExpression' do
      [:json_element, :json_field, :json_element_text, :json_field_text, :json_path, :json_path_text].each do |op|
        expect(rbi).to match(
          /sig \{ params\(args: T\.untyped, kwargs: T\.untyped\)\.returns\(User::PrivateRelationWhereChain::JsonbExpression\) \}\s+def #{op}\(\*args, \*\*kwargs\); end/,
        )
      end
    end

    it 'nests a JsonbExpression class subclassing the base, including its methods module' do
      expect(rbi).to include('class JsonbExpression < ::JsonbOperations::ActiveRecord::JsonbExpression')
      expect(rbi).to include('include User::PrivateRelationWhereChain::GeneratedJsonbExpressionMethods')
    end

    it 'gives every comparator on JsonbExpression a sig returning the model relation' do
      [
        :equals,
        :not_equals,
        :greater_than,
        :greater_than_or_equal_to,
        :less_than,
        :less_than_or_equal_to,
        :between,
        :included_in,
        :not_included_in,
        :matches,
        :does_not_match,
      ].each do |op|
        expect(rbi).to match(
          /sig \{ params\(value: T\.untyped\)\.returns\(User::PrivateRelation\) \}\s+def #{op}\(value\); end/,
        )
      end
    end

    it 'preserves variadic shape on contains_any_key / contains_all_keys with PrivateRelation return' do
      [:contains_any_key, :contains_all_keys].each do |op|
        expect(rbi).to match(
          /sig \{ params\(keys: T\.untyped\)\.returns\(User::PrivateRelation\) \}\s+def #{op}\(\*keys\); end/,
        )
      end
    end

    it 'emits the parallel association-relation chain returning PrivateAssociationRelation' do
      expect(rbi).to include('module GeneratedJsonbAssociationRelationMethods')
      expect(rbi).to include('class PrivateAssociationRelationWhereChain')
      expect(rbi).to include('include User::GeneratedJsonbAssociationRelationMethods')
      expect(rbi).to match(
        /sig \{ params\(args: T\.untyped, kwargs: T\.untyped\)\.returns\(User::PrivateAssociationRelation\) \}\s+def contains\(\*args, \*\*kwargs\); end/,
      )
      expect(rbi).to match(
        /sig \{ params\(args: T\.untyped, kwargs: T\.untyped\)\.returns\(User::PrivateAssociationRelationWhereChain::JsonbExpression\) \}\s+def json_field_text\(\*args, \*\*kwargs\); end/,
      )
      expect(rbi).to match(
        /sig \{ params\(value: T\.untyped\)\.returns\(User::PrivateAssociationRelation\) \}\s+def equals\(value\); end/,
      )
    end
  end

  describe '.gather_constants' do
    it 'includes PG-connected AR models' do
      expect(described_class.gather_constants).to include(User)
    end

    it 'excludes models whose connection adapter is not postgresql' do
      stub_klass = Class.new(ActiveRecord::Base)
      sqlite_config = instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, adapter: 'sqlite3')
      allow(stub_klass).to receive_messages(name: 'NonPgModel', connection_db_config: sqlite_config)

      expect(described_class.gather_constants).not_to include(stub_klass)
    end

    it 'excludes abstract classes even on a postgres connection' do
      stub_klass = Class.new(ActiveRecord::Base) do
        self.abstract_class = true
      end
      pg_config = instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, adapter: 'postgresql')
      allow(stub_klass).to receive_messages(name: 'AbstractPgModel', connection_db_config: pg_config)

      expect(described_class.gather_constants).not_to include(stub_klass)
    end
  end
end
