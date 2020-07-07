class AddClosedToOrganisation < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :closed, :boolean, default: false
  end
end
