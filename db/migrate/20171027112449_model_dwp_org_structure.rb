class ModelDwpOrgStructure < ActiveRecord::Migration
  def up
    dwp = Organisation.find_by(name: "Department for Work and Pensions")

    child_org_names = [
      'Industrial Injuries Advisory Council',
      'Social Security Advisory Committee',
      'Health and Safety Executive',
      'The Pensions Advisory Service',
      'The Pensions Regulator',
      'Pension Protection Fund Ombudsman',
      'Pensions Ombudsman',
      'National Employment Savings Trust (NEST) Corporation',
      'Pension Protection Fund',
      'Independent Case Examiner',
      'Office for Nuclear Regulation',
      'Office for Disability Issues'
    ]
    closed_child_org_names = [
      'Child Maintenance and Enforcement Commission',
      'Disabled People’s Employment Corporation',
      'Remploy Ltd',
      'Independent Living Fund',
      'Equality 2025',
      'Children\'s Workforce Development Council',
      'Department for Social Development',
      'Department of Social Security',
      'Disability and Carers Service',
      'Parliamentary Contributory Pension Fund',
      'Pension Service',
      'Pension, Disability and Carers Service',
      'Personal Accounts Delivery Authority'
    ]

    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dwp)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dwp)
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
