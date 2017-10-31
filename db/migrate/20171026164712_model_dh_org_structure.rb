class ModelDhOrgStructure < ActiveRecord::Migration
  def up
    dh = Organisation.find_by(name: "Department of Health")

    child_org_names = [
      'Medicines and Healthcare products Regulatory Agency',
      'Care Quality Commission',
      'Human Fertilisation and Embryology Authority',
      'Human Tissue Authority',
      'Monitor',
      'National Institute for Health and Care Excellence',
      'Public Health England',
      'Health Research Authority',
      'NHS Trust Development Authority',
      'NHS Blood and Transplant',
      'NHS England',
      'NHS Litigation Authority',
      'Advisory Committee on Clinical Excellence Awards',
      'Administration of Radioactive Substances Advisory Committee',
      'British Pharmacopoeia Commission',
      'Commission on Human Medicines',
      'Committee on Mutagenicity of Chemicals in Food, Consumer Products and the Environment',
      'Independent Reconfiguration Panel',
      'NHS Business Services Authority',
      'Review Body on Doctors\' and Dentists\' Remuneration',
      'NHS Pay Review Body',
      'Broadmoor Hospital investigation',
      'Health and Social Care Information Centre',
      'Health Education England',
      'Healthcare UK',
      'Office for Life Sciences',
      'Morecambe Bay Investigation',
      'National Information Board',
      'Accelerated Access Review',
      'National Data Guardian',
      'Porton Biopharma Limited',
      'NHS Improvement',
      'NHS Digital',
      'Council for Healthcare Regulatory Excellence',
      'National Biological Standards Board',
      'National Blood Authority',
      'Prescription Pricing Authority',
      'UK Transplant',
      'United Kingdom Blood Transfusion Services',
    ]
    closed_child_org_names = [
      'Alcohol Education and Research Council',
      'Commission for Health Improvement',
      'Commission for Patient and Public Involvement in Health',
      'Commission for Social Care Inspection',
      'Cooksey Review',
      'Dental Practice Board',
      'Dental Vocational Training Authority',
      'Eastern Health and Social Services Board',
      'Family Health Services Appeal Authority',
      'General Social Care Council',
      'Healthcare Commission',
      'Health Protection Agency',
      'Hearing Aid Council',
      'Mental Health Act Commission',
      'National Care Standards Commission',
      'National Patient Safety Agency',
      'National Treatment Agency for Substance Misuse',
      'NHS Appointments Commission',
      'NHS Direct National Health Service Trust',
      'NHS Estates',
      'NHS Information Centre',
      'NHS Institute for Innovation and Improvement',
      'NHS Logistics Authority',
      'NHS Pensions Agency',
      'NHS Professionals',
      'NHS Purchasing and Supply Agency',
      'Office of the Health Professions Adjudicator',
      'Professional Standards Authority for Health and Social Care',
      'Review Body for Nursing and Other Health Professions',
      'National Radiological Protection Board',
      'National School of Government',
      'Public Health Laboratory Service Board',
    ]

    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dh)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dh)
        if org.closed?
          puts "#{child_name} already closed"
        else
          org.update_attributes(closed: true)
          puts "Marking #{child_name} as closed"
        end
      end
    end

    # Grand children
    nbsa = Organisation.find_by(name: 'NHS Business Services Authority')
    ['Counter Fraud and Security Management Service'].each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, nbsa)
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
