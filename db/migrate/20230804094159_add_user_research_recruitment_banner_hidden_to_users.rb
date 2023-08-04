class AddUserResearchRecruitmentBannerHiddenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :user_research_recruitment_banner_hidden, :boolean, default: false
  end
end
