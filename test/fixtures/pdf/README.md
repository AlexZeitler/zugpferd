# PDF fixtures

Test PDFs for `Zugpferd::PDF::Extractor`. The tests that use them need no Ghostscript.

## Ghostscript (`ghostscript-*.pdf`)

Made with `Zugpferd::PDF::Embedder`. There is one PDF per invoice file name:

- `ghostscript-2p1.pdf`: `factur-x.xml`
- `ghostscript-2p1-xrechnung.pdf`: `xrechnung.xml`
- `ghostscript-2p0.pdf`: `zugferd-invoice.xml`
- `ghostscript-1p0.pdf`: `ZUGFeRD-invoice.xml`, holding the ZUGFeRD 1.0 stub `zugferd-1p0.xml`

The others hold `../cii/invoice.xml`. To make them again:

```bash
docker compose run --rm test ruby -Ilib test/fixtures/pdf/generate.rb
```

## Mustangproject (`mustang/`)

`MustangBeispiel20221026.pdf` comes from a producer other than Ghostscript (Producer: "weclapp (via mustangproject.org 2.5.3.weclapp1)"). It is a PDF/A-3 with `factur-x.xml`, CII, profile EN 16931.

- Source: https://github.com/ZUGFeRD/mustangproject/blob/0abe7bba61f0d248d0c96cedf03f975837a7e252/library/src/test/resources/MustangBeispiel20221026.pdf
- SHA-256: `98a694e3eaca6c7e37a85cba73a640977c121c01549e09182836b433d8d53a18`
- Licence: Apache License 2.0. `mustang/LICENSE` and `mustang/NOTICE` are copied unchanged from the same commit. The licence is stated for the repository as a whole, not for this file.
