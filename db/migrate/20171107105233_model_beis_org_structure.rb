class ModelBeisOrgStructure < ActiveRecord::Migration
  def up
    beis = Organisation.find_by(name: "Department for Business, Energy & Industrial Strategy")
    brdo = Organisation.find_by(name: "Better Regulation Delivery Office")
    cnpa = Organisation.find_by(name: "Civil Nuclear Police Authority")
    lr = Organisation.find_by(name: "HM Land Registry")
    nda = Organisation.find_by(name: "Nuclear Decommissioning Authority")
    ipo = Organisation.find_by(name: "Intellectual Property Office")

    parent_child_orgs = {
        beis => [
          "Advisory, Conciliation and Arbitration Service",
          "Arts and Humanities Research Council",
          "Better Regulation Delivery Office",
          "Biotechnology and Biological Sciences Research Council",
          "British Business Bank",
          "British Hallmarking Council",
          "Capital for Enterprise Limited",
          "Central Arbitration Committee",
          "Certification Officer",
          "Civil Nuclear Police Authority",
          "Coal Authority",
          "Committee on Climate Change",
          "Committee on Radioactive Waste Management",
          "Committee on Fuel Poverty",
          "Companies House",
          "Competition Appeal Tribunal",
          "Competition and Markets Authority",
          "Competition Commission",
          "Competition Service",
          "Consumer Futures",
          "Copyright Tribunal",
          "Council for Science and Technology",
          "Economic and Social Research Council",
          "Engineering and Physical Sciences Research Council",
          "Fuel Poverty Advisory Group",
          "Government Chemist",
          "Government Office for Science",
          "Groceries Code Adjudicator",
          "HM Land Registry",
          "Independent Complaints Reviewer",
          "Insolvency Practitioners Tribunal",
          "Medical Research Council",
          "Met Office",
          "National Measurement Office",
          "Natural Environment Research Council",
          "Nuclear Decommissioning Authority",
          "Nuclear Liabilities Financing Assurance Board",
          "Office of Fair Trading",
          "Office of Manpower Economics",
          "Office of the Regulator of Community Interest Companies",
          "Ofgem",
          "Oil and Gas Authority",
          "Ordnance Survey",
          "Higher Education Statistics Agency",
          "Regulatory Delivery",
          "Innovate UK",
          "Industrial Development Advisory Board",
          "Insolvency Rules Committee",
          "Intellectual Property Office",
          "Land Registration Rule Committee",
          "Low Pay Commission",
          "Regulatory Policy Committee",
          "Science and Technology Facilities Council",
          "Technology Strategy Board",
          "The Insolvency Service",
          "The Shareholder Executive",
          "UK Atomic Energy Authority",
          "UK Green Investment Bank",
          "UK Research and Innovation",
          "UK Space Agency",
        ],
        brdo => ["Regulatory Delivery"],
        cnpa => ["Civil Nuclear Constabulary"],
        lr => ["Land Registration Rule Committee"],
        nda => ["Radioactive Waste Management", "Sellafield Ltd"],
        ipo => ["Company Names Tribunal"],
    }

    closed_child_org_names = [
      "Department of Energy & Climate Change",
      "Department for Business, Innovation & Skills",
      "National Measurement and Regulation Office",
      "Advantage West Midlands",
      "Business Development Service",
      "CO2Sense",
      "Community Development Foundation",
      "Consumer Council for Postal Services",
      "Department for Business, Enterprise and Regulatory Reform",
      "Department for Innovation, Universities and Skills",
      "Department of Enterprise, Trade and Investment",
      "Department of Trade and Industry",
      "Design Council",
      "East Midlands Development Agency (emda)",
      "East of England Development Agency",
      "Gas and Electricity Consumer Council (Energywatch)",
      "Local Better Regulation Office",
      "North West Development Agency",
      "Northwest Business Link",
      "Northwest Regional Development Agency",
      "Office of the Commissioner for Protection Against Unlawful Industrial Action",
      "Office of the Commissioner for the Rights of Trade Union Members",
      "One North East",
      "Professional Oversight Board",
      "South East England Development Agency",
      "South West of England Regional Development Agency",
      "Thurrock Thames Gateway Development Corporation",
      "Wave Hub",
      "Working Ventures UK",
      "Yorkshire Forward",
      "Monopolies and Mergers Commission",
      "Particle Physics and Astronomy Research Council",
      "National Weights and Measures Laboratory",
    ]

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

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, beis)
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
