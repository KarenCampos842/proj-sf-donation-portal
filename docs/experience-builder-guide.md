# Guía de Experience Builder: montar el portal público (Workstream B)

Para: administrador de Salesforce del equipo. Sandbox: `donations-dev`. Alcance: historias DON-01, DON-02, DON-03, DON-04, DON-08, DON-10, DON-11 y DON-12 (E1).

> **Estado a la fecha de esta guía (2026-11-10).** El sitio **"Mexico Dreamin Donation Portal"** (Build Your Own LWR, prefijo `portal`) existe en `donations-dev`, el código del portal está desplegado, el sitio está publicado y se probó con el usuario invitado real. URL: `https://uady--class2026b.sandbox.my.site.com/portal/`. Las secciones 1 a 4 describen cómo se configuró, para repetirlo o auditarlo; la sección 7 registra lo verificado y lo que sigue pendiente.

> **Pagos.** El formulario ya no usa el gateway simulado: `DonationIntakeService.DonationPaymentGateway` delega en `DonationPaymentController` de Workstream A (flows `Payment_Attempt_Create` y `Payment_Preference_Create`) con la credencial de **prueba** de Mercado Pago. El cobro con tarjeta de prueba lo completa una persona en el checkout de Mercado Pago (sección 7).

## 0. Qué se despliega

Todo está en `force-app/main/default/`:

| Tipo | Componentes |
|---|---|
| Apex (producción, B) | `CampaignPortalController`, `DonorRecognitionService`, `DonationIntakeService`, `CampaignDTO`, `DonorRecognitionDTO` |
| Apex (Workstream A, ya existente) | `DonationPaymentController` (`startDonation`, `openPayment`, `getPaymentResult`), `MercadoPagoPreferenceAction`, `MercadoPagoPaymentLookupAction` |
| Apex (pruebas) | `CampaignPortalControllerTest`, `DonorRecognitionServiceTest`, `DonationIntakeServiceTest`, `PortalTestDataFactory` |
| LWC | `donationPortal` (contenedor), `campaignList`, `campaignDetail`, `campaignProgress`, `donorRecognitionList`, `donationForm`, `donationThankYou` (página de retorno de Mercado Pago) |
| LWC de apoyo | `portalMessages`, `portalUtils`, `portalDemoData`, `portalTheme`, `donationFormMessages`, `donationFormRules`, `donationThankYouMessages` |
| Etiqueta personalizada | `Donation_Return_Url` = `https://uady--class2026b.sandbox.my.site.com/portal/gracias` |
| Seguridad (metadatos) | `profiles/Mexico Dreamin Donation Portal Profile`, `sharingRules/Fundraising_Campaign__c`, `permissionsets/Mercado_Pago_Callout` |
| Sitio (metadatos) | `digitalExperiences`, `digitalExperienceConfigs`, `networks`, `sites` |

Los objetos y campos de D1 ya están desplegados en `donations-dev`.

Comandos (desde la raíz del repositorio). El primero **no guarda nada** en el org; el segundo despliega y requiere autorización explícita:

```bash
# 1) Validación (check-only)
sf project deploy start --dry-run --source-dir force-app/main/default/classes --source-dir force-app/main/default/lwc --source-dir force-app/main/default/labels --test-level RunSpecifiedTests --tests CampaignPortalControllerTest --tests DonorRecognitionServiceTest --tests DonationIntakeServiceTest --tests DonationPaymentControllerTest --tests MercadoPagoPreferenceActionTest --tests MercadoPagoPaymentLookupActionTest --target-org donations-dev-vibes --wait 30

# 2) Despliegue real (solo con autorización)
sf project deploy start --source-dir force-app/main/default/classes --source-dir force-app/main/default/lwc --source-dir force-app/main/default/labels --test-level RunSpecifiedTests --tests CampaignPortalControllerTest --tests DonorRecognitionServiceTest --tests DonationIntakeServiceTest --tests DonationPaymentControllerTest --tests MercadoPagoPreferenceActionTest --tests MercadoPagoPaymentLookupActionTest --target-org donations-dev-vibes --wait 30
```

Notas de la máquina de desarrollo (Windows):

