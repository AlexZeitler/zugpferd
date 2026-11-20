---
outline: deep
---

# PDF Extraction

Read the invoice XML from a ZUGFeRD / Factur-X / XRechnung hybrid PDF you received, then parse it with the CII or UBL reader.

## Prerequisites

Extraction uses the [pdf-reader](https://github.com/yob/pdf-reader) gem. zugpferd does not depend on it, so XML-only users do not install it. Add it to your Gemfile:

```ruby
gem "pdf-reader", "~> 2.16"
```

Without it, `extract` raises `Zugpferd::PDF::Extractor::PdfReaderNotFound` with that line in the message. Ghostscript is not needed.

## Basic Usage

```ruby
require "zugpferd"
require "zugpferd/pdf"  # explicit opt-in for PDF support

result = Zugpferd::PDF::Extractor.new.extract(pdf_path: "rechnung.pdf")

result.xml       # => the embedded XML, unchanged
result.filename  # => "factur-x.xml"
result.syntax    # => :cii or :ubl, nil for anything else

invoice = result.read  # CII::Reader or UBL::Reader, chosen by the root element
```

## Which Attachment Is the Invoice

The extractor accepts the file names that the ZUGFeRD and Factur-X specifications give the invoice XML:

| File name | Specification |
|-----------|---------------|
| `factur-x.xml` | ZUGFeRD 2.1.1 Technical Supplement Part A, §2.2; Factur-X 1.0.06 to 1.08 (ZUGFeRD 2.2 to 2.4), §6.2 |
| `xrechnung.xml` | the XRECHNUNG profile: ZUGFeRD 2.1.1 Technical Supplement Reference Profiles, §3.1; Factur-X 1.0.06 to 1.08, §6.2 |
| `zugferd-invoice.xml` | ZUGFeRD 2.0, §5.2; ZUGFeRD 2.1.1 Technical Supplement Part B, §2.2 |
| `ZUGFeRD-invoice.xml` | ZUGFeRD 1.0, §7.2 |

Names are matched exactly. Other attachments, such as delivery notes or time sheets, are ignored.

The lookup has two steps:

1. The catalog's `/AF` array, where PDF/A-3 lists associated files.
2. Only if that holds no invoice: the `/Names /EmbeddedFiles` name tree, including trees split across `/Kids`.

The name comes from the file specification's `/UF` entry, or `/F` when `/UF` is missing. If more than one attachment has an invoice name, `extract` raises `AmbiguousInvoice` instead of guessing.

## ZUGFeRD 1.0

ZUGFeRD 1.0 uses a different root element (`CrossIndustryDocument`) that the CII reader does not support. `extract` still returns its XML, with `syntax` set to `nil`. `result.read` raises `UnsupportedSyntax` with a message that names ZUGFeRD 1.0.

## Limits

PDFs come from outside, so the extractor sets two limits. Both can be changed:

```ruby
Zugpferd::PDF::Extractor.new(
  max_xml_bytes: 10 * 1024 * 1024,  # default: 10 MiB
  max_name_tree_depth: 32           # default: 32
)
```

Passing either limit raises `LimitExceeded`.

**What the size limit covers.** pdf-reader inflates a whole stream in one call, so it cannot stop early. The extractor therefore inflates the invoice attachment itself, a few hundred bytes of compressed input at a time, and stops as soon as the output passes `max_xml_bytes`. It may produce up to about 530 KB more than the limit before it stops.

**What it does not cover.** pdf-reader still reads the rest of the PDF, including cross-reference streams and object streams, and inflates them without a limit. The whole PDF file is also read into memory. If you accept PDFs from unknown senders, also limit the file size before you call `extract`.

The attachment must use no filter or `FlateDecode` without a predictor, which is what invoice producers write. Other filters raise `ExtractError`.

## Error Handling

```ruby
begin
  result = Zugpferd::PDF::Extractor.new.extract(pdf_path: "rechnung.pdf")
  invoice = result.read
rescue Zugpferd::PDF::Extractor::PdfReaderNotFound
  # add gem "pdf-reader" to the Gemfile
rescue Zugpferd::PDF::Extractor::InvoiceNotFound
  # a plain PDF, or no attachment with an invoice file name
rescue Zugpferd::PDF::Extractor::AmbiguousInvoice
  # more than one invoice attachment
rescue Zugpferd::PDF::Extractor::UnsupportedSyntax
  # e.g. ZUGFeRD 1.0; result.xml is still available
rescue Zugpferd::PDF::Extractor::ExtractError => e
  # broken PDF or attachment, unsupported filter, or a limit (LimitExceeded)
end
```

`ExtractError` is the parent of `InvoiceNotFound`, `AmbiguousInvoice`, `LimitExceeded` and `UnsupportedSyntax`.

## Out of Scope

The extractor does not validate the PDF or its XMP metadata, does not read ZUGFeRD 1.0 into the model, and does not repair broken PDFs. To validate a received PDF, use [veraPDF or Mustangproject](./pdf-embedding#validating-the-output).
