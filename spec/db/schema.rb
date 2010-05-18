ActiveRecord::Schema.define(:version => 0) do
  create_table :audits, :force => true do |t|
    t.column :auditable_id, :integer
    t.column :auditable_type, :string
    t.column :user_id, :integer
    t.column :user_type, :string
    t.column :username, :string
    t.column :action, :string
    t.column :changes, :text
    t.column :version, :integer, :default => 0
    t.column :created_at, :datetime
  end

  create_table :people do |t|
    t.integer :parent_id
  end
end
