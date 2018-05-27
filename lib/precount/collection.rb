module Precount
  module Collection

    # descendants should implement method `any_record` and `ids` and `asso`

    def full_fk_name
      joining_and_filter
      @full_fk_name
    end

    def joining_and_filter
      return @joining_and_filter if @joining_and_filter
      rel = any_record.send(asso).unscope(:order)
      i = rel.where_values.index{|w| Arel::Nodes::Equality === w && w.right == '$1' }
      @full_fk_name = rel.where_values.delete_at(i).to_sql.sub! /\s*\=.*/, ''
      rel.bind_values.pop
      @joining_and_filter = rel.where("#{@full_fk_name} IN (?)", ids)
    end

    def associated_table
      @associated_table ||= joining_and_filter.table_name
    end

  end
end
