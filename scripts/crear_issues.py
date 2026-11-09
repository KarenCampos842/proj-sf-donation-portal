#!/usr/bin/env python3
"""
Crea las historias del backlog (v2, con recortes de E1) como issues de GitHub.

Uso:
  gh auth login                      # una sola vez
  gh auth refresh -s project         # solo si quieres añadirlas al Project
  python crear_issues.py --dry-run   # ver qué crearía, sin crear nada
  python crear_issues.py             # crear

Es seguro repetirlo: omite las historias cuyo ID ya existe como issue
(por ejemplo DON-01, que ya es el #1).
Al final genera docs/tablero.md (ID, RF, hito, historia, AC, estado, evidencia).
"""
import argparse, json, os, subprocess, sys, time

# ----------------------------- CONFIGURACIÓN -----------------------------
REPO = "KarenCampos842/proj-sf-donation-portal"
OWNER = "KarenCampos842"
PROJECT_NUMBER = "13"          # número del Project (está en su URL: .../projects/N). Vacío = no añadir
USERS = {                    # Responsable -> usuario de GitHub
    "A": "RodrigoPeraza",
    "B": "KarenCampos842",                 # <- usuario de GitHub de B
    "C": "Alambrep",                 # <- usuario de GitHub de C
}
MILESTONES = {               # hito -> (prefijo del título, fecha límite)
    "E1": ("E1 - Primera entrega", "2026-11-10"),
    "E2": ("E2 - Segunda entrega", "2026-11-17"),
}
LABELS = {
    "must": "d73a4a", "should": "fbca04", "could": "0e8a16",
}
PENDING = ("Pendiente de evidencia.\n"
           "Enlace a video con marca de tiempo, captura de pantalla o demostración.")

# ------------------------------- HISTORIAS --------------------------------
S = []
def s(id, title, rf, prio, hito, talla, resp, story, acs, tacs):
    S.append(dict(id=id, title=title, rf=rf, prio=prio, hito=hito, talla=talla,
                  resp=resp, story=story, acs=acs, tacs=tacs))

# ---- Donante: descubrir campañas ----
s('DON-01', 'Consultar las campañas disponibles', 'RF-D1a, RFV1', 'must', 'E1', 'M', 'B',
  'Como visitante, quiero ver las campañas disponibles, para elegir la causa a la que quiero aportar.',
  ['Dado que soy visitante y entro al portal sin cuenta ni sesión iniciada, cuando consulto el listado, entonces puedo ver las campañas disponibles y comenzar una donación sin registrarme ni iniciar sesión.',
   'Dado que hay una o más campañas Activas dentro de sus fechas, cuando entro al portal, entonces veo cada una con nombre, imagen, meta y avance, y puedo abrir su detalle.',
   'Dado que una campaña está Activa pero su fecha de inicio aún no llega, cuando entro, entonces no aparece.',
   'Dado que una campaña está Pausada, cuando entro o abro su enlace, entonces veo su información marcada como "Pausada" y no puedo donarle.',
   'Dado que no hay campañas disponibles, cuando entro, entonces veo el mensaje "No hay campañas disponibles por ahora".',
   'Dado que una campaña está en Borrador o Cerrada, cuando entro al listado, entonces no aparece.'],
  ['La consulta pública devuelve solo campañas publicables y campos expresamente públicos; Borrador nunca se expone.',
   'La elegibilidad para pagar se calcula con estado y fechas en el servidor, no solo con una etiqueta en la interfaz.',
   'Las Pausadas se muestran como informativas, sin acción para donar.'])

s('DON-02', 'Consultar el detalle de una campaña', 'RF-D1a', 'must', 'E1', 'S', 'B',
  'Como visitante, quiero ver el detalle de una campaña, para entender su propósito antes de donar.',
  ['Dado que abro una campaña disponible, cuando veo su detalle, entonces veo nombre, descripción, imagen, meta, avance y fecha de cierre si existe.',
   'Dado que estoy en el detalle, cuando quiero ver otras campañas, entonces puedo volver al listado.',
   'Dado que la campaña está Pausada o Cerrada, cuando abro su detalle, entonces leo su información y veo que no acepta donaciones.',
   'Dado que la campaña está Pausada o Cerrada, cuando intento donar desde su detalle, entonces no puedo iniciar la donación.'],
  ['El detalle se resuelve por el identificador de la campaña y vuelve a validar su elegibilidad en el servidor.',
   'La respuesta pública no incluye datos internos ni personales de donantes.'])

s('DON-03', 'Consultar el avance de una campaña', 'RF-D1a', 'must', 'E1', 'S', 'B',
  'Como visitante, quiero ver cuánto se ha reunido respecto a la meta, para conocer el avance de la campaña.',
  ['Dado que hay donaciones confirmadas, cuando consulto la campaña, entonces el total recaudado es la suma de esas donaciones.',
   'Dado que una donación confirmada es anónima, cuando se calcula el avance, entonces su monto también se incluye.',
   'Dado que el total alcanza o supera la meta, cuando consulto el avance, entonces veo el porcentaje real, incluso por encima de 100 %, y la campaña sigue aceptando donaciones mientras esté vigente.',
   'Dado que una donación se confirma, cuando recargo el portal, entonces el avance incluye ese monto.',
   'Dado que un pago no está confirmado, cuando consulto el avance, entonces ese pago no se incluye.'],
  ['El total se calcula en el servidor a partir de las donaciones confirmadas de la campaña (campo de resumen sobre la relación campaña-donación).',
   'El porcentaje no se limita artificialmente a 100 %.',
   'La consulta pública devuelve totales agregados, no registros individuales de donación.'])

s('DON-04', 'Ver el reconocimiento de donantes', 'RF-C1', 'must', 'E1', 'M', 'B',
  'Como visitante, quiero ver los nombres y montos de quienes eligieron aparecer, para conocer quién apoya la campaña.',
  ['Dado que una donación confirmada eligió reconocimiento público, cuando abro la campaña, entonces veo su nombre y su monto en el reconocimiento de esa campaña.',
   'Dado que aún no hay nombres para mostrar, cuando consulto el reconocimiento, entonces veo un mensaje que lo indica.',
   'Dado que una donación es anónima, cuando consulto el reconocimiento, entonces no aparece su nombre ni su correo.',
   'Dado que un pago no está confirmado, cuando consulto el reconocimiento, entonces no aparece.',
   'Dado que consulto el reconocimiento, cuando veo cada entrada, entonces solo hay nombre y monto: ni correo ni otro dato personal.'],
  ['La consulta filtra por donaciones confirmadas con reconocimiento público.',
   'La respuesta incluye solo nombre público y monto; no serializa el registro completo de la donación.',
   'La lista se ordena por fecha de confirmación descendente.'])

s('DON-05', 'Consultar campañas cerradas', '—', 'could', 'E2', 'S', 'B',
  'Como visitante, quiero ver campañas cerradas y sus resultados, para conocer lo que se ha logrado antes.',
  ['Dado que existen campañas cerradas, cuando consulto el historial, entonces veo su nombre, meta y total final.',
   'Dado que no hay campañas cerradas, cuando consulto el historial, entonces veo un mensaje que lo indica.',
   'Dado que una campaña está cerrada, cuando intento donarle, entonces no puedo.'],
  ['La consulta del historial es de solo lectura y es el único lugar público donde aparecen las Cerradas.',
   'Las campañas cerradas no forman parte del conjunto elegible para iniciar pagos.'])

