require 'sinatra'
require 'mongo'
require 'json/ext'

before do
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"

    halt 200
  end
end

configure do
  collections = Mongo::Client.new(['127.0.0.1:27017'], :database => 'test')
  set :collection, collections[:restaurants]
  set :bind, '0.0.0.0'
end

get '/' do
  'Hello world!'
end

get '/restaurants/?' do
  content_type :json
  @collection.find.to_a.to_json
end

get '/restaurants/:id/?' do
  content_type :json
  restaurant_by_id(params[:id])
end

helpers do
  def restaurant_by_id id
    id = object_id(id) if String === id
    return {}.to_json if id.nil?

    restaurant = @collection.find(_id: id).to_a.first
    (restaurant || {}).to_json
  end

  def object_id val
    begin
      BSON::ObjectId.from_string(val)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end
end

post '/restaurants/search' do
  request.body.rewind
  request_payload = JSON.parse request.body.read
  print request_payload
  # do something with the payload
end

post '/restaurants/?' do
  puts @collection
  puts params
  content_type :json
  result = @collection.insert_one params

  status 201
  body ''
  response.headers['Location '] = result.inserted_id
  @collection.find(_id: result.inserted_id).to_a.first.to_json
end

# This API should be changed.
put '/update/:id/?' do
  content_type :json
  id = object_id(params[:id])
  @collection.find(_id: id)
    .find_one_and_update('$set' => request.params)
  document_by_id(id)
end

# This API should be changed.
put '/update_name/:id/?' do
  content_type :json
  id = object_id(params[:id])
  name = params[:name]
  @collection.find(_id: id)
    .find_one_and_update('$set' => {name: name})
  document_by_id(id)
end

delete '/restaurants/:id' do
  content_type :json
  id = object_id(params[:id])
  hits = @collection.find(_id: id)
  exists = !restaurant.to_a.first.nil?;
  hits.find_one_and_delete if exists
  { success: exists }.to_json
end