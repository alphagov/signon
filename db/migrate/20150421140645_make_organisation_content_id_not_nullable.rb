class MakeOrganisationContentIdNotNullable < ActiveRecord::Migration
  class User < ApplicationRecord
    belongs_to :organisation
  end

  class Organisation < ApplicationRecord
    has_many :users
  end

  def up
    # This migration is written with the assumption that organisation
    # content_ids have been populated. Any without a content_id are either
    # duplicates or have been deleted from Whitehall.
    Organisation.where("content_id is NULL").each do |organisation|
      if Rails.env.development?
        if organisation.users.any?
          organisation.users.update_all(organisation_id: nil)
        end
        organisation.delete

      else
        if organisation.users.any?
          raise "Can't delete the orphaned organisation with slug: #{organisation.slug} as it has #{organisation.users.count} users. You need to reassign them to non-orphaned organisations and retry."
        else
          organisation.delete
        end
      end
    end

    change_column_null :organisations, :content_id, false
  end

  def down
    change_column_null :organisations, :content_id, true
  end
end