- La CLI sale con código 1 aunque el resultado sea correcto (`status: 0`). Revisa siempre el campo `status` del JSON o el detalle en *Setup > Deployment Status*.
- `sf data query` y los argumentos con espacios (por ejemplo `--name "Mexico Dreamin Donation Portal"` en `sf community publish`) fallan con un error de ruta de Windows. Para consultas se usó `sf api request rest`, y la publicación se hizo con la API Connect (`POST /services/data/v68.0/connect/communities/<networkId>/publish`).

## 1. Crear el sitio LWR

El sandbox ya tiene un sitio heredado, **"Donaciones"**, con prefijo `donaciones` (Aura, de 2019, con componentes de NPSP y PayPal). No lo reutilices ni uses ese prefijo.

**Desde la interfaz**

1. *Setup > Digital Experiences > All Sites > New*.
2. Plantilla: **Build Your Own (LWR)**.
3. Nombre: `Mexico Dreamin Donation Portal`. Prefijo de URL: `portal` (solo caracteres alfanuméricos).
4. Espera a que termine la creación (es asíncrona). El primer sitio LWR de un org tarda más porque inicializa servicios.

**Desde la CLI (equivalente)**

```bash
sf community create --name "Mexico Dreamin Donation Portal" --template-name "Build Your Own (LWR)" --url-path-prefix portal --target-org donations-dev-vibes
```

Si el comando no existe en tu versión de la CLI, crea el sitio desde la interfaz.

**Ya creado.** El sitio existe en `donations-dev` (no lo vuelvas a crear; duplicaría la red y el usuario invitado). Nombres técnicos reales:

| Elemento | Valor |
|---|---|
| `DigitalExperienceConfig` / bundle | `Mexico_Dreamin_Donation_Portal1` (`site/Mexico_Dreamin_Donation_Portal1`), `urlPathPrefix` = `portal` |
| `Network` | `Mexico Dreamin Donation Portal` (su `urlPathPrefix` técnico `portalvforcesite` lo asigna Salesforce y no es la URL del sitio LWR) |
| `CustomSite` | `Mexico_Dreamin_Donation_Portal` |
| Página principal | `Home` (ruta `/`), con `c:donationPortal` |
| Página de retorno de pago | `Gracias` (ruta `/gracias`), con `c:donationThankYou` |
| Idioma del sitio | Español (`es-MX`) |
| URL | `https://uady--class2026b.sandbox.my.site.com/portal/` |

**Recuperar el sitio al repositorio** (recomendado, para tenerlo versionado). Ejecuta cada comando por separado; los tipos van separados por espacios, sin comillas ni comas:

```bash
sf project retrieve start --metadata DigitalExperienceBundle DigitalExperienceConfig Network CustomSite --target-org donations-dev
```

**Configuración básica en Builder** (*Workspaces > Builder*)

- *Settings > Languages*: idioma predeterminado **Español (México)**. Los mensajes de los componentes base (validaciones, fechas) dependen de esto.
- Anota la URL de vista previa del sitio; se usa en la sección 6.

## 2. Permisos del usuario invitado (Guest User)

Principio: **mínimo privilegio**. El invitado solo lee campos públicos de campañas y ejecuta las clases Apex del portal. No tiene acceso a `Donation__c` ni a `Payment_Attempt__c` y no tiene *API Enabled* (`docs/security.md`, sección 2; `docs/data-model.md`, sección 6.2).

### 2.1 Encontrar el perfil y el usuario invitado

- *Builder > Settings > General*: enlace al **perfil del usuario invitado** (Guest User Profile). Los pasos 2.2 a 2.4 se hacen en ese perfil. Aquí: **Mexico Dreamin Donation Portal Profile** (licencia Guest User License).
- El **usuario invitado** (para zona horaria y regla de compartición) se localiza en *Setup > Sites* > tu sitio > *Public Access Settings* > *View Users*. Aquí: `Mexico Dreamin Donation Portal Site Guest User`, `CommunityNickname` = `Mexico_Dreamin_Donation_Portal`, zona horaria `America/Merida`, idioma y configuración regional `es_MX`.

### 2.2 Permisos de objeto y de campo (FLS)

En el perfil invitado, *Object Settings*:

| Objeto | Acceso |
|---|---|
| `Fundraising_Campaign__c` | **Read** solamente |
| `Donation__c` | Ninguno |
| `Payment_Attempt__c` | Ninguno |
| `Rejected_Notice__c` (D2) | Ninguno |

Acceso de lectura a campo (FLS) en `Fundraising_Campaign__c`, y **solo estos 14 campos** (el modelo, sección 6.2, los define como públicos):