# ---- Donante: preparar la donación ----
s('DON-08', 'Elegir un monto sugerido', 'RF-D1a', 'must', 'E1', 'S', 'B',
  'Como donante, quiero elegir uno de los montos sugeridos, para indicar rápido cuánto quiero aportar.',
  ['Dado que voy a donar a una campaña disponible, cuando llego al paso del monto, entonces veo las opciones rápidas configuradas; inicialmente son $100, $250, $500, $1,000, $2,000, $5,000, $10,000 y $20,000 MXN.',
   'Dado que selecciono una opción rápida, cuando continúo, entonces ese monto es el que se usa para el pago.',
   'Dado que no elegí ningún monto, cuando intento continuar, entonces no avanzo y se me pide indicar uno.'],
  ['Los ocho importes iniciales se presentan como opciones independientes, con formato monetario MXN consistente.',
   'Elegir un importe solo prepara la donación; no crea la operación de pago ni efectúa un cargo.',
   'Los importes salen de la configuración vigente (ADM-13 en E2; en E1, valores fijos).',
   'Regla: las opciones rápidas y la opción de otro monto (DON-09) se muestran juntas en el mismo paso. DON-09 entra en E2.'])

s('DON-09', 'Capturar otro monto', 'RF-D1b', 'must', 'E2', 'S', 'B',
  'Como donante, quiero indicar un monto distinto de los sugeridos, para aportar lo que puedo.',
  ['Dado que estoy en el paso del monto, cuando veo las opciones rápidas, entonces veo en el mismo paso la opción de capturar otro monto.',
   'Dado que capturo un monto igual o superior al mínimo vigente (inicialmente $50 MXN) y el proveedor lo admite, cuando continúo, entonces el resumen muestra exactamente ese monto.',
   'Dado que había elegido una opción rápida y capturo otro monto (o al revés), cuando continúo, entonces solo cuenta el último que indiqué.',
   'Dado que pagué un monto personalizado, cuando reviso mi donación, entonces el monto cobrado y el registrado son los que capturé.',
   'Dado que capturo menos del mínimo vigente, cero, un negativo, texto, un valor vacío o más de dos decimales, cuando continúo, entonces no avanzo y veo el motivo.',
   'Dado que capturo un monto que el proveedor no puede procesar, cuando continúo, entonces veo que esa cantidad no se puede procesar y puedo elegir otra.'],
  ['La validación se aplica en cliente y en servidor; la del navegador no se considera una barrera de seguridad.',
   'El monto se maneja como decimal exacto con dos posiciones, sin operaciones de punto flotante.',
   'Solo hay un valor de monto activo: capturar uno descarta el otro.',
   'El mínimo se obtiene de la configuración vigente (ADM-13); su valor inicial es $50 MXN. El máximo real de la cuenta de prueba de Mercado Pago se documenta en TEC-02.'])

s('DON-10', 'Donar de forma anónima', 'RF-D2', 'must', 'E1', 'S', 'B',
  'Como donante, quiero que mi nombre no se muestre públicamente, para aportar sin exponerme.',
  ['Dado que elijo donar de forma anónima y no pido factura, cuando capturo mis datos, entonces solo se me pide mi correo.',
   'Dado que mi donación anónima se confirma, cuando se actualiza la campaña, entonces mi monto suma al avance sin mostrar mi identidad.',
   'Dado que elijo anonimato, cuando también pido factura, entonces se me piden los datos fiscales y mi nombre sigue sin mostrarse en el portal.',
   'Dado que mi donación es anónima, cuando reviso el portal (campañas, reconocimiento y agradecimiento), entonces no aparece mi nombre ni mi correo.'],
  ['La donación conserva un indicador de visibilidad anónima.',
   'El anonimato aplica frente al público; el proveedor de pago procesa los datos mínimos necesarios para completar la operación simulada.',
   'El correo se usa solo para el flujo operativo y la constancia; nunca se incluye en consultas públicas.',
   'El correo se valida por estructura, sin afirmar que se verifica la existencia del buzón.'])

s('DON-11', 'Donar con reconocimiento público', 'RF-C1', 'must', 'E1', 'S', 'B',
  'Como donante, quiero indicar el nombre con el que quiero aparecer (mío, de mi familia o de mi empresa), para que se reconozca mi apoyo.',
  ['Dado que elijo aparecer públicamente, cuando capturo mis datos, entonces se me piden nombre o nombre de empresa, apellidos (si soy persona) y correo.',
   'Dado que mi donación se confirma, cuando abro la campaña, entonces mi nombre aparece como lo capturé, junto con mi monto.',
   'Dado que dejo vacío el nombre o el correo, o el nombre pasa de 80 caracteres, cuando intento continuar, entonces no avanzo y veo qué corregir.',
   'Dado que escribo código o etiquetas en el nombre (por ejemplo `<script>alert(1)</script>`), cuando se muestra, entonces aparece como texto inofensivo y no se ejecuta.'],
  ['El nombre público es independiente del correo y de los datos que procesa el proveedor de pago.',
   'El nombre se sanea antes de guardarse y se escapa al mostrarse (RNF-04); límite de 80 caracteres.',
   'Las donaciones anónimas no generan nombre público.'])

s('DON-12', 'Solicitar factura', 'RF-F1', 'must', 'E1', 'M', 'B',
  'Como donante que necesita factura, quiero indicar mis datos fiscales al donar, para que quien emita la factura tenga los datos necesarios.',
  ['Dado que pido factura, cuando capturo mis datos, entonces se me piden nombre o razón social, RFC, código postal fiscal y régimen fiscal, sea persona física o moral.',
   'Dado que pido factura, cuando elijo mi visibilidad, entonces puedo ser anónimo o público.',
   'Dado que capturo un RFC, cuando continúo, entonces se valida su estructura completa (letras iniciales, fecha y homoclave), considerando 13 caracteres para persona física y 12 para persona moral; no se consulta al SAT.',
   'Dado que capturo el RFC en minúsculas o con espacios al inicio o al final, cuando continúo, entonces se guarda en mayúsculas y sin espacios.',
   'Dado que capturo GODE561231GR8 (persona física) o ABC010203XY1 (persona moral), cuando continúo, entonces se acepta.',
   'Dado que capturo un RFC de 11 o 14 caracteres, con mes 13 (GODE561331GR8), con letras donde va la fecha o con caracteres especiales no permitidos, cuando continúo, entonces se rechaza con el mensaje "El RFC no tiene un formato válido".',
   'Dado que falta un dato fiscal obligatorio, cuando intento continuar, entonces no avanzo y veo cuál falta.',
   'Dado que completé una donación con factura, cuando se revisa el sistema, entonces no existe ninguna factura ni comprobante fiscal generado por el sistema.'],
  ['Los datos fiscales se guardan separados de los datos públicos y solo los ven los roles internos.',
   'La validación de RFC usa el patrón completo del SAT y se aplica en el servidor.',
   'El régimen fiscal se elige de una lista (catálogo del SAT) filtrada por tipo de persona.',
   'No se emite CFDI, no se consulta al SAT, no se piden datos bancarios y no se pide el uso de la factura.'])

