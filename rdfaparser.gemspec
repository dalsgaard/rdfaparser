require 'rubygems'
require 'rake'

Gem::Specification.new do |spec|
  spec.name = 'rdfaparser'
  spec.version = "0.0.1"
  spec.summary = "RDFa parser"
  spec.description = ""
  spec.author = "Kim Dalsgaard"
  spec.email = "kim@kimdalsgaard.com"
  
  spec.add_dependency 'nokogiri'
  spec.files = FileList['lib/**/*.rb']
  spec.require_paths = ['lib']
end
