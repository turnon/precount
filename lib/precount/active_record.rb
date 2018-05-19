require 'precount/loader'

module ActiveRecord
  class Relation
    def load
      rt = load_without_precount
      return rt if @records.empty? || @precounted || !Precount.working?

      Precount::Loader.new(self).load!
      @precounted = true
      rt
    end

    def reset
      rt = reset_without_precount
      return rt if !Precount.working?
      @precounted = nil
      rt
    end
  end

  module Querying
    delegate :precount, :prexists, :preavg, :premax, :premin, :presum, to: :all
  end

  module QueryMethods
    def all_precount_associations
      @all_precount_associations ||=
        precount_values | preavg_values.keys |
        premax_values.keys | premin_values.keys | presum_values.keys
    end
  end

  [:count, :xists].each do |q|
    QueryMethods.class_eval <<-RUBY, __FILE__, __LINE__
      def pre#{q} *args
        spawn.pre#{q}!(*args)
      end

      def pre#{q}! *args
        @pre#{q}_values = (pre#{q}_values | args.map(&:to_sym))
        self
      end

      def pre#{q}_values
        @pre#{q}_values ||= []
      end
    RUBY
  end

  [:avg, :max, :min, :sum].each do |q|
    QueryMethods.class_eval <<-RUBY, __FILE__, __LINE__
      def pre#{q}(model_attrs)
        spawn.pre#{q}!(model_attrs)
      end

      def pre#{q}!(model_attrs)
        v = pre#{q}_values
        model_attrs.each_pair do |model, attrs|
          v[model.to_sym].concat(Array(attrs).map(&:to_sym)).uniq!
        end
        self
      end

      def pre#{q}_values
        @pre#{q} ||= Hash.new{ |h, k| h[k] = [] }
      end
    RUBY
  end
end
