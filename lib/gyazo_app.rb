require 'sinatra/config_file'
require 'gyazo/initialize'
require 'gyazo/image'

class GyazoApp < Sinatra::Base
  register Sinatra::ConfigFile

  set :root, File.expand_path('../', File.dirname(__FILE__))

  config_file 'config/config.yml'
  
  before do
    if !request.get? && options.gyazo_id
      halt(500) unless params[:id] == options.gyazo_id
    end
  end

  get '/' do
    redirect options.repository_url
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
    "http://#{options.my_host rescue request.host_with_port}/#{@image.gyazo_hash}.png"
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
