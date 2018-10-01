class ModelDfeOrgStructure < ActiveRecord::Migration
  def up
    dfe = Organisation.find_by(name: "Department for Education")

    child_org_names = ["Education Funding Agency",
                       "Standards and Testing Agency",
                       "Ofqual",
                       "Ofsted",
                       "Office of the Children's Commissioner",
                       "School Teachers' Review Body",
                       "National College for Teaching and Leadership",
                       "National College for School Leadership",
                       "Office of the Schools Adjudicator",
                       "Schools Commissioners Group",
                       "Government Equalities Office",
                       "Equality and Human Rights Commission",
                       "Skills Funding Agency",
                       "Higher Education Funding Council for England",
                       "Office for Fair Access",
                       "Student Loans Company",
                       "UK Commission for Employment and Skills",
                       "Construction Industry Training Board",
                       "Engineering Construction Industry Training Board",
                       "Education and Skills Funding Agency",
                       "Institute for Apprenticeships"]

    closed_child_org_names = ["Department for Education and Skills",
                              "Department for Children, Schools and Families",
                              "Qualifications and Curriculum Authority",
                              "Derby North East Education Action Zone",
                              "Kitts Green and Shard End Education Action Zone",
                              "Greenwich Education Action Zone",
                              "Wolverhampton Education Action Zone",
                              "Wednesbury Education Action Zone",
                              "Bolton Education Action Zone",
                              "Hamilton Oxford Education Action Zone",
                              "Dudley Education Action Zone",
                              "Westminster Education Action Zone",
                              "North East Derbyshire Coalfields Education Action Zone",
                              "Telford and Wrekin Education Action Zone",
                              "Withernsea and Southern Holderness Education Action Zone",
                              "Easington and Seaham Education Action Zone",
                              "North Islington Education Action Zone",
                              "Stoke Education Action Zone",
                              "Sunderland Education Action Zone",
                              "Peterlee Education Action Zone",
                              "Southend Education Action Zone",
                              "Bedford Education Action Zone",
                              "Leigh Park Education Action Zone",
                              "Downham and Bellingham Education Action Zone",
                              "Corby Education Action Zone",
                              "Bristol Education Action Zone",
                              "North West Shropshire Education Action Zone",
                              "Wythenshawe Education Action Zone",
                              "Ellesmere Port Education Action Zone",
                              "Camborne, Pool and Redruth Education Action Zone",
                              "Coventry Education Action Zone",
                              "North Gillingham Education Action Zone",
                              "Gloucester Education Action Zone",
                              "East Manchester Education Action Zone",
                              "Clacton and Harwich Education Action Zone",
                              "Hackney Education Action Zone",
                              "Hastings and St Leonards Education Action Zone",
                              "Kent and Somerset Education Action Zone",
                              "Bridgwater Education Action Zone",
                              "Wakefield Education Action Zone",
                              "Great Yarmouth Education Action Zone",
                              "South East England Virtual Education Action Zone",
                              "Heart of Slough Education Action Zone",
                              "Plymouth Education Action Zone",
                              "Learning and Skills Council",
                              "Barrow Education Action Zone",
                              "Speke Garston Education Action Zone",
                              "East Cleveland Education Action Zone",
                              "South Bradford Education Action Zone",
                              "North Stockton Education Action Zone",
                              "Council for Catholic Maintained Schools",
                              "Adult Learning Inspectorate",
                              "Training and Development Agency for Schools",
                              "National School of Government",
                              "Postgraduate Medical Education and Training Board",
                              "British Educational Communications and Technology Agency",
                              "Qualifications and Curriculum Development Agency",
                              "Young People's Learning Agency",
                              "Polytechnics and Colleges Funding Council",
                              "Commission for Racial Equality",
                              "Equal Opportunities Commission",
                              "Disability Rights Commission",
                              "General Teaching Council for England",
                              "Ashington Education Action Zone",
                              "Further and Higher Education Funding Councils for Wales",
                              "Investors in People UK",
                              "School Food Trust"]


    missing_orgs = []

    child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dfe)
      end
    end

    closed_child_org_names.each do |child_name|
      org = Organisation.find_by(name: child_name)
      if org.nil?
        missing_orgs << child_name
        puts "!! Couldn't find #{child_name}"
      else
        update_parent(org, dfe)
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
