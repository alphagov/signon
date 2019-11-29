class OldPassword < ApplicationRecord
  belongs_to :password_archivable, polymorphic: true
end
