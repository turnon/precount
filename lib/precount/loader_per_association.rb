require 'forwardable'
require 'precount/collection'

module Precount
  class LoaderPerAssociation

    include Collection

    extend Forwardable
    def_delegators :@relation, :pk_name, :ids, :any_record,
      :precount_values, :preavg_values, :premax_values, :premin_values, :presum_values

    def initialize relation, asso
      @relation = relation
      @asso = asso
      query!
    end

    def assign record
      row = result[record[pk_name].to_s]

      if row.nil?
        record.instance_variable_set "@#{asso}_count", 0 if count?
        return
      end

      row.each_pair do |column, value|
        value = column_types[column].type_cast value
        record.instance_variable_set "@#{column}", value
      end
    end

    private

    attr_reader :asso, :result, :column_types

    def query!
      sql = ActiveRecord::Reflection::ThroughReflection === reflection ? from_through : not_from_through
      rt = klass.connection.select_all(sql)
      @column_types = rt.column_types
      @result = rt.each_with_object({}){ |row, rs| rs[row.delete('id')] = row }
    end

    def count?
      return @counting if defined?(@counting)
      @counting = precount_values.include? asso
    end

    def reflection
      @reflection ||= klass.reflections[asso]
    end

    def from_through?
      ActiveRecord::Reflection::ThroughReflection === reflection
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
        columns.map{ |column| "#{associated_table}.#{column}" }.join(', ')
      )
    end

    def klass
      @klass ||= any_record.class
    end

    def from_through
      parent_id = "associated_#{full_fk_name}_id".gsub(/[\W|_]+/, '_')
      id_pairs = joining_and_filter.select("#{full_fk_name} #{parent_id}, #{wanted_columns}").distinct.to_sql
      "select #{parent_id} id, #{aggregate_functions} from (#{id_pairs}) #{associated_table} group by #{parent_id}"
    end

    def not_from_through
      joining_and_filter.group(full_fk_name).
        select("#{full_fk_name} id, #{aggregate_functions}").to_sql
    end
  end
end
