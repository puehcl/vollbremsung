# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vollbremsung'

Gem::Specification.new do |spec|
  spec.name        = 'vollbremsung'
  spec.version     = Vollbremsung::VERSION
  spec.date        = '2014-09-21'
  spec.summary     = "Handbrake bulk encoding tool"
  spec.description = "vollbremsung is a Handbrake bulk encoding tool, desigend to reencode a file structure to a DLNA enabled TV compatible format comfortably."
  spec.author      = "Maximilian Irro"
  spec.email       = 'max@disposia.org'
  spec.files       = `git ls-files -z`.split("\x0")
  spec.executables = ['vollbremsung']
  spec.homepage    = 'https://github.com/mpgirro/vollbremsung'
  spec.license     = 'MIT'
  
  spec.require_paths = ['lib']
  
  spec.required_ruby_version = '>= 1.9.3'
  spec.add_dependency 'handbrake', '~> 0.4'
  
end