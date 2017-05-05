

PRIVILEGES_ORDER = Admission::Privilege.define_order do
  privilege :vassal,   levels: %i[lord]
  privilege :man,      levels: %i[commoner knight count duke king emperor]
  privilege :supernatural, levels: %i[god primordial]
  privilege :harambe
end

REQUEST_ABILITIES = Admission::Ability.define_request_abilities PRIVILEGES_ORDER do

  privilege :harambe do
    allow_all
    forbid :to_live
  end

  privilege :supernatural do
    allow :all do
      not_woman?
    end
    forbid :to_be_proven
    forbid :rule_over_people
  end

  privilege :supernatural, :god do
    allow :all do |country|
      COUNTRIES.europe? country
    end
    allow :rule_over_people do |country|
      COUNTRIES.europe? country
    end
  end

  privilege :supernatural, :primordial do
    allow :all
    allow :rule_over_people
  end


  # read = %i[index show edit]
  # manage = %i[new create update destroy]
  # archive = %i[archive unarchive]
  #
  # privilege :super do
  #   allow :all
  # end
  #
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