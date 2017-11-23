class AddClosedToOrganisation < ActiveRecord::Migration[4.2]
  def change
    add_column :organisations, :closed, :boolean, default: false
  end
end
