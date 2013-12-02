module Metrics
  def accounts_count
    [[:total, User.count]]
  end

  def accounts_count_by_state
    [[:active, User.active.count],
      [:suspended, User.suspended.count]]
  end

  def active_accounts_count_by_role
    User.active.count(group: :role)
  end

  def active_accounts_count_by_application
    User.active.joins(permissions: :application).where("permissions like '%signin%'").count(group: Doorkeeper::Application.arel_table['name'])
  end

  def active_accounts_count_by_organisation
    User.active.joins(:organisation).count(group: Organisation.arel_table['name']).to_a << ['None assigned', User.where(organisation_id: nil).count]
  end

  def active_accounts_count_by_days_inactive
    [7, 15, 30, 60, 90].inject([]) do |result, days_count|
      result << ["#{days_count}+", User.active.where('current_sign_in_at <= ?', days_count.days.ago).count]
      result
    end
  end

  def active_accounts_count_by_email_domain
    User.active.count(group: "substring_index(email, '@', -1)")
  end

  def active_accounts_count_by_application_per_organisation
    Organisation.all.inject([]) do |result, org|
      User.active.joins(permissions: :application).where(organisation_id: org.id).where("permissions like '%signin%'").count(group: Doorkeeper::Application.arel_table['name']).to_a.map do |counts|
        result << [org.name, counts].flatten
      end
      result
    end
  end
end
