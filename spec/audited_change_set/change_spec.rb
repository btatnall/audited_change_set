require 'spec_helper'

module AuditedChangeSet
  describe Change do

    let(:audit) { double(Audit) }

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

        before :each do
          AuditableModel.stub(:find_by_id).and_return(nil)
          AuditableModel.stub(:find_by_id).with("1").and_return(double(AuditableModel, :to_s => 'to_s_ified'))
        end

        it "uses associated object for new value" do
          changes = { "auditable_model_id" => "1"}
          yielded_fields ={"auditable_model_id" => ["", "to_s_ified"]}

          audit.stub(:action).and_return("create")
          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
        end

        it "uses associated object for old value" do
          changes = { "auditable_model_id" => ["1", nil]}
          yielded_fields ={"auditable_model_id" => ["to_s_ified", ""]}

          audit.stub(:action).and_return("create")
          audit.stub(:[]).and_return(changes)
          Change.new(audit).should yield_these(yielded_fields)
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
            double(AuditableModel, :to_s => "more revenue"),
            double(AuditableModel, :to_s => "less cost")
          ]
          AuditableModel.stub(:find_by_id) do |options|
            models.shift
          end
            
          changes = { "title" => "irrelevant", "auditable_model_id" => ["1", "2"]}
          yielded_fields ={"auditable_model_id" => ["more revenue", "less cost"]}

          audit.stub(:action).and_return("create")
          audit.stub(:[]).and_return(changes)
          Change.new(audit, ["auditable_model_id"]).should yield_these(yielded_fields)
        end
      end
    end
  end
end