`Name`, `Description__c`, `Goal__c`, `Start_Date__c`, `End_Date__c`, `Status__c`, `Is_General__c`, `Image_URL__c`, `Image_Alt_Text__c`, `Total_Raised__c`, `Donation_Count__c`, `Progress_Percent__c`, `Accepts_Donations__c`, `Is_Publicly_Visible__c`.

Todos de solo lectura. Sin FLS, las consultas del portal fallan con "No pudimos cargar las campañas".

Estado real (`profiles/Mexico Dreamin Donation Portal Profile.profile-meta.xml`): FLS de lectura explícito en 11 campos. `Name`, `Goal__c` y `Start_Date__c` no aparecen porque son obligatorios y Salesforce siempre los hace legibles. `Donation__c` y `Payment_Attempt__c` no tienen ningún permiso de objeto ni de campo en este perfil.

### 2.3 Acceso a clases Apex

En el perfil invitado, *Enabled Apex Class Access*, habilita **solo** las clases que el sitio invoca desde el navegador:

| Clase | Quién la invoca |
|---|---|
| `CampaignPortalController` | `campaignList`, `campaignDetail` |
| `DonorRecognitionService` | `donorRecognitionList` |
| `DonationIntakeService` | `donationForm` (`startDonation`, `openPayment`) |
| `DonationPaymentController` (A) | `donationThankYou` (`getPaymentResult`) |

`DonationIntakeService` llama a `DonationPaymentController` desde Apex; esa llamada interna no necesita el permiso, pero `donationThankYou` la invoca directamente. `MercadoPagoPreferenceAction`, `MercadoPagoPaymentLookupAction`, los DTO y las clases de prueba **no** se conceden.

Además, el permission set **`Mercado_Pago_Callout`** (acceso al principal `MercadoPago-MercadoPagoTest` y lectura de `UserExternalCredential`, sin permisos sobre objetos del proyecto) está asignado al usuario invitado. Sin él, el callout a Mercado Pago falla.

### 2.4 Lo que debe quedar apagado

- *System Permissions > API Enabled*: **desmarcado**.
- Sin acceso a objetos estándar que no use el portal.
- Registros creados desde el sitio pertenecen a un usuario interno por omisión (`TEC-01`); lo configura Workstream A.

### 2.5 Regla de compartición del invitado

`Fundraising_Campaign__c` ya tiene modelo de compartición externo **Private**, por lo que el invitado no ve ninguna campaña hasta que exista esta regla.

*Setup > Sharing Settings > Fundraising_Campaign__c Sharing Rules > Guest User Access, Based on Criteria > New*:

| Campo | Valor |
|---|---|
| Criterio | `Status__c` **igual a** `Active`, `Paused`, `Closed` |
| Compartido con | El usuario invitado del sitio |
| Acceso | **Read Only** |

`Draft` debe quedar **excluido**. Las reglas de invitado solo conceden lectura y no pueden usar campos fórmula, por eso se filtra por estado. Las fechas las valida el servidor (`CampaignPortalController`), no la regla.

Qué cubre cada estado hoy:

- **Active y Paused**: son obligatorios; sin ellos el catálogo queda vacío.
- **Closed**: DON-02 exige abrir el detalle de campañas cerradas por enlace directo. La regla real ya incluye `Closed`. El código conserva todavía el **workaround temporal** (`CampaignPortalController.ClosedCampaignReader`, `without sharing` y limitado a campañas `Closed`); con la regla activa ya no es indispensable y se puede borrar en un cambio posterior. Funciona con o sin la regla.
- Riesgo ya aceptado en el modelo: una campaña `Active` con fecha de inicio futura queda compartida con el invitado aunque el portal no la muestra. Es dato de campaña, no de donantes.

**Regla real** (`force-app/main/default/sharingRules/Fundraising_Campaign__c.sharingRules-meta.xml`, regla `Campanas_Publicas_Invitado`, `guestUser` = `Mexico_Dreamin_Donation_Portal`, acceso `Read`, `includeHVUOwnedRecords` = `false`). El criterio está guardado con las **etiquetas** del picklist en español: `Status__c` igual a `Cerrada,Activa,Pausada`. Eso es lo que devolvió la org al recuperarla y funciona: en `Fundraising_Campaign__Share` hay filas con causa `GuestRule` y acceso `Read` para las campañas Active, Paused y Closed, y ninguna para las campañas Draft. Si recreas la regla desde la interfaz, elige los tres estados; no uses la forma `Active,Paused,Closed` en metadatos sin comprobar el resultado con una consulta a `Fundraising_Campaign__Share`.

