# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{apns}
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Pozdena", "Thomas Kollbach"]
  s.autorequire = %q{apns}
  s.date = %q{2013-08-28}
  s.description = <<DESC
Simple Apple push notification service gem.
It supports the 3rd wire format (command 2) with support for content-availible (Newsstand), expiration dates and delivery priority (background pushes)}
DESC

  s.email = ["jpoz@jpoz.net", "thomas@kollba.ch"]
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README.textile", "Rakefile", "lib/apns", "lib/apns/core.rb", "lib/apns/notification.rb", "lib/apns.rb"]
  s.homepage = %q{http://github.com/jpoz/apns}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Simple Apple push notification service gem}

  s.add_development_dependency 'rspec'

end
