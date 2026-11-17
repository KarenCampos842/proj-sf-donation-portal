/**
 * PAY-08. Batch for the Mercado Pago reconciliation.
 *
 *  - start: asks Mercado Pago for the approved payments once and keeps the ones to register
 *    (callouts and queries only).
 *  - execute: registers one chunk of BATCH_SIZE payments. Each chunk is its own transaction
 *    with fresh limits, so many pending payments never make the whole run fail; if one chunk
 *    fails, the others are still registered and the next run tries the failed ones again.
 *  - finish: writes the summary to the debug log.
 *
 * Each payment runs the Donation_Register flow (about 2 queries and 3 writes, counting the
 * savepoint), so 20 per chunk stays far below the limits of 100 queries and 150 writes.
 */
public without sharing class MercadoPagoReconciliationBatch
        implements Database.Batchable<Object>, Database.AllowsCallouts, Database.Stateful {
    public static final Integer BATCH_SIZE = 20;

    @TestVisible
    private final MercadoPagoReconciliationService.Summary summary = new MercadoPagoReconciliationService.Summary();

    public Iterable<Object> start(Database.BatchableContext context) {
        List<Object> items = new List<Object>();
        for (MercadoPagoPaymentLookupAction.Result payment : MercadoPagoReconciliationService.findCandidates(summary)) {
            items.add(payment);
        }
        return items;
    }

    public void execute(Database.BatchableContext context, List<Object> scope) {
        for (Object item : scope) {
            MercadoPagoReconciliationService.register((MercadoPagoPaymentLookupAction.Result) item, summary);
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, summary.toString());
    }
}
