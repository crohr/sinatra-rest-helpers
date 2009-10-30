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
  
  def test_parse_input_data!(*params)
    parse_input_data!(*params)
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
  describe ":provides" do
    it "should throw a 406 if the client requested only unsupported formats" do
      mime :json, 'application/json'
      mime :xml, 'application/xml'
      mime :object_json, 'application/vnd.com.example.Object+json;level=1'
      request = mock("request", :accept => ["text/plain"])
      app = App.new(request)
      app.should_receive(:halt).with(406, "application/json,application/xml,application/vnd.com.example.Object+json;level=1")
      app.test_provides!(:json, :xml, :object_json)
    end
    it "should not throw a 406 if the client requested a supported format" do
      request = mock("request", :accept => ["application/json"])
      mime :json, "application/json"
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!(:json)
      app.response.headers['Content-Type'].should == "application/json"
    end
    it "should be case insensitive" do
      request = mock("request", :accept => ["application/json"])
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!("application/JSON")
      app.response.headers['Content-Type'].should == "application/JSON"
    end
    it "should not accept a request with a type level lower than what is supported" do
      request = mock("request", :accept => ["application/json;level=1"])
      app = App.new(request)
      app.should_receive(:halt).with(406, "application/json;level=3,application/json;level=2")
      app.test_provides!("application/json;level=3", "application/json;level=2")
    end
    it "should accept a request having a supported mime type, but with no level" do
      request = mock("request", :accept => ["application/json"])
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!("application/json;level=2")
      app.response.headers['Content-Type'].should == "application/json;level=2"
    end
    it "should select the first type matching the criteria" do
      request = mock("request", :accept => ["application/json;level=2", "application/xml", "application/vnd.fr.grid5000.api.Cluster+json;level=2"])
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!("application/json;level=3", "application/vnd.fr.grid5000.api.Cluster+json;level=2")
      app.response.headers['Content-Type'].should == "application/vnd.fr.grid5000.api.Cluster+json;level=2"
    end
    it "should accept requests with a level, even if the developer didn't explicitely defined one" do
      request = mock("request", :accept => ["application/json;level=1"])
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!("application/json")
      app.response.headers['Content-Type'].should == "application/json"
    end
    it "should correctly deal with widlcard characters [client-side, I]" do
      request = mock("request", :accept => ["application/vnd.fr.grid5000.api.*+json"])
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!("application/vnd.fr.grid5000.api.Cluster+json;level=1")
      app.response.headers['Content-Type'].should == "application/vnd.fr.grid5000.api.Cluster+json;level=1"
    end
    it "should correctly deal with widlcard characters [client-side, II]" do
      request = mock("request", :accept => ["application/*"])
      app = App.new(request)
      app.should_not_receive(:halt)
      app.test_provides!("application/vnd.fr.grid5000.api.Cluster+json;level=1")
      app.response.headers['Content-Type'].should == "application/vnd.fr.grid5000.api.Cluster+json;level=1"
    end
  end
  
  describe ":parse_input_data!" do
    it "should load input data in application/x-www-form-urlencoded format" do
      parser_selector = mock("parser_selector")
      request = mock("request", :env => {'rack.request.form_hash' => {"foo" => "bar"}, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'})
      app = App.new(request)
      parser_selector.should_not_receive(:select)
      app.test_parse_input_data!(parser_selector).should == {"foo" => "bar"}
    end
    it "should load input data in application/json format" do
      require 'json'
      parser_selector = mock("parser_selector")
      request = mock("request", :env => {'rack.input' => StringIO.new({"foo" => "bar"}.to_json), 'CONTENT_TYPE' => 'application/json'})
      app = App.new(request)
      parser_selector.should_receive(:select).with('application/json').and_return(JSON)
      app.test_parse_input_data!(parser_selector).should == {"foo" => "bar"}
    end
    it "should halt with a 400 status code if the input data is empty" do
      parser_selector = mock("parser_selector")
      request = mock("request", :env => {'rack.input' => StringIO.new(), 'CONTENT_TYPE' => 'application/json'})
      app = App.new(request)
      app.should_receive(:halt).with(400, /must not be empty/).and_raise(Exception.new)
      lambda{app.test_parse_input_data!(parser_selector)}.should raise_error(Exception)
    end
    it "should halt with a 400 status code if the input data is over the limit" do
      parser_selector = mock("parser_selector")
      request = mock("request", :env => {'rack.input' => StringIO.new("123456789_1"), 'CONTENT_TYPE' => 'application/json'})
      app = App.new(request)
      app.should_receive(:halt).with(400, /must not exceed 10 bytes/).and_raise(Exception.new)
      lambda{app.test_parse_input_data!(parser_selector, :limit => 10)}.should raise_error(Exception)
    end
    it "should halt with a 400 status code if the content type is not set" do
      parser_selector = mock("parser_selector")
      request = mock("request", :env => {'rack.input' => StringIO.new("123456789_1")})
      app = App.new(request)
      app.should_receive(:halt).with(400, /must provide a Content-Type HTTP header/)
      app.test_parse_input_data!(parser_selector)
    end
    it "should return 400 if the request's body is not parseable" do
      require 'json'
      parser_selector = mock("parser_selector")
      request = mock("request", :env => {'rack.input' => StringIO.new('{"foo": bar"}'), 'CONTENT_TYPE' => 'application/json'})
      app = App.new(request)
      parser_selector.should_receive(:select).with('application/json').and_return(JSON)
      app.should_receive(:halt).with(400, /unexpected token at '\{"foo": bar"\}'/)
      app.test_parse_input_data!(parser_selector)
    end
  end
  
  describe ":compute_etag" do
    it "should correctly compute the etag with multiple parameters" do
      App.new(nil).compute_etag([1,2,3], 2, "whatever", :xyz).should == Digest::SHA1.hexdigest([[1,2,3], 2, "whatever", :xyz].join("."))
    end
    it "should correctly compute the etag with one parameter" do
      App.new(nil).compute_etag(1).should == Digest::SHA1.hexdigest([1].join("."))
    end
    it "should raise an Argument Error if no arguments are present" do
      lambda{App.new(nil).compute_etag()}.should raise_error(ArgumentError, /must provide at least one parameter/)
    end
  end
end
