
class User

  DB = Concurrent::Hash.new

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
        "I have so much karma! #{karma}, to be specific."
  end

  def initialize type, name
    @id = SecureRandom.hex 3
    @anonymous = type != 'with_name'
    @name = anonymous? ? "User-#{id}" : name
    @karma = 0
    @status = create_status
  end

  def anonymous?
    @anonymous
  end

  def create_status
    privilege = anonymous? ? User::ANONYMOUS : USER::WITH_NAME
    Admission::Status.new self, [privilege], User.admission_rules
  end

  def self.admission_privileges
    @admission_privileges ||= Admission.define_privileges self do
      privilege 'ANONYMOUS'
      privilege 'WITH_NAME'
    end
  end

  def self.admission_rules
    @admission_rules ||= Admission.define_rules admission_privileges do

      with ANNONYMOUS do
        allow :post_message
        allow :give_carma, if: ->{ karma >= 1 }
      end

      privilege WITH_NAME do
        allow :post_message
        allow :give_karma
        allow :brag, if: ->{ karma >= 5 }
      end

    end
  end

  def process_msg msg, data
    status.request! msg.to_sym
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
