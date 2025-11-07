global with sharing class CredentialVerificationService {
  webService static String verifyCredential(
    String contactLastName,
    String contactCertificationName
  ) {
    List<Contact> contacts = [
      SELECT
        (
          SELECT isActive__c
          FROM Contact_Certifications__r
          WHERE Name = :contactCertificationName
        )
      FROM Contact
      WHERE LastName = :contactLastName
      LIMIT 1
    ];
    Contact contact = contacts.size() > 0 ? contacts[0] : null;
    Contact_Certification__c certification = contact
        ?.Contact_Certifications__r
        ?.size() > 0
      ? contact.Contact_Certifications__r[0]
      : null;

    if (contact == null || certification == null) {
      return 'No record found';
    }

    return certification.isActive__c ? 'Valid' : 'Needs Renewal';
  }
}
