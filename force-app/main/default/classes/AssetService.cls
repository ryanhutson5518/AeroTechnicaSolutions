@RestResource(urlMapping='/lost')
global with sharing class AssetService {
  @HttpPost
  global static String reportLostDevice(String assetIdentifier) {
    List<Asset> assets = [
      SELECT
        Id,
        (
          SELECT Id
          FROM Insurances__r
          WHERE Coverage__c = 'Comprehensive'
          LIMIT 1
        ),
        (
          SELECT Name
          FROM Claims__r
          WHERE Type__c = 'Loss'
          LIMIT 1
        )
      FROM Asset
      WHERE Asset_Identifier__c = :assetIdentifier
      LIMIT 1
    ];

    Asset asset = assets.size() == 1 ? assets[0] : null;
    if (asset == null) {
      return 'No device found.';
    }

    Insurance__c comprehensiveInsurance = asset.Insurances__r?.size() > 0
      ? asset.Insurances__r[0]
      : null;
    Claim__c existingLossClaim = asset.Claims__r?.size() > 0
      ? asset.Claims__r[0]
      : null;

    asset.Status = 'Lost';
    update asset;

    if (comprehensiveInsurance == null) {
      return 'No coverage. Asset status adjusted to Lost.';
    }

    String claimName;

    if (existingLossClaim == null) {
      Claim__c newClaim = new Claim__c(
        Type__c = 'Loss',
        Asset__c = asset.Id,
        Insurance__c = comprehensiveInsurance.Id
      );
      insert newClaim;

      newClaim = [SELECT Name FROM Claim__c WHERE Id = :newClaim.Id LIMIT 1];
      claimName = newClaim.Name;
    } else {
      claimName = existingLossClaim.Name + 'already filed.';
    }

    return claimName;
  }
}
