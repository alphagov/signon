class ModelModOrgStructure < ActiveRecord::Migration
  def up
    mod = Organisation.find_by(name: 'Ministry of Defence')
    dstl = Organisation.find_by(name: 'Defence Science and Technology Laboratory')
    ukho = Organisation.find_by(name: 'UK Hydrographic Office')

    parent_child_orgs = {
        mod => [
            "Advisory Committee on Conscientious Objectors",
            "Advisory Group on Military Medicine",
            "Armed Forces' Pay Review Body",
            "Central Advisory Committee on Compensation",
            "Central Advisory Committee on Pensions and Compensation",
            "Defence Academy of the United Kingdom",
            "Defence Electronics and Components Agency",
            "Defence Equipment and Support",
            "Defence Infrastructure Organisation",
            "Defence Medical Education and Training Agency",
            "Defence Nuclear Safety Committee",
            "Defence, Press and Broadcasting Advisory Committee",
            "Defence Safety Authority",
            "Defence Science and Technology Laboratory",
            "Defence Scientific Advisory Council",
            "Defence and Security Media Advisory Committee",
            "Defence Sixth Form College",
            "Defence Support Group",
            "Fleet Air Arm Museum",
            "Independent Medical Expert Group",
            "Joint Forces Command",
            "Military Aviation Authority",
            "National Army Museum",
            "National Employer Advisory Board",
            "National Museum of the Royal Navy",
            "Nuclear Research Advisory Council",
            "Queen's Harbour Master",
            "Reserve Forces' and Cadets' Associations",
            "Review Board for Government Contracts",
            "Royal Air Force Museum",
            "Royal Marines Museum",
            "Royal Navy Submarine Museum",
            "Scientific Advisory Committee on the Medical Implications of Less-Lethal Weapons",
            "Service Children's Education",
            "Service Complaints Commissioner",
            "Service Complaints Ombudsman",
            "Service Personnel and Veterans Agency",
            "Service Prosecuting Authority",
            "Single Source Regulations Office",
            "The Oil and Pipelines Agency",
            "UK Hydrographic Office",
            "Veterans Advisory and Pensions Committees",
            "Veterans UK",
            "United Kingdom Reserve Forces Association"
        ],
        dstl => ["Centre for Defence Enterprise", "Defence and Security Accelerator"],
        ukho => ["HM Nautical Almanac Office"]
    }

    closed_child_org_names = [
        "Army Base Repair Organisation",
        "Chemical and Biological Defence Establishment",
        "Defence Analytical Services Agency",
        "Defence Aviation Repair Agency",
        "Defence Bills Agency",
        "British Forces Post Office",
        "Defence Estates",
        "Defence Communication Services Agency",
        "Defence Intelligence and Security Centre",
        "Defence Procurement Agency",
        "Defence Storage and Distribution Agency",
        "Defence Transport and Movements Agency",
        "Disposal Services Agency",
        "Medical Supplies Agency",
        "Ministry of Defence Police and Guarding Agency",
        "People, Pay and Pensions Agency",
        "Warship Support Agency",
        "Armed Forces Personnel Administration Agency"
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
        update_parent(org, mod)
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
