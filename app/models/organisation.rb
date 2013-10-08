class Organisation < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :organisation_type, presence: true

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
