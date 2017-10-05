class AssignAphaOrgToNewParent < ActiveRecord::Migration
  def up
    defra = Organisation.find_by(name: "Department for Environment, Food & Rural Affairs")

    apha = Organisation.find_by(name: "Animal and Plant Health Agency")
    if apha.nil?
      puts "!! Couldn't find 'Animal and Plant Health Agency'"
    else
      if apha.parent != defra
        begin
          old_parent_name = apha.parent.nil?? "nil" : apha.parent.name
          apha.update_attributes!(parent: defra)
          puts "Updating parent for 'Animal and Plant Health Agency' from #{old_parent_name} to #{defra.name}"
        rescue => error
          puts "Parent re-assignment failed for: 'Animal and Plant Health Agency' with error '#{error.message}'"
        end
      else
        puts "Parent for 'Animal and Plant Health Agency' is correct"
      end
    end
  end

  def down
    # This change cannot be reversed
  end
end
