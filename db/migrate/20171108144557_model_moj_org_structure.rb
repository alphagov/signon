class ModelMojOrgStructure < ActiveRecord::Migration
  def up
    moj = Organisation.find_by(name: "Ministry of Justice")
    hmcts = Organisation.find_by(name: "HM Courts & Tribunals Service")
    noms = Organisation.find_by(name: "National Offender Management Service")

    parent_child_orgs = {
        moj => [
            "Academy for Justice Commissioning",
            "Academy for Social Justice Commissioning",
            "Administrative Justice and Tribunals Council",
            "Advisory Panel on Public Sector Information",
            "Advisory Committees on Justices of the Peace",
            "Cafcass",
            "Civil Justice Council",
            "Civil Procedure Rule Committee",
            "Criminal Injuries Compensation Authority",
            "Criminal Cases Review Commission",
            "Criminal Procedure Rule Committee",
            "Family Justice Council",
            "Family Procedure Rule Committee",
            "Her Majesty's Magistrates Courts Service Inspectorate",
            "HM Courts & Tribunals Service",
            "HM Inspectorate of Prisons",
            "HM Inspectorate of Probation",
            "HM Prison Service",
            "Independent Advisory Panel on Deaths in Custody",
            "Independent Monitoring Boards",
            "Judicial Appointments and Conduct Ombudsman",
            "Judicial Appointments Commission",
            "Judicial Office",
            "Law Commission",
            "Legal Aid Agency",
            "Legal Services Board",
            "Legal Services Commission",
            "National Offender Management Service",
            "Official Solicitor and Public Trustee",
            "Office of the Public Guardian",
            "Parole Board",
            "Prisons and Probation Ombudsman",
            "Prison Service Pay Review Body",
            "Sentencing Council for England and Wales",
            "The Jeffrey Review",
            "The Legal Ombudsman",
            "Tribunal Procedure Committee",
            "Victims' Advisory Panel",
            "Victims' Commissioner",
            "Youth Justice Board for England and Wales"
        ],
        hmcts => [
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
            "Chancery Division of the High Court"
        ],
        noms => ["National Probation Service"]
    }

    closed_child_org_names = [
        "Criminal Injuries Compensation Appeals Panel",
        "H.M. Inspectorate of Court Administration",
        "Administrative Justice and Tribunals Council Welsh Committee",
        "Appeals Service Agency",
        "Council on Tribunals",
        "Department for Constitutional Affairs",
        "Department of Constitutional Affairs",
        "Foreign Compensation Commission",
        "Lord Chancellor's Department",
        "Office for Criminal Justice Reform",
        "Office of the Lay Observer",
        "Office of the Legal Services Complaints Commissioner",
        "Office of the Legal Services Ombudsman"
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
        update_parent(org, moj)
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
