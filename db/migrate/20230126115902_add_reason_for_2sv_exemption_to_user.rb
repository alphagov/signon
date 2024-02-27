class AddReasonFor2svExemptionToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :reason_for_2sv_exemption, :string
  end
end
