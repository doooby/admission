class User < ApplicationRecord

  scope :with_privilege, -> (names) {
    names = [names] unless names.is_a? Array
    names = names.map{|name| "'#{name}'"}.join ','
    where.not(privileges: nil).where("\"users\".\"privileges\"->'_all' ?| ARRAY[#{names}]")
  }

  def status
    @status ||= UserStatus.for_user(self)
  end

end