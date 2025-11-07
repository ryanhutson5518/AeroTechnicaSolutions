@isTest
private class CredentialVerificationServiceTest {
  @isTest
  static void testVerifyCredentialWithValidCertification() {
    // Setup test data
    Contact testContact = new Contact(LastName = 'Smith');
    insert testContact;

    // Create a Certification record (required for Contact_Certification__c)
    Certification__c testCertification = new Certification__c(
      Name = 'Test Certification'
    );
    insert testCertification;

    // Create certification without setting Name field (auto-generated)
    Contact_Certification__c testCertificationLink = new Contact_Certification__c(
      Contact__c = testContact.Id,
      Certification__c = testCertification.Id,
      Issue_Date__c = Date.today(),
      isActive__c = true
    );
    insert testCertificationLink;

    // Query to get the auto-generated Name
    Contact_Certification__c retrievedCertification = [
      SELECT Name
      FROM Contact_Certification__c
      WHERE Id = :testCertificationLink.Id
      LIMIT 1
    ];

    // Call the method with the actual generated name
    String result = CredentialVerificationService.verifyCredential(
      'Smith',
      retrievedCertification.Name
    );

    // Verify results
    System.assertEquals(
      'Valid',
      result,
      'Should return Valid for active certification'
    );
  }

  @isTest
  static void testVerifyCredentialWithInactiveCertification() {
    // Setup test data
    Contact testContact = new Contact(LastName = 'Johnson');
    insert testContact;

    // Create a Certification record (required for Contact_Certification__c)
    Certification__c testCertification = new Certification__c(
      Name = 'Test Certification'
    );
    insert testCertification;

    // Create certification without setting Name field (auto-generated)
    Contact_Certification__c testCertificationLink = new Contact_Certification__c(
      Contact__c = testContact.Id,
      Certification__c = testCertification.Id,
      Issue_Date__c = Date.today(),
      isActive__c = false
    );
    insert testCertificationLink;

    // Query to get the auto-generated Name
    Contact_Certification__c retrievedCertification = [
      SELECT Name
      FROM Contact_Certification__c
      WHERE Id = :testCertificationLink.Id
      LIMIT 1
    ];

    // Call the method with the actual generated name
    String result = CredentialVerificationService.verifyCredential(
      'Johnson',
      retrievedCertification.Name
    );

    // Verify results
    System.assertEquals(
      'Needs Renewal',
      result,
      'Should return Needs Renewal for inactive certification'
    );
  }

  @isTest
  static void testVerifyCredentialWithNonExistentContact() {
    // Call the method with non-existent contact
    String result = CredentialVerificationService.verifyCredential(
      'Unknown',
      'Test Certification'
    );

    // Verify results
    System.assertEquals(
      'No record found',
      result,
      'Should return No record found for non-existent contact'
    );
  }

  @isTest
  static void testVerifyCredentialWithNonExistentCertification() {
    // Setup test data
    Contact testContact = new Contact(LastName = 'Williams');
    insert testContact;

    // Call the method with non-existent certification
    String result = CredentialVerificationService.verifyCredential(
      'Williams',
      'Non-existent Certification'
    );

    // Verify results
    System.assertEquals(
      'No record found',
      result,
      'Should return No record found for non-existent certification'
    );
  }
}
