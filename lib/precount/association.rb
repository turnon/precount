module Precount
  module Association

    # descendants should implement method `reflection` and `ids`

    protected

    def joining_and_filter
      @joining_and_filter ||= source_relation.joins(joins_args)
    end

    def full_fk_name
      @full_fk_name ||=
        if has_and_belongs_to_many?
          "#{reflection.join_table}.#{reflection.foreign_key}"
        else
          "#{first_join.klass.table_name}.#{first_join.foreign_key}"
        end
    end

    private

    def chaining
      @chaining ||= (reflection.chain[0..-2].reject{ |c| c.klass.name =~ /^HABTM_/ } << reflection.chain[-1])
    end

    def source_relation
      return @source_relation if @source_relation
      relation = first_join.klass.all.unscope(:order)
      relation = has_and_belongs_to_many? ? with_join_table(relation) : relation.where(first_join.foreign_key => ids)
      relation = relation.module_exec(&first_join.scope) if first_join.scope
      @source_relation = relation
    end

    def joins_args
      @joins_args ||= chaining[0..-2].map(&:source_reflection_name).
        reduce({}){ |asso, name| asso.blank? ? name : {name => asso} }
    end

    def first_join
      @first_join ||= chaining[-1]
    end

    def with_join_table relation
      mapping = "#{full_fk_name} = #{reflection.table_name}.#{reflection.association_primary_key}"
      join_st = "INNER JOIN #{reflection.join_table} ON #{mapping}"
      filter_st = "#{reflection.join_table}.#{reflection.foreign_key} IN (?)"
      relation.joins(join_st).where(filter_st, ids)
    end

    def has_and_belongs_to_many?
      reflection.macro == :has_and_belongs_to_many
    end
  end
end
