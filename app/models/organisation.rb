class Organisation < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :organisation_type, presence: true

end
