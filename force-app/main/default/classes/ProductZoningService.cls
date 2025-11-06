@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
  @HttpGet
  global static String checkFlyZone() {
    // Default CountryCode from header (case-insensitive) to 'US' if missing
    String countryCode = 'US';
    Map<String, String> headers = RestContext.request.headers;
    if (headers != null) {
      for (String key : headers.keySet()) {
        if (key != null && key.equalsIgnoreCase('CountryCode')) {
          String v = headers.get(key);
          if (String.isNotBlank(v)) {
            countryCode = v.trim();
          }
          break;
        }
      }
    }

    // Extract ProductCode from URL path after /ProductZoning/
    String productCode;
    String uri = RestContext.request.requestURI; // e.g., /services/apexrest/ProductZoning/ABC-123/extra
    // Split and get first segment after 'ProductZoning'
    productCode = null;
    if (String.isNotBlank(uri)) {
      List<String> parts = uri.split('/');
      // ['', 'services', 'apexrest', 'ProductZoning', 'ABC-123', 'extra']
      if (parts.size() > 4 && parts[3].equalsIgnoreCase('ProductZoning')) {
        if (parts.size() > 4 && String.isNotBlank(parts[4])) {
          productCode = EncodingUtil.urlDecode(parts[4], 'UTF-8');
        }
      }
    }

    // 1) Query Product by ProductCode; only select Family
    Product2 prod = [
      SELECT Family
      FROM Product2
      WHERE ProductCode = :productCode
      LIMIT 1
    ];

    // Validate ProductCode
    if (String.isBlank(prod.ProductCode)) {
      RestContext.response.statusCode = 400; // Bad Request
      return 'ProductCode is missing or doesn\'t exist';
    }

    // 2) Query Product_Geo_Mapping__mdt by Product_Family__c and Country_Code__c (exact match), return first match
    Product_Geo_Mapping__mdt mapping = [
      SELECT Permissable_Fly_Zone__c
      FROM Product_Geo_Mapping__mdt
      WHERE Product_Family__c = :prod.Family AND Country_Code__c = :countryCode
      LIMIT 1
    ];
    RestContext.response.statusCode = 200;

    if (mapping == null || String.isBlank(mapping.Permissable_Fly_Zone__c)) {
      return 'Confirm with the local authorities';
    }

    return mapping.Permissable_Fly_Zone__c;
  }
}
