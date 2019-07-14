class User < ApplicationRecord

  validates_presence_of :name

  def status
    @status ||= begin
      Admission::Status.new(
          self,
          User.parse_privileges(privilege),
          User.rules,
          Admission::ResourceArbitration
      )
    end
  end
  delegate :can?, to: :status

  def self.new_attributes
    Admission::Attributes.build :name, :privilege
  end
  
  def self.edit_attributes
    Admission::Attributes.build :privilege
  end

  PRIVILEGE_HUMAN_NAMES = {
      nil => 'no privilege',
      user: 'User',
      author: 'Author',
      admin: 'Admin'
  }

  def privilege_text
    PRIVILEGE_HUMAN_NAMES[status.privileges&.first&.name]
  end

  # since user can have only single privilege,
  # simply get that one
  def self.parse_privileges name
    name.blank? ? [] : [privileges.get(name)]
  end

  # since user can have only single privilege,
  # dump only name of the first
  def self.dump_privileges list
    return if list.blank?
    list.first.name
  end

  def self.privileges
    @privileges ||= Admission.define_privileges do
      privilege :user
      privilege :author, inherits: :user
      privilege :admin, inherits: :user
    end
  end

  def self.rules
    @rules ||= Admission::ResourceArbitration.define_rules privileges do

      privilege :user do

        # can read any article
        allow Article, :show

        # can post message to any article
        allow [Article, :messages], :create_message

      end

      privilege :author do

        # can write new articles
        allow Article, :new, :create

        # can modify own articles
        allow_resource Article, :edit, :update, rule: :allow_changes?

      end

      privilege :admin do

        # can manage users
        allow User, :new, :create, :edit, :update

      end

    end
  end

end
