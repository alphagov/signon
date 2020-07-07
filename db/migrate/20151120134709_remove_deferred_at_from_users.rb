class RemoveDeferredAtFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :deferred_2sv_at
  end
end
