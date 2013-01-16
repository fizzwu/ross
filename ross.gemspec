# coding: utf-8
Gem::Specification.new do |s|
  s.name = 'ross'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.summary = "ROSS is a ruby client for aliyun oss"
  s.authors = ["Fizz Wu"]
  s.email = "fizzwu@gmail.com"
  s.files = `git ls-files`.split("\n")
  
  s.add_dependency("rest-client", ">=1.6.0")
end