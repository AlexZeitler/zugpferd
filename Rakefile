require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.pattern = "test/unit/**/*_test.rb"
  end

  Rake::TestTask.new(:integration) do |t|
    t.libs << "test"
    t.pattern = "test/integration/**/*_test.rb"
  end

  Rake::TestTask.new(:conformance) do |t|
    t.libs << "test"
    t.pattern = "test/integration/conformance_test.rb"
  end
end

desc "Download schemas and test suite"
task :setup do
  sh "bin/setup-schemas"
end

desc "Validate a single XML file (FILE=path.xml)"
task :validate do
  require "zugpferd"
  file = ENV.fetch("FILE")
  xml = File.read(file)
  errors = Zugpferd::Validation::SchematronValidator.new(
    schemas_path: "vendor/schemas"
  ).validate(xml, rule_set: :cen_ubl)

  if errors.empty?
    puts "Valid"
  else
    errors.each { |e| puts "[#{e.id}] #{e.text}" }
    exit 1
  end
end

task default: :test
