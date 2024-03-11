namespace :once_off do
  desc "Update all GDS Users with Imminence signin permission to give them GDS Editor permission"
  task add_gds_editor_permission: :environment do
    imminence = Doorkeeper::Application.find_by(name: "Imminence")
    imminence_signin = imminence.supported_permissions.find_by(name: "signin")
    imminence_gds_editor = imminence.supported_permissions.find_or_create_by!(name: "GDS Editor", delegatable: false, grantable_from_ui: true, default: false)

    Organisation.where(slug: "government-digital-service").first.users.with_permission(imminence_signin).each do |user|
      user.supported_permissions << imminence_gds_editor
      user.save!
    end
  end
end
