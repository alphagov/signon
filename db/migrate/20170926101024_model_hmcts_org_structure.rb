class ModelHmctsOrgStructure < ActiveRecord::Migration
  def up
    # Make sure parent of HMCTS is MOJ

    hmcts = Organisation.find_by(name: "HM Courts & Tribunals Service")
    moj = Organisation.find_by(name: "Ministry of Justice")
    if moj.present?
      if hmcts.parent != moj
        begin
          hmcts.update_attribute(parent: moj)
          puts "Assigned HMCTS to have MOJ as parent"
        rescue => error
          puts "Could not update parent for #{hmcts.name} to MOJ because of error: #{error.message}"
        end
      else
        puts "HMCTS already had MOJ as parent"
      end
    else
      puts "!! Could not find Ministry of Justice"
    end

    # Make sure children of HMCTS are assigned to HMCTS

    organisation_names = [
        "Bankruptcy Court",
        "First-tier Tribunal (Mental Health)",
        "First-tier Tribunal (General Regulatory Chamber)",
        "First-tier Tribunal (War Pensions and Armed Forces Compensation)",
        "First-tier Tribunal (Asylum Support)",
        "First-tier Tribunal (Tax)",
        "Gangmasters Licensing Appeals",
        "First-tier Tribunal (Criminal Injuries Compensation)",
        "First-tier Tribunal (Care Standards)",
        "Employment Tribunal",
        "Employment Appeal Tribunal",
        "Senior Courts Costs Office",
        "First-tier Tribunal (Social Security and Child Support)",
        "Court of Protection",
        "Reserve Forces Appeal Tribunal",
        "First-tier Tribunal (Property Chamber)",
        "Upper Tribunal (Tax and Chancery Chamber)",
        "Upper Tribunal (Lands Chamber)",
        "Upper Tribunal (Administrative Appeals Chamber)",
        "First-tier Tribunal (Immigration and Asylum)",
        "Upper Tribunal (Immigration and Asylum Chamber)",
        "First-tier Tribunal (Special Educational Needs and Disability)",
        "Admiralty Court",
        "Family Division of the High Court",
        "Planning Court",
        "Technology and Construction Court",
        "Mercantile Court",
        "Commercial Court",
        "Companies Court",
        "Intellectual Property Enterprise Court",
        "Court of Appeal Civil Division",
        "Northampton County Court Business Centre",
        "Patents Court",
        "Court of Appeal Criminal Division",
        "Queen's Bench Division of the High Court",
        "Administrative Court",
        "Chancery Division of the High Court",
        "HM Courts Service"
    ]

    missing_orgs = []

    organisation_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        if org.parent != hmcts
          begin
            old_parent_name = org.parent.nil?? "nil" : org.parent.name
            puts "Checking parent for #{child_name}. Old parent is #{old_parent_name}"
            org.update_attributes!(parent: hmcts)
            puts "Updated parent for #{child_name} from #{old_parent_name} to hmcts"
          rescue => error
            puts "Parent re-assignment failed for: #{child_name} with error '#{error.message}'"
          end
        else
          puts "Parent for #{child_name} is correct"
        end
      end
    end

    if missing_orgs.empty?
      puts "All organisations were found"
    else
      puts "Missing organisations: #{missing_orgs.join("\n")}"
    end
  end

  def down
    # This change cannot be reversed
  end
end
