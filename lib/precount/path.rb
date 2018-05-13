module Precount
  class Path
    def initialize *path
      @path = path
    end

    def endpoints records, associations = @path.dup
      next_level = associations.shift
      next_records = records.flat_map{ |r| r.send next_level }
      associations.empty? ? next_records : endpoints(next_records, associations)
    end
  end
end
