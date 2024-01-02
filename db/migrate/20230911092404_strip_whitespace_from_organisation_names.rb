class StripWhitespaceFromOrganisationNames < ActiveRecord::Migration[7.0]
  NAME_HAS_LEADING_OR_TRAILING_SPACE = "name REGEXP('^\s+') OR name REGEXP('\s+$')".freeze

  def up
    Organisation.where(NAME_HAS_LEADING_OR_TRAILING_SPACE).find_each(&:save!)
  end

  def down; end
end
