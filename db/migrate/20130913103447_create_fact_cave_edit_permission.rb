class CreateFactCaveEditPermission < ActiveRecord::Migration
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: 'Doorkeeper::Application'
  end

  def up
    fact_cave = ::Doorkeeper::Application.find_by_name("Fact Cave")
    if fact_cave
      SupportedPermission.create!(application: fact_cave, name: "edit_fact")
    end
 
  end

  def down
  end
end
