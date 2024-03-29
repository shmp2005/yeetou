# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yeetou/version'

Gem::Specification.new do |gem|
  gem.name = "yeetou"
  gem.version = Yeetou::VERSION
  gem.authors = ["Jianhua Tang"]
  gem.email = %w[shmp2005@163.com]
  gem.description = %q{ Write a gem description}
  gem.summary = %q{ Write a gem summary}
  gem.homepage = "http://www.yeetou.com"

  gem.add_dependency "mongoid", ["~> 3.0.4"]

  gem.files = `git ls-files`.split($/)
  gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w[lib]
end
