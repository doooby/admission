require_relative './user'

get '/' do
  erb File.read(File.join Dir.pwd, 'index.html.erb')
end

get '/connect' do
  user = User::DB[params[:user_id]] || next
  if Faye::WebSocket.websocket? env
    ws = Faye::WebSocket.new env
    user.connect_ws ws
    ws.rack_response
  end
end

post '/open_chat' do
  data = JSON.parse request.body.read
  user = User.new data['type'], data['name']
  User::DB[user.id] = user
  JSON.generate({id: user.id, name: user.name})
end

class User

  def process_msg msg, data
    status.request! msg.to_sym
    send "msg_#{msg}", data

  rescue Admission::Denied => e
    ws_send 'denied', body: e.message

  end

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
    User.broadcast_message self, "I have so much karma! #{karma}, to be specific."
  end

  def create_status
    privilege = User.privileges.get(anonymous? ? :anonymous : :with_name)
    Admission::Status.new self, [privilege], User.rules, Admission::Arbitration
  end

  def self.privileges
    @privileges ||= Admission.define_privileges do
      privilege :anonymous
      privilege :with_name
    end
  end

  def self.rules
    @rules ||= Admission::Arbitration.define_rules_for privileges do

      privilege :anonymous do
        allow :post_message
        allow(:give_karma){ karma >= 1 }
      end

      privilege :with_name do
        allow :post_message
        allow :give_karma
        allow(:brag){ karma >= 5 }
      end

    end
  end

end
