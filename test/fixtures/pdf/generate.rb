# Regenerates the Ghostscript fixtures in this directory. Needs Ghostscript
# and bin/setup-schemas, so run it in the Docker image:
#
#   docker compose run --rm test ruby -Ilib test/fixtures/pdf/generate.rb
require "zugpferd"
require "zugpferd/pdf"
require "tmpdir"

dir = __dir__
cii = File.binread(File.expand_path("../cii/invoice.xml", dir))
zugferd1 = File.binread(File.join(dir, "zugferd-1p0.xml"))

FIXTURES = {
  "ghostscript-2p1.pdf" => [cii, "2p1", "EN 16931"],
  "ghostscript-2p1-xrechnung.pdf" => [cii, "2p1", "XRECHNUNG"],
  "ghostscript-2p0.pdf" => [cii, "2p0", "EN 16931"],
  "ghostscript-1p0.pdf" => [zugferd1, "1p0", "BASIC"],
}.freeze

Dir.mktmpdir do |tmp|
  ps = File.join(tmp, "base.ps")
  base = File.join(tmp, "base.pdf")
  File.write(ps, "%!PS\n/Helvetica findfont 12 scalefont setfont\n72 750 moveto (Invoice) show\nshowpage\n")
  system("gs", "-q", "-dBATCH", "-dNOPAUSE", "-sDEVICE=pdfwrite", "-o", base, ps, exception: true)

  FIXTURES.each do |name, (xml, version, level)|
    Zugpferd::PDF::Embedder.new.embed(
      pdf_path: base, xml: xml, output_path: File.join(dir, name),
      version: version, conformance_level: level
    )
    puts "#{name}: #{File.size(File.join(dir, name))} bytes"
  end
end
