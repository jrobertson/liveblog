Gem::Specification.new do |s|
  s.name = 'liveblog'
  s.version = '1.2.15'
  s.summary = 'Uses the Dynarex gem to create a daily live blog. Convenient for grouping together microblog posts'
  s.authors = ['James Robertson']
  s.files = Dir['lib/liveblog.rb', 'lib/liveblog.xsl', 'lib/today.xsl', 'lib/liveblog.css']
  s.add_runtime_dependency('dxsectionx', '~> 0.2', '>=0.2.0')
  s.add_runtime_dependency('simple-config', '~> 0.6', '>=0.6.3')
  s.add_runtime_dependency('subunit', '~> 0.2', '>=0.2.7')
  s.add_runtime_dependency('rexle-diff', '~> 0.6', '>=0.6.2')
  s.signing_key = '../privatekeys/liveblog.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/liveblog'
  s.required_ruby_version = '>= 2.1.2'
end
