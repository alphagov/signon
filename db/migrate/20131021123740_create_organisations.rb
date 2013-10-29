class CreateOrganisations < ActiveRecord::Migration
  def change
    create_table :organisations do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :organisation_type, null: false
      t.string :abbreviation
      t.datetime :closed_at

      t.timestamps
    end

    add_index :organisations, :slug, unique: true

    create_table :organisations_users do |t|
      t.integer :organisation_id
      t.integer :user_id
    end

    add_index :organisations_users, :organisation_id
    add_index :organisations_users, :user_id
  end
end
