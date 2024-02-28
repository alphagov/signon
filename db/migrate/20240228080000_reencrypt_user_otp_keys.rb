class ReencryptUserOtpKeys < ActiveRecord::Migration[7.1]
  def change
    User.find_each(&:encrypt)
  end
end
