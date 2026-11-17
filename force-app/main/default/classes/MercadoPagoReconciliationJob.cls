/**
 * PAY-08. Scheduled job for the Mercado Pago reconciliation.
 *
 * A scheduled job cannot make callouts, so it only queues Worker, which can.
 * Scheduled once by an administrator (see docs/payments-api.md, section 6):
 *   System.schedule('Conciliación Mercado Pago', '0 15 * * * ?', new MercadoPagoReconciliationJob());
 */
public without sharing class MercadoPagoReconciliationJob implements Schedulable {
    public void execute(SchedulableContext context) {
        System.enqueueJob(new Worker());
    }

    /**
     * Runs the reconciliation with callouts allowed.
     */
    public class Worker implements Queueable, Database.AllowsCallouts {
        public void execute(QueueableContext context) {
            MercadoPagoReconciliationService.Summary summary = MercadoPagoReconciliationService.run();
            System.debug(LoggingLevel.INFO, summary.toString());
        }
    }
}
