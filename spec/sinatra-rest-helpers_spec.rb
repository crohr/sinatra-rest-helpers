require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


class App
  include Sinatra::RestHelpers
  
  attr_accessor :request, :response
  def initialize(request)
    @request = request
    @response = OpenStruct.new(:headers => {})
  end
  
  def test_provides!(*params)
    provides *params
  end
end

def mime(ext, type)
  ext = ".#{ext}" unless ext.to_s[0] == ?.
  Rack::Mime::MIME_TYPES[ext.to_s] = type
end

describe "SinatraRestHelpers" do
  before(:each) do
    Rack::Mime::MIME_TYPES.clear
  end
  it "should throw a 406 if the client requested only unsupported formats" do
    request = mock("request", :accept => "application/json")
    app = App.new(request)
    app.should_receive(:halt).with(406, "")
    app.test_provides!(:json)
  end
  it "should not throw a 406 if the client requested a supported format" do
    request = mock("request", :accept => "application/json")
    mime :json, "application/json"
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!(:json)
    app.response.headers['Content-Type'].should == "application/json"
  end
  it "should be case insensitive" do
    request = mock("request", :accept => "application/json")
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!("application/JSON")
    app.response.headers['Content-Type'].should == "application/JSON"
  end
  it "should not accept a request with a type level lower than what is supported" do
    request = mock("request", :accept => "application/json;level=1")
    app = App.new(request)
    app.should_receive(:halt).with(406, "application/json;level=3, application/json;level=2")
    app.test_provides!("application/json;level=3", "application/json;level=2")
  end
  it "should accept a request having a supported mime type, but with no level" do
    request = mock("request", :accept => "application/json")
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!("application/json;level=2")
    app.response.headers['Content-Type'].should == "application/json;level=2"
  end
  it "should select the first type matching the criteria" do
    request = mock("request", :accept => "application/json;level=2, application/xml, application/vnd.fr.grid5000.api.Cluster+json;level=2")
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!("application/json;level=3", "application/vnd.fr.grid5000.api.Cluster+json;level=2")
    app.response.headers['Content-Type'].should == "application/vnd.fr.grid5000.api.Cluster+json;level=2"
  end
  it "should accept requests with a level, even if the developer didn't explicitely defined one" do
    request = mock("request", :accept => "application/json;level=1")
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!("application/json")
    app.response.headers['Content-Type'].should == "application/json"
  end
  it "should correctly deal with widlcard characters [client-side, I]" do
    request = mock("request", :accept => "application/vnd.fr.grid5000.api.*+json")
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!("application/vnd.fr.grid5000.api.Cluster+json;level=1")
    app.response.headers['Content-Type'].should == "application/vnd.fr.grid5000.api.Cluster+json;level=1"
  end
  it "should correctly deal with widlcard characters [client-side, II]" do
    request = mock("request", :accept => "application/*")
    app = App.new(request)
    app.should_not_receive(:halt)
    app.test_provides!("application/vnd.fr.grid5000.api.Cluster+json;level=1")
    app.response.headers['Content-Type'].should == "application/vnd.fr.grid5000.api.Cluster+json;level=1"
  end
end
