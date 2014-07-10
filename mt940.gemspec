# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'mt940/version'

Gem::Specification.new do |s|
  s.name        = 'mt940'
  s.version     = MT940::VERSION
  s.authors     = ['Frank Oxener']
  s.description = %q{A basic MT940 parser.}
  s.summary     = %q{MT940 parser}
  s.email       = %q{frank.oxener@gmail.com}

  s.homepage    = %q{http://github.com/dovadi/mt940}
  s.licenses    = ['MIT']

  s.extra_rdoc_files = [
     'LICENSE.txt',
     'README.md'
   ]

  s.files         = `git ls-files`.split(/\n/)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split(/\n/)
  s.executables   = `git ls-files -- bin/*`.split(/\n/).map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activesupport'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'test-unit'
end
