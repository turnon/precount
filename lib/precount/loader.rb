require 'forwardable'
require 'precount/count_loader'
require 'precount/exists_loader'

module Precount
  class Loader

    extend Forwardable
    def_delegators :@relation, :all_precount_associations,
      :precount_values, :preavg_values, :premax_values, :premin_values, :presum_values, :prexists_values

    def initialize relation
      @relation = relation
      @records = relation.instance_variable_get :@records
    end

    def load!
      all_precount_associations.each do |asso|
        count_loader = CountLoader.new(self, asso)
        @records.each{ |rec| count_loader.assign rec }
      end
      prexists_values.each do |asso|
        xloader = ExistsLoader.new(self, asso)
        @records.each{ |rec| xloader.assign rec }
      end
    end

    def any_record
      @record ||= @records[0]
    end

    def key_name asso
      refl = adjacent_reflection(asso)
      refl.macro == :belongs_to ? refl.foreign_key : pk_name
    end

    def bind_values asso
      refl = adjacent_reflection(asso)
      refl.macro == :belongs_to ? fks(refl.foreign_key) : ids
    end

    private

    def adjacent_reflection asso
      @relation.reflections[asso].chain[-1]
    end

    def pk_name
      @pk_name ||= any_record.class.primary_key.to_sym
    end

    def ids
      @ids ||= @records.map{ |r| r[pk_name] }.uniq
    end

    def fks fk_name
      (@fks ||= Hash.new{ |h, k| h[k] = @records.map{ |r| r[k] }.uniq })[fk_name]
    end

  end
end
