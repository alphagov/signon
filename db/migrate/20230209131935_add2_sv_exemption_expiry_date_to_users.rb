class Add2SvExemptionExpiryDateToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :expiry_date_for_2sv_exemption, :date
  end
end
