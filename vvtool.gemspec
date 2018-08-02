
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vvtool/version"

Gem::Specification.new do |spec|
  spec.name          = "vvtool"
  spec.version       = VVTool::VERSION
  spec.authors       = ["isaced"]
  spec.email         = ["isaced@163.com"]

  spec.summary       = "VVTool - VirtualView 工具集."
  spec.description   = "目前可用于结合 VVPlayground 支持 VirtualView 模版开发实时预览."
  spec.homepage      = "https://github.com/isaced/VVTool"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.add_dependency "thor", "~> 0.20"
  spec.add_dependency "listen", "~> 3.0"
end
