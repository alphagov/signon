class RemoveAppointedPersonForEnglandAndWalesOrganisation < ActiveRecord::Migration
  def up
    organistion = Organisation.find_by(slug: "")
    if organistion.present?
      raise "Unexpected users for #{organisation.title}" if organistion.users.count > 0

      organistion.destroy
    end
  end

  def down
    # This org was created in error, there's no need for a down to re-instate it
  end
end
