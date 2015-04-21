FactoryGirl.define do
  factory :organisation do
    sequence(:slug) { |n| "ministry-of-funk-#{n}000" }
    sequence(:name) { |n| "Ministry of Funk #{n}000" }
    sequence(:content_id) { SecureRandom.uuid }
    organisation_type "Ministerial Department"
  end
end
