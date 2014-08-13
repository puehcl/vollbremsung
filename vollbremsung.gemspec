Gem::Specification.new do |s|
  spec.name        = 'vollbremsung'
  spec.version     = Vollbremsung::VERSION
  spec.date        = '2014-08-13'
  spec.summary     = "Handbrake bulk encoding tool"
  spec.description = "Handbrake bulk encoding tool"
  spec.author      = "Maximilian Irro"
  spec.email       = 'max@disposia.org'
  spec.files       = `git ls-files -z`.split("\x0")
  spec.executables = ['vollbremsung']
  spec.homepage    = 'https://github.com/mpgirro/vollbremsung'
  spec.license     = 'MIT'
  
  spec.require_paths = ['lib']
  
  spec.add_dependency 'json' 
  spec.add_dependency 'mkmf' # part of stdlib
  spec.add_dependency 'open3'
  spec.add_dependency 'json'
  spec.add_dependency 'handbrake'
end