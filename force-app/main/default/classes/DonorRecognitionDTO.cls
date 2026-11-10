/**
 * One entry of the public donor recognition list (DON-04).
 *
 * It exposes only the public name and the amount. No email, tax data, record Id or
 * any other field of the donation is ever added here.
 */
public with sharing class DonorRecognitionDTO {
    @AuraEnabled public String publicName;
    @AuraEnabled public Decimal amount;

    /**
     * @param publicName name the donor chose to show
     * @param amount confirmed amount of the donation
     */
    public DonorRecognitionDTO(String publicName, Decimal amount) {
        this.publicName = publicName;
        this.amount = amount;
    }
}
