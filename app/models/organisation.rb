# encoding = utf-8

class Organisation < ActiveRecord::Base
  has_ancestry

  has_many :users

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :organisation_type, presence: true

  def name_with_abbreviation
    if abbreviation.present? && abbreviation != name
      "#{name} – #{abbreviation}"
    else
      name
    end
  end
end
