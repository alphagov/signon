# encoding = utf-8

class Organisation < ActiveRecord::Base
  has_and_belongs_to_many :users

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

  def web_url
    root_url + '/government/organisations/' + slug
  end

private

  def root_url
    if Rails.env.development?
      Plek.current.find('whitehall-admin')
    else
      Plek.current.find('www')
    end
  end
end
