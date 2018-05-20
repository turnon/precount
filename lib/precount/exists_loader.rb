require 'forwardable'
require 'precount/association'

module Precount
  class ExistsLoader

    include Association

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
      @result ||= joining_and_filter.
        distinct(first_join.foreign_key).pluck(first_join.foreign_key).to_set
    end

    def reflection
      @reflection ||= reflections[asso]
    end

  end
end
