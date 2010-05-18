$LOAD_PATH.unshift(File.dirname(__FILE__))
require "audited_change_set"
require "rspec"
require "sqlite3"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)
ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/db/schema.rb")

class Person < ActiveRecord::Base
  belongs_to :parent, :class_name => name, :foreign_key => "parent_id"
end
