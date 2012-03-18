require 'sinatra/config_file'
require 'gyazo/image'
require 'haml'

class GyazoApp < Sinatra::Base
  register Sinatra::ConfigFile
  enable :inline_templates

  set :root, File.expand_path('../', File.dirname(__FILE__))

  config_file 'config/config.yml'

  configure do
    if mongo_uri = ENV['MONGOHQ_URL']
      Mongoid.database = Mongo::Connection.from_uri(mongo_uri).
        db(URI.parse(mongo_uri).path.gsub(/^\//, ''))
    else # can spin up on local
      host = settings.mongo_host rescue 'localhost'
      port = settings.mongo_port rescue Mongo::Connection::DEFAULT_PORT
      database_name = settings.mongo_database
      Mongoid.database = Mongo::Connection.new(host, port).db(database_name)
    end
    Mongoid.autocreate_indexes = true
  end

  before do
    gyazo_id = settings.gyazo_id rescue ENV['gyazo_id']
    if !request.get? && gyazo_id
      halt(500) unless params[:id] == gyazo_id
    end
  end

  get '/' do
    @images = Gyazo::Image.order_by([:created_at, :desc]).all
    haml :index
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

__END__

@@ layout
!!! 5
%html
  %head
    %title yuyat's Gyazo
    %meta{'http-equiv' => 'Content-Type', :content => 'text/html'}
  %body
    = yield

@@ index
%h1 yuyat's Gyazo
%p #{@images.size} pictures posted.
%ul
  - @images.each do |image|
    %li
      .posted_at #{image.created_at}
      .image
        %img{:src => "/#{image.gyazo_hash}.png"}
