class RemoveDeferredAtFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :deferred_2sv_at
  end
end
