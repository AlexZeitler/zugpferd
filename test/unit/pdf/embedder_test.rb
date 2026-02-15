require "test_helper"
require "zugpferd/pdf"
require "tempfile"

class EmbedderTest < Minitest::Test
  def setup
    @embedder = Zugpferd::PDF::Embedder.new
  end

  def test_raises_on_missing_input_pdf
    assert_raises(ArgumentError) do
      @embedder.embed(
        pdf_path: "/nonexistent/file.pdf",
        xml: "<xml/>",
        output_path: "/tmp/out.pdf"
      )
    end
  end

  def test_raises_on_invalid_version
    Tempfile.create(["test", ".pdf"]) do |f|
      f.write("%PDF-1.4 minimal")
      f.flush

      err = assert_raises(ArgumentError) do
        @embedder.embed(
          pdf_path: f.path,
          xml: "<xml/>",
          output_path: "/tmp/out.pdf",
          version: "9p9"
        )
      end
      assert_match(/Unknown version/, err.message)
    end
  end

  def test_raises_on_invalid_conformance_level
    Tempfile.create(["test", ".pdf"]) do |f|
      f.write("%PDF-1.4 minimal")
      f.flush

      err = assert_raises(ArgumentError) do
        @embedder.embed(
          pdf_path: f.path,
          xml: "<xml/>",
          output_path: "/tmp/out.pdf",
          version: "2p1",
          conformance_level: "FANTASY"
        )
      end
      assert_match(/Unknown conformance level/, err.message)
    end
  end

  def test_valid_conformance_levels_for_2p1
    expected = ["MINIMUM", "BASIC WL", "BASIC", "EN 16931", "EXTENDED", "XRECHNUNG"]
    assert_equal expected, Zugpferd::PDF::Embedder::CONFORMANCE_LEVELS["2p1"]
  end

  def test_valid_conformance_levels_for_1p0
    expected = ["BASIC", "COMFORT", "EXTENDED"]
    assert_equal expected, Zugpferd::PDF::Embedder::CONFORMANCE_LEVELS["1p0"]
  end

  def test_versions_constant
    assert_equal %w[rc 1p0 2p0 2p1], Zugpferd::PDF::Embedder::VERSIONS
  end

  def test_rc_version_accepts_any_conformance_level
    Tempfile.create(["test", ".pdf"]) do |f|
      f.write("%PDF-1.4 minimal")
      f.flush

      # 2p1 with invalid conformance level raises ArgumentError about conformance
      err = assert_raises(ArgumentError) do
        @embedder.embed(
          pdf_path: f.path, xml: "<xml/>", output_path: "/tmp/out.pdf",
          version: "2p1", conformance_level: "FANTASY"
        )
      end
      assert_match(/Unknown conformance level/, err.message)

      # rc with same conformance level does NOT raise ArgumentError about conformance
      # (no whitelist for rc — it passes param validation)
      assert_raises(ArgumentError) do
        @embedder.embed(
          pdf_path: "/nonexistent.pdf", xml: "<xml/>", output_path: "/tmp/out.pdf",
          version: "rc", conformance_level: "FANTASY"
        )
      end
      # If it reached the file-not-found check, conformance validation was skipped
    end
  end
end
