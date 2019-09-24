class ModelFcoOrgStructure < ActiveRecord::Migration
  def up
    fco = Organisation.find_by(name: "Foreign & Commonwealth Office")
    gch = Organisation.find_by(name: "Government Communications Headquarters")

    parent_child_orgs = {
        fco => ["BBC World Service",
                "British Council",
                "Chevening Scholarship Programme",
                "FCO Services",
                "Government Communications Headquarters",
                "Great Britain-China Centre",
                "Marshall Aid Commemoration Commission",
                "Preventing Sexual Violence Initiative",
                "Secret Intelligence Service",
                "Westminster Foundation for Democracy",
                "Wilton Park"],
        gch => ["CESG",
                "National Cyber Security Centre"],
    }

    missing_orgs = []

    parent_child_orgs.each do |expected_parent, children|
      children.each do |child_name|
        org = Organisation.find_by(name: child_name)
        if org.nil?
          missing_orgs << child_name
          puts "!! Couldn't find #{child_name}"
        else
          update_parent(org, expected_parent)
        end
      end
    end

    if missing_orgs.empty?
      puts "All organisations were found"
    else
      puts "Missing organisations: #{missing_orgs.join("\n")}"
    end
  end

  def update_parent(org, parent)
    if org.parent != parent
      begin
        old_parent_name = org.parent.nil? ? "nil" : org.parent.name
        puts "Checking parent for #{org.name}. Old parent is #{old_parent_name}"
        org.update_attributes!(parent: parent)
        puts "Updating parent for #{org.name} from #{old_parent_name} to #{parent.name}"
      rescue StandardError => error
        puts "Parent re-assignment failed for: #{org.name} with error '#{error.message}'"
      end
    else
      puts "Parent for #{org.name} is correct"
    end
  end

  def down
    # This change cannot be reversed
  end
end
