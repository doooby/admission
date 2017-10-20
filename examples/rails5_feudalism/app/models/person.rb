class Person < ApplicationRecord
  COUNTRIES = %w[Moravia Bohemia Silesia].freeze

  has_one :user, dependent: :destroy
  has_many :possessions, dependent: :destroy
  has_many :traits, dependent: :destroy

  validates_presence_of :name
  validates_inclusion_of :country, in: COUNTRIES

end
