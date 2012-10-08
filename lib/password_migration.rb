module PasswordMigration

  # Handle old passwords
  def valid_legacy_password?(incoming_password)
    return false if encrypted_password.blank?
    bcrypt   = ::BCrypt::Password.new(encrypted_password)
    password = ::BCrypt::Engine.hash_secret(incoming_password, bcrypt.salt)
    Devise.secure_compare(password, encrypted_password)
  end

  def valid_password?(incoming_password)
    return true if super

    if valid_legacy_password?(incoming_password)
      update_legacy_password(incoming_password)
    end
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def update_legacy_password(incoming_password)
    self.password = incoming_password
    self.encrypted_password = password_digest(@password)
    save!
  end
end