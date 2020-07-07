class AddAncestryToOrganisations < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :ancestry, :string
    add_index :organisations, :ancestry
  end
end
