class CreateNote < ActiveRecord::Migration
  def up
    create_table :notes do |t|
      t.references :user
      t.string :type
      t.string :details
      t.date :occurred_on
    end
  end

  def down
    remove_table :notes
  end
end
