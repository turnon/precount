require 'forwardable'
require 'precount/collection'

module Precount
  class ExistsLoader

    include Collection

    extend Forwardable
    def_delegators :@relation, :pk_name, :ids, :any_record

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
        distinct(full_fk_name).pluck(full_fk_name).to_set
    end

  end
end
