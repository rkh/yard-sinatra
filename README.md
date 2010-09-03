YARD::Sinatra
=============

This plugin adds [Sinatra](http://sinatrarb.com) routes to [YARD](http://yardoc.org/) output.

BigBand
-------

YARD::Sinatra is part of the [BigBand](http://github.com/rkh/big_band) stack.
Check it out if you are looking for fancy Sinatra extensions.

Usage
-----

Install via gemcutter:

    gem install yard-sinatra

Add comments to your routes (well, that's optional):

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
    
    end

The you're ready to go:

    yardoc example_app.rb

YARD will automatically detect the yard-sinatra plugin and load it.

Other use cases
---------------

As with yard, this can be used for other means besides documentation.
For instance, you might want a list of all routes defined in a given list of files without executing those files:

    require "yard/sinatra"
    YARD::Registry.load Dir.glob("lib/**/*.rb")
    YARD::Sinatra.routes.each do |route|
      puts route.http_verb, route.http_path, route.file, route.docstring
    end

Thanks
------

* Ryan Sobol for implementing *not\_found* documentation.
* Loren Segal for making it seamlessly work as YARD plugin.
  Well, and for YARD.
