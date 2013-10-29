class RemoveClosedAtFromOrganisation < ActiveRecord::Migration
  def up
    remove_column :organisations, :closed_at
  end

  def down
    add_column :organisations, :closed_at, :datetime
  end
end
