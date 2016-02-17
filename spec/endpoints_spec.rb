require File.expand_path('../spec_helper', __FILE__)

describe GyazoApp do
  before :each do
    @file = File.open(File.expand_path('../dummy-image.png', __FILE__))
    @image = Gyazo::Image.create!(:gyazo_hash => "test-hash", :body => BSON::Binary.new(@file.read))
  end

  after :each do
    @image.delete rescue nil
  end

  it 'says hello' do
    get '/'
    expect(last_response).to be_ok
  end
  
  it 'has favicon' do
    get '/favicon.ico'
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq('image/x-icon')
  end

  it 'should be uploaded something' do
    expect(Gyazo::Image).to receive(:create!).and_return(@image)
    post '/upload.cgi', :imagedata => Rack::Test::UploadedFile.new(@file.path)
    expect(last_response).to be_ok
  end

  it 'should show image' do
    get '/test-hash.png'
    expect(last_response).to be_ok
  end

  it 'should show 404 if no image' do
    get '/test-nonexist-hash.png'
    expect(last_response).to be_not_found
  end

  it 'should be able to delete image' do
    delete '/test-hash.png'
    expect(last_response).to be_ok
    expect(Gyazo::Image.where(:gyazo_hash => "test-hash").first).to be_nil
  end
end
