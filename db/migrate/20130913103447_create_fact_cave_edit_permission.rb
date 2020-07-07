class CreateFactCaveEditPermission < ActiveRecord::Migration[3.2]
  def up
    fact_cave = ::Doorkeeper::Application.find_by(name: "Fact Cave")
    if fact_cave
      permission = SupportedPermission.new(application_id: fact_cave.to_param, name: "edit_fact")
      permission.save!
    end
  end

  def down; end
end
