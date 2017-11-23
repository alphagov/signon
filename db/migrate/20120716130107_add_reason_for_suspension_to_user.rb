class AddReasonForSuspensionToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :reason_for_suspension, :string
  end
end
