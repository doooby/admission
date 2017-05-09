

PRIVILEGES_ORDER = Admission::Privilege.define_order do
  privilege :vassal,   levels: %i[lord]
  privilege :human,      levels: %i[count king]
  privilege :emperor,  inherits: %i[vassal human]
end

ACTIONS_RULES = Admission::Arbitration.define_rules PRIVILEGES_ORDER do

  privilege :human do
    allow_all{ not_woman? }
    forbid :raise_taxes
    forbid :impose_corvee

    forbid :impose_draft
    forbid :act_as_god
  end

  privilege :human, :count do
    allow_all do |country|
      countries.include? country
    end
    allow :impose_corvee do |country|
      countries.include? country
    end
  end

  privilege :human, :king do
    allow_all
    allow :raise_taxes
  end

  privilege :vassal, :lord do
    allow :impose_draft
  end

  privilege :emperor do
    allow :act_as_god
  end

end

RESOURCE_RULES = Admission::ResourceArbitration.define_rules PRIVILEGES_ORDER do

  # privilege :harambe do
  #   allow :all
  # end
  #
  # privilege :vassal do
  #
  #   allow_resource Person, :show do |person, _|
  #     self == person
  #   end
  #
  #   allow :persons, :index do |country|
  #     countries.include? country
  #   end
  #
  # end
  #
  # privilege :vassal, :lord do
  #
  #   allow_resource Person, :show
  #
  #   allow_resource Person, %i[index update] do |person, country|
  #     allowance = countries.include? country
  #     next allowance unless person
  #
  #     allowance && person.countries.include?(country)
  #   end
  #
  #   allow_resource Person :destroy do |person, country|
  #     countries.include?(country) && person.sex != Person::APACHE_HELICOPTER
  #   end
  #
  # end



  # privilege :partner do
  #
  #   allow :companies, %i[index new create]
  #   allow_resource Company, %i[show edit policies documents debts generate_doc] do |company, country|
  #     next false unless company.country == country
  #     company.id == company_id || company.supervisor_id == company_id
  #   end
  #
  #   allow :policies, %i[index new create]
  #   allow_resource Policy, %i[show edit get_contacts] do |policy, country|
  #     next false unless policy.country == country
  #     policy.supervisor_id == company_id || policy.company_id == company_id
  #   end
  #
  #   allow :contacts, %i[index new create]
  #   allow_resource Contact, %i[show edit generate_doc] do |contact, country|
  #     next false unless contact.country == country
  #     contact.company_id == company_id || contact.supervisor_id == company_id
  #   end
  #
  #   allow :documents, read + %i[download]
  #   allow_resource Document, archive do |document, country|
  #     !document.exam
  #   end
  #
  #   allow :debts, read
  #   allow :categories, read
  #
  # end

end