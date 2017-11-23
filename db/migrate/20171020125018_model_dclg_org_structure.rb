class ModelDclgOrgStructure < ActiveRecord::Migration[4.2]
  def up
    dclg = Organisation.find_by(name: "Department for Communities and Local Government")

    child_org_names = [
      "Architects Registration Board",
      "Audit Commission",
      "Building Regulations Advisory Committee",
      "Ebbsfleet Development Corporation",
      "Homes and Communities Agency",
      "Housing Ombudsman",
      "Leasehold Advisory Service",
      "Local Government Ombudsman",
      "London Thames Gateway Development Corporation",
      "Planning Inspectorate",
      "Queen Elizabeth II Conference Centre",
      "Valuation Tribunal for England",
      "Valuation Tribunal Service",
      "West Northamptonshire Development Corporation",
    ]
    closed_child_org_names = [
      "Commission for Architecture and the Built Environment (CABE)",
      "Firebuy",
      "Standards Board for England",
      "English Partnerships",
      "Housing Corporation",
      "Office for Tenants and Social Landlords",
      "Tenant Services Authority",
      "Barker Review of Land Use Planning",
      "Infrastructure Planning Commission",
    ]

    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dclg)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dclg)
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
