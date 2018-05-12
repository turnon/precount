require "precount/version"
require 'active_record'

module ActiveRecord
  class Relation
    alias_method :load_without_precount, :load

    def load
      rt = load_without_precount
      return rt if @records.empty?

      fk_values = @records.map(&:id).uniq
      precounts_values.each do |asso|
        instance_var_name = "@#{asso}_count"
        result = exec_precount asso, fk_values
        @records.each{ |rec| set_count rec, instance_var_name, result }
      end

      rt
    end

    private

    def exec_precount asso, fk_values
      refl = reflections[asso]
      refl.klass.where({refl.foreign_key => fk_values}).group(refl.foreign_key).count
    end

    def set_count record, var_name, counts
      c = counts[record.id] || 0
      record.instance_variable_set var_name, c
    end
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