### 2.6 Zona horaria del invitado (V-01)

`TODAY()` y `Date.today()` usan la zona horaria del usuario invitado. Edita ese usuario (*Setup > Sites > Public Access Settings > View Users > Edit*) y fija **America/Merida** (la que usa hoy el usuario invitado). Sin esto, entre las 18:00 y las 24:00 hora de Mérida una campaña que inicia mañana podría mostrarse hoy.

### 2.7 Imágenes de campañas (CSP)

`Image_URL__c` apunta a servidores externos. *Setup > Security > CSP Trusted Sites > New*: URL del servidor de imágenes (`https://…`), contexto **Experience Builder Sites** (LWR), directiva **img-src**. Sin esto las imágenes se bloquean y las tarjetas muestran la imagen neutral. El portal solo acepta URLs `https`.

## 3. Montar `donationPortal` en la página principal

1. *Workspaces > Builder*.
2. Menú *Pages* (arriba) > **Home**.
3. Quita el contenido de ejemplo de la página. Conserva el encabezado y el pie que da la plantilla.
4. Abre el panel *Components* y busca **Portal de donaciones** (categoría de componentes personalizados).
5. Arrástralo a una sección de **una sola columna a ancho completo**.
6. En el panel de propiedades, **Nombre API de la página** debe ser el nombre API de la página donde lo pusiste (por omisión `Home`). Si es otra, el cambio de vista no funcionará.
7. *Save* y abre la vista previa.

Reglas:

- **Arrastra únicamente `donationPortal`.** Los demás componentes los monta él. `donationForm` también aparece en el panel, pero necesita un `campaignId` y no debe usarse solo.
- El portal vive en **una sola página**. Las vistas cambian por la URL, sin recargar:

| URL | Vista |
|---|---|
| `/portal/` | Catálogo de campañas |
| `/portal/?campana=<Id>` | Detalle (también para campañas cerradas) |
| `/portal/?campana=<Id>&donar=1` | Formulario de donación de esa campaña |

- Los botones Atrás y Adelante del navegador recorren esas vistas.
- Un Id inválido o inexistente en `?campana=` muestra "No encontramos esta campaña…" con un botón para volver al catálogo.
- El **modo de demostración** del reconocimiento (datos ficticios) existe en los componentes pero **no está expuesto** en Builder ni en la URL. No intentes activarlo en el sitio público.

## 4. Tema y colores (`--dxp-*`)

Los componentes leen estas variables, con un valor de respaldo en `portalTheme.css`, así que funcionan aunque la variable no exista:

| Variable | Respaldo | Se usa para |
|---|---|---|
| `--dxp-g-brand` | `#0b5cab` | Acento: barra de avance, monto recaudado, píldoras seleccionadas, enlaces |
| `--dxp-g-brand-contrast` | `#ffffff` | Texto sobre el acento |
| `--dxp-g-root` | `#ffffff` | Fondo del contenido y de las tarjetas |
| `--dxp-g-root-contrast` | `#1b1f23` | Texto principal |

Los colores de estado (Activa, Pausada, Cerrada), los bordes y los grises son fijos por diseño y no cambian con el tema.

Cómo cambiarlos:

1. En Builder, abre **Theme** (icono de pincel) y la sección de colores.
2. Ajusta el color de marca (*Brand*) y los colores base de fondo y texto. Esos valores del conjunto de marca (*branding set*) alimentan las variables `--dxp-g-*`.
3. Guarda y recarga la vista previa.

Cómo comprobarlo (los nombres exactos de las variables dependen de la versión de la plantilla): abre las herramientas de desarrollo del navegador, selecciona el elemento `html` y busca `--dxp-g-brand` en *Computed / Styles*. Si el nombre no existe, la barra de avance seguirá con el azul de respaldo y habrá que ajustar el nombre de la variable en `portalTheme.css`.

Recomendaciones:

