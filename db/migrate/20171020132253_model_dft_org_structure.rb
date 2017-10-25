class ModelDftOrgStructure < ActiveRecord::Migration
  def up
    dft = Organisation.find_by(name: "Department for Transport")

    child_org_names = [
      "Air Accidents Investigation Branch",
      "Airports Commission",
      "BRB (Residuary) Ltd",
      "British Transport Police Authority",
      "Centre for Connected and Autonomous Vehicles",
      "Civil Aviation Authority",
      "Directly Operated Railways Limited",
      "Disabled Persons Transport Advisory Committee",
      "Driver and Vehicle Licensing Agency",
      "Driver and Vehicle Standards Agency",
      "Driving Standards Agency",
      "Highways England",
      "High Speed Two (HS2) Limited",
      "London and Continental Railways Ltd",
      "Marine Accident Investigation Branch",
      "Maritime and Coastguard Agency",
      "Northern Lighthouse Board",
      "Office for Low Emission Vehicles",
      "Office of Rail and Road",
      "Office of Rail Regulation",
      "Passenger Focus",
      "Rail Accident Investigation Branch",
      "Railway Heritage Committee",
      "Transport Focus",
      "Traffic Commissioners for Great Britain",
      "Trinity House",
      "Trust ports",
      "Vehicle and Operator Services Agency",
      "Vehicle Certification Agency",
    ]
    closed_child_org_names = [
      "Government Car and Despatch Agency",
      "Renewable Fuels Agency",
      "Strategic Rail Authority",
      "Driver and Vehicle Testing Agency",
      "Highways Agency",
    ]

    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dft)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dft)
        if org.closed?
          puts "#{child_name} already closed"
        else
          org.update_attributes(closed: true)
          puts "Marking #{child_name} as closed"
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
        old_parent_name = org.parent.nil?? "nil" : org.parent.name
        puts "Checking parent for #{org.name}. Old parent is #{old_parent_name}"
        org.update_attributes!(parent: parent)
        puts "Updating parent for #{org.name} from #{old_parent_name} to #{parent.name}"
      rescue => error
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
