module XmlHelper
  UBL_NS = {
    "ubl" => "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
    "cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
    "cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
  }.freeze

  CII_NS = {
    "rsm" => "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100",
    "ram" => "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100",
    "udt" => "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100",
  }.freeze

  def parse_xml(xml_string)
    Nokogiri::XML(xml_string) { |config| config.strict }
  end

  def xpath_text(doc, xpath, namespaces = UBL_NS)
    doc.at_xpath(xpath, namespaces)&.text
  end
end
