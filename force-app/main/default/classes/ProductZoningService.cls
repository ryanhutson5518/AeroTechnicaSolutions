@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
  @HttpGet
  global static String getFlyZone() {
    RestRequest req = RestContext.request;
    Map<String, String> queryParams = req.params;
    String productCode = queryParams.get('ProductCode');

    String countryCode = req.headers.get('CountryCode');

    if (countryCode == null) {
      countryCode = 'US'; // Use 'US' as the default country code
    }

    if (String.isBlank(productCode)) {
      return 'ProductCode is missing or doesn\'t exist';
    }

    List<Product2> products = [
      SELECT Id, Family
      FROM Product2
      WHERE ProductCode = :productCode
      LIMIT 1
    ];
    if (products.isEmpty()) {
      return 'ProductCode is missing or doesn\'t exist';
    }

    String productFamily = products[0].Family;

    List<Product_Geo_Mapping__mdt> mappings = [
      SELECT Permissible_Fly_Zone__c
      FROM Product_Geo_Mapping__mdt
      WHERE
        Product_Family__c = :productFamily
        AND Country_Code__c = :countryCode
      LIMIT 1
    ];

    if (!mappings.isEmpty()) {
      return mappings[0].Permissible_Fly_Zone__c;
    } else {
      return 'Confirm with the local authorities';
    }
  }
}
