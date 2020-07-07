class AddAncestryToOrganisations < ActiveRecord::Migration[3.2]
  def change
    add_column :organisations, :ancestry, :string
    add_index :organisations, :ancestry
  end
end
