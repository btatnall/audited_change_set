require "spec_helper"

module AuditedChangeSet
  describe ChangeSet do
    describe "::for_auditable" do
      let(:klass)     { double(Class) }
      let(:auditable) { double('auditable') }
      before { klass.stub(:find) { auditable } }

      it "returns the change_set for the given auditable object" do
        ChangeSet.should_receive(:new).with(auditable, nil, nil).and_return(change_set = double(ChangeSet))
        ChangeSet.for_auditable(klass, 37).should be(change_set)
      end

      it "passes the fields into the ChangeSet constructor" do
        fields = ["field"]
        ChangeSet.should_receive(:new).with(auditable, fields, nil)
        ChangeSet.for_auditable(klass, 37, fields)
      end

      it "passes the change id into the ChangeSet constructor" do
        fields = ["field"]
        ChangeSet.should_receive(:new).with(auditable, fields, 42)
        ChangeSet.for_auditable(klass, 37, fields, 42)
      end
    end

    describe "#auditable_name" do
      let(:auditable) { double('auditable', :name => 'irrelevant') }
      let(:change_set) { ChangeSet.new(auditable) } 

      it "returns the name of the auditable object" do
        change_set.auditable_name.should == 'irrelevant'
      end
    end

    context "change_set for an auditable model" do
      let(:auditable_model) { stub(Person, :name => 'irrelevant') }
      let(:change_set) { ChangeSet.new(auditable_model) } 

      describe "#each" do
        context "without specified fields" do
          it "yields changes for the auditable_model audits" do
            audits = [double(Audit), double(Audit)]
            auditable_model.stub(:audits).and_return(audits)

            changes = [stub(Change), stub(Change)]
            Change.should_receive(:for_audits).with(audits, nil, nil).and_return(changes)

            yielded_changes = []
            change_set.each do |change|
              yielded_changes << change
            end

            yielded_changes.should == changes
          end
        end

        context "with specified fields" do
          let(:fields) { ["name", "intent"] }
          let(:change_set) { ChangeSet.new(auditable_model, fields) }
          it "provides the specified fields to the changes factory" do
            audits = [double(Audit), double(Audit)]
            auditable_model.stub(:audits).and_return(audits)

            changes = [stub(Change), stub(Change)]
            Change.should_receive(:for_audits).with(audits, fields, nil).and_return(changes)
            change_set.each do
              #just need to invoke this
            end
          end

          context "and an change id" do
            let(:change_id) { 42 }
            let(:change_set) { ChangeSet.new(auditable_model, fields, change_id) }
            it "provides the change id to the changes factory" do
              audits = [double(Audit), double(Audit)]
              auditable_model.stub(:audits).and_return(audits)

              changes = [stub(Change), stub(Change)]
              Change.should_receive(:for_audits).with(audits, fields, change_id).and_return(changes)
              change_set.each do
                #just need to invoke this
              end
            end
          end
        end

      end

      describe "#changed_fields" do
        it "returns all of the changed field names" do
          audits = [double(Audit), double(Audit)]
          auditable_model.stub(:audits).and_return(audits)
          Change.stub(:field_names_for_audits).with(audits).and_return(["intent", "executive_status"])
          
          change_set.changed_fields.should == ["executive_status", "intent"]
        end
      end

    end
  end
end
