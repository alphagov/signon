class CloneTradeTariffAdmin < ActiveRecord::Migration[5.2]
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: "Doorkeeper::Application"
  end

  def up
    ActiveRecord::Base.transaction do
      existing_trade_tariff_admin = ::Doorkeeper::Application.find_by_name("Trade Tariff Admin (PaaS)")
      cloned_trade_tariff_admin = ::Doorkeeper::Application.new
      existing_trade_tariff_admin.attributes.each_pair do |key, value|
        if !%w(created_at updated_at id uid).include?(key)
          cloned_trade_tariff_admin[key] = value
        end
      end
      cloned_trade_tariff_admin.name = "New London: #{cloned_trade_tariff_admin.name}"
      cloned_trade_tariff_admin.save!

      SupportedPermission.where(application_id: existing_trade_tariff_admin.id).each do |existing_supported_permission|
        # Some are created by default and the index will complain if we try to duplicate them
        if !SupportedPermission.exists?(application_id: cloned_trade_tariff_admin.id, name: existing_supported_permission.name)
          cloned_supported_permission = SupportedPermission.new
          existing_supported_permission.attributes.each_pair do |key, value|
            if !%w(created_at updated_at id).include?(key)
              cloned_supported_permission[key] = value
            end
          end
          cloned_supported_permission.application_id = cloned_trade_tariff_admin.id
          cloned_supported_permission.save!
        end
      end

      UserApplicationPermission.where(application_id: existing_trade_tariff_admin.id).each do |existing_user_application_permission|
        cloned_user_application_permission = UserApplicationPermission.new
        existing_user_application_permission.attributes.each_pair do |key, value|
          if !%w(created_at updated_at id).include?(key)
            cloned_user_application_permission[key] = value
          end
          # The new UserApplicationPermission will need a SupportedPermission for the new application
          existing_supported_permission = existing_user_application_permission.supported_permission
          cloned_supported_permission = SupportedPermission.where(name: existing_supported_permission.name, application_id: cloned_trade_tariff_admin.id).first
          cloned_user_application_permission.supported_permission_id = cloned_supported_permission.id
          cloned_user_application_permission.application_id = cloned_trade_tariff_admin.id
        end
        cloned_user_application_permission.save!
      end
    end
  end

  def down
    # This change cannot be reversed
  end
end
