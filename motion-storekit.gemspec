# -*- encoding: utf-8 -*-
VERSION = "1.0"

Gem::Specification.new do |spec|
  spec.name          = "motion-storekit"
  spec.version       = VERSION
  spec.authors       = ["Mark Wise"]
  spec.email         = ["markmediadude@gmail.com"]
  spec.description   = "StoreKit wrapper for RubyMotion"
  spec.summary       = "Provides classes to make working with In-App Purchases easier."
  spec.homepage      = ""
  spec.license       = ""

  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files         = files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "motion-redgreen"
  spec.add_development_dependency "motion-stump"
  spec.add_development_dependency "bacon-expect"
  spec.add_development_dependency "motion_print"
end
