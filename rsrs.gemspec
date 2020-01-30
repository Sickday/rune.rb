require_relative 'lib/rsrs/version'

Gem::Specification.new do |spec|
  ##
  # GEM
  spec.name          = 'rsrs'
  spec.version       = RSRS::VERSION
  spec.authors       = ['Patrick W']
  spec.email         = ['Sickday@pm.me']

  ##
  # INFO
  spec.summary       = %q{A RuneScape game server suite written in Ruby.}
  spec.description   = %q{RuneScape Ruby Suite is a RuneScape game server suite written in Ruby. It's made to be fun to use, easy to follow, and simple to extend.}
  spec.homepage      = "http://jco.xyz"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  ##
  # METADATA
  spec.metadata["allowed_push_host"] = 'http://mygemserver.com'
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = 'https://gitlab.com/sickday/rsrs'
  spec.metadata["changelog_uri"] = 'https://gitlab.com/sickday/rsrs/blob/master/README.md'

  ##
  # DEVELOPMENT DEPENDENCIES
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'pry'

  ##
  # RUNTIME DEPENDENCIES
  spec.add_runtime_dependency 'sorbet-runtime'
  spec.add_runtime_dependency 'sequel'
  spec.add_runtime_dependency 'sqlite3'
  spec.add_runtime_dependency 'concurrent-ruby'
  spec.add_runtime_dependency 'bindata'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
