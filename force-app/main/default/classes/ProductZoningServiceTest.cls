@IsTest
private class ProductZoningServiceTest {
  // Utility to set up REST context
  private static void setupRestContext(
    String url,
    String productCode,
    Map<String, String> headers
  ) {
    RestRequest req = new RestRequest();
    req.httpMethod = 'GET';
    req.requestURI = url;
    req.params.put('ProductCode', productCode);
    req.addHeader('Content-Type', 'application/json');
    if (headers != null) {
      for (String k : headers.keySet()) {
        req.addHeader(k, headers.get(k));
      }
    }
    RestContext.request = req;

    RestResponse res = new RestResponse();
    RestContext.response = res;
  }

  @IsTest
  static void testHappyPath_ExactCountryHeaderMatch() {
    // Data
    Product2 p = new Product2(
      Name = 'Phantom 4',
      ProductCode = 'P4',
      Family = 'Single-Rotor',
      IsActive = true
    );
    insert p;

    // Request with CountryCode header in any case
    Map<String, String> hdrs = new Map<String, String>{ 'countrycode' => 'US' };
    setupRestContext('/services/apexrest/ProductZoning', 'P4', hdrs);

    Test.startTest();
    String result = ProductZoningService.getFlyZone();
    Test.stopTest();

    System.assertEquals('Recommended', result, 'Should return mapping zone');
  }

  @IsTest
  static void testDefaultCountryWhenHeaderMissing() {
    // Data
    Product2 p = new Product2(
      Name = 'Mavic 3',
      ProductCode = 'M3',
      Family = 'Fixed-Wing',
      IsActive = true
    );
    insert p;

    // No CountryCode header at all
    setupRestContext('/services/apexrest/ProductZoning', 'M3', null);

    Test.startTest();
    String result = ProductZoningService.getFlyZone();
    Test.stopTest();

    System.assertEquals(
      'Regulated',
      result,
      'Should use default US when header missing'
    );
  }

  @IsTest
  static void testBadRequestWhenProductMissingOrNotFound() {
    // No products inserted. Header present or not should not matter.
    setupRestContext(
      '/services/apexrest/ProductZoning',
      'UNKOWN',
      new Map<String, String>{ 'CountryCode' => 'US' }
    );

    Test.startTest();
    String result = ProductZoningService.getFlyZone();
    Test.stopTest();

    System.assertEquals(
      'ProductCode is missing or doesn\'t exist',
      result,
      'Should indicate missing/invalid product'
    );
  }

  @IsTest
  static void testConfirmAuthoritiesWhenNoMappingOrBlankZone() {
    // Product exists but either no mapping or mapping has blank zone
    Product2 p = new Product2(
      Name = 'Mini 4',
      ProductCode = 'MN4',
      Family = 'Mini',
      IsActive = true
    );
    insert p;

    // Case 1: No mapping found - need to handle exception when no records found
    setupRestContext(
      '/services/apexrest/ProductZoning',
      'MN4',
      new Map<String, String>{ 'CountryCode' => 'DE' }
    );
    Test.startTest();
    String result1 = ProductZoningService.getFlyZone();

    System.assertEquals(
      'Confirm with the local authorities',
      result1,
      'No mapping should advise to confirm'
    );

    setupRestContext(
      '/services/apexrest/ProductZoning',
      'MN4',
      new Map<String, String>{ 'CountryCode' => 'US' }
    );
    String result2 = ProductZoningService.getFlyZone();
    Test.stopTest();

    System.assertEquals(
      'Confirm with the local authorities',
      result2,
      'Blank zone should advise to confirm'
    );
  }
}
