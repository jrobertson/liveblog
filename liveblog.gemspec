Gem::Specification.new do |s|
  s.name = 'liveblog'
  s.version = '0.3.0'
  s.summary = 'Uses the Dynarex gem to create a daily live blog. Convenient for grouping together microblog posts'
  s.authors = ['James Robertson']
  s.files = Dir['lib/liveblog.rb', 'liveblog.xsl']
  s.add_runtime_dependency('dynarex', '~> 1.5', '>=1.5.5')
  s.add_runtime_dependency('martile', '~> 0.5', '>=0.5.2')
  s.signing_key = '../privatekeys/liveblog.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/liveblog'
end
