#!/usr/bin/env ruby
require "bundler/setup"
require "zugpferd"
require "zugpferd/pdf"
require "zugpferd/validation"
require "bigdecimal"
require "tempfile"

# --- 1. Invoice aufbauen ---

invoice = Zugpferd::Model::Invoice.new(
  number: "RE-2024-0042",
  issue_date: Date.new(2024, 6, 15),
  currency_code: "EUR"
)

invoice.due_date = Date.new(2024, 7, 15)
invoice.delivery_date = Date.new(2024, 6, 15)
invoice.buyer_reference = "LEITWEG-123-456"
invoice.customization_id = "urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0"
invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"

# Seller
invoice.seller = Zugpferd::Model::TradeParty.new(name: "Zugpferd GmbH")
invoice.seller.vat_identifier = "DE123456789"
invoice.seller.electronic_address = "zugpferd@example.com"
invoice.seller.electronic_address_scheme = "EM"
invoice.seller.postal_address = Zugpferd::Model::PostalAddress.new(
  country_code: "DE",
  city_name: "Frankfurt am Main",
  postal_zone: "60311",
  street_name: "Kaiserstr. 42"
)
invoice.seller.contact = Zugpferd::Model::Contact.new(
  name: "Max Mustermann",
  telephone: "+49 69 12345678",
  email: "rechnung@zugpferd.example.com"
)

# Buyer
invoice.buyer = Zugpferd::Model::TradeParty.new(name: "Muster AG")
invoice.buyer.electronic_address = "muster@example.com"
invoice.buyer.electronic_address_scheme = "EM"
invoice.buyer.postal_address = Zugpferd::Model::PostalAddress.new(
  country_code: "DE",
  city_name: "Berlin",
  postal_zone: "10115",
  street_name: "Unter den Linden 1"
)

# --- Position 1: Software-Lizenzen ---
line1 = Zugpferd::Model::LineItem.new(
  id: "1",
  invoiced_quantity: "5",
  unit_code: "C62",
  line_extension_amount: "2500.00"
)
line1.item = Zugpferd::Model::Item.new(
  name: "Zugpferd Enterprise License",
  tax_category: "S",
  tax_percent: BigDecimal("19")
)
line1.price = Zugpferd::Model::Price.new(amount: "500.00")
invoice.line_items << line1

# --- Position 2: Consulting ---
line2 = Zugpferd::Model::LineItem.new(
  id: "2",
  invoiced_quantity: "16",
  unit_code: "HUR",
  line_extension_amount: "2400.00"
)
line2.item = Zugpferd::Model::Item.new(
  name: "Technische Beratung E-Invoicing",
  tax_category: "S",
  tax_percent: BigDecimal("19")
)
line2.price = Zugpferd::Model::Price.new(amount: "150.00")
invoice.line_items << line2

# --- Position 3: Schulung ---
line3 = Zugpferd::Model::LineItem.new(
  id: "3",
  invoiced_quantity: "1",
  unit_code: "C62",
  line_extension_amount: "1800.00"
)
line3.item = Zugpferd::Model::Item.new(
  name: "Workshop: XRechnung & ZUGFeRD in der Praxis (2 Tage)",
  tax_category: "S",
  tax_percent: BigDecimal("19")
)
line3.price = Zugpferd::Model::Price.new(amount: "1800.00")
invoice.line_items << line3

# --- Steuer ---
netto = BigDecimal("6700.00")
steuer = BigDecimal("1273.00")
brutto = BigDecimal("7973.00")

invoice.tax_breakdown = Zugpferd::Model::TaxBreakdown.new(
  tax_amount: steuer.to_s("F"),
  currency_code: "EUR"
)
invoice.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
  taxable_amount: netto.to_s("F"),
  tax_amount: steuer.to_s("F"),
  category_code: "S",
  currency_code: "EUR",
  percent: BigDecimal("19")
)

# --- Summen ---
invoice.monetary_totals = Zugpferd::Model::MonetaryTotals.new(
  line_extension_amount: netto.to_s("F"),
  tax_exclusive_amount: netto.to_s("F"),
  tax_inclusive_amount: brutto.to_s("F"),
  payable_amount: brutto.to_s("F")
)

# --- Zahlung ---
invoice.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
  payment_means_code: "58",
  account_id: "DE89370400440532013000"
)

# --- 2. CII-XML erzeugen und validieren ---
xml = Zugpferd::CII::Writer.new.write(invoice)
File.write("example_invoice.xml", xml)
puts "XML geschrieben: example_invoice.xml"

