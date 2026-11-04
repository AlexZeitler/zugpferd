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

  def test_writes_purchase_order_reference
    doc = write(invoice_with_order_reference)

    assert_equal "PO-4711", xpath_text(doc, "/ubl:Invoice/cac:OrderReference/cbc:ID")
  end

  def test_writes_purchase_order_reference_after_invoicing_period
    names = write(invoice_with_order_reference).root.element_children.map(&:name)

    assert_equal names.index("InvoicePeriod") + 1, names.index("OrderReference")
  end

  def test_writes_purchase_order_reference_in_credit_note
    credit_note = CreditNote.new(number: "GS-1", issue_date: Date.new(2024, 6, 15))
    credit_note.purchase_order_reference = "PO-4711"

    doc = parse_xml(Zugpferd::UBL::Writer.new.write(credit_note))

    assert_equal "PO-4711", xpath_text(doc, "/*/cac:OrderReference/cbc:ID")
  end

  def test_omits_purchase_order_reference_when_not_set
    invoice = Invoice.new(number: "RE-1", issue_date: Date.new(2024, 6, 15))

    assert_nil write(invoice).at_xpath("//cac:OrderReference", UBL_NS)
  end

  def test_purchase_order_reference_survives_roundtrip
    xml = Zugpferd::UBL::Writer.new.write(invoice_with_order_reference)

    assert_equal "PO-4711", Zugpferd::UBL::Reader.new.read(xml).purchase_order_reference
  end

  def test_writes_price_base_quantity_after_price_amount
    price = write(build_document(Invoice, line_with_price(base_quantity: BigDecimal("100"), base_quantity_unit_code: "C62")))
      .at_xpath("/ubl:Invoice/cac:InvoiceLine/cac:Price", UBL_NS)

    assert_equal %w[PriceAmount BaseQuantity], price.element_children.map(&:name)
    assert_equal "100", xpath_text(price, "cbc:BaseQuantity")
    assert_equal "C62", price.at_xpath("cbc:BaseQuantity", UBL_NS)["unitCode"]
  end

  def test_omits_price_base_quantity_by_default
    price = write(build_document(Invoice, line_with_price)).at_xpath("//cac:Price", UBL_NS)

    assert_equal %w[PriceAmount], price.element_children.map(&:name)
  end

  def test_price_base_quantity_survives_roundtrip
    line = line_with_price(base_quantity: BigDecimal("100"), base_quantity_unit_code: "C62")
    read = Zugpferd::UBL::Reader.new.read(Zugpferd::UBL::Writer.new.write(build_document(Invoice, line)))
    price = read.line_items.first.price

    assert_equal BigDecimal("100"), price.base_quantity
    assert_equal "C62", price.base_quantity_unit_code
  end

  def test_writes_line_item_period_before_item
    doc = write(build_document(Invoice, line_with_period))
    line = doc.at_xpath("/ubl:Invoice/cac:InvoiceLine", UBL_NS)

    assert_equal "2024-06-01", xpath_text(line, "cac:InvoicePeriod/cbc:StartDate")
    assert_equal "2024-06-30", xpath_text(line, "cac:InvoicePeriod/cbc:EndDate")
    assert_equal %w[ID InvoicedQuantity LineExtensionAmount InvoicePeriod Item],
                 line.element_children.map(&:name)
  end

  def test_writes_line_item_period_in_credit_note
    line = line_with_period
    line.period_end_date = nil
    doc = write(build_document(CreditNote, line))

    assert_equal "2024-06-01", xpath_text(doc, "/*/cac:CreditNoteLine/cac:InvoicePeriod/cbc:StartDate")
    assert_nil doc.at_xpath("/*/cac:CreditNoteLine/cac:InvoicePeriod/cbc:EndDate", UBL_NS)
  end

  def test_omits_line_item_period_without_dates
    line = line_with_period
    line.period_start_date = line.period_end_date = nil

    assert_nil write(build_document(Invoice, line)).at_xpath("//cac:InvoicePeriod", UBL_NS)
  end

  def test_line_item_period_survives_roundtrip
    xml = Zugpferd::UBL::Writer.new.write(build_document(Invoice, line_with_period))
    read = Zugpferd::UBL::Reader.new.read(xml).line_items.first

    assert_equal Date.new(2024, 6, 1), read.period_start_date
    assert_equal Date.new(2024, 6, 30), read.period_end_date
  end

  private

  def line_with_period
    LineItem.new(
      id: "1", invoiced_quantity: "1", unit_code: "C62", line_extension_amount: "10",
      period_start_date: Date.new(2024, 6, 1), period_end_date: Date.new(2024, 6, 30),
      item: Item.new(name: "Widget")
    )
  end

  def build_document(klass, line)
    document = klass.new(number: "RE-1", issue_date: Date.new(2024, 6, 15))
    document.line_items << line
    document
  end

  def line_with_price(**price_attributes)
    LineItem.new(
      id: "1", invoiced_quantity: "1", unit_code: "C62", line_extension_amount: "10",
      item: Item.new(name: "Widget"), price: Price.new(amount: "10", **price_attributes)
    )
  end

  def invoice_with_period
    invoice = Invoice.new(number: "RE-1", issue_date: Date.new(2024, 6, 15))
    invoice.buyer_reference = "04011000-12345-34"
    invoice.invoicing_period_start_date = Date.new(2024, 6, 1)
    invoice.invoicing_period_end_date = Date.new(2024, 6, 30)
    invoice
  end

  def invoice_with_order_reference
    invoice = invoice_with_period
    invoice.purchase_order_reference = "PO-4711"
    invoice
  end

  def write(document)
    parse_xml(Zugpferd::UBL::Writer.new.write(document))
  end
end
