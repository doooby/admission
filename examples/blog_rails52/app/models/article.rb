class Article < ApplicationRecord

  belongs_to :author, class_name: 'User'
  has_many :messages

  validates_presence_of :author, :title, :body

  def allow_changes? user, _
    author == user
  end

end
