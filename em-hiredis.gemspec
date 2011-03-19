# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'em-hiredis/version'

Gem::Specification.new do |s|
  s.name        = 'em-hiredis'
  s.version     = EM::Hiredis::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Martyn Loughran']
  s.email       = ['me@mloughran.com']
  s.homepage    = 'http://github.com/mloughran/em-hiredis'
  s.summary     = 'Eventmachine redis client'
  s.description = 'Eventmachine redis client using hiredis native parser'

  s.add_dependency 'hiredis', '~> 0.3.0'
  s.add_dependency 'eventmachine', '= 0.12.10'

  s.rubyforge_project = 'em-hiredis'

  s.files         = Dir.glob('**/*')
  s.test_files    = Dir.glob('{test,spec,features}/*')
  s.executables   = Dir.glob('bin/*').map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
