module Precount
  module Collection

    # descendants should implement method `any_record` and `ids`

    attr_reader :full_fk_name

    def joining_and_filter
      rel = any_record.send(asso).unscope(:order)
      i = rel.where_values.index{|w| Arel::Nodes::Equality === w && w.left.relation.engine == ActiveRecord::Base }
      @full_fk_name = rel.where_values.delete_at(i).to_sql.sub! /\s*\=.*/, ''
      rel.bind_values.pop
      rel.where("#{full_fk_name} IN (?)", ids)
    end
  end
end
