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
