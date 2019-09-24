class ModelHmtOrgStructure < ActiveRecord::Migration
  def up
    hmt = Organisation.find_by(name: "HM Treasury")
    ukgi = Organisation.find_by(name: "UK Government Investments")

    parent_child_orgs = {
        hmt => [
            "Financial Conduct Authority",
            "Financial Services Trade and Investment Board",
            "Government Internal Audit Agency",
            "Infrastructure UK",
            "National Infrastructure Commission",
            "Office for Budget Responsibility",
            "Office of Financial Sanctions Implementation",
            "Payment Systems Regulator",
            "Royal Mint",
            "Royal Mint Advisory Committee",
            "NS&I",
            "The Crown Estate",
            "UK Debt Management Office",
            "UK Government Investments",
        ],
        ukgi => [
            "UK Financial Investments Limited",
            "Government Corporate Finance Profession",
        ],
    }

    closed_child_org_names = [
        "Asset Protection Agency",
        "Office of HM Paymaster General",
        "Office of Tax Simplification",
        "Royal Mail",
        "Royal Trustees' Office",
        "Exchequer and Audit Department",
        "Public Accounts Commission",
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
        update_parent(org, hmt)
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
