class AddAncestryToOrganisations < ActiveRecord::Migration
  def change
    add_column :organisations, :ancestry, :string
    add_index :organisations, :ancestry
  end
end