s('DON-13', 'Aceptar el aviso de privacidad', '—', 'should', 'E2', 'S', 'B',
  'Como donante que pide factura, quiero aceptar el aviso de privacidad, para dejar constancia de que autorizo el uso de mis datos fiscales.',
  ['Dado que pido factura, cuando llego al envío, entonces veo la casilla "Acepto el aviso de privacidad", sin texto adicional ni página aparte.',
   'Dado que marqué la casilla, cuando se registra mi donación, entonces queda guardado que acepté y la fecha y hora.',
   'Dado que no marqué la casilla, cuando intento continuar con factura, entonces no avanzo y se me indica que es obligatoria.',
   'Dado que no pido factura, cuando capturo mis datos, entonces no se me muestra la casilla.'],
  ['La aceptación se guarda como un indicador y una fecha y hora en el intento de pago y se copia a la donación; no basta con una variable que solo habilite el botón.',
   'El servidor rechaza un intento con factura sin la aceptación, aunque el navegador la omita.'])

s('DON-17', 'Corregir datos inválidos', '—', 'must', 'E2', 'M', 'B',
  'Como donante, quiero identificar y corregir los datos inválidos sin volver a capturar todo, para completar mi donación sin frustración.',
  ['Dado que un campo obligatorio está vacío o con formato inválido, cuando intento continuar, entonces se señala el campo y se explica qué corregir.',
   'Dado que corrijo el dato señalado, cuando continúo, entonces se conservan los demás datos que ya capturé.',
   'Dado que ocurre un error interno, cuando intento continuar, entonces no veo mensajes técnicos ni datos internos.'],
  ['Cada campo se valida en el servidor y recibe mensajes de validación asociados.',
   'Los errores internos se registran de forma segura y se traducen a mensajes en español.',
   'Los mensajes de error no incluyen claves, correos, nombres de donantes ni información sensible.'])

s('DON-18', 'Revisar y confirmar la donación', '—', 'must', 'E2', 'M', 'B',
  'Como donante, quiero revisar el resumen de mi donación y confirmarlo, para autorizar el pago con esos datos.',
  ['Dado que completé mis datos, cuando se presenta el resumen, entonces veo campaña, monto en MXN, correo, visibilidad y, si la pedí, la solicitud de factura.',
   'Dado que elegí reconocimiento público, cuando reviso el resumen, entonces veo el nombre que se mostrará; si elegí anonimato, veo que mi nombre no será visible.',
   'Dado que confirmo el resumen, cuando continúo, entonces paso al pago con ese monto y esa campaña.',
   'Dado que vuelvo a cambiar un dato, cuando regreso al resumen, entonces debo confirmarlo otra vez.',
   'Dado que no confirmo el resumen, cuando intento continuar, entonces no paso al pago.'],
  ['El resumen se genera con los valores ya validados que se enviarán al proveedor, no con valores que llegan del navegador al momento de cobrar.',
   'La confirmación es obligatoria para todos los importes.',
   'Si el donante cambia datos, el resumen se recalcula y debe confirmarse de nuevo antes de pagar.',
   'Regla: el resumen se pide a todos los donantes, sin importar el monto.'])

# ---- Donante: pagar y recibir confirmación ----
s('DON-19', 'Pagar con tarjeta', 'RF-D3', 'must', 'E1', 'L', 'A',
  'Como donante, quiero pagar con tarjeta de forma segura, para completar mi donación en línea.',
  ['Dado que completé mis datos y la campaña acepta donaciones, cuando continúo, entonces puedo pagar con una tarjeta de prueba por el monto y la campaña que elegí.',
   'Dado que pagué, cuando reviso lo que guarda el programa, entonces no hay datos de mi tarjeta.',
   'Dado que la campaña dejó de aceptar donaciones antes de iniciar el pago, cuando intento pagar, entonces no puedo y veo el motivo.',
   'Dado que alguien altera el monto o la campaña antes de pagar, cuando continúa, entonces el cobro corresponde a lo que se validó en el servidor.',
   'Dado que el proveedor no responde al abrir el pago, cuando continúo, entonces veo "No pudimos abrir el pago, intenta de nuevo" y no queda un intento a medias.'],
  ['La operación de pago se crea en el servidor con el monto y la campaña ya validados: `POST /checkout/preferences` de Mercado Pago (Checkout Pro) con `items[0].unit_price` = monto, `currency_id` = MXN, `external_reference` = Id del intento (PAY-07), `back_urls` (success, failure, pending) hacia la página de agradecimiento, `auto_return` = approved y `notification_url` = entrada pública de avisos (PAY-06).',
   'La llamada usa una credencial con nombre; el token de acceso de prueba vive en la credencial externa, nunca en el código, el repositorio ni los prompts.',
   'Los datos de tarjeta los captura el proveedor; no se almacenan en Salesforce.',
   'Crear la operación de pago no crea una donación confirmada.',
   'Las llamadas al proveedor tienen pruebas con respuestas simuladas (aprobado, error del proveedor, tiempo agotado).'])

s('DON-20', 'Entender un pago cancelado o rechazado', 'RF-D4', 'must', 'E1', 'M', 'A',
  'Como donante, quiero saber si mi pago se canceló o fue rechazado, para entender que mi donación no se completó y decidir cómo continuar.',
  ['Dado que cancelé el pago, cuando regreso al portal, entonces veo que se canceló y que no se registró mi donación.',
   'Dado que el proveedor rechazó mi pago (tarjeta de prueba con titular "OTHE"), cuando regreso al portal, entonces veo que fue rechazado y que no se registró mi donación.',
   'Dado que mi pago no se completó y la campaña sigue disponible, cuando quiero intentarlo de nuevo, entonces puedo iniciar una nueva donación.',
   'Dado que cerré la ventana sin conocer el resultado, cuando regreso al portal, entonces no se me dice que cancelé ni que me rechazaron: se me dice que el resultado aún no está confirmado.',
   'Dado que mi pago no se completó, cuando consulto el avance, entonces ese intento no aparece.'],
  ['El estado Cancelado o Rechazado solo se asigna cuando lo informa el proveedor o una consulta autenticada del pago (`GET /v1/payments/{id}` con estado `rejected` o `cancelled`).',
   'Abandono del navegador, cancelación del pago y estado desconocido son condiciones distintas.',
   'Un intento cancelado o rechazado no crea donación, no suma y no envía constancia; un nuevo intento no altera el resultado del anterior.'])

