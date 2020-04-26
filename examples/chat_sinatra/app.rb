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
