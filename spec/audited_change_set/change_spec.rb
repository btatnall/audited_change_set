require 'spec_helper'

module AuditedChangeSet
  describe Change do

    let(:audit) { double(Audit, :auditable_type => "Person") }

    describe "::for_audits" do
      let(:audits) {[double(Audit), double(Audit)]}

      it "constructs an array of changes from the audits" do
        changes = [double(Change), double(Change)]
        changes.each do |change|
          change.stub(:relevant?).and_return(true)
        end
        audits.each_with_index do |audit, index|
          audit.stub(:id).and_return(53)
          Change.stub(:new).with(audit, nil).and_return(changes[index])
        end
        Change.for_audits(audits).should == changes.reverse
      end

      context "with specified fields" do
        let(:audits) { [double(Audit), double(Audit)] }
        let(:fields) { ["name", "intent"] }
        let(:changes) { [double(Change), double(Change)] }

        it "constructs an array of changes filtered by the specified fields from the audits" do
          audits.each_with_index do |audit, index|
            audit.stub(:id).and_return(53)
            Change.stub(:new).with(audit, fields).and_return(changes[index])
          end
          changes.first.should_receive(:relevant?).and_return(true)
          changes.last.should_receive(:relevant?).and_return(false)
          Change.for_audits(audits, fields).should == [changes.first]
        end

        context "with a change id" do
          it "doesn't pass the fields into any audits whose id matches the change id" do
            change_id = 42
            audits.first.stub(:id).and_return(53)
            audits.second.stub(:id).and_return(change_id)

            changes.first.stub(:relevant?).and_return(true)
            changes.second.stub(:relevant?).and_return(true)

            Change.should_receive(:new).with(audits.first, fields).and_return(changes.first)
            Change.should_receive(:new).with(audits.second, nil).and_return(changes.second)

            Change.for_audits(audits, fields, change_id.to_s) # this just needs to get invoked
          end
        end
      end
    end

    describe "::field_names_for_audits" do
      let(:audits) {[double(Audit), double(Audit)]}
      it "returns an array of the fields which have changed across the audits" do
        changes = [double(Change), double(Change)]
        audits.each_with_index do |audit, index|
          audit.stub(:id).and_return(53)
          Change.stub(:new).with(audit, nil).and_return(changes[index])
        end
        changes.first.stub(:field_names).and_return(["intent", "name"])
        changes.last.stub(:field_names).and_return(["name", "executive_status"])
        Change.field_names_for_audits(audits).should == ["executive_status", "intent", "name"]
      end
    end

    describe "#field_names" do
      it "returns a list of field names for this change" do
        audit_changes = {'intent' => [nil, 'irrelevant'], 'name' => [nil, 'irrelevant'], 'executive_status' => [nil, '']}
        audit.stub(:[]).with(:changes).and_return(audit_changes)
        change = Change.new(audit)
        change.field_names.should == ['name', 'intent']
      end
    end

    describe "#username" do
      it "returns user.username" do
        audit.stub(:user) { double("user") }
        audit.stub(:username) { "Example User" }
        change = Change.new(audit)
        change.username.should == "Example User"
      end

      it "returns 'unknown' if no user associated" do
        audit.stub(:user).and_return nil
        change = Change.new(audit)
        change.username.should == 'unknown'
      end
    end

    it "#date returns the date when the audit was made" do
      d = DateTime.now
      audit.stub(:created_at).and_return(d)
      change = Change.new(audit)
      change.date.should == d
    end

    it "#id returns the audit id" do
      audit.stub(:id).and_return(42)
      change = Change.new(audit)
      change.id.should == audit.id
    end

    it "#action returns the audit action" do
      audit.stub(:action).and_return("create")
      change = Change.new(audit)
      change.action.should == "create"
    end

    describe "#relevant?" do
      context "any of the audits match the specified fields" do
        it "returns true" do
          audit.stub(:[]).with(:changes).and_return("intent" => "irrelevant")
          Change.new(audit, ["intent"]).should be_relevant
        end
      end
      context "none of the audits match the specified fields" do
        it "returns false" do
          audit.stub(:[]).with(:changes).and_return("name" => "irrelevant")
          Change.new(audit, ["intent"]).should_not be_relevant
        end
      end
      context "no specified fields" do
        it "returns true" do
          audit.stub(:[]).with(:changes).and_return("intent" => "irrelevant")
          Change.new(audit).should be_relevant
        end
      end
    end

    describe "#each yields fields for each changed attribute" do
      Rspec::Matchers.define :yield_these do |field_values|
        match do |change|
          @yielded_fields = []
          change.each do |field|
            @yielded_fields << field
          end
          matching_fields = @yielded_fields.select do |field|
            field_values[field.name].present? && 
            field_values[field.name].first == field.old_value &&
            field_values[field.name].second == field.new_value
          end
          matching_fields.size == field_values.size && @yielded_fields.size == field_values.size
        end

        failure_message_for_should do |changes_hash|
          "expected Change to yield #{field_values.to_a.inspect}, but got #{@yielded_fields.map{|f| [f.name, [f.old_value, f.new_value]]}.inspect}"
        end
      end

      context "change is a create" do
        before(:each) do
          audit.stub(:action).and_return("create")
        end

        it "sets old value to nil and new value to attribute value" do
          changes = { "name" => "new name", "intent" => "new intent"}

          yielded_fields ={"name" => ["", "new name"], "intent" => ["", "new intent"]}

          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
        end

        it "does not show empty string values" do
          changes = { "blank_field" => "", "non_blank" => "something"}
          yielded_fields = { "non_blank" => ["", "something"] }

          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
        end

        it "does show 'false' values" do
          changes = { "false_field" => false}
          yielded_fields = { "false_field" => ["", "false"] }

          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
        end
      end

      context "change is an update" do
        before(:each) do
          audit.stub(:action).and_return("update")
        end

        it "sets the old and new values" do
          changes = { "name" => ["old name", "changed name"] }
          yielded_fields = {"name" => ["old name", "changed name"] }

          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
        end

        it "shows if we changed to empty string" do
          changes = { "changed_to_empty" => ["not empty", ""]}
          yielded_fields = {"changed_to_empty" => ["not empty", ""]}

          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
        end
      end

      context "field is an association" do
        context "finds associated object" do
          before :each do
            Person.stub(:find_by_id).and_return(nil)
            Person.stub(:find_by_id).with("1").and_return(double(Person, :to_s => 'to_s_ified'))
          end

          it "for new value" do
            changes = { "person_id" => "1"}
            yielded_fields ={"person_id" => ["", "to_s_ified"]}

            audit.stub(:[]).and_return(changes)
            Change.new(audit).should yield_these(yielded_fields)
          end

          it "for old value" do
            changes = { "person_id" => ["1", nil]}
            yielded_fields ={"person_id" => ["to_s_ified", ""]}

            audit.stub(:[]).and_return(changes)
            Change.new(audit).should yield_these(yielded_fields)
          end

          it "by reflecting on belongs_to association" do
            changes = { "parent_id" => ["1", nil]}
            yielded_fields ={"parent_id" => ["to_s_ified", ""]}

            audit.stub(:[]).and_return(changes)
            Change.new(audit).should yield_these(yielded_fields)
          end
        end

        context "display" do
          before :each do
            Person.stub(:find_by_id).with("1").and_return(double(Person, :to_s => 'to_sified'))
            Person.stub(:find_by_id).with("2").and_return(double(Person, :name => 'name_method', :to_s => 'to_sified'))
            Person.stub(:find_by_id).with("3").and_return(double(Person, :field_name => 'field_name_method', :name => 'name_method'))
          end

          it "uses name before to_s" do
            changes = { "parent_id" => ["1", "2"]}
            yielded_fields = {"parent_id" => ["to_sified", "name_method"]}
            audit.stub(:[]).and_return(changes)

            Change.new(audit).should yield_these(yielded_fields)
          end

          it "uses field name before name" do
            changes = { "parent_id" => ["3", "2"]}
            yielded_fields = {"parent_id" => ["field_name_method", "name_method"]}
            audit.stub(:[]).and_return(changes)

            Change.new(audit).should yield_these(yielded_fields)
          end
        end
      end

      context "fields are specified" do
        it "uses only the relevant fields" do
          changes = { "name" => "irrelevant", "intent" => "win"}
          yielded_fields ={"intent" => ["", "win"]}

          audit.stub(:action).and_return("create")
          audit.stub(:[]).and_return(changes)
          Change.new(audit, ["intent"]).should yield_these(yielded_fields)
        end

        it "uses the relevant fields after downcasing" do
          changes = { "name" => "irrelevant", "intent" => "win"}
          yielded_fields ={"intent" => ["", "win"]}

          audit.stub(:action).and_return("create")
          audit.stub(:[]).and_return(changes)
          Change.new(audit, ["Intent"]).should yield_these(yielded_fields)
        end

        it "uses only the relevant fields that are associations" do
          models = [
            double(Person, :to_s => "more revenue"),
            double(Person, :to_s => "less cost")
          ]
          Person.stub(:find_by_id) do |options|
            models.shift
          end
            
          changes = { "title" => "irrelevant", "person_id" => ["1", "2"]}
          yielded_fields ={"person_id" => ["less cost", "more revenue"]}

          audit.stub(:action).and_return("create")
          audit.stub(:[]).and_return(changes)
          Change.new(audit, ["person_id"]).should yield_these(yielded_fields)
        end
      end
    end

    describe "hooks" do
      let(:field_class)  { Class.new(Change::Field) }
      let(:change_class) { Class.new(Change) }

      describe "Field::transform_value" do
        it "yields the new and old values" do
          yielded_args = []
          
          field_class::hook(:transform_value) do |block_arg|
            yielded_args << block_arg
          end

          field_class.new("Person", "anything", "new", "old")
          yielded_args.should == ["new", "old"]
        end

        context "given the callback returns a non-nil value" do
          it "uses the returned value" do
            field_class::hook(:transform_value) do |block_arg|
              "#{block_arg} modified by callback"
            end

            field = field_class.new("Person", "anything", "new value", "old value")

            field.new_value.should == "new value modified by callback"
            field.old_value.should == "old value modified by callback"
          end
        end

        context "given the callback returns nil" do
          it "uses it's unhooked value" do
            field_class::hook(:transform_value) do |block_arg|
              nil
            end

            field = field_class.new("Person", "anything", "new value", "old value")

            field.new_value.should == "new value"
            field.old_value.should == "old value"
          end
        end
      end

      describe "Field::get_associated_object" do
        it "yields the id of the associated object" do
          yielded_args = []
          
          field_class::hook(:get_associated_object) do |block_arg|
            yielded_args << block_arg
          end

          field_class.new("Person", "anything_id", 37, 42)
          yielded_args.should == [37, 42]
        end

        context "given the callback returns a non-nil value" do
          it "uses the returned value" do
            field_class::hook(:get_associated_object) do |block_arg|
              "#{block_arg} returned by callback"
            end

            field = field_class.new("Person", "anything_id", "new value", "old value")

            field.new_value.should == "new value returned by callback"
            field.old_value.should == "old value returned by callback"
          end
        end

        context "given the callback returns nil" do
          it "uses the default strategy to find the associated object" do
            returned_object = Object.new
            Person.stub(:find_by_id).with(37) { returned_object }
            field_class::hook(:get_associated_object) do |block_arg|
              nil
            end

            field = field_class.new("Person", "person_id", 37)
            field.new_value.should == returned_object.to_s
          end
        end
      end

      describe "Change::username" do
        let(:user) { double("User") }
        let(:audit) { double("Audit", :user => user, :username => "supplied username") }

        it "yields the user" do
          yielded_args = []
          
          change_class::hook(:username) do |user_arg|
            yielded_args << user_arg
          end

          change = change_class.new(audit)
          change.username # to invoke the hook
          yielded_args.should == [user]
        end

        context "given the callback returns a non-nil value" do
          it "uses the returned value" do
            change_class::hook(:username) do |user_arg|
              "returned username"
            end

            change = change_class.new(audit)
            change.username.should == "returned username"
          end
        end

        context "given the callback returns nil" do
          it "uses the audit's username" do
            yielded_args = []
            
            change_class::hook(:username) do |user_arg|
              nil
            end

            change = change_class.new(audit)
            change.username.should == "supplied username"
          end
        end
      end
    end
  end
end
