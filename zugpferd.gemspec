Gem::Specification.new do |spec|
  spec.name          = "zugpferd"
  spec.version       = "0.1.0"
  spec.authors       = ["Alexander Zeitler"]
  spec.summary       = "EN 16931 E-Invoice library for Ruby (UBL + CII)"
  spec.license       = "MIT"
  spec.homepage      = "https://alexzeitler.github.io/zugpferd/"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => "https://github.com/alexzeitler/zugpferd",
    "homepage_uri"    => spec.homepage,
  }

  spec.files = Dir["lib/**/*.rb"] - Dir["lib/zugpferd/validation/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.16"
  spec.add_dependency "bigdecimal", "~> 3.1"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.0"
end
