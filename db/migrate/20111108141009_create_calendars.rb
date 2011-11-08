class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.integer :year
      t.string :division
      t.timestamps
    end
  end
end
