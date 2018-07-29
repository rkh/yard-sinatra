Gem::Specification.new do |s|
  # Get the facts.
  s.name             = "yard-sinatra"
  s.version          = "1.0.0"
  s.description      = "Displays Sinatra routes (including comments) in YARD output."

  # External dependencies
  s.add_dependency "yard", "~> 0.7"
  s.add_dependency "mustermann", ">= 1.0"
  s.add_development_dependency "rspec", "~> 2.6"

  # Those should be about the same in any BigBand extension.
  s.authors          = ["Konstantin Haase"]
  s.email            = "konstantin.mailinglists@googlemail.com"
  s.files            = Dir["**/*.{rb,md}"] << "LICENSE"
  s.homepage         = "http://github.com/rkh/#{s.name}"
  s.require_paths    = ["lib"]
  s.summary          = s.description
end
