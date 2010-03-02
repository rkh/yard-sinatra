require "sinatra/base"
require "user"

class ExampleApp < Sinatra::Base

  # Settings for a given user
  #
  # @param [User] some user
  # @return [Hash] settings for that user
  def settings(some_user)
    raise NotImplementedMethod
  end
  
  # Displays a settings page for the current user
  #
  # @see ExampleApp#settings
  get "/settings" do
    haml :settings, {}, :settings => settings(current_user)
  end
  
  put("/settings") { }
  delete("/settings") { }
  post("/settings") { }
  head("/settings") { }

end