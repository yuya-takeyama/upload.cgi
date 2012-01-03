require 'sinatra/config_file'
require 'gyazo/image'

class GyazoApp < Sinatra::Base
  register Sinatra::ConfigFile

  set :root, File.expand_path('../', File.dirname(__FILE__))

  config_file 'config/config.yml'

  configure do
    if mongo_uri = ENV['MONGOHQ_URL']
        Mongoid.database = Mongo::Connection.from_uri(mongo_uri).
                               db(URI.parse(mongo_uri).path.gsub(/^\//, ''))
      else # can spin up on local
        host = settings.respond_to?(:mongo_host) ? settings.mongo_host : 'localhost'
        port = settings.respond_to?(:mongo_port) ? settings.mongo_port :  Mongo::Connection::DEFAULT_PORT
        database_name = settings.mongo_database
      Mongoid.database = Mongo::Connection.new(host, port).db(database_name)
    end
  end

  before do
    if !request.get? && settings.gyazo_id
      halt(500) unless params[:id] == settings.gyazo_id
    end
  end

  get '/' do
    redirect settings.repository_url
  end
  
  get '/favicon.ico' do
    send_file File.expand_path("../../favicon.ico", __FILE__),
              :type => 'image/x-icon', :disposition => 'inline' \
        rescue raise(Sinatra::NotFound)
  end

  post '/upload.cgi' do
    data = (begin
              params[:imagedata][:tempfile].read
            rescue
              params[:imagedata]
            end)
    hash = Digest::MD5.hexdigest(data).to_s
    @image = Gyazo::Image.create!(:gyazo_hash => hash, :body => BSON::Binary.new(data))
    "http://#{settings.my_host rescue request.host_with_port}/#{@image.gyazo_hash}.png"
  end

  get '/:hash.png' do
    @image = Gyazo::Image.where(:gyazo_hash => params[:hash]).first \
        or raise(Sinatra::NotFound)
    content_type 'image/png'
    @image.body.to_s
  end

  delete '/:hash.png' do
    content_type 'text/plain'
    @image = Gyazo::Image.where(:gyazo_hash => params[:hash]).first
    @image.destroy ? "Destroy Success!" : halt(503)
  end
end
