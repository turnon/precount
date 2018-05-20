module Precount
  module Association

    # descendants should implement method `reflection` and `ids`

    protected

    def joining_and_filter
      @joining_and_filter ||= source_relation.joins(joins_args)
    end

    def full_fk_name
      @full_fk_name ||= "#{first_join.klass.table_name}.#{first_join.foreign_key}"
    end

    private

    def chaining
      @chaining ||= reflection.chain
    end

    def source_relation
      return @source_relation if @source_relation
      relation = first_join.klass.all.unscope(:order).where(first_join.foreign_key => ids)
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
  end
end
