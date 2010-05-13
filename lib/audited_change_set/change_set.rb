module AuditedChangeSet
  class ChangeSet
    include Enumerable

    def self.for_auditable(klass, id, fields=nil, change_id=nil)
      new(klass.find(id), fields, change_id)
    end

    def initialize(auditable, fields=nil, change_id=nil)
      @auditable = auditable
      @fields = fields
      @change_id = change_id
    end

    delegate :name, :to => :@auditable, :prefix => :auditable

    def each(&block)
      changes.each(&block)
    end

    def changed_fields
      Change.field_names_for_audits(@auditable.audits).sort
    end

  private

    def changes
      @changes ||= Change.for_audits(@auditable.audits, @fields, @change_id)
    end
  end
end