s('DON-21', 'Ver el resultado de mi pago al volver', 'RF-D4', 'must', 'E1', 'M', 'A',
  'Como donante, quiero ver el resultado real de mi pago al volver al portal, para saber que mi pago se recibió y si ya está confirmado.',
  ['Dado que completé el pago, cuando regreso al portal, entonces siempre veo una página de agradecimiento.',
   'Dado que el proveedor confirmó mi pago, cuando regreso al portal, entonces el agradecimiento indica que mi aportación fue recibida.',
   'Dado que el proveedor aún no confirma mi pago (estado `in_process` o `pending`), cuando regreso al portal, entonces el agradecimiento me dice que estamos confirmando mi pago y no se me sugiere pagar otra vez.',
   'Dado que mi donación es anónima, cuando veo el agradecimiento, entonces no aparece mi nombre.',
   'Dado que el pago aún no está confirmado, cuando veo el agradecimiento, entonces no dice que está confirmado.',
   'Dado que cambio en la dirección el estado (`status=approved`) o el identificador de pago por el de otra persona, cuando cargo la página, entonces no se registra ninguna donación ni veo datos de esa otra donación.',
   'Dado que veo el agradecimiento, cuando lo reviso, entonces no muestra datos de otros donantes.'],
  ['En E1 la página de retorno toma el `payment_id` que regresa Mercado Pago y el servidor consulta `GET /v1/payments/{payment_id}` con el token de prueba. Solo si el estado es `approved`, el `external_reference` corresponde a un intento existente y el monto coincide, registra la donación (PAY-02). En E2 esto lo hace también el aviso automático (PAY-06); el que llegue primero registra y el otro no duplica (PAY-03).',
   'Los parámetros de la dirección (`status`, `external_reference`, `preference_id`) nunca se usan como prueba de pago.',
   'Los errores de comunicación se distinguen de los rechazos definitivos.',
   'La página no expone información de otros donantes.'])

s('DON-23', 'Recibir una constancia por correo', 'RF-D5', 'must', 'E2', 'M', 'C',
  'Como donante, quiero recibir una sola constancia de mi pago confirmado en mi correo, para tener evidencia de mi donación.',
  ['Dado que mi pago se confirmó, cuando reviso mi correo, entonces recibo una constancia en español con campaña, monto, fecha y referencia de la operación.',
   'Dado que recibo la constancia, cuando la leo, entonces indica que es una operación de prueba sin valor fiscal.',
   'Dado que mi donación es anónima, cuando leo la constancia, entonces no muestra mi nombre.',
   'Dado que mi pago no está confirmado, cuando reviso mi correo, entonces no recibí constancia.',
   'Dado que la confirmación de mi pago se procesa más de una vez, cuando reviso mi correo, entonces recibí una sola constancia.'],
  ['La envía el portal al crearse la donación confirmada; el recibo de Mercado Pago no se usa porque en pruebas llega al correo ficticio del comprador de prueba.',
   'El envío se controla con un indicador "constancia enviada" en la donación, para no repetirlo.',
   'Se documenta el límite diario de correos a direcciones externas de la org Developer Edition y se prueba solo con correos del equipo.'])

s('DON-24', 'Registrar un pago confirmado después del cierre', '—', 'should', 'E2', 'S', 'A',
  'Como donante, quiero que se registre mi donación si ya había pagado antes del cierre de la campaña y la confirmación llega después, para que no se pierda una aportación válida.',
  ['Dado que pagué antes de que cerrara la campaña, cuando el proveedor confirma después del cierre, entonces mi donación se registra y cuenta en el resultado final.',
   'Dado que la campaña ya estaba cerrada, cuando intento iniciar un pago, entonces no puedo.',
   'Dado que el proveedor no confirma el pago, cuando llega el cierre, entonces no se registra ninguna donación.'],
  ['La elegibilidad de la campaña se verifica al crear el intento y la preferencia de pago, no al confirmar.',
   'La confirmación posterior se procesa según el intento creado válidamente; se usa `date_approved` del pago para documentar cuándo se pagó.'])

s('DON-26', 'Ver el portal en otro idioma', '—', 'could', None, 'S', 'B',
  'Como donante que no lee español, quiero ver el portal en mi idioma, para donar con confianza.',
  ['Dado que hay otro idioma disponible, cuando lo elijo, entonces el portal, el resumen y la constancia se ven en ese idioma.',
   'Dado que no hay otro idioma disponible, cuando entro, entonces el portal funciona en español sin errores.'],
  ['Los textos quedan en etiquetas personalizadas, preparados para traducirse (RNF-13); no es obligatorio implementar otro idioma.'])

# ---- Gestor de campañas ----
s('GES-02', 'Consultar estado y avance de las campañas', 'RF-S1', 'must', 'E1', 'S', 'C',
  'Como gestor de campañas, quiero ver todas las campañas con su estado, fechas, meta y avance, para saber cuáles reciben donaciones y cuáles necesitan atención.',
  ['Dado que existen campañas, cuando abro el listado interno, entonces veo de cada una su estado, fecha de inicio, fecha de cierre si existe, meta, total recaudado y si acepta donaciones.',
   'Dado que una campaña no tiene donaciones, cuando consulto su avance, entonces veo cero.',
   'Dado que un pago no está confirmado, cuando consulto el avance, entonces no se incluye en el total.'],
  ['La vista interna incluye todas las campañas y muestra la causa de cierre cuando corresponda.',
   'El avance se calcula con donaciones confirmadas de cada campaña.',
   'El gestor tiene lectura sobre campañas y donaciones, pero no modifica monto ni resultado del pago.'])

s('GES-03', 'Preparar una campaña', 'RF-S1', 'must', 'E1', 'M', 'C',
  'Como gestor de campañas, quiero crear una campaña con nombre, descripción, imagen, meta y fechas, para preparar una recaudación.',
  ['Dado que capturo nombre, descripción, imagen, meta y fecha de inicio, cuando guardo, entonces la campaña queda en Borrador y no es pública.',
   'Dado que capturo los datos completos y elijo activarla al crearla, cuando hoy está dentro de sus fechas, entonces la campaña aparece en el portal.',
   'Dado que no capturo fecha de cierre, cuando guardo, entonces la campaña puede seguir abierta hasta que se pause o cierre.',
   'Dado que falta el nombre o la meta es cero o negativa, cuando intento guardar, entonces no se guarda y veo qué corregir.',
   'Dado que la fecha de cierre es anterior a la de inicio, cuando intento guardar, entonces se rechaza con el motivo.'],
  ['El estado inicial por defecto es Borrador; se puede crear y activar en un solo paso.',
   'Las validaciones se aplican en el servidor: nombre, meta mayor a cero y fechas.',
   'Fecha de inicio obligatoria; fecha de cierre opcional. Zona horaria America/Merida.',
   'Las campañas no se pueden borrar (se quita el permiso de borrado): borrar una campaña borraría sus donaciones.'])

s('GES-06', 'Activar una campaña', 'RF-S1', 'must', 'E1', 'S', 'C',
  'Como gestor de campañas, quiero activar una campaña preparada, para publicarla y que reciba donaciones durante su vigencia.',
  ['Dado que una campaña en Borrador tiene sus datos completos, cuando la activo dentro de sus fechas, entonces aparece en el portal y acepta donaciones.',
   'Dado que ya hay una campaña Activa, cuando activo otra, entonces ambas se muestran a la vez.',
   'Dado que la fecha de inicio es futura, cuando la activo, entonces no aparece ni acepta donaciones hasta esa fecha.',
   'Dado que falta un dato obligatorio, cuando intento activarla, entonces sigue en Borrador y veo qué falta.'],
  ['La activación cambia el estado, pero la elegibilidad pública también verifica las fechas.',
   'Cubre RF-S1 CA1 de la guía: crear y activar una campaña con nombre y meta la publica en el portal.',
   'Varias campañas pueden estar Activas a la vez; el sistema no impone un límite.'])

