class CreateBankHolidays < ActiveRecord::Migration
  def change
    create_table :bank_holidays do |t|
      t.references :calendar
      t.date :date
      t.string :division
      t.string :title
      t.string :notes
      t.timestamps
    end
  end
end
