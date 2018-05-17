require 'forwardable'

module Precount
  class LoaderPerAssociation

    extend Forwardable
    def_delegators :@relation, :klass, :pk_name, :full_pk_name, :ids, :reflections,
      :precount_values, :preavg_values, :premax_values, :premin_values, :presum_values

    attr_reader :asso

    def initialize relation, asso
      @relation = relation
      @asso = asso
    end

    def result
      @result ||= (
        sql = ActiveRecord::Reflection::ThroughReflection === reflection ? from_through : not_from_through
        klass.connection.select_all(sql).
          each_with_object({}){ |row, rs| rs[row.delete('id')] = row }
      )
    end

    def count?
      return @counting if defined?(@counting)
      @counting = precount_values.include? asso
    end

    private

    def reflection
      @reflection ||= reflections[asso]
    end

    def associated_table
      @associated_table ||= reflection.klass.table_name
    end

    def aggregate_functions
      @aggregate ||= (
        agg = []
        agg << "COUNT(1) #{asso}_count" if count?
        preavg_values[asso].each{ |column| agg << "AVG(#{associated_table}.#{column}) avg_#{asso}_#{column}" }
        premax_values[asso].each{ |column| agg << "MAX(#{associated_table}.#{column}) max_#{asso}_#{column}" }
        premin_values[asso].each{ |column| agg << "MIN(#{associated_table}.#{column}) min_#{asso}_#{column}" }
        presum_values[asso].each{ |column| agg << "SUM(#{associated_table}.#{column}) sum_#{asso}_#{column}" }
        agg.join(', ')
      )
    end

    def wanted_columns
      @wanted_columns ||= (
        asso_pk_name = reflection.klass.primary_key.to_sym
        columns = [asso_pk_name] | preavg_values[asso] | premax_values[asso] | premin_values[asso] | presum_values[asso]
        columns.map{ |column| "#{associated_table}.#{column} #{column}" }.join(', ')
      )
    end

    def joining
      @joining ||= klass.joins(asso).where(pk_name => ids).unscope(:order)
    end

    def from_through
      parent_id = "#{klass.table_name}_id"
      id_pairs = joining.select("#{full_pk_name} #{parent_id}, #{wanted_columns}").distinct.to_sql
      "select #{parent_id} id, #{aggregate_functions} from (#{id_pairs}) #{associated_table} group by #{parent_id}"
    end

    def not_from_through
      joining.group(full_pk_name).select("#{full_pk_name} id, #{aggregate_functions}").to_sql
    end
  end
end
