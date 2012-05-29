# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{apns}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Pozdena"]
  s.autorequire = %q{apns}
  s.date = %q{2010-03-22}
  s.description = %q{Simple Apple push notification service gem}
  s.email = %q{jpoz@jpoz.net}
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README.textile", "Rakefile", "lib/apns", "lib/apns/core.rb", "lib/apns/notification.rb", "lib/apns.rb"]
  s.homepage = %q{http://github.com/jpoz/apns}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Simple Apple push notification service gem}

  s.add_development_dependency 'rspec'

end
