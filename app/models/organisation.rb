# encoding = utf-8

class Organisation < ActiveRecord::Base
  GDS_ORG_CONTENT_ID = "af07d5a5-df63-4ddc-9383-6a666845ebe9".freeze

  has_ancestry

  has_many :users

  validates :slug, presence: true, uniqueness: true
  validates :content_id, presence: true
  validates :name, presence: true
  validates :organisation_type, presence: true

  def name_with_abbreviation
    return_value = if abbreviation.present? && abbreviation != name
                     "#{name} – #{abbreviation}"
                   else
                     name
                   end

    return_value += " (closed)" if closed?

    return_value
  end
end
