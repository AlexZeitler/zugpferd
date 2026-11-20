require "zlib"

# Writes small PDFs with attachments, for extractor cases that Ghostscript
# never produces: split name trees, extra or duplicate attachments, /F-only
# file specs, unusual filters.
class PdfBuilder
  def initialize
    @objects = []
  end

  # @return [String] an indirect reference, e.g. "3 0 R"
  def add(body)
    @objects << body
    "#{@objects.size} 0 R"
  end

  # Reserves an object number for a body set later, so objects can refer to
  # each other in a cycle.
  def reserve
    @objects << nil
    @objects.size
  end

  def set(number, body)
    @objects[number - 1] = body
    "#{number} 0 R"
  end

  def stream(dict, data)
    add("<< #{dict} /Length #{data.bytesize} >>\nstream\n".b + data.b + "\nendstream".b)
  end

  # A file specification with its embedded file. Pass uf: nil or f: nil to
  # leave a key out; uf may be a hex string such as "<FEFF0066...>".
  def attachment(xml, uf: nil, f: nil, filter: :flate)
    data, filter_entry =
      case filter
      when :flate then [Zlib::Deflate.deflate(xml), "/Filter /FlateDecode"]
      when :none then [xml, ""]
      else [xml, "/Filter /#{filter}"]
      end
    file = stream("/Type /EmbeddedFile /Subtype /text#2Fxml #{filter_entry}", data)

    names = ""
    names += " /F #{pdf_string(f)}" if f
    names += " /UF #{pdf_string(uf)}" if uf
    add("<< /Type /Filespec#{names} /EF << /F #{file} /UF #{file} >> /AFRelationship /Data >>")
  end

  # @param af [Array<String>] file spec references for the catalog's /AF
  # @param embedded_files [String, nil] reference to the EmbeddedFiles name tree root
  def render(af: [], embedded_files: nil)
    pages = add("<< /Type /Pages /Kids [] /Count 0 >>")
    catalog = "<< /Type /Catalog /Pages #{pages}"
    catalog += " /AF [#{af.join(" ")}]" if af.any?
    catalog += " /Names << /EmbeddedFiles #{embedded_files} >>" if embedded_files
    root = add(catalog + " >>")

    out = "%PDF-1.7\n%\xE2\xE3\xCF\xD3\n".b
    offsets = @objects.each_with_index.map do |body, index|
      offset = out.bytesize
      out << "#{index + 1} 0 obj\n".b << body.b << "\nendobj\n".b
      offset
    end

    xref = out.bytesize
    out << "xref\n0 #{@objects.size + 1}\n0000000000 65535 f \n".b
    offsets.each { |offset| out << format("%010d 00000 n \n", offset).b }
    out << "trailer\n<< /Size #{@objects.size + 1} /Root #{root} >>\nstartxref\n#{xref}\n%%EOF\n".b
  end

  def name_tree(pairs)
    add("<< /Names [#{pairs.map { |name, ref| "#{pdf_string(name)} #{ref}" }.join(" ")}] >>")
  end

  private

  def pdf_string(value)
    value.start_with?("<") ? value : "(#{value})"
  end
end