s('GES-07', 'Pausar y reanudar una campaña', 'RF-S1', 'must', 'E1', 'S', 'C',
  'Como gestor de campañas, quiero pausar y reanudar una campaña sin cambiar sus fechas, para detener las donaciones temporalmente si hay un problema.',
  ['Dado que una campaña está Activa, cuando la pauso, entonces deja de aceptar donaciones y conserva sus fechas.',
   'Dado que una campaña está Pausada y aún está dentro de sus fechas, cuando la reanudo, entonces vuelve a aceptar donaciones.',
   'Dado que una campaña está Pausada, cuando alguien intenta donar desde un enlace guardado, entonces no puede.'],
  ['Pausar y reanudar son transiciones de estado; no se simulan cambiando fechas.',
   'El servidor valida el estado al crear la operación de pago.',
   'Los pagos ya iniciados antes de la pausa se registran si el proveedor los confirma (igual que DON-24).'])

s('GES-09', 'Actualizar una campaña', 'RF-S1', 'must', 'E1', 'S', 'C',
  'Como gestor de campañas, quiero actualizar la descripción, la imagen, la meta y las fechas de una campaña, para mantener correcta su información.',
  ['Dado que cambio la descripción o la imagen con datos válidos, cuando guardo, entonces el detalle público muestra la información nueva.',
   'Dado que una campaña ya recibió donaciones, cuando cambio su meta, entonces el portal muestra la meta nueva y recalcula el avance contra ella.',
   'Dado que cambio las fechas con datos válidos, cuando guardo, entonces el portal respeta las fechas nuevas.',
   'Dado que actualizo una campaña, cuando guardo, entonces las donaciones confirmadas no cambian.',
   'Dado que un cambio no cumple las reglas de validación, cuando guardo, entonces se conserva la última información válida.',
   'Dado que la nueva fecha de cierre es anterior a la de inicio, cuando guardo, entonces no se guarda y veo el motivo.',
   'Dado que soy moderador, cuando intento editar una campaña, entonces no puedo.'],
  ['Los cambios se validan en el servidor antes de guardarse.'])

s('GES-10', 'Consultar las donaciones de una campaña', 'RF-S2', 'should', 'E2', 'S', 'C',
  'Como gestor de campañas, quiero ver las donaciones confirmadas de una campaña, para entender cómo se compone su recaudación.',
  ['Dado que una campaña tiene donaciones confirmadas, cuando las consulto, entonces veo monto, fecha, referencia y visibilidad de cada una.',
   'Dado que hay donaciones anónimas, cuando las consulto, entonces aparecen identificadas como anónimas.',
   'Dado que soy gestor, cuando intento cambiar un monto o el resultado de un pago, entonces no puedo.'],
  ['La consulta se limita a las donaciones de la campaña.',
   'El gestor puede ver el correo; monto y resultado del pago son de solo lectura.'])

s('GES-11', 'Dejar de aceptar donaciones al llegar la fecha de cierre', '—', 'must', 'E2', 'M', 'C',
  'Como gestor de campañas, quiero que la campaña deje de aceptar donaciones cuando termine su fecha de cierre, para cerrar la recaudación en el momento previsto.',
  ['Dado que una campaña tiene fecha de cierre, cuando termina ese día (hora de Mérida), entonces deja de aceptar donaciones y pasa a Cerrada.',
   'Dado que una campaña no tiene fecha de cierre, cuando pasa el tiempo, entonces sigue aceptando donaciones mientras esté Activa.',
   'Dado que una campaña alcanzó su meta antes de su fecha de cierre, cuando un visitante la consulta, entonces todavía puede donar.',
   'Dado que la fecha de cierre ya terminó, cuando alguien intenta donar aunque tuviera la página abierta desde antes, entonces no puede iniciar el pago.'],
  ['La elegibilidad se calcula con estado y fechas en el servidor desde el instante de corte.',
   'Un proceso programado diario pasa a Cerrada las campañas vencidas y guarda la causa "Por fecha".'])

s('GES-12', 'Cerrar una campaña antes de su fecha', '—', 'could', 'E2', 'S', 'C',
  'Como gestor de campañas, quiero cerrar una campaña antes de su fecha, para terminar la recaudación cuando ya no haga falta.',
  ['Dado que una campaña está Activa, cuando la cierro, entonces deja de aceptar donaciones y conserva su total.',
   'Dado que una campaña está Cerrada, cuando intento donarle, entonces no puedo.'],
  ['Cerrar es distinto de pausar. Se conserva la causa "Manual".',
   'Reabrir una campaña cerrada no se definió (pregunta 5); si hace falta más plazo, se ajusta la fecha mientras esté Activa (GES-09).',
   'Cerrar no borra ni modifica donaciones confirmadas.'])

s('GES-15', 'Consultar el resultado final de una campaña', '—', 'could', 'E2', 'S', 'C',
  'Como gestor de campañas, quiero ver el resultado final de una campaña cerrada, para saber cuánto se recaudó y cuántas donaciones hubo.',
  ['Dado que una campaña está Cerrada, cuando consulto su resultado, entonces veo meta, total recaudado y número de donaciones confirmadas.',
   'Dado que hubo donaciones anónimas, cuando consulto el total, entonces sus montos están incluidos.',
   'Dado que hubo intentos de pago sin confirmar, cuando consulto el resultado, entonces no se incluyen.'],
  ['Los totales se calculan con las donaciones confirmadas de la campaña.',
   'La vista no permite editar monto, estado ni referencia de pago.'])

# ---- Moderador ----
s('MOD-01', 'Consultar los nombres publicados', 'RF-C1', 'must', 'E2', 'S', 'C',
  'Como moderador, quiero ver los nombres que se muestran públicamente, para revisar que sean apropiados.',
  ['Dado que hay donaciones confirmadas con reconocimiento público, cuando abro la lista de nombres, entonces veo nombre, campaña, monto y fecha.',
   'Dado que quiero revisar una campaña, cuando filtro por ella, entonces veo solo sus nombres.',
   'Dado que una donación es anónima o no está confirmada, cuando abro la lista, entonces no aparece.'],
  ['La lista muestra solo lo necesario para revisar: nombre público, campaña, monto y fecha. No muestra correo.',
   'Orden por fecha descendente, con filtro por campaña.'])

s('MOD-03', 'Corregir un nombre público', 'RF-C1', 'must', 'E2', 'S', 'C',
  'Como moderador, quiero corregir un nombre público que tenga errores o sea inapropiado, para mantener un reconocimiento legible y respetuoso.',
  ['Dado que un nombre tiene errores de escritura o formato, cuando guardo la corrección, entonces el portal muestra el nombre corregido.',
   'Dado que corrijo un nombre, cuando consulto su historial, entonces veo quién lo cambió, cuándo y el valor anterior.',
   'Dado que intento cambiar el correo, el monto, la campaña o el estado del pago desde la moderación, cuando guardo, entonces no se permite.'],
  ['El moderador edita únicamente el nombre público.',
   'El historial de campos guarda quién, cuándo y el valor anterior.',
   'El nombre corregido se sanea igual que el original.'])

