class ModelDcmsOrgStructure < ActiveRecord::Migration
  def up
    dcms = Organisation.find_by(name: "Department for Digital, Culture, Media & Sport")

    child_org_names = [
      'Royal Parks',
      'Horserace Betting Levy Board',
      'Arts Council England',
      'British Library',
      'British Museum',
      'English Heritage',
      'Gambling Commission',
      'Geffrye Museum',
      'Horniman Public Museum and Public Park Trust',
      'Imperial War Museum',
      'National Gallery',
      'National Heritage Memorial Fund',
      'Science Museum Group',
      'National Museums Liverpool',
      'National Portrait Gallery',
      'Natural History Museum',
      'Olympic Delivery Authority',
      'Royal Armouries Museum',
      'Sir John Soane\'s Museum',
      'Sports Grounds Safety Authority',
      'UK Sport',
      'VisitBritain',
      'Wallace Collection',
      'British Film Institute',
      'Sport England',
      'VisitEngland',
      'UK Anti-Doping',
      'Victoria and Albert Museum',
      'The Theatres Trust',
      'The Reviewing Committee on the Export of Works of Art and Objects of Cultural Interest',
      'Treasure Valuation Committee',
      'Ofcom',
      'Channel 4',
      'S4C',
      'BBC',
      'Historic Royal Palaces',
      'Heritage Lottery Fund (administered by the NHMF)',
      'Royal Museums Greenwich',
      'Tate',
      'English Institute of Sport',
      'Information Commissioner\'s Office',
      'Historic England',
      'The National Archives',
      'The Advisory Council on National Records and Archives',
      'Big Lottery Fund',
    ]

    closed_child_org_names = [
      'Gaming Board for Great Britain',
      'Community Fund',
      'Football Licensing Authority',
      'Museums, Libraries and Archives Council',
      'Department of National Heritage',
      'Independent Television Commission',
      'Broadcasting Standards Commission',
      'Millennium Commission',
      'National Endowment for Science, Technology and the Arts',
      'New Opportunities Fund',
      'Phoenix Sports',
      'Public Lending Right Office',
      'UK Film Council',
      'Office of the Data Protection Registrar',
      'English Sports Council',
    ]

    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dcms)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dcms)
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
