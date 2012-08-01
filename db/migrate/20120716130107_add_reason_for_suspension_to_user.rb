class AddReasonForSuspensionToUser < ActiveRecord::Migration
  def change
    add_column :users, :reason_for_suspension, :string
  end
end