s('MOD-06', 'Consultar el correo del donante', 'RF-S2', 'should', 'E2', 'S', 'C',
  'Como moderador, quiero ver el correo de una donación, para contactar al donante si hay que aclarar su nombre público.',
  ['Dado que abro una donación confirmada, cuando veo su información interna, entonces puedo ver el correo.',
   'Dado que la donación es anónima, cuando la consulto como moderador, entonces veo el correo sin que se publique.',
   'Dado que soy visitante del portal, cuando intento ver correos de donantes, entonces no obtengo nada.'],
  ['El correo se restringe al entorno interno y a los tres roles que autorizó el cliente.',
   'El correo nunca viaja en las respuestas del portal público.'])

# ---- Administrador ----
s('ADM-01', 'Asignar roles internos', '—', 'must', 'E2', 'M', 'C',
  'Como administrador del sistema, quiero asignar a cada integrante su rol, para limitar su acceso a lo que le corresponde.',
  ['Dado que asigno el rol de gestor, cuando esa persona entra, entonces puede administrar campañas.',
   'Dado que asigno el rol de moderador, cuando esa persona entra, entonces puede revisar y corregir nombres públicos, pero no administrar campañas.',
   'Dado que asigno el rol de administrador, cuando esa persona entra, entonces puede asignar roles y consultar la información interna.',
   'Dado que una persona no tiene rol, cuando intenta entrar a una función interna, entonces se le niega el acceso.'],
  ['Un conjunto de permisos por rol, con mínimo privilegio.',
   'El acceso al correo y la edición del nombre público se controlan por separado.',
   'Ningún rol puede editar monto, referencia ni estado de pago de una donación. El perfil Administrador del sistema de Salesforce (quien configura la org) queda fuera de esta regla y se documenta en seguridad.md.'])

s('ADM-03', 'Consultar todas las donaciones confirmadas', 'RF-S2', 'must', 'E1', 'S', 'C',
  'Como administrador del sistema, quiero ver todas las donaciones confirmadas, para supervisar la recaudación.',
  ['Dado que existen donaciones confirmadas de distintas campañas y modalidades, cuando abro el listado, entonces veo de cada una su estado de pago (Confirmado), monto, modalidad, campaña, fecha, referencia, correo y si solicita factura.',
   'Dado que una donación es anónima, cuando la consulto internamente, entonces aparece identificada como anónima.',
   'Dado que un pago no tiene confirmación válida, cuando abro el listado, entonces no existe una donación para ese pago.',
   'Dado que soy cualquier usuario interno, cuando intento cambiar el monto o el estado de pago, entonces no puedo.'],
  ['La vista interna incluye solo registros creados por confirmaciones válidas.',
   'Los intentos pendientes, cancelados o rechazados no aparecen como donaciones.',
   'Monto y estado de pago son de solo lectura para todo rol.'])

s('ADM-04', 'Filtrar donaciones', 'RF-S2', 'should', 'E2', 'S', 'C',
  'Como administrador del sistema, quiero filtrar las donaciones por campaña, fecha y visibilidad, para encontrar registros concretos.',
  ['Dado que hay donaciones de varias campañas, cuando filtro por una, entonces solo veo las de esa campaña.',
   'Dado que filtro por visibilidad, cuando aplico el filtro, entonces solo veo las que coinciden.',
   'Dado que el filtro no encuentra nada, cuando lo aplico, entonces veo "No hay resultados" y no un error.'],
  ['Los filtros se aplican sobre campos persistidos con valores definidos.',
   'Las consultas respetan los permisos de quien las ejecuta.'])

s('ADM-05', 'Atender solicitudes de factura', 'RF-F2', 'must', 'E1', 'S', 'C',
  'Como administrador del sistema, quiero ver qué donaciones piden factura y con qué datos, para que quien emita la factura fuera del sistema tenga los datos.',
  ['Dado que existe una donación con factura, cuando la consulto, entonces la veo marcada como "solicita factura", con nombre o razón social, RFC, código postal fiscal, régimen fiscal y la aceptación del aviso de privacidad.',
   'Dado que hay donaciones de varios tipos, cuando busco las que piden factura, entonces veo solo esas.',
   'Dado que una donación no pidió factura, cuando busco solicitudes de factura, entonces no aparece.',
   'Dado que soy visitante del portal, cuando intento ver datos fiscales, entonces no obtengo nada.',
   'Dado que atiendo una solicitud, cuando reviso el sistema, entonces no hay forma de emitir un comprobante fiscal.'],
  ['La marca de factura y los datos fiscales se guardan junto a la donación y solo se exponen a roles internos.',
   'El filtro opera sobre un campo propio de solicitud de factura.'])

s('ADM-07', 'Rastrear una donación hasta su pago', 'RF-D3', 'must', 'E1', 'S', 'A',
  'Como administrador del sistema, quiero relacionar cada donación con su pago, para verificar de qué transacción proviene.',
  ['Dado que existe una donación confirmada, cuando abro su detalle, entonces veo la referencia del pago al que corresponde.',
   'Dado que busco por esa referencia, cuando hay coincidencia, entonces encuentro una sola donación.',
   'Dado que un pago no tiene confirmación válida, cuando busco su referencia, entonces no encuentro ninguna donación confirmada.'],
  ['El identificador de pago de Mercado Pago (`payment.id`) se guarda en un campo externo, único y que las personas no pueden editar.',
   'La búsqueda permite localizar una donación por ese identificador.'])

s('ADM-12', 'Consultar avisos de pago rechazados', 'RF-S4', 'should', 'E2', 'S', 'A',
  'Como administrador del sistema, quiero ver los avisos de pago que se rechazaron y por qué, para detectar errores o intentos no válidos.',
  ['Dado que se rechazó un aviso, cuando abro el historial de rechazos, entonces veo cuándo llegó y el motivo.',
   'Dado que un aviso fue aceptado, cuando abro el historial de rechazos, entonces no aparece.',
   'Dado que un aviso traía datos sensibles, cuando veo su registro, entonces esos datos no se muestran completos.'],
  ['Se registra resultado de validación, fecha, identificador técnico y motivo seguro: "Firma inválida", "Aviso repetido", "Intento no encontrado", "Monto no coincide", "Tipo de aviso no soportado".',
   'No se guardan secretos, datos de tarjeta ni datos personales innecesarios.',
   'El acceso queda restringido al administrador.'])

