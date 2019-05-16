class User < ApplicationRecord

  validates_presence_of :name

  def status
    @status ||= UserStatus.for_user(self)
  end
  delegate :can?, to: :status

  def privilege_text
    UserStatus::PRIVILEGE_HUMAN_NAMES[status.privileges&.first&.name]
  end

  def self.new_attributes
    Admission::Index.new.add :name, :privilege
  end
  
  def self.edit_attributes
    Admission::Index.new.add :privilege
  end

end
