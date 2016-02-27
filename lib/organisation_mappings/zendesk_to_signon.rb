module OrganisationMappings
  class ZendeskToSignon
    def self.apply
      OrganisationMappings.domain_names_to_organisations.each do |domain_names, organisation_name|
        organisation = Organisation.find_by_name(organisation_name)
        if organisation
          User.
            where(organisation_id: nil).
            where("#{substring_function} IN (?)", domain_names).
            update_all(organisation_id: organisation.id)
        else
          puts "Could not find organisation matching name '#{organisation_name}'"
        end
      end
    end

    def self.substring_function
      if Signonotron2.mysql?
        "substring_index(email, '@', -1)"
      else
        "split_part(email, '@', 2)"
      end
    end
  end

  # obtained from Zendesk Organisations Api
  def self.domain_names_to_organisations
    {["attorneygeneral.gsi.gov.uk"] => "Attorney General's Office",
     ["digital.cabinet-office.gov.uk"] => "Cabinet Office",
     ["bis.gsi.gov.uk"] => "Department for Business, Innovation & Skills",
     ["communities.gsi.gov.uk"] => "Department for Communities and Local Government",
     ["culture.gsi.gov.uk"] => "Department for Culture, Media & Sport",
     ["decc.gsi.gov.uk"] => "Department of Energy & Climate Change",
     ["defra.gsi.gov.uk"] => "Department for Environment, Food & Rural Affairs",
     ["education.gsi.gov.uk"] => "Department for Education",
     ["dfid.gsi.gov.uk", "dfid.gov.uk"] =>       "Department for International Development",
     ["dft.gsi.gov.uk"] => "Department for Transport",
     ["dh.gsi.gov.uk"] => "Department of Health",
     ["dwp.gsi.gov.uk",
      "dwp.gov.uk",
      "thepensionservice.gsi.gov.uk",
      "jobcentreplus.gsi.gov.uk",
      "csa.gsi.gov.uk",
      "childmaintenance.gsi.gov.uk"] => "Department for Work & Pensions",
     ["dsa.gsi.gov.uk"] => "Driving Standards Agency",
     ["dvla.gsi.gov.uk"] => "Driver and Vehicle Licensing Agency",
     ["fco.gsi.gov.uk", "fco.gov.uk", "digital.fco.gov.uk"] =>       "Foreign & Commonwealth Office",
     ["highways.gsi.gov.uk"] => "Highways Agency",
     ["hmrc.gsi.gov.uk"] => "HM Revenue & Customs",
     ["hm-treasury.gsi.gov.uk", "hmtreasury.gsi.gov.uk"] => "HM Treasury",
     ["homeoffice.gsi.gov.uk", "homeoffice.gov.uk"] => "Home Office",
     ["hs2.org.uk"] => "High Speed Two (HS2) Limited",
     ["mcga.gov.uk"] => "Maritime and Coastguard Agency",
     ["mod.uk"] => "Ministry of Defence",
     ["justice.gsi.gov.uk", "digital.justice.gov.uk"] => "Ministry of Justice",
     ["publicguardian.gsi.gov.uk"] => "Office of the Public Guardian",
     ["ofsted.gov.uk"] => "Ofsted",
     ["phe.gov.uk"] => "Public Health England",
     ["scotlandoffice.gsi.gov.uk"] => "Scotland Office",
     ["slc.co.uk"] => "Student Loans Company",
     ["ukti.gsi.gov.uk"] => "UK Trade & Investment",
     ["voa.gsi.gov.uk"] => "Valuation Office Agency",
     ["vosa.gsi.gov.uk"] => "Vehicle and Operator Services Agency",
     ["vca.gov.uk"] => "Vehicle Certification Agency",
     ["walesoffice.gsi.gov.uk"] => "Wales Office"}
  end
end
