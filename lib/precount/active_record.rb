module ActiveRecord
  class Relation
    def load
      rt = load_without_precount
      return rt if @records.empty? || @precounted || !Precount.working?

      pk = klass.primary_key.to_sym
      pks = @records.map{|r| r[pk]}.uniq
      precounts_values.each do |asso|
        instance_var_name = "@#{asso}_count"
        result = exec_precount asso, pks
        @records.each{ |rec| set_count rec, pk, instance_var_name, result }
      end
      @precounted = true

      rt
    end

    def reset
      rt = reset_without_precount
      return rt if !Precount.working?
      @precounted = nil
      rt
    end

    private

    def exec_precount asso, pks
      joining = klass.joins(asso).where(klass.primary_key => pks).unscope(:order)
      group_key = "#{klass.table_name}.#{klass.primary_key}"
      refl = reflections[asso]

      unless ActiveRecord::Reflection::ThroughReflection === refl
        result = joining.group("#{group_key}").count
        return result.keys.each_with_object(result){ |k, h| h[k.to_s] = h.delete(k) }
      end

      asso_klass = refl.klass
      wanted_columns = "#{group_key} id, #{asso_klass.table_name}.#{asso_klass.primary_key} asso"
      id_pairs = joining.select(wanted_columns).distinct.to_sql
      q = klass.connection.select_all("select id, count(*) count_all from (#{id_pairs}) t group by id")
      q.each_with_object({}){ |row, rs| rs[row['id']] = row['count_all'] }
    end

    def set_count record, pk, var_name, counts
      c = counts[record[pk].to_s].to_i
      record.instance_variable_set var_name, c
    end
  end

  module Querying
    delegate :precounts, to: :all
  end

  module QueryMethods
    def precounts *args
      spawn.precounts!(*args)
    end

    def precounts! *args
      @precounts_values = (precounts_values | args)
      self
    end

    def precounts_values
      @precounts_values ||= []
    end
  end
end
