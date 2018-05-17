require 'forwardable'
require 'precount/loader_per_association'

module Precount
  class Loader

    extend Forwardable
    def_delegators :@relation, :klass, :reflections, :all_precount_associations,
      :precount_values, :preavg_values, :premax_values, :premin_values, :presum_values

    def initialize relation
      @relation = relation
      @records = @relation.instance_variable_get :@records
    end

    def load!
      all_precount_associations.each do |asso|
        loader_per_asso = LoaderPerAssociation.new(self, asso)
        @records.each{ |rec| assign rec, loader_per_asso }
      end
    end

    def pk_name
      @pk_name ||= klass.primary_key.to_sym
    end

    def full_pk_name
      @full_pk_name ||= "#{klass.table_name}.#{klass.primary_key}"
    end

    def ids
      @ids ||= @records.map{ |r| r[pk_name] }.uniq
    end

    private

    def assign record, loader
      row = loader.result[record[pk_name].to_s]

      if row.nil?
        record.instance_variable_set "@#{loader.asso}_count", 0 if loader.count?
        return
      end

      row.each_pair do |column, value|
        record.instance_variable_set "@#{column}", value
      end
    end
  end
end
