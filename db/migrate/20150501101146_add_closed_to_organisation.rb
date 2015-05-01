class AddClosedToOrganisation < ActiveRecord::Migration
  def change
    add_column :organisations, :closed, :boolean, default: false
  end
end
