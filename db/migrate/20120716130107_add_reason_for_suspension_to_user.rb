class AddReasonForSuspensionToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :reason_for_suspension, :string
  end
end
