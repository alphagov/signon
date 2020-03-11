class AddAphaAsChildOfDefra < ActiveRecord::Migration[5.2]
  def up
    defra = Organisation.find_by(abbreviation: "Defra")
    puts "!! Couldn't find Defra" && return if defra.nil?
    epha = Organisation.find_by(abbreviation: "APHA")
    puts "!! Couldn't find APHA" && return if epha.nil?
    epha.update!(parent: defra)
    puts "Updated parent for #{epha.name} to #{defra.name}"
  rescue StandardError => e
    puts "Parent re-assignment failed for: #{epha.name} with error '#{e.message}'"
  end

  def down
    # This change cannot be reversed
  end
end
