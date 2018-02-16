require_relative 'lib/admission/version'

Gem::Specification.new do |spec|

  spec.name = 'admission'
  spec.version = Admission::VERSION
  spec.summary = 'admission library'
  spec.license = 'GPL-3.0'

  spec.homepage = 'https://github.com/doooby/admission'
  spec.author = 'doooby'
  spec.description = 'update-me'
  spec.email = 'zelazk.o@email.cz'

  ignore_files_regex = %r~^examples~
  library_files = (`git ls-files -z`).split "\x0"
  library_files.reject!{|f| ignore_files_regex === f}
  spec.files = library_files

end
