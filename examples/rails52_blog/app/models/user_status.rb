class UserStatus < Admission::Status
  
  PRIVILEGE_HUMAN_NAMES = {
    nil => 'no privilege',
    user: 'User',
    author: 'Author',
    admin: 'Admin'
  }

  # admission expect list of privileges (even here we use single per user)
  # we use `ResourceArbitration` for scoped requests
  def self.for_user user
    new user, parse_privileges(user.privilege), rules, Admission::ResourceArbitration
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
        allow_resource Article, :edit, :update do |article|
          article.author == self
        end
        
      end
      
      privilege :admin do
        
        # can manage users
        allow User, :new, :create, :edit, :update
        
      end
      
    end
  end
  
end
