/**
 * Amount configuration that the donation form receives (ADM-13).
 *
 * It exposes only the minimum amount and the suggested amounts, in MXN with two decimals.
 * It holds no personal data.
 */
public with sharing class DonationAmountSettingsDTO {
    @AuraEnabled public Decimal minimumAmount;
    @AuraEnabled public List<Decimal> suggestedAmounts;

    /**
     * @param minimumAmount current minimum amount
     * @param suggestedAmounts current suggested amounts, in the order set by the administrator
     */
    public DonationAmountSettingsDTO(Decimal minimumAmount, List<Decimal> suggestedAmounts) {
        this.minimumAmount = minimumAmount;
        this.suggestedAmounts = suggestedAmounts;
    }
}