s('ADM-13', 'Ajustar montos sugeridos y mínimo', 'RF-D1a', 'should', 'E2', 'M', 'C',
  'Como administrador del sistema, quiero ajustar los montos sugeridos y el mínimo, para adaptarlos sin pedir un cambio al equipo técnico.',
  ['Dado que cambio uno o varios montos sugeridos y guardo la configuración, cuando un visitante prepara una donación, entonces ve las opciones actualizadas.',
   'Dado que cambio el mínimo y guardo la configuración, cuando un visitante captura un monto personalizado, entonces se aplica el nuevo mínimo.',
   'Dado que un monto sugerido es menor que el mínimo vigente, cuando guardo, entonces se rechaza la configuración.',
   'Dado que el mínimo es cero o negativo, cuando guardo, entonces se rechaza la configuración.'],
  ['Los montos viven en una configuración global editable por el administrador, no por campaña.',
   'Valores iniciales: los ocho importes de DON-08 y el mínimo de $50.',
   'La configuración no permite modificar el monto ni el estado de una donación ya creada.'])

# ---- Pagos y seguridad ----
s('PAY-01', 'Aceptar solo confirmaciones auténticas', 'RF-V3b', 'must', 'E2', 'M', 'A',
  'Como administrador del sistema, quiero que solo se acepten confirmaciones que vienen del proveedor, para que nadie pueda simular pagos.',
  ['Dado que llega una confirmación auténtica, cuando se valida, entonces se procesa.',
   'Dado que alguien que no es el proveedor envía una confirmación falsa o alterada, cuando llega, entonces se rechaza, no se crea ninguna donación y el rechazo queda visible para el administrador.',
   'Dado que un aviso real llega con el cuerpo alterado, cuando se valida, entonces se rechaza con motivo "Firma inválida".',
   'Dado que un aviso real se reenvía mucho después (fuera de la ventana de tolerancia), cuando llega, entonces se rechaza.',
   'Dado que un visitante vuelve a la página de agradecimiento sin confirmación auténtica, cuando se consulta el resultado, entonces no se crea una donación.'],
  ['La autenticidad se verifica con el encabezado `x-signature` de Mercado Pago: se arma el texto `id:{data.id};request-id:{x-request-id};ts:{ts};` y se compara su HMAC-SHA256 con la clave secreta de avisos contra el valor `v1`. La comparación no depende del orden de llegada.',
   'Se rechazan avisos con `ts` fuera de una ventana de 5 minutos.',
   'Aunque la firma sea válida, el estado del pago se confirma siempre con `GET /v1/payments/{id}`; el cuerpo del aviso no se usa como fuente del monto ni del estado.',
   'La clave secreta de avisos vive en una configuración protegida, nunca en el código ni en el repositorio.'])

s('PAY-02', 'Registrar la donación solo tras la confirmación', 'RF-D5', 'must', 'E1', 'L', 'A',
  'Como administrador del sistema, quiero que una donación se registre únicamente cuando el proveedor confirme el pago, para que las cifras sean confiables.',
  ['Dado que el proveedor confirma un pago válido, cuando se procesa, entonces existe una donación con monto, campaña, fecha, referencia, correo, visibilidad, solicitud de factura y aceptación del aviso de privacidad.',
   'Dado que el pago fue rechazado, cancelado o aún no está confirmado, cuando consulto el portal y el avance, entonces no hay donación ni suma.',
   'Dado que falla el registro después de recibir la confirmación, cuando termina el proceso, entonces no queda una donación incompleta.',
   'Dado que el monto confirmado por el proveedor no coincide con el del intento, cuando se procesa, entonces no se registra la donación y queda un rechazo con motivo "Monto no coincide".',
   'Dado que un visitante intenta crear una donación ya confirmada o cambiar el estado de una existente por cualquier vía, cuando lo intenta, entonces falla.'],
  ['El registro se ejecuta como una sola operación: se guardan todos los datos o ninguno.',
   'El monto registrado es `transaction_amount` del pago confirmado, no un valor enviado por el navegador.',
   'Los datos del formulario se recuperan del intento (PAY-07) mediante `external_reference`.',
   'El usuario invitado no puede editar registros después de crearlos: la escritura de la donación la hace código de servidor sin reglas de compartición, solo después de validar el pago con el proveedor.'])

s('PAY-03', 'Evitar donaciones duplicadas', 'RF-V3b', 'must', 'E2', 'S', 'A',
  'Como administrador del sistema, quiero que una misma confirmación no genere donaciones repetidas, para que el avance y las constancias no se dupliquen.',
  ['Dado que el proveedor envía dos veces la misma confirmación, cuando se procesan, entonces existe una sola donación y su monto cuenta una vez.',
   'Dado que la página de retorno y el aviso automático registran el mismo pago casi al mismo tiempo, cuando terminan, entonces existe una sola donación.',
   'Dado que una confirmación ya se procesó, cuando vuelve a llegar, entonces no se envía una segunda constancia.'],
  ['El identificador de pago del proveedor tiene restricción de unicidad (ADM-07); un segundo intento de inserción se trata como "ya procesado", no como error.',
   'El procesamiento es idempotente: repetir el mismo evento no crea ni modifica la donación.'])

s('PAY-06', 'Recibir la confirmación del proveedor', 'RF-V3a, RF-D5', 'must', 'E2', 'L', 'A',
  'Como administrador del sistema, quiero que el aviso de pago del proveedor llegue al sistema y registre la donación sin que nadie intervenga, para que las donaciones se actualicen solas.',
  ['Dado que un donante pagó con una tarjeta de prueba, cuando el proveedor envía su aviso de pago, entonces el aviso llega al sistema y la donación se registra sin intervención de nadie.',
   'Dado que el proveedor rechaza el pago, cuando se procesa el aviso, entonces no se crea ninguna donación.',
   'Dado que llega un aviso de un pago reembolsado o con contracargo, cuando se procesa, entonces se registra y se ignora (fuera de alcance), sin cambiar ninguna donación.',
   'Dado que llega un aviso cuya referencia no corresponde a ningún intento, cuando se procesa, entonces no cambia nada y se rechaza con motivo "Intento no encontrado".',
   'Dado que falla la recepción del aviso, cuando reviso, entonces no hay una donación a medias ni marcada como confirmada.',
   'Dado que llegan varios avisos a la vez, cuando se procesan, entonces todos se procesan bien.'],
  ['Entrada pública REST expuesta por el sitio, con permisos mínimos; la acción privilegiada ocurre solo después de validar el aviso (PAY-01).',
   'Solo se procesan avisos de tipo `payment`; los demás se registran como "Tipo de aviso no soportado".',
   'Responde 200 a avisos aceptados, repetidos e ignorados, y 400 a firma inválida, para que el proveedor no reintente sin fin.',
   'Sin consultas ni escrituras dentro de ciclos.'])

