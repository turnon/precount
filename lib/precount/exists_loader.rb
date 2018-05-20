require 'forwardable'

module Precount
  class ExistsLoader

    extend Forwardable
    def_delegators :@relation, :pk_name, :ids, :reflections

    def initialize relation, asso
      @relation = relation
      @asso = asso
    end

    def assign record
      record.instance_variable_set "@#{asso}_exists", result.include?(record[pk_name])
    end

    private

    attr_reader :asso

    def result
      @result ||= source_relation.joins(joins_args).
        distinct(first_join.foreign_key).pluck(first_join.foreign_key).to_set
    end

    def reflection
      @reflection ||= reflections[asso]
    end

    def chaining
      @chaining ||= reflection.chain
    end

    def source_relation
      return @source_relation if @source_relation
      relation = first_join.klass.all.unscope(:order).where(first_join.foreign_key => ids)
      relation = relation.module_exec(&first_join.scope) if first_join.scope
      @source_relation = relation
    end

    def joins_args
      @joins_args ||= chaining[0..-2].map(&:source_reflection_name).
        reduce({}){ |asso, name| asso.blank? ? name : {name => asso} }
    end

    def first_join
      @first_join ||= chaining[-1]
    end

  end
end
