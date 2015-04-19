Gem::Specification.new do |s|
  s.name = 'liveblog'
  s.version = '0.9.7'
  s.summary = 'Uses the Dynarex gem to create a daily live blog. Convenient for grouping together microblog posts'
  s.authors = ['James Robertson']
  s.files = Dir['lib/liveblog.rb', 'lib/liveblog.xsl', 'lib/liveblog.css']
  s.add_runtime_dependency('dynarex', '~> 1.5', '>=1.5.20')
  s.add_runtime_dependency('martile', '~> 0.5', '>=0.5.11')
  s.add_runtime_dependency('simple-config', '~> 0.3', '>=0.3.1')
  s.add_runtime_dependency('subunit', '~> 0.2', '>=0.2.4')
  s.add_runtime_dependency('rexle-diff', '~> 0.5', '>=0.5.4')
  s.signing_key = '../privatekeys/liveblog.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/liveblog'
  s.required_ruby_version = '>= 2.1.2'
end
