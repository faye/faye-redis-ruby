Gem::Specification.new do |s|
  s.name              = "faye-redis"
  s.version           = "0.1.0"
  s.summary           = "Redis backend engine for Faye"
  s.author            = "James Coglan"
  s.email             = "jcoglan@gmail.com"
  s.homepage          = "http://github.com/faye/faye-redis-ruby"

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]
  s.require_paths     = %w[lib]

  s.files = %w[README.rdoc] + Dir.glob("{spec,lib}/**/*")

  s.add_dependency "eventmachine", ">= 0.12.0"
  s.add_dependency "em-hiredis", ">= 0.0.1"
  s.add_dependency "multi_json"

  s.add_development_dependency "rspec"
end
