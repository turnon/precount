module Precount
  module Arel

    def first_join_table_name
      first_join_table.table_alias || first_join_table.name
    end

    def join_column
      source.right[0].right.expr.children.
        find{ |c| !c.to_sql.index("\"areas\".\"id\"").nil? }.to_sql.split('=').
        find{ |field| field.index("\"areas\".\"id\"").nil? }
    end

    def first_join_table
      @first_join_table ||= source.right[0].left
    end
  end
end
