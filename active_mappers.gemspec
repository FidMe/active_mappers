Gem::Specification.new do |s|
  s.name        = 'active_mappers'
  s.version     = '1.1.1'
  s.date        = '2018-12-04'
  s.summary     = 'Slick, fast view layer for you Rails API.'
  s.description = 'Fast, simple, declarative way to design your API\'s view layer'
  s.authors     = ['Michaël Villeneuve']
  s.homepage    = 'https://github.com/fidme/active_mappers'
  s.email       = 'contact@michaelvilleneuve.fr'
  s.files       = [
    'lib/core_ext/hash.rb',
    'lib/active_mappers.rb',
    'lib/active_mappers/key_transformer.rb',
    'lib/active_mappers/setup.rb'
  ]
  s.license     = 'MIT'
  s.add_runtime_dependency(%q<activesupport>, [">= 4.2"])
end
