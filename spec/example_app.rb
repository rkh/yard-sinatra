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

  # Error 404 Page Not Found
  not_found do
    haml :'404'
  end

  put("/settings") { }
  delete("/settings") { }
  post("/settings") { }
  head("/settings") { }

  namespace "/nested" do
    # root
    get do
      "this is a route at the root of the namespace"
    end

    # nested route
    get("/route") {"this is a nested route!"}

		namespace "/double" do
			# double nested route
			get("/route") { }
		end
  end

end
