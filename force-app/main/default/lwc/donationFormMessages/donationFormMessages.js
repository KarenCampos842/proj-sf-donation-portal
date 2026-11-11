// Visible texts of the donation form. Each key maps one to one to a Custom Label
// (@salesforce/label/c.DonationForm_<Section>_<Key>), so moving to labels only changes this file.
export const FORM_MESSAGES = {
    title: 'Haz tu donación',
    campaign: 'Campaña: {0}',
    back: 'Volver a la campaña',
    noCampaign: 'No encontramos la campaña a la que quieres donar. Regresa y elige una campaña.',
    amount: {
        legend: 'Elige un monto',
        required: 'Elige un monto para continuar.'
    },
    email: {
        label: 'Correo electrónico',
        help: 'Lo usamos solo para enviarte la constancia de tu donación. Nunca se muestra públicamente.',
        required: 'Escribe tu correo.',
        invalid: 'Escribe un correo válido.'
    },
    visibility: {
        toggle: 'Donar de forma anónima',
        anonymous: 'Anónima',
        public: 'Con nombre',
        anonymousHelp: 'Tu nombre no se mostrará en el portal.',
        publicName: 'Nombre público',
        publicNameHelp:
            'Puede ser tu nombre y apellidos, el de tu familia o el de tu empresa. Así aparecerá en el reconocimiento de la campaña.',
        publicNameRequired: 'Escribe el nombre con el que quieres aparecer.',
        publicNameTooLong: 'El nombre no puede tener más de 80 caracteres.'
    },
    invoice: {
        toggle: 'Solicitar factura',
        yes: 'Sí',
        no: 'No',
        independent: 'Pedir factura no cambia si tu donación es anónima o pública.',
        scope: 'Solo guardamos estos datos para atender tu solicitud; el portal no emite facturas.',
        legalName: 'Nombre o razón social',
        legalNameRequired: 'Escribe tu nombre o razón social.',
        legalNameTooLong: 'El nombre o razón social no puede tener más de 254 caracteres.',
        rfc: 'RFC',
        rfcHelp: 'Escríbelo sin espacios. Solo revisamos que tenga un formato válido; no lo consultamos con el SAT.',
        rfcRequired: 'Escribe tu RFC.',
        rfcInvalid: 'El RFC no tiene un formato válido.',
        taxpayerType: 'Tipo de persona: {0}',
        person: 'Física',
        company: 'Moral',
        postalCode: 'Código postal fiscal',
        postalCodeRequired: 'Escribe tu código postal fiscal.',
        postalCodeInvalid: 'El código postal debe tener 5 dígitos.',
        regime: 'Régimen fiscal',
        regimePlaceholder: 'Selecciona un régimen',
        regimeHelp: 'Mostramos los regímenes que corresponden al tipo de persona de tu RFC.',
        regimeRequired: 'Selecciona tu régimen fiscal.'
    },
    submit: {
        label: 'Continuar al pago',
        busy: 'Abriendo el pago…',
        note: 'Te llevaremos a Mercado Pago para completar tu pago.',
        errorTitle: 'No pudimos continuar',
        genericError: 'No pudimos abrir el pago, intenta de nuevo',
        fixFields: 'Revisa los campos marcados para continuar.'
    }
};
