require "precount/version"
require 'active_record'

module Precount
  class << self
    def toggle
      @working = !@working
    end

    def working?
      @working
    end
  end
end

module ActiveRecord
  class Relation
    alias_method :load_without_precount, :load
    alias_method :reset_without_precount, :reset
  end
end

Precount.toggle

require "precount/active_record"
