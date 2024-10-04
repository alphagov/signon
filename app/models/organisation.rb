class Organisation < ApplicationRecord
  GDS_ORG_CONTENT_ID = "af07d5a5-df63-4ddc-9383-6a666845ebe9".freeze
  NONE = "None".freeze

  has_ancestry

  has_many :users

  validates :slug, presence: true, uniqueness: { case_sensitive: true }
  validates :content_id, presence: true
  validates :name, presence: true
  validates :organisation_type, presence: true

  before_save :strip_whitespace_from_name

  scope :closed, -> { where(closed: true) }
  scope :not_closed, -> { where(closed: false) }

  default_scope { order(arel_table[:closed].asc, name: :asc) }

  def name_with_abbreviation(indicate_closed: true)
    return_value = if abbreviation.present? && abbreviation != name
                     "#{name} - #{abbreviation}"
                   else
                     name
                   end

    return_value += " (closed)" if indicate_closed && closed?

    return_value
  end

private

  def strip_whitespace_from_name
    name.strip!
  end
end
