require File.expand_path('../spec_helper', __FILE__)

describe GyazoApp do
  before :all do
    @file = File.open(File.expand_path('../dummy-image.png', __FILE__))
    @image = Gyazo::Image.create!(:gyazo_hash => "test-hash", :body => BSON::Binary.new(@file.read))
  end

  it 'says hello' do
    get '/'
    last_response.should be_not_found
  end

  it 'should be uploaded something' do
    Gyazo::Image.should_receive(:create!).and_return(@image)
    post '/upload.cgi', :imagedata => Rack::Test::UploadedFile.new(@file.path)
    last_response.should be_ok
  end

  it 'should show image' do
    get '/test-hash.png'
    last_response.should be_ok
  end

  it 'should be able to delete image' do
    delete '/test-hash.png'
    last_response.should be_ok
    Gyazo::Image.where(:gyazo_hash => "test-hash").first.should be_nil
  end
end
