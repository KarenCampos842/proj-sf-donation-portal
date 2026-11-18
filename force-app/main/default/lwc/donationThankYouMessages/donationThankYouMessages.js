// Visible texts of the payment result page. The texts of each state come from docs/payments-api.md.
// Each key maps one to one to a Custom Label (@salesforce/label/c.ThankYou_<Key>).
export const THANK_YOU_MESSAGES = {
    title: 'Tu donación',
    loading: 'Revisando tu pago…',
    checkAgain: 'Revisar de nuevo',
    backToPortal: 'Ver más campañas',
    tryAgain: 'Intentar de nuevo',
    states: {
        Confirmed: '¡Gracias por donar! Recibimos tu aportación y ya cuenta para la campaña. Tu apoyo nos impulsa a seguir aprendiendo y construyendo.',
        Pending: 'Estamos confirmando tu pago. No necesitas pagar otra vez; revisa de nuevo en unos minutos.',
        Rejected: 'Tu pago fue rechazado y no se registró tu donación. Puedes intentarlo de nuevo cuando quieras.',
        Cancelled: 'Cancelaste el pago y no se registró tu donación. Si cambiaste de opinión, puedes intentarlo de nuevo.',
        NoPayment: 'No se completó el pago; no se registró tu donación.',
        Unknown: 'Aún no podemos confirmar tu pago.'
    }
};
