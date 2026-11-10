// Visible texts of the payment result page. The texts of each state come from docs/payments-api.md.
// Each key maps one to one to a Custom Label (@salesforce/label/c.ThankYou_<Key>).
export const THANK_YOU_MESSAGES = {
    title: 'Resultado de tu pago',
    loading: 'Revisando tu pago…',
    checkAgain: 'Revisar de nuevo',
    backToPortal: 'Volver a las campañas',
    tryAgain: 'Intentar de nuevo',
    states: {
        Confirmed: '¡Gracias! Recibimos tu aportación.',
        Pending: 'Estamos confirmando tu pago. No necesitas pagar otra vez.',
        Rejected: 'Tu pago fue rechazado y no se registró tu donación.',
        Cancelled: 'Tu pago se canceló y no se registró tu donación.',
        NoPayment: 'No se completó el pago; no se registró tu donación.',
        Unknown: 'Aún no podemos confirmar tu pago.'
    }
};