- Contraste mínimo **4.5:1** entre el color de marca y su color de contraste (texto de botones y píldoras).
- Un color de marca muy claro hará ilegible el texto blanco. Revisa también el estado enfocado con el teclado.
- Alternativa versionada: edita el contenido `sfdc_cms__brandingSet` del sitio recuperado (`digitalExperiences/site/<sitio>/sfdc_cms__brandingSet/`), siguiendo los patrones de colores y contraste de la plantilla.

## 5. Revisión visual y de accesibilidad

Resultado de la revisión del 2026-11-10 sobre el sitio publicado, como visitante sin sesión, con Microsoft Edge automatizado (Playwright) y emulación de móvil de 360 px:

- [x] Sin desplazamiento horizontal a 360 px en el catálogo, en el detalle de todos los estados y en el formulario con los datos fiscales abiertos (0 px de desbordamiento en cada caso).
- [x] Teclado: el orden de foco es enlace "Skip to Main" y luego cada tarjeta; Enter sobre la tarjeta enfocada abre el detalle.
- [x] El foco se ve en las tarjetas: contorno de 2 px en el color de acento (comprobado en captura).
- [x] Con *Reducir movimiento* activado, los componentes del portal no tienen animaciones ni transiciones propias. Solo queda la transición de 0,1 s del enlace "Skip to Main" que aporta la plantilla.
- [x] Los estados Activa, Pausada, Cerrada y Finalizada se distinguen por texto (insignia y mensaje), no solo por color.
- [x] Contraste calculado sobre los colores de `portalTheme.css` (WCAG): texto principal 16,6:1, texto atenuado 8,0:1, acento sobre blanco 6,7:1, insignias entre 7,5:1 y 10,3:1, relleno de la barra sobre su pista 5,4:1. Todos superan 4,5:1 (texto) y 3:1 (elementos no textuales).
- [ ] Pendiente: píldoras de monto y botones con teclado en el formulario (solo se probó el foco en tarjetas), y lector de pantalla (la barra de avance anuncia el porcentaje real, por ejemplo "120% de la meta"). No se probó con un lector de pantalla.

## 6. Pruebas funcionales en el sandbox

Se hicieron el 2026-11-10 sobre el sitio publicado (`https://uady--class2026b.sandbox.my.site.com/portal/`), como **visitante sin sesión** (contexto nuevo del navegador, sin cookies) y llamando a los métodos Apex como usuario invitado. Las campañas de prueba llevan el prefijo `[PRUEBA]`; las campañas `(demo)` y sus donaciones las creó el equipo antes y no se tocaron. No se crearon donaciones ni se hicieron cargos.

| # | Escenario | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| 1 | Entrar a `/portal/` sin sesión | Tarjetas de campañas activas vigentes y pausadas; sin borradores ni cerradas | Aprobado: 5 activas y 2 pausadas; no aparecen las campañas Draft, Closed, futura ni finalizada |
| 2 | Sin campañas disponibles | Mensaje exacto "No hay campañas disponibles por ahora" | No se probó en vivo (habría que ocultar las campañas); cubierto por pruebas Jest y Apex |
| 3 | Abrir el detalle desde una tarjeta | URL `?campana=<Id>`, sin recarga completa; botón "Volver a las campañas" | Aprobado: la URL cambia sin recargar el documento |
| 4 | Botones Atrás y Adelante | Recorren catálogo, detalle y formulario | Aprobado: formulario → detalle → catálogo con Atrás, y de regreso con Adelante, sin recarga |
| 5 | Campaña pausada | Insignia "Pausada", sin botón "Donar" activo | Aprobado: insignia "Pausada", mensaje y botón "Donaciones en pausa" |
| 6 | Campaña cerrada por enlace directo | Detalle visible, informativo; "Donaciones cerradas" | Aprobado |
| 7 | Campaña `Active` con fecha de cierre vencida | Insignia "Campaña finalizada" y el texto acordado | Aprobado: insignia, texto "Esta campaña ha finalizado su periodo de recaudación y ya no acepta donaciones." y botón "Donaciones cerradas" |
| 8 | Borrador y activa futura por enlace directo | "No encontramos esta campaña…" | Aprobado en ambos |
| 9 | `?campana=abc` y un Id válido inexistente | Mensaje centralizado y regreso al catálogo | Aprobado en ambos, con el botón "Ver campañas disponibles" |
| 10 | Avance con meta superada | Porcentaje real mayor a 100 %, barra llena, campaña sigue activa | No se probó en vivo (ninguna campaña supera su meta); cubierto por pruebas Jest y Apex (50 %, 100 % y 120 %) |
| 11 | Reconocimiento | Solo nombre y monto de donaciones `Confirmed` y `Public`, más reciente primero | Aprobado en lo visible: la campaña demo con donantes públicos devuelve solo `publicName` y `amount`; una campaña Draft devuelve lista vacía. El orden y los filtros por estado y visibilidad se verificaron con pruebas Apex |
| 12 | Formulario anónimo | Solo correo; `Visibility = Anonymous` | Aprobado: 8 montos exactos, ninguno preseleccionado, anónimo por defecto; sin monto aparece "Elige un monto para continuar." |
| 13 | Formulario público | Pide nombre público (máx. 80) | Aprobado: el campo aparece al desactivar el anonimato, `maxlength` = 80 y solo espacios se rechaza con "Escribe el nombre con el que quieres aparecer." |
| 14 | Factura + anónimo | Pide datos fiscales y sigue anónimo | Aprobado en la interfaz: aparecen nombre o razón social, RFC, código postal y régimen sin salir del modo anónimo; no aparece "CFDI". El envío completo con factura no se ejecutó en vivo |
| 15 | RFC `GODE561331GR8` (mes 13) | Rechazado: "El RFC no tiene un formato válido." | Aprobado en el navegador y en el servidor |

