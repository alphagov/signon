class AddRequire2svToOrganisations < ActiveRecord::Migration[7.0]
  def change
    add_column :organisations, :require_2sv, :boolean, null: false, default: false
  end
end
