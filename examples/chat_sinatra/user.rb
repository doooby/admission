
class User

  DB = Concurrent::Hash.new

  attr_reader :id, :name, :status, :ws
  attr_accessor :karma

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
