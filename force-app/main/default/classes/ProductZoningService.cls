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

    // Extract ProductCode: split on "/ProductZoning/" and take the next segment
    List<String> segments = RestContext.request.requestURI.split('/');
    Integer indexOfMarker = segments.indexOf('ProductZoning');
    String productCode = segments.size() - 1 >=
      indexOfMarker + 1
      ? segments[indexOfMarker + 1]
      : null;

    // 1) Query Product by ProductCode; only select Family
    Product2 prod = null;
    if (String.isNotBlank(productCode)) {
      try {
        prod = [
          SELECT Family
          FROM Product2
          WHERE ProductCode = :productCode
          LIMIT 1
        ];
      } catch (Exception ex) {
      }
    }

    // Validate ProductCode
    if (prod == null) {
      RestContext.response.statusCode = 400; // Bad Request
      return 'ProductCode is missing or doesn\'t exist';
    }

    // 2) Query Product_Geo_Mapping__mdt by Product_Family__c and Country_Code__c (exact match), return first match
    Product_Geo_Mapping__mdt mapping = null;
    try {
      mapping = [
        SELECT Permissible_Fly_Zone__c
        FROM Product_Geo_Mapping__mdt
        WHERE
          Product_Family__c = :prod.family
          AND Country_Code__c = :countryCode
        LIMIT 1
      ];
    } catch (Exception ex) {
    }

    String flyZone = mapping?.Permissible_Fly_Zone__c;
    RestContext.response.statusCode = 200;

    if (String.isEmpty(flyZone)) {
      return 'Confirm with the local authorities';
    }

    return flyZone;
  }
}