validator = Zugpferd::Validation::SchematronValidator.new(schemas_path: "vendor/schemas")
errors = validator.validate_all(xml, rule_sets: [:cen_cii, :xrechnung_cii])
fatals = errors.select { |e| e.flag == "fatal" }

if fatals.any?
  puts "\nValidierungsfehler:"
  fatals.each { |e| puts "  [#{e.id}] #{e.text}" }
  abort "\nAbbruch: Rechnung ist nicht XRechnung-konform."
end
puts "Validierung bestanden (#{errors.size} Hinweise, 0 fatale Fehler)"

# --- 3. Basis-PDF erzeugen (PostScript -> PDF via Ghostscript) ---
ps_content = <<~PS
  %!PS-Adobe-3.0
  /Helvetica findfont 24 scalefont setfont
  72 750 moveto (Rechnung RE-2024-0042) show

  /Helvetica findfont 11 scalefont setfont
  72 710 moveto (Zugpferd GmbH) show
  72 696 moveto (Kaiserstr. 42, 60311 Frankfurt am Main) show
  72 682 moveto (USt-IdNr.: DE123456789) show

  72 650 moveto (An: Muster AG) show
  72 636 moveto (Unter den Linden 1, 10115 Berlin) show

  72 600 moveto (Rechnungsdatum: 15.06.2024) show
  72 586 moveto (Leitweg-ID: LEITWEG-123-456) show

  % Tabellenkopf
  /Helvetica-Bold findfont 10 scalefont setfont
  72 550 moveto (Pos) show
  110 550 moveto (Beschreibung) show
  350 550 moveto (Menge) show
  410 550 moveto (Einheit) show
  460 550 moveto (Einzelpreis) show
  530 550 moveto (Gesamt) show

  0.5 setlinewidth
  72 545 moveto 560 545 lineto stroke

  /Helvetica findfont 10 scalefont setfont

  72 530 moveto (1) show
  110 530 moveto (Zugpferd Enterprise License) show
  350 530 moveto (5) show
  410 530 moveto (Stk) show
  460 530 moveto (500,00) show
  520 530 moveto (2.500,00) show

  72 515 moveto (2) show
  110 515 moveto (Technische Beratung E-Invoicing) show
  350 515 moveto (16) show
  410 515 moveto (Std) show
  460 515 moveto (150,00) show
  520 515 moveto (2.400,00) show

  72 500 moveto (3) show
  110 500 moveto (Workshop: XRechnung & ZUGFeRD \\(2 Tage\\)) show
  350 500 moveto (1) show
  410 500 moveto (Stk) show
  455 500 moveto (1.800,00) show
  520 500 moveto (1.800,00) show

  72 490 moveto 560 490 lineto stroke

  /Helvetica findfont 10 scalefont setfont
  410 470 moveto (Netto:) show
  520 470 moveto (6.700,00) show
  410 455 moveto (USt 19%:) show
  520 455 moveto (1.273,00) show

  /Helvetica-Bold findfont 11 scalefont setfont
  410 435 moveto (Gesamt:) show
  515 435 moveto (7.973,00 EUR) show

  /Helvetica findfont 10 scalefont setfont
  72 390 moveto (Zahlbar per SEPA-Ueberweisung) show
  72 376 moveto (IBAN: DE89 3704 0044 0532 0130 00) show

  72 340 moveto (Vielen Dank fuer Ihren Auftrag!) show

  showpage
PS

ps_file = Tempfile.new(["invoice", ".ps"])
ps_file.write(ps_content)
ps_file.flush

base_pdf = "example_invoice_base.pdf"
system("gs", "-dBATCH", "-dNOPAUSE", "-sDEVICE=pdfwrite", "-o", base_pdf, ps_file.path,
  [:out, :err] => "/dev/null")
ps_file.close!
puts "Basis-PDF erzeugt: #{base_pdf}"

# --- 4. XML in PDF/A-3 einbetten ---
output_pdf = "example_invoice_zugferd.pdf"
embedder = Zugpferd::PDF::Embedder.new
embedder.embed(
  pdf_path: base_pdf,
  xml: xml,
  output_path: output_pdf,
  version: "2p1",
  conformance_level: "XRECHNUNG"
)
puts "ZUGFeRD-PDF erzeugt: #{output_pdf}"

# Aufräumen
File.delete(base_pdf)
puts "Basis-PDF gelöscht"
puts "Fertig!"
