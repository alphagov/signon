class RemoveDeferredAtFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :deferred_2sv_at
  end
end
