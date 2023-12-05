FactoryBot.define do
  factory :organisation do
    sequence(:slug) { |n| "ministry-of-funk-#{n}000" }
    sequence(:name) { |n| "Ministry of Funk #{n}000" }
    content_id { SecureRandom.uuid }
    organisation_type { "Ministerial Department" }
  end

  factory :gds_organisation, parent: :organisation do
    content_id { Organisation::GDS_ORG_CONTENT_ID }
  end
end
