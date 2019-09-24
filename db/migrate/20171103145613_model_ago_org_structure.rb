class ModelAgoOrgStructure < ActiveRecord::Migration
  def up
    ago = Organisation.find_by(name: "Attorney General's Office")
    tsd = Organisation.find_by(name: "Treasury Solicitor’s Department")

    parent_child_orgs = {
        ago => ["Treasury Solicitor’s Department",
                "Crown Prosecution Service",
                "Serious Fraud Office",
                "HM Crown Prosecution Service Inspectorate",
                "Government Legal Department"],
        tsd => ["Bank of England"],
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
