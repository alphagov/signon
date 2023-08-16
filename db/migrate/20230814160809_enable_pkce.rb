# frozen_string_literal: true

class EnablePkce < ActiveRecord::Migration[7.0]
  def change
    change_table :oauth_access_grants, bulk: true do |t|
      t.column :code_challenge, :string, null: true
      t.column :code_challenge_method, :string, null: true
    end
  end
end
