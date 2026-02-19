Gem::Specification.new do |spec|
  spec.name          = "zugpferd"
  spec.version       = "0.3.1"
  spec.authors       = ["Alexander Zeitler"]
  spec.summary       = "XRechnung & ZUGFeRD e-invoicing library for Ruby (UBL + CII)"
  spec.description   = "Read, write and convert XRechnung and ZUGFeRD electronic invoices " \
                        "(e-Rechnung) according to EN 16931. Supports UBL 2.1 and UN/CEFACT CII " \
                        "syntaxes with dedicated classes for Invoice, Credit Note, Corrected Invoice, " \
                        "Self-billed Invoice, Partial Invoice and Prepayment Invoice."
  spec.license       = "MIT"
  spec.homepage      = "https://alexzeitler.github.io/zugpferd/"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri"   => "https://github.com/alexzeitler/zugpferd",
    "homepage_uri"      => spec.homepage,
    "changelog_uri"     => "https://github.com/alexzeitler/zugpferd/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/zugpferd",
    "bug_tracker_uri"   => "https://github.com/alexzeitler/zugpferd/issues",
  }

  spec.files = Dir["lib/**/*.rb"] + Dir["vendor/zugferd/**/*"] + ["bin/setup-schemas"]
  spec.executables = ["setup-schemas"]
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.16"
  spec.add_dependency "bigdecimal", "~> 3.1"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.0"
end
