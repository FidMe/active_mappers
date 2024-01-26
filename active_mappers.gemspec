Gem::Specification.new do |s|
  s.name        = 'active_mappers'
  s.version     = '1.5.2'
  s.date        = '2024-01-26'
  s.summary     = 'Slick, fast view layer for you Rails API.'
  s.description = 'Fast, simple, declarative way to design your API\'s view layer'
  s.authors     = ['Michaël Villeneuve', 'Loïc SENCE']
  s.homepage    = 'https://github.com/fidme/active_mappers'
  s.email       = 'contact@michaelvilleneuve.fr'
  s.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  s.license = 'MIT'
  s.add_runtime_dependency('activesupport', ['>= 4.2'])
  s.add_runtime_dependency('method_source', ['~> 0.9.2'])
  s.add_runtime_dependency('mocha', ['>= 1.8.0'])
  s.add_runtime_dependency('ruby2ruby', ['> 2.4.0'])
  s.add_runtime_dependency('ruby_parser', ['~> 3.1'])
end
