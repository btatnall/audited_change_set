module AuditedChangeSet
  class Change
    module Hooks
      def self.included(mod)
        mod.extend ClassMethods
      end

      module ClassMethods
        def hooks
          @hooks ||= {}
        end

        def hook(method, &block)
          hooks[method] = block
        end
      end

      def hooks
        self.class.hooks
      end

    private

      def hook(key, *args)
        hooks[key] && instance_exec(*args, &hooks[key])
      end

    end

    include Enumerable
    include Hooks

    class Field
      include Hooks

      @@display_methods = %w[field_name name to_s]

      attr_reader :name, :old_value, :new_value

      def initialize(change_type, name, new_val, old_val=nil)
        @change_type = change_type
        @name = name.to_s
        @new_value, @old_value = [new_val, old_val].map {|val| transform_value(val) }
      end

      def transform_value(val)
        hook(:transform_value, val) || (association_class ? associated_value(val) : val.to_s)
      end

      def associated_value(val)
        object = get_associated_object(val)
        object.send(display_method(object))
      end

      def association_class
        @association_class ||= begin
          if reflection && class_name = reflection.options[:class_name]
            class_name.constantize
          else
            name.to_s =~ /(.*)_id$/
            $1.camelize.constantize
          end
        ensure
          nil
        end
      end

      def reflection
        change_class = @change_type.constantize
        @reflection ||= change_class.reflect_on_association(name_without_id.to_sym) if change_class.respond_to?(:reflect_on_association)
      end

      def get_associated_object(id)
        hook(:get_associated_object, id) || association_class.find_by_id(id)
      end

      def name_without_id
        name.chomp "_id"
      end

      private
      def display_method(object)
        @@display_methods.detect { |m| object.respond_to?(m) }
      end
    end

    class << self
      def for_audits(audits, fields=nil, unfiltered_change_id=nil)
        audits_to_changes(audits, fields, unfiltered_change_id).select(&:relevant?).reverse
      end

      def field_names_for_audits(audits)
        audits_to_changes(audits).map(&:field_names).flatten.uniq.sort
      end

    private

      def audits_to_changes(audits, fields=nil, unfiltered_change_id=nil)
        audits.map do |a|
          filter = (a.id == unfiltered_change_id.to_i) ? nil : fields
          new(a, filter)
        end
      end
    end

    def initialize(audit, fields=nil)
      @audit = audit
      @fields = fields
    end

    def create_field(name, changes)
      Field.new(@audit.auditable_type, name, *[changes].flatten.reverse)
    end

    delegate :id, :to => :@audit

    delegate :action, :to => :@audit

    def username
      if @audit.user
        hook(:username, @audit.user) || @audit.username
      else
        'unknown'
      end
    end

    def date
      @audit.created_at
    end

    def relevant?
      any?(&:present?)
    end
    
    def relevant_field?(field) 
      @fields ? @fields.map(&:downcase).include?(field.name) : true
    end

    def field_names
      non_empty_fields.map { |name, vals| name }
    end

    def each(&block)
      changed_fields.each(&block)
    end

  private
    
    def changed_fields
      @changes_fields ||= non_empty_fields.map { |name, vals| create_field(name, vals) }.select {|field| relevant_field?(field) }
    end

    def non_empty_fields
      @audit[:changes].reject { |name, val| val.to_s.empty? }
    end
  end
end