Pruebas adicionales como invitado:

- **RFC y régimen:** el RFC se normaliza a mayúsculas y sin espacios; con 13 caracteres muestra "Física" y ofrece 13 regímenes, con 12 muestra "Moral" y ofrece 8. Coincide con el catálogo del modelo. Código postal `1234` se rechaza con "El código postal debe tener 5 dígitos."
- **Servidor (`DonationIntakeService.startDonation`):** monto 75, correo inválido, `Public` sin nombre y RFC con mes 13 se rechazan con mensajes en español. Una campaña Paused, Closed, Draft o `Active` finalizada responde "Esta campaña ya no acepta donaciones." En ningún caso se creó un intento.
- **Página `/gracias`:** `payment_id=999999999999&status=approved` muestra "Aún no podemos confirmar tu pago." (no confía en `status`); `payment_id=null` o sin parámetros muestra "No se completó el pago; no se registró tu donación."
- **Datos privados (SEG-01):** sin sesión, `.../portal/services/data/v68.0/sobjects/Donation__c`, `.../query` y `.../sobjects/Payment_Attempt__c` responden 404, y `/services/data/...` en el dominio del sitio responde 401. El perfil invitado no tiene permisos de objeto sobre `Donation__c` ni `Payment_Attempt__c` y `API Enabled` está apagado. El perfil invitado solo tiene acceso a las 4 clases de la sección 2.3 (consulta a `SetupEntityAccess`). Ninguna respuesta pública incluyó correo, RFC ni datos fiscales.
- **Intentos de pago de prueba:** se crearon dos intentos con el correo `prueba.portal@example.com` (uno por llamada directa a Apex y otro desde el formulario), ambos para la campaña `[PRUEBA] Campaña activa vigente`. Mercado Pago devolvió una preferencia en cada uno. No se pagaron ni se cobró nada. Quedan en la org; el flow `Payment_Attempt_Delete_Stale` de Workstream A está pensado para limpiar intentos antiguos.

Pruebas de seguridad del visitante (SEG-01, `docs/security.md`, sección 1): los resultados anteriores son los datos reales para llenar esa tabla. La repetición por una segunda persona sigue pendiente.

## 7. Qué ya se verificó y qué no

**Verificado:**

