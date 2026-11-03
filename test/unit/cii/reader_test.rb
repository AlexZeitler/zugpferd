require "test_helper"

class CIIReaderTest < Minitest::Test
  include XmlHelper
  include Zugpferd::Model

  def test_reads_tax_total_when_present
    xml = Zugpferd::CII::Writer.new.write(invoice_with(subtotal("S", "19.00")))
    breakdown = read(xml).tax_breakdown

    assert_equal BigDecimal("19"), breakdown.tax_amount
    assert_equal "SEK", breakdown.currency_code
  end

  def test_sets_zero_when_tax_total_is_missing_and_breakdown_sums_to_zero
    breakdown = read(without_tax_total(invoice_with(subtotal("O", "0")))).tax_breakdown

    assert_equal BigDecimal("0"), breakdown.tax_amount
  end

  def test_sets_zero_for_several_breakdown_entries_summing_to_zero
    invoice = invoice_with(subtotal("O", "0"), subtotal("E", "0.00"))
    breakdown = read(without_tax_total(invoice)).tax_breakdown

    assert_equal BigDecimal("0"), breakdown.tax_amount
    assert_equal %w[O E], breakdown.subtotals.map(&:category_code)
  end

  def test_takes_currency_from_invoice_when_tax_total_is_missing
    breakdown = read(without_tax_total(invoice_with(subtotal("O", "0")))).tax_breakdown

    assert_equal "SEK", breakdown.currency_code
    assert_equal %w[SEK], breakdown.subtotals.map(&:currency_code)
  end

  def test_raises_when_tax_total_is_missing_and_total_includes_vat
    invoice = invoice_with(subtotal("S", "19.00"), tax_inclusive_amount: "119.00")
    error = assert_raises(Zugpferd::CII::Reader::MissingTaxTotalError) { read(without_tax_total(invoice)) }

    assert_includes error.message, "BT-110"
  end

  def test_raises_when_tax_total_is_missing_and_total_excludes_vat
    invoice = invoice_with(subtotal("S", "19.00"), tax_inclusive_amount: "100.00")

    assert_raises(Zugpferd::CII::Reader::MissingTaxTotalError) { read(without_tax_total(invoice)) }
  end

  def test_raises_when_tax_total_is_missing_and_breakdown_sums_to_negative_amount
    invoice = invoice_with(subtotal("S", "-19.00"))

    assert_raises(Zugpferd::CII::Reader::MissingTaxTotalError) { read(without_tax_total(invoice)) }
  end

  def test_raises_when_tax_total_is_missing_and_breakdown_is_empty
    assert_raises(Zugpferd::CII::Reader::MissingTaxTotalError) { read(without_tax_total(invoice_with)) }
  end

  def test_missing_tax_total_error_is_a_zugpferd_error
    assert_operator Zugpferd::CII::Reader::MissingTaxTotalError, :<, Zugpferd::Error
  end

  private

  def read(xml)
    Zugpferd::CII::Reader.new.read(xml)
  end

  def without_tax_total(invoice)
    doc = parse_xml(Zugpferd::CII::Writer.new.write(invoice))
    doc.at_xpath("//ram:TaxTotalAmount", CII_NS).remove
    doc.to_xml
  end

  def subtotal(category_code, tax_amount)
    TaxSubtotal.new(taxable_amount: "100.00", tax_amount: tax_amount, category_code: category_code, currency_code: "SEK")
  end

  def invoice_with(*subtotals, tax_inclusive_amount: "100.00")
    invoice = Invoice.new(number: "RE-1", issue_date: Date.new(2024, 6, 15), currency_code: "SEK")
    invoice.tax_breakdown = TaxBreakdown.new(tax_amount: subtotals.sum(BigDecimal("0"), &:tax_amount), currency_code: "SEK")
    invoice.tax_breakdown.subtotals = subtotals
    invoice.monetary_totals = MonetaryTotals.new(
      line_extension_amount: "100.00", tax_exclusive_amount: "100.00",
      tax_inclusive_amount: tax_inclusive_amount, payable_amount: tax_inclusive_amount
    )
    invoice
  end
end
