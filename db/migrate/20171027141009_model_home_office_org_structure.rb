class ModelHomeOfficeOrgStructure < ActiveRecord::Migration
  def up
    ho = Organisation.find_by(name: "Home Office")

    child_org_names = [
      'Advisory Council on the Misuse of Drugs',
      'Animals in Science Committee',
      'Biometrics and Forensics Ethics Group',
      'Biometrics Commissioner',
      'Border Force',
      'Disclosure and Barring Service',
      'Forensic Science Regulator',
      'Gangmasters Licensing Authority',
      'HM Inspectorate of Constabulary',
      'HM Passport Office',
      'Immigration Enforcement',
      'Independent Anti-slavery Commissioner',
      'Independent Family Returns Panel',
      'Independent Police Complaints Commission',
      'Independent Reviewer of Terrorism Legislation',
      'Intelligence Services Commissioner',
      'Interception of Communications Commissioner',
      'Investigatory Powers Tribunal',
      'Migration Advisory Committee',
      'National Counter Terrorism Security Office',
      'National Crime Agency Remuneration Review Body',
      'National DNA Database Ethics Group',
      'Office of the Immigration Services Commissioner',
      'Office of Surveillance Commissioners',
      'Police Advisory Board for England and Wales',
      'Police Arbitration Tribunal',
      'Police Discipline Appeals Tribunal',
      'Police Remuneration Review Body',
      'Security Industry Authority',
      'Serious Organised Crime Agency',
      'Surveillance Camera Commissioner',
      'Technical Advisory Board',
      'UK Visas and Immigration'
    ]
    closed_child_org_names = [
      'UK Passport Service',
      'UK Border Agency',
      'Chief Fire and Rescure Adviser',
      'Police Negotiating Board',
      'National Fraud Authority',
      'Board of Inland Revenue',
      'Department of Inland Revenue',
      'H.M. Customs and Excise',
      'Revenue and Customs Prosecutions Office',
      'Animal Procedures Committee',
      'Defence Vetting Agency',
      'Assets Recovery Agency',
      'Central Police Training and Development Authority',
      'Criminal Records Bureau',
      'Firearms Consultative Committee',
      'Forensic Science Service',
      'Independent Chief Inspector of Borders and Immigration',
      'National Crime Agency',
      'National Crime Squad',
      'National Criminal Intelligence Service',
      'National Policing Improvement Agency',
      'Office of the Identity Commissioner',
      'Police Information Technology Organisation',
      'Identity and Passport Service',
      'Police Complaints Authority'
    ]

    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, ho)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, ho)
        if org.closed?
          puts "#{child_name} already closed"
        else
          org.update_attributes(closed: true)
          puts "Marking #{child_name} as closed"
        end
      end
    end

    # Grand children
    tab = Organisation.find_by(name: 'Technical Advisory Board')
    ['Centre for the Protection of National Infrastructure'].each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, tab)
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
