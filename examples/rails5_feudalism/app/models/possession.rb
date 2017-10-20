class Possession < ApplicationRecord

  belongs_to :person

  validates_presence_of :name

end
