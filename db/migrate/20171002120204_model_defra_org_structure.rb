class ModelDefraOrgStructure < ActiveRecord::Migration
  def up
    defra = Organisation.find_by(name: "Department for Environment, Food & Rural Affairs")
    fera = Organisation.find_by(name: "The Food and Environment Research Agency")
    rpa = Organisation.find_by(name: "Rural Payments Agency")
    fc = Organisation.find_by(name: "Forestry Commission")

    organisation_names = {
        defra => [
            "Animal Health and Veterinary Laboratories Agency",
            "Centre for Environment, Fisheries and Aquaculture Science",
            "The Food and Environment Research Agency",
            "Rural Payments Agency",
            "Veterinary Medicines Directorate",
            "Marine Management Organisation",
            "Consumer Council for Water",
            "Environment Agency",
            "Joint Nature Conservation Committee",
            "Natural England",
            "Agriculture and Horticulture Development Board",
            "Sea Fish Industry Authority",
            "Advisory Committee on Releases to the Environment",
            "Science Advisory Council",
            "Covent Garden Market Authority",
            "Broads Authority",
            "Dartmoor National Park Authority",
            "Exmoor National Park Authority",
            "Lake District National Park Authority",
            "New Forest National Park Authority",
            "North York Moors National Park Authority",
            "Independent Agricultural Appeals Panel",
            "Agricultural Wages Committee",
            "Plant Varieties and Seeds Tribunal",
            "Drinking Water Inspectorate",
            "The Water Services Regulation Authority",
            "National Forest Company",
            "Advisory Committee on Pesticides",
            "Agricultural Dwelling House Advisory Committees (x16)",
            "Veterinary Products Committee",
            "Board of Trustees of the Royal Botanic Gardens Kew",
            "Northumberland National Park Authority",
            "Forestry Commission",
            "Peak District National Park Authority",
            "South Downs National Park Authority",
            "Yorkshire Dales National Park Authority",
            "Rural Development Programme for England Network",
            "Veterinary Residues Committee",
        ],
        fera => [
            "UK Government Decontamination Service",
        ],
        rpa => [
            "British Cattle Movement Service",
        ],
        fc => [
            "Forest Enterprise (England)",
            "Forest Research",
        ],
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
              old_parent_name = org.parent.nil? ? "nil" : org.parent.name
              puts "Checking parent for #{child_name}. Old parent is #{old_parent_name}"
              org.update_attributes!(parent: expected_parent)
              puts "Updating parent for #{child_name} from #{old_parent_name} to #{expected_parent.name}"
            rescue StandardError => error
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
