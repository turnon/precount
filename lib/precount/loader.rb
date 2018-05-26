require 'forwardable'
require 'precount/loader_per_association'
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
        loader_per_asso = LoaderPerAssociation.new(self, asso)
        @records.each{ |rec| loader_per_asso.assign rec }
      end
      prexists_values.each do |asso|
        xloader = ExistsLoader.new(self, asso)
        @records.each{ |rec| xloader.assign rec }
      end
    end

    def pk_name
      @pk_name ||= any_record.class.primary_key.to_sym
    end

    def ids
      @ids ||= @records.map{ |r| r[pk_name] }.uniq
    end

    def any_record
      @record ||= @records[0]
    end
  end
end
