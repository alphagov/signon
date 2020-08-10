class UpdateAphaParent < ActiveRecord::Migration[6.0]
  def up
    apha = Organisation.find_by(abbreviation: "APHA")
    defra = Organisation.find_by(abbreviation: "DEFRA")
    apha.update!(parent: defra)
  end

  def down; end
end