s('PAY-07', 'Guardar el intento de pago', 'RF-D3', 'must', 'E1', 'M', 'A',
  'Como administrador del sistema, quiero que cada pago iniciado quede ligado a los datos que capturó el donante, para poder registrar la donación correcta cuando el proveedor la confirme.',
  ['Dado que un donante continúa al pago, cuando se abre el pago, entonces existe un intento con campaña, monto, correo, visibilidad, nombre público y datos de factura.',
   'Dado que el proveedor confirma el pago, cuando se registra la donación, entonces sus datos son los del intento.',
   'Dado que existe un intento, cuando consulto el portal, el avance, el reconocimiento o el listado de donaciones, entonces el intento no aparece.',
   'Dado que un intento no se confirmó en 7 días, cuando pasa ese plazo, entonces se borra junto con sus datos personales.',
   'Dado que soy visitante, cuando intento leer o modificar un intento, el mío o el de otra persona, entonces no puedo.'],
  ['Objeto propio, separado de la donación. Su Id viaja al proveedor como `external_reference`.',
   'El intento lo crea código de servidor que valida todo de nuevo (campaña elegible, monto, RFC); el visitante no tiene permisos sobre el objeto.',
   'Los registros creados por el invitado se asignan a un usuario interno como dueño por defecto.',
   'Un proceso programado diario borra los intentos no confirmados con más de 7 días.',
   'Cuando entre DON-13 (E2), el intento también guarda la aceptación del aviso de privacidad.'])

s('SEG-01', 'Probar que un visitante no ve datos ajenos', 'RF-V2', 'must', 'E1', 'M', 'C',
  'Como administrador del sistema, quiero evidencia repetible de que un visitante sin sesión no puede ver ni modificar donaciones de otras personas, para proteger a los donantes.',
  ['Dado que existen donaciones e intentos de otras personas, cuando un visitante sin sesión intenta leerlos por el portal o por cualquiera de las vías listadas en los criterios técnicos, entonces no obtiene ningún dato.',
   'Dado que existen donaciones de otras personas, cuando intenta modificarlas o crear una ya confirmada, entonces el intento falla.',
   'Dado el documento de seguridad, cuando otra persona (B) sigue sus pasos, entonces obtiene el mismo resultado.',
   'Dado que el visitante intenta ver correos o datos fiscales, cuando prueba por cualquier vía, entonces no obtiene nada.'],
  ['Vías mínimas a probar: (1) navegar el portal; (2) llamar las acciones del sitio (Aura y Apex) desde la consola del navegador o Postman con el Id real de una donación; (3) API REST y consultas de Salesforce sin sesión; (4) búsqueda global del sitio; (5) rutas internas escritas a mano (`/s/donation/<id>`, perfiles, detalle de registro); (6) parámetros alterados en la página de agradecimiento (DON-21).',
   'El usuario invitado no tiene el permiso "API habilitada" ni permisos sobre donaciones ni intentos.',
   'Los métodos públicos del sitio solo devuelven agregados por campaña y, del reconocimiento, nombre y monto.',
   'Cada paso de docs/seguridad.md lleva precondición, acción exacta, resultado esperado, resultado obtenido y evidencia.',
   'Se documentan los permisos del visitante y por qué cada uno es necesario, y la clasificación de cada dato personal.'])

# ------------------------------- LÓGICA ---------------------------------
def run(cmd, inp=None):
    r = subprocess.run(cmd, input=inp, text=True, capture_output=True,
                       encoding="utf-8", errors="replace")
    if r.returncode:
        raise RuntimeError(r.stderr.strip() or r.stdout.strip())
    return r.stdout.strip()

def body(st):
    out = [f"**RF covered:** {st['rf']}", "", "## Story", "", st['story'], "",
           "## Acceptance criteria (Given / When / Then)", ""]
    out += [f"- [ ] **AC{i}.** {a}" for i, a in enumerate(st['acs'], 1)]
    out += ["", "## Technical tasks (TAC)", ""]
    out += [f"- [ ] {t}" for t in st['tacs']]
    out += ["", "## Evidence", "", PENDING]
    return "\n".join(out)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", choices=["E1", "E2"], help="crear solo un hito")
    ap.add_argument("--fix", action="store_true",
                    help="reescribe título y cuerpo de las issues ya creadas (arregla acentos)")
    a = ap.parse_args()

    existing, ms_titles, collabs = {}, {}, set()
    if not a.dry_run:
        for name, color in LABELS.items():  # si ya existe (como las tuyas), no se toca
            try:
                run(["gh", "label", "create", name, "--color", color, "-R", REPO])
            except RuntimeError:
                pass
        titles = run(["gh", "api", f"repos/{REPO}/milestones?state=all", "--paginate",
                      "--jq", ".[].title"]).splitlines()
        for k, (prefix, due) in MILESTONES.items():
            found = next((t for t in titles if t.startswith(k)), None)
            if not found:
                run(["gh", "api", f"repos/{REPO}/milestones", "-f", f"title={prefix}",
                     "-f", f"due_on={due}T23:59:59Z"])
                found = prefix
            ms_titles[k] = found
        collabs = set(run(["gh", "api", f"repos/{REPO}/collaborators", "--paginate",
                           "--jq", ".[].login"]).splitlines())
        for i in json.loads(run(["gh", "issue", "list", "-R", REPO, "--state", "all",
                                 "--limit", "300", "--json", "number,title,url"])):
            existing[i["title"].split("_")[0].strip()] = i["url"]
        for k, u in USERS.items():
            if u and u not in collabs:
                print(f"AVISO: {u} (frente {k}) no es colaborador del repo: no se le asignará. "
                      f"Invítalo en Settings > Collaborators y que acepte la invitación.")

    urls = dict(existing)
    for st in S:
        if a.only and st['hito'] != a.only:
            continue
        title = f"{st['id']}_{st['title']}"
        if st['id'] in existing:
            if a.fix and st['id'] != "DON-01":
                run(["gh", "issue", "edit", existing[st['id']], "-R", REPO,
                     "--title", title, "--body-file", "-"], inp=body(st))
                print(f"~ {title} corregida")
                time.sleep(1)
            else:
                print(f"= {title} ya existe, se omite")
            continue
        if a.dry_run:
            print(f"+ {title} [{st['hito']}] {st['prio']} frente-{st['resp']}")
            continue
        cmd = ["gh", "issue", "create", "-R", REPO, "--title", title, "--body-file", "-",
               "--label", st['prio']]
        if st['hito']:
            cmd += ["--milestone", ms_titles[st['hito']]]
        user = USERS.get(st['resp'])
        if user and user in collabs:
            cmd += ["--assignee", user]
        url = run(cmd, inp=body(st)).splitlines()[-1]
        urls[st['id']] = url
        print(f"+ {title} -> {url}")
        if PROJECT_NUMBER:
            try:
                run(["gh", "project", "item-add", PROJECT_NUMBER, "--owner", OWNER, "--url", url])
            except RuntimeError as e:
                print(f"  (no se añadió al Project: {e})")
        time.sleep(1.5)  # evita límites de ritmo de GitHub

    if not a.dry_run:
        os.makedirs("docs", exist_ok=True)
        with open("docs/tablero.md", "w", encoding="utf-8") as f:
            f.write("# Tablero de historias\n\n| ID | RF | Hito | Historia | AC | Estado | Evidencia |\n"
                    "|---|---|---|---|---|---|---|\n")
            for st in S:
                u = urls.get(st['id'], "")
                link = f"[{st['title']}]({u})" if u else st['title']
                f.write(f"| {st['id']} | {st['rf']} | {st['hito'] or 'Sin fecha'} | {link} | "
                        f"{len(st['acs'])} | Backlog | Pendiente |\n")
        print("Escrito docs/tablero.md (enlázalo desde el README)")

if __name__ == "__main__":
    main()
