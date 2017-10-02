class ModelCabinetOfficeOrgStructure < ActiveRecord::Migration
  def up
    cabinet_office = Organisation.find_by(name: "Cabinet Office")
    downing_street = Organisation.find_by(name: "Prime Minister's Office, 10 Downing Street")
    civil_service = Organisation.find_by(name: "Civil Service")
    civil_service_resourcing = Organisation.find_by(name: "Civil Service Resourcing")

    organisation_names = {
        cabinet_office => [
          "Committee on Standards in Public Life",
          "Office of the Leader of the House of Commons",
          "Advisory Committee on Business Appointments",
          "Boundary Commission for England",
          "House of Lords Appointments Commission",
          "Privy Council Office",
          "Civil Service Commission",
          "Security Vetting Appeals Panel",
          "Senior Salaries Review Body",
          "Office of the Leader of the House of Lords",
          "Boundary Commission for Wales",
          "National security and intelligence",
          "Efficiency and Reform Group",
          "Office of the Parliamentary Counsel",
          "Commissioner for Public Appointments",
          "The McKay Commission",
          "Prime Minister's Office, 10 Downing Street",
          "Deputy Prime Minister's Office",
          "Government Estates Management",
          "Open Public Services",
          "Crown Commercial Service",
          "Civil Service",
          "Office of the Registrar of Consultant Lobbyists",
          "Third Party Campaigning Review",
          "Cabinet Office Board",
          "National School of Government"
        ],
        downing_street => [
          "UK Holocaust Memorial Foundation"
        ],
        civil_service => [
          "Operational Delivery Profession",
          "Policy Profession",
          "Project Delivery Profession",
          "Procurement profession",
          "Government Legal Service",
          "Government Communication Service",
          "Government Finance Profession",
          "Government Economic Service",
          "Human Resources Profession",
          "Internal Audit Profession",
          "Government Occupational Psychology Profession",
          "Government Knowledge & Information Management Profession",
          "Government Veterinary Services",
          "Government Property Profession",
          "Government Tax Profession",
          "Government Science & Engineering Profession",
          "Government Planning Inspectors",
          "Government Statistical Service",
          "Government Planning Profession",
          "Government Operational Research Service",
          "Government Social Research Profession",
          "Intelligence Analysis",
          "Government IT Profession",
          "Medical Profession",
          "Civil Service Reform",
          "Government Security Profession",
          "Civil Service Resourcing",
          "Government Commercial Function",
          "Digital, data and technology professions",
          "Civil Service Board"
        ],
        civil_service_resourcing => [
          "Civil Service Fast Stream",
          "Civil Service Fast Track Apprenticeship"
        ]
    }

    missing_orgs = []

    organisation_names.each do |expected_parent, children|
      children.each do |child_name|
        org = Organisation.find_by(name: child_name)
        if org.nil?
          missing_orgs << child_name
          puts "!! Couldn't find #{child_name}"
        else
          if org.parent != expected_parent
            begin
              old_parent_name = org.parent.nil?? "nil" : org.parent.name

              puts "Checking parent for #{child_name}. Old parent is #{old_parent_name}"

              org.update_attributes!(parent: expected_parent)

              puts "Updating parent for #{child_name} from #{old_parent_name} to #{expected_parent.name}"
            rescue => error
              puts "Parent re-assignment failed for: #{child_name} with error '#{error.message}'"
            end
          else
            puts "Parent for #{child_name} is correct"
          end
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
