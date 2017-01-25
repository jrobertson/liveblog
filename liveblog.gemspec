Gem::Specification.new do |s|
  s.name = 'liveblog'
  s.version = '1.2.8'
  s.summary = 'Uses the Dynarex gem to create a daily live blog. Convenient for grouping together microblog posts'
  s.authors = ['James Robertson']
  s.files = Dir['lib/liveblog.rb', 'lib/liveblog.xsl', 'lib/today.xsl', 'lib/liveblog.css']
  s.add_runtime_dependency('dxsectionx', '~> 0.1', '>=0.1.4')
  s.add_runtime_dependency('simple-config', '~> 0.6', '>=0.6.0')
  s.add_runtime_dependency('subunit', '~> 0.2', '>=0.2.4')
  s.add_runtime_dependency('rexle-diff', '~> 0.5', '>=0.5.4')
  s.signing_key = '../privatekeys/liveblog.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/liveblog'
  s.required_ruby_version = '>= 2.1.2'
end
