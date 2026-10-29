require "test_helper"

class UBLWriterTest < Minitest::Test
  include XmlHelper
  include Zugpferd::Model

  def test_writes_invoicing_period
    doc = write(invoice_with_period)

    assert_equal "2024-06-01", xpath_text(doc, "/ubl:Invoice/cac:InvoicePeriod/cbc:StartDate")
    assert_equal "2024-06-30", xpath_text(doc, "/ubl:Invoice/cac:InvoicePeriod/cbc:EndDate")
  end

  def test_writes_invoicing_period_after_buyer_reference
    names = write(invoice_with_period).root.element_children.map(&:name)

    assert_equal names.index("BuyerReference") + 1, names.index("InvoicePeriod")
  end

  def test_writes_invoicing_period_in_credit_note
    credit_note = CreditNote.new(number: "GS-1", issue_date: Date.new(2024, 6, 15))
    credit_note.invoicing_period_start_date = Date.new(2024, 6, 1)

    doc = parse_xml(Zugpferd::UBL::Writer.new.write(credit_note))

    assert_equal "2024-06-01", xpath_text(doc, "/*/cac:InvoicePeriod/cbc:StartDate")
    assert_nil doc.at_xpath("/*/cac:InvoicePeriod/cbc:EndDate", UBL_NS)
  end

  def test_omits_invoicing_period_without_dates
    invoice = Invoice.new(number: "RE-1", issue_date: Date.new(2024, 6, 15))

    assert_nil write(invoice).at_xpath("//cac:InvoicePeriod", UBL_NS)
  end

  def test_invoicing_period_survives_roundtrip
    xml = Zugpferd::UBL::Writer.new.write(invoice_with_period)
    read = Zugpferd::UBL::Reader.new.read(xml)

    assert_equal Date.new(2024, 6, 1), read.invoicing_period_start_date
    assert_equal Date.new(2024, 6, 30), read.invoicing_period_end_date
  end

  private

  def invoice_with_period
    invoice = Invoice.new(number: "RE-1", issue_date: Date.new(2024, 6, 15))
    invoice.buyer_reference = "04011000-12345-34"
    invoice.invoicing_period_start_date = Date.new(2024, 6, 1)
    invoice.invoicing_period_end_date = Date.new(2024, 6, 30)
    invoice
  end

  def write(document)
    parse_xml(Zugpferd::UBL::Writer.new.write(document))
  end
end
