@isTest
private class AssetServiceTest {
  @isTest
  static void testReportLostDeviceWithValidAssetAndCoverage() {
    // Setup test data
    Asset testAsset = new Asset(
      Name = 'Test Asset',
      Asset_Identifier__c = 'TEST-001',
      Status = 'Active'
    );
    insert testAsset;

    Insurance__c testInsurance = new Insurance__c(
      Asset__c = testAsset.Id,
      Coverage__c = 'Comprehensive',
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(365),
      Active__c = true
    );
    insert testInsurance;

    // Call the method
    String result = AssetService.reportLostDevice('TEST-001');

    // Verify results
    Asset updatedAsset = [
      SELECT Id, Status
      FROM Asset
      WHERE Id = :testAsset.Id
    ];
    System.assertEquals(
      'Lost',
      updatedAsset.Status,
      'Asset status should be updated to Lost'
    );

    // Verify claim was created
    List<Claim__c> claims = [
      SELECT Id, Name, Type__c
      FROM Claim__c
      WHERE Asset__c = :testAsset.Id
    ];
    System.assertEquals(1, claims.size(), 'Should have created one claim');
    System.assertEquals(
      'Loss',
      claims[0].Type__c,
      'Claim should be of type Loss'
    );
  }

  @isTest
  static void testReportLostDeviceWithValidAssetButNoCoverage() {
    // Setup test data
    Asset testAsset = new Asset(
      Name = 'Test Asset',
      Asset_Identifier__c = 'TEST-002',
      Status = 'Active'
    );
    insert testAsset;

    // No insurance record - this simulates no coverage

    // Call the method
    String result = AssetService.reportLostDevice('TEST-002');

    // Verify results
    Asset updatedAsset = [
      SELECT Id, Status
      FROM Asset
      WHERE Id = :testAsset.Id
    ];
    System.assertEquals(
      'Lost',
      updatedAsset.Status,
      'Asset status should be updated to Lost'
    );

    // Verify no claim was created
    List<Claim__c> claims = [
      SELECT Id
      FROM Claim__c
      WHERE Asset__c = :testAsset.Id
    ];
    System.assertEquals(0, claims.size(), 'Should not have created any claims');
    System.assertEquals(
      'No coverage. Asset status adjusted to Lost.',
      result,
      'Should return appropriate message'
    );
  }

  @isTest
  static void testReportLostDeviceWithExistingLossClaim() {
    // Setup test data
    Asset testAsset = new Asset(
      Name = 'Test Asset',
      Asset_Identifier__c = 'TEST-003',
      Status = 'Active'
    );
    insert testAsset;

    Insurance__c testInsurance = new Insurance__c(
      Asset__c = testAsset.Id,
      Coverage__c = 'Comprehensive',
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(365),
      Active__c = true
    );
    insert testInsurance;

    // Create existing loss claim
    Claim__c existingClaim = new Claim__c(
      Type__c = 'Loss',
      Asset__c = testAsset.Id,
      Insurance__c = testInsurance.Id
    );
    insert existingClaim;

    // Call the method
    String result = AssetService.reportLostDevice('TEST-003');

    // Verify results
    Asset updatedAsset = [
      SELECT Id, Status
      FROM Asset
      WHERE Id = :testAsset.Id
    ];
    System.assertEquals(
      'Lost',
      updatedAsset.Status,
      'Asset status should be updated to Lost'
    );

    // Verify no new claim was created
    List<Claim__c> claims = [
      SELECT Id, Name, Type__c
      FROM Claim__c
      WHERE Asset__c = :testAsset.Id
    ];
    System.assertEquals(1, claims.size(), 'Should still have only one claim');
    System.assertEquals(
      true,
      result.contains('already filed'),
      'Should indicate claim already filed'
    );
  }

  @isTest
  static void testReportLostDeviceWithNonExistentAsset() {
    // Call the method with non-existent asset
    String result = AssetService.reportLostDevice('NON-EXISTENT');

    // Verify results
    System.assertEquals(
      'No device found.',
      result,
      'Should return appropriate message for non-existent asset'
    );
  }
}