- **Despliegue real a `donations-dev`:** ID `0AfVC00000PBhkn0AD`, `Succeeded`, 31 de 31 componentes y 137 de 137 pruebas Apex (CampaignPortalControllerTest, DonorRecognitionServiceTest, DonationIntakeServiceTest, DonationPaymentControllerTest, MercadoPagoPreferenceActionTest, MercadoPagoPaymentLookupActionTest). Antes se validó en modo `--dry-run` (`0AfVC00000PBhZV0A1`) con el mismo resultado.
- **Cobertura Apex (líneas):** `DonationIntakeService` 161/161, `CampaignPortalController` 89/89, `DonorRecognitionService` 22/22, `DonorRecognitionDTO` 3/3. `DonationPaymentController`, de Workstream A, queda en 52/56.
- **Jest:** 136 pruebas aprobadas en 7 suites; 97,2 % de cobertura de líneas en los LWC.
- **Code Analyzer:** sin hallazgos de severidad 1 o 2 en el código; 8 avisos moderados en producción (complejidad ciclomática, parámetros booleanos, lista de parámetros y `requestAnimationFrame` del contador) y el resto en pruebas. El motor `flow` no arrancó porque falta Python en la máquina de desarrollo.
- **Sitio publicado:** trabajo de publicación `08PVC00000fpkW22AI` completado sin error. Navegación del contenedor en una plantilla LWR real: `comm__namedPage` con `state` actualiza la URL sin recarga y `CurrentPageReference` entrega `campana` y `donar`.
- **Invitado real:** FLS, acceso a clases Apex, regla de compartición (filas `GuestRule` para Active, Paused y Closed, ninguna para Draft) y `API Enabled` apagado, comprobados contra la org y con llamadas anónimas al sitio.
- **Pagos (parte de B):** el formulario crea el intento y la preferencia con la credencial de prueba de Mercado Pago a través de `DonationPaymentController` y redirige a `https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=…`.

**Pendiente:**

- **Prueba manual del pago con Mercado Pago.** Falta la cuenta *Comprador de prueba* de la aplicación del proyecto. Con ella hay que completar el checkout con la Mastercard de prueba y los titulares `APRO`, `OTHE` y `CONT` (y opcionalmente `FUND`, `SECU`, `EXPI`) y confirmar: regreso a `/portal/gracias`, estado mostrado, donación registrada una sola vez en el aprobado y ninguna donación en el rechazado. El checkout abierto con un navegador automatizado mostró "Hubo un error accediendo a esta página", así que esa prueba debe hacerse a mano. No guardes datos de tarjeta en el repositorio.
- Los nombres reales de las variables `--dxp-g-*` y su efecto en el tema no se comprobaron; el portal usa los valores de respaldo de `portalTheme.css`.
- Lector de pantalla y teclado dentro del formulario (sección 5).
- Escenarios 2 y 10 en vivo (cubiertos por pruebas automáticas) y envío completo con factura.

## 8. Antes de abrir el sitio a más personas

- [x] Workstream A fusionó su PR #47 y el formulario usa `DonationPaymentController` (el gateway simulado ya no existe).
- [x] Etiqueta personalizada `Donation_Return_Url` con la URL real de la página de gracias.
- [x] Permisos del invitado revisados contra la sección 2.
- [x] Sitio publicado en el sandbox.
- [ ] Prueba de extremo a extremo con la cuenta Comprador de prueba (sección 7).
- [ ] Tabla SEG-01 de `docs/security.md` completada y repetida por una segunda persona.
- [ ] Sin datos de personas reales en el sandbox. Las campañas `[PRUEBA]` y los dos intentos de prueba son datos de prueba identificables.
- [ ] Decidir si se elimina el `ClosedCampaignReader` (`without sharing`), que con la regla de compartición actual ya no es indispensable (sección 2.5).

Para volver a publicar tras cambios en Builder: *Builder > Publish*, o la API Connect descrita en la sección 0. Un sitio publicado es accesible desde Internet, aun en un sandbox.

## 9. Problemas frecuentes

| Síntoma | Causa probable |
|---|---|
| Página en blanco | El componente no está en el sitio, o el sitio no entrega `CurrentPageReference` (revisa que esté en una página del sitio y no en otra plantilla) |
| "No pudimos cargar las campañas" | Falta FLS o acceso a clases Apex del invitado (2.2, 2.3), o no hay regla de compartición (2.5) |
| Catálogo vacío con campañas activas | Falta la regla de compartición para el invitado, o las fechas no cumplen (inicio futuro, cierre vencido) |
| Al elegir una campaña la página no cambia | **Nombre API de la página** no coincide con la página real (3, paso 6) |
| Detalle de campaña cerrada dice "No encontramos…" | Falta FLS de lectura en `Fundraising_Campaign__c` para el invitado (2.2) |
| Imágenes no cargan | Falta el sitio de confianza CSP (2.7) o la URL no es `https` |
| Fechas con un día de diferencia | Zona horaria del usuario invitado (2.6) |
| El formulario redirige a `example.com` | Es el gateway simulado antiguo; el código actual usa `DonationPaymentGateway` (sección 0). Si lo ves, el código desplegado es una versión vieja |
