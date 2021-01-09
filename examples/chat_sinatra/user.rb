
class User

  DB = Concurrent::Hash.new

  include Admission::Status
  attr_reader :id, :name, :status, :ws
  attr_accessor :karma

  def msg_post_message data
    User.broadcast_message self, data['body']
  end

  def msg_give_karma data
    user = DB[data['id']]
    if user
      user.karma += 1
      user.ws_send 'karma', karma: user.karma
    end
  end

  def msg_brag _
    User.broadcast_message self,
        "I have so much karma! #{karma} to be specific."
  end

  def initialize type, name
    @id = SecureRandom.hex 3
    @anonymous = type != 'with_name'
    @name = anonymous? ? "User-#{id}" : name
    @karma = 0
    self.privileges = [
        User.admission_privileges.get(self, (anonymous? ? :anonymous : :with_name))
    ]
  end

  def anonymous?
    @anonymous
  end

  def self.admission_privileges
    @admission_privileges ||= Admission.define_privileges do
      privilege :anonymous
      privilege :with_name
    end
  end

  def self.admission_rules
    @admission_rules ||= Admission.define_rules admission_privileges do

      privilege :anonymous do
        allow :post_message
        allow :give_karma, if: ->{ status.karma >= 1 }
      end

      privilege :with_name do
        allow :post_message
        allow :give_karma
        allow :brag, if: ->{ status.karma >= 5 }
      end

    end
  end

  def create_admission_arbitration *args
    Admission::Arbitration.new User.admission_privileges, User.admission_rules, *args
  end

  def process_msg msg, data
    admissible! msg.to_s
    send "msg_#{msg}", data

  rescue Admission::Denied => e
    ws_send 'denied', body: e.message

  end

  def connect_ws ws
    @ws = ws

    ws.on :message do |event|
      data = JSON.parse event.data
      msg = data['msg']
      process_msg msg, data
    end
  end

  def ws_send msg, **data
    data['msg'] = msg
    data = JSON.generate data
    ws.send data
  end

  def self.broadcast_message author, body
    DB.values.each do |user|
      next if user == author
      user.ws_send 'message', {
          id: author.id,
          name: author.name,
          body: body
      }
    end
  end

end
