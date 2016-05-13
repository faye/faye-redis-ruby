Gem::Specification.new do |s|
  s.name              = 'faye-redis'
  s.version           = '0.2.0'
  s.summary           = 'Redis backend engine for Faye'
  s.author            = 'James Coglan'
  s.email             = 'jcoglan@gmail.com'
  s.homepage          = 'http://github.com/faye/faye-redis-ruby'

  s.extra_rdoc_files  = %w[README.md]
  s.rdoc_options      = %w[--main README.md --markup markdown]
  s.require_paths     = %w[lib]

  s.files = %w[CHANGELOG.md README.md] +
            Dir.glob('lib/**/*.rb')

  s.add_dependency 'eventmachine', '>= 0.12.0'
  s.add_dependency 'em-hiredis', '>= 0.3.0'
  s.add_dependency 'multi_json', '>= 1.0.0'
  s.add_dependency 'em-hiredis-sentinel', '>= 0.2.3'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-eventmachine'
  s.add_development_dependency 'websocket-driver'
end
