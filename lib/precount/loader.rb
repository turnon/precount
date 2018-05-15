require 'forwardable'

module Precount
  class Loader

    extend Forwardable
    def_delegators :@relation, :klass, :precounts_values, :reflections

    def initialize relation
      @relation = relation
      @records = @relation.instance_variable_get :@records
    end

    def load!
      precounts_values.each do |asso|
        instance_var_name = "@#{asso}_count"
        result = exec_precount asso
        @records.each{ |rec| set_count rec, instance_var_name, result }
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

    def exec_precount asso
      joining = klass.joins(asso).where(pk_name => ids).unscope(:order)
      refl = reflections[asso]

      unless ActiveRecord::Reflection::ThroughReflection === refl
        result = joining.group(full_pk_name).count
        return result.keys.each_with_object(result){ |k, h| h[k.to_s] = h.delete(k) }
      end

      asso_klass = refl.klass
      wanted_columns = "#{full_pk_name} id, #{asso_klass.table_name}.#{asso_klass.primary_key} asso"
      id_pairs = joining.select(wanted_columns).distinct.to_sql
      q = klass.connection.select_all("select id, count(*) count_all from (#{id_pairs}) t group by id")
      q.each_with_object({}){ |row, rs| rs[row['id']] = row['count_all'] }
    end

    def set_count record, var_name, counts
      c = counts[record[pk_name].to_s].to_i
      record.instance_variable_set var_name, c
    end
  end
end
