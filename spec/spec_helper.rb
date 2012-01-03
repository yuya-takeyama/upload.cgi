ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler/setup'
Bundler.require()
Bundler.require(:test)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'gyazo_app'

GyazoApp.set :gyazo_id, false

RSpec.configure do |c|
  c.include Rack::Test::Methods

  def app
    GyazoApp
  end

  c.before :all do
    Gyazo::Image.delete_all
  end
 
  c.after :all do
    Gyazo::Image.delete_all
  end
end
