class AddAphaAsChildOfDefra < ActiveRecord::Migration[5.2]
  def up
    defra = Organisation.find_by_abbreviation("Defra")
    puts "!! Couldn't find Defra" && return if defra.nil?
    epha = Organisation.find_by_abbreviation("APHA")
    puts "!! Couldn't find APHA" && return if epha.nil?
    epha.update_attributes!(parent: defra)
    puts "Updated parent for #{epha.name} to #{defra.name}"
  rescue => error
    puts "Parent re-assignment failed for: #{epha.name} with error '#{error.message}'"
  end

  def down
    # This change cannot be reversed
  end
end
