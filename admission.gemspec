require_relative './lib/admission/version'

Gem::Specification.new do |spec|

  spec.name = 'admission'
  spec.version = Admission::VERSION
  spec.summary = 'admission library'
  spec.license = 'GPL-3.0'

  spec.homepage = 'https://github.com/doooby/admission'
  spec.author = 'Ondřej Želazko'
  spec.description = 'Admission rules to actions or resources, privileges system included'
  spec.email = 'zelazk.o@email.cz'

  spec.files = (`git ls-files -z lib visualisation/dist/app.js admission.gemspec`).split "\x0"
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.0'

end
