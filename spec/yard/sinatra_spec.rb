require "yard/sinatra"

describe YARD::Sinatra do
  before(:all) do
    $NO_CONTINUATION_WARNING = true
    YARD::Registry.load [File.expand_path("../../example_app.rb", __FILE__)], true
  end

  it "reads sinatra routes" do
    YARD::Sinatra.routes.size.should == 5
  end

  it "sets properties correctly" do
    YARD::Sinatra.routes.each do |route|
      %w[GET HEAD POST PUT DELETE].should include(route.http_verb)
      route.http_path.should == "/settings"
      route.file.should =~ /example_app\.rb$/
      route.docstring.should =~ /Displays a settings page for the current user/ if route.http_verb == "GET"
    end
  end

  it "reads sinatra error handlers" do
    YARD::Sinatra.error_handlers.size.should == 1
  end

  it "sets error handlers correctly" do
    YARD::Sinatra.error_handlers.each do |error_handler|
      %w[NOT_FOUND].should include(error_handler.http_verb)
      error_handler.file.should =~ /example_app\.rb$/
      error_handler.docstring.should =~ /Error 404 Page Not Found/ if error_handler.http_verb == "NOT_FOUND"
    end
  end

end
