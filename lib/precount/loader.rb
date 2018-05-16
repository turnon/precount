require 'forwardable'

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
        count_asso = precount_values.include?(asso) && asso
        result = exec_precount asso, count_asso
        @records.each{ |rec| set_result rec, result, count_asso }
      end
    end

    private

    def pk_name
      @pk_name ||= klass.primary_key.to_sym
    end

    def full_pk_name
      @full_pk_name ||= "#{klass.table_name}.#{klass.primary_key}"
    end

    def ids
      @ids ||= @records.map{ |r| r[pk_name] }.uniq
    end

    def aggregate(asso, count_asso)
      table = reflections[asso].klass.table_name
      agg = []
      agg << "COUNT(1) #{asso}_count" if count_asso
      preavg_values[asso].each{ |column| agg << "AVG(#{table}.#{column}) avg_#{asso}_#{column}" }
      premax_values[asso].each{ |column| agg << "MAX(#{table}.#{column}) max_#{asso}_#{column}" }
      premin_values[asso].each{ |column| agg << "MIN(#{table}.#{column}) min_#{asso}_#{column}" }
      presum_values[asso].each{ |column| agg << "SUM(#{table}.#{column}) sum_#{asso}_#{column}" }
      agg.join(', ')
    end

    def want(asso)
      table = reflections[asso].klass.table_name
      asso_pk_name = reflections[asso].klass.primary_key.to_sym
      columns = [asso_pk_name] | preavg_values[asso] |
        premax_values[asso] | premin_values[asso] | presum_values[asso]
      columns.map{ |column| "#{table}.#{column} #{column}" }.join(', ')
    end

    def exec_precount asso, count_asso
      joining = klass.joins(asso).where(pk_name => ids).unscope(:order)
      refl = reflections[asso]
      aggregated_columns = aggregate(asso, count_asso)

      unless ActiveRecord::Reflection::ThroughReflection === refl
        sql = joining.group(full_pk_name).select("#{full_pk_name} id, #{aggregated_columns}").to_sql
        result = klass.connection.select_all(sql)
        return result.each_with_object({}){ |row, rs| rs[row.delete('id')] = row }
      end

      key = "#{klass.table_name}_id"
      table = reflections[asso].klass.table_name
      wanted_columns = "#{full_pk_name} #{key}, #{want(asso)}"
      id_pairs = joining.select(wanted_columns).distinct.to_sql
      q = klass.connection.select_all("select #{key} id, #{aggregated_columns} from (#{id_pairs}) #{table} group by #{key}")
      q.each_with_object({}){ |row, rs| rs[row.delete('id')] = row }
    end

    def set_result record, result, count_asso
      row = result[record[pk_name].to_s]

      if row.nil?
        record.instance_variable_set "@#{count_asso}_count", 0 if count_asso
        return
      end

      row.each_pair do |column, value|
        record.instance_variable_set "@#{column}", value
      end
    end
  end
end
