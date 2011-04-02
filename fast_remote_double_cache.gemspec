require 'rubygems' 

SPEC = Gem::Specification.new do |s|
  s.name = 'fast_remote_double_cache'
  s.version = '0.1'
  
  s.authors = ['Le1t0']
  s.summary = 'A version of 37signals fast_remote_cache deployment strategy, which makes a separate checkout where tasks can be run prior to deploy, instead of during deploy'
  s.description = s.summary.dup
  s.email = 'dev@ewout.to'
  s.homepage = 'http://github.com/le1t0/fast_remote_double_cache'

  s.require_paths = ['lib']
  s.add_dependency('le1t0-capistrano', '= 2.5.18.024')
  candidates = Dir.glob("{bin,lib}/**/*") 
  candidates.concat(%w(LICENSE README.rdoc))
  s.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  s.default_executable = "fast_remote_double_cache"
  s.executables = ["fast_remote_double_cache"]
end
