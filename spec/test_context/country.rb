COUNTRIES = [
    :czech,
    :deutschland,
    :taiwan,
    :russia,
    :australia,
    :moon
]

class << COUNTRIES

  def europe? country
    %i[czech deutschland russia].include? country
  end

  def safe? country
    %i[czech deutschland taiwan].include? country
  end

  def are_you_dispensable? person
    not (%i[russia] & person.countries).empty?
  end

end