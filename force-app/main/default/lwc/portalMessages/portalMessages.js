// Every visible text of the portal lives here. Each key maps one to one to a Custom Label
// (@salesforce/label/c.Portal_<Section>_<Key>), so moving to labels only changes this file.
export const MESSAGES = {
    eventName: 'Mexico Dreamin´',
    availability: {
        OPEN: 'Activa',
        PAUSED: 'Pausada',
        CLOSED: 'Cerrada',
        ENDED: 'Campaña finalizada'
    },
    list: {
        title: 'Campañas disponibles',
        subtitle: 'Elige la campaña con la que quieres apoyar a nuestra comunidad en Mexico Dreamin´.',
        loading: 'Cargando campañas…',
        empty: 'No hay campañas disponibles por ahora',
        error: 'No pudimos cargar las campañas. Intenta de nuevo en unos momentos.',
        retry: 'Reintentar',
        viewDetail: 'Ver detalle',
        viewDetailOf: 'Ver detalle de la campaña {0}',
        generalCampaign: 'Campaña general',
        closesOn: 'Cierra el {0}',
        pausedNote: 'Pausada por ahora: todavía no recibe donaciones.',
        imageAlt: 'Imagen de la campaña {0}',
        noImageAlt: 'Imagen no disponible para la campaña {0}'
    },
    progress: {
        label: 'Avance de la campaña',
        raised: 'Recaudado: {0}',
        goal: 'Meta: {0}',
        ofGoal: '{0} de la meta',
        goalReached: 'Meta alcanzada',
        donationOne: '1 donación confirmada',
        donationMany: '{0} donaciones confirmadas'
    },
    detail: {
        back: 'Volver a las campañas',
        loading: 'Cargando la campaña…',
        error: 'No pudimos cargar la campaña. Intenta de nuevo en unos momentos.',
        retry: 'Reintentar',
        notFound: 'No encontramos esta campaña. Es posible que el enlace no sea correcto o que la campaña ya no esté disponible.',
        viewAvailable: 'Ver campañas disponibles',
        aboutTitle: 'Acerca de esta campaña',
        generalCampaign: 'Campaña general',
        startsOn: 'Inicio: {0}',
        endsOn: 'Cierre: {0}',
        donate: 'Donar',
        donationsClosed: 'Donaciones cerradas',
        donationsPaused: 'Donaciones en pausa',
        pausedNotice: 'Esta campaña está pausada y por ahora no acepta donaciones.',
        closedNotice: 'Esta campaña está cerrada y ya no acepta donaciones.',
        endedNotice: 'Esta campaña ha finalizado su periodo de recaudación y ya no acepta donaciones.',
        notAcceptingNotice: 'En este momento esta campaña no acepta donaciones.',
        imageAlt: 'Imagen de la campaña {0}',
        noImageAlt: 'Imagen no disponible para la campaña {0}'
    },
    recognition: {
        title: 'Reconocimiento de donantes',
        loading: 'Cargando reconocimientos…',
        empty: 'Aún no hay donantes con reconocimiento público en esta campaña.',
        error: 'No pudimos cargar el reconocimiento de donantes. Intenta de nuevo en unos momentos.',
        retry: 'Reintentar',
        showMore: 'Ver más donantes',
        listLabel: 'Donantes con reconocimiento público',
        demoBadge: 'Vista de demostración',
        demoNote: 'Estos nombres y montos son ficticios y no corresponden a donaciones reales.'
    }
};

/**
 * Replaces {0}, {1}... in a message with the given values.
 * @param {string} template message with numbered placeholders
 * @param {...(string|number)} values values for the placeholders
 * @returns {string} the message with the values inserted
 */
export function formatMessage(template, ...values) {
    return template.replace(/\{(\d+)\}/g, (match, index) => {
        const value = values[Number(index)];
        return value === undefined || value === null ? '' : String(value);
    });
}
