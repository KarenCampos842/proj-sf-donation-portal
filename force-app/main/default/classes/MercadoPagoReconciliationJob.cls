/**
 * PAY-08. Scheduled job for the Mercado Pago reconciliation: it only starts the batch,
 * which does the callouts and registers the payments in chunks.
 * Scheduled once by an administrator (see docs/payments-api.md, section 6):
 *   System.schedule('Conciliación Mercado Pago', '0 15 * * * ?', new MercadoPagoReconciliationJob());
 */
public without sharing class MercadoPagoReconciliationJob implements Schedulable {
    public void execute(SchedulableContext context) {
        Database.executeBatch(new MercadoPagoReconciliationBatch(), MercadoPagoReconciliationBatch.BATCH_SIZE);
    }
}
