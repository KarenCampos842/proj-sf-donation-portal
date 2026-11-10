# Guía de Experience Builder: montar el portal público (Workstream B)

Para: administrador de Salesforce del equipo. Sandbox: `donations-dev`. Alcance: historias DON-01, DON-02, DON-03, DON-04, DON-08, DON-10, DON-11 y DON-12 (E1).

> **Estado a la fecha de esta guía.** Nada de lo descrito aquí se ha ejecutado en el sandbox: el sitio no existe, el código del portal no está desplegado y no se ha probado con un usuario invitado real. Cada paso indica qué debes verificar. Lo que sí se probó está en la sección 7.

> **No publiques el sitio todavía.** El formulario usa un *gateway simulado* (`DonationIntakeService.MockPaymentGateway`): devuelve un Id temporal y una URL de `example.com`, no guarda nada y no cobra. Hasta que se conecte el código de Workstream A (sección 8) nadie puede pagar de verdad.

## 0. Qué se despliega

Todo está en `force-app/main/default/`:

| Tipo | Componentes |
|---|---|
| Apex (producción) | `CampaignPortalController`, `DonorRecognitionService`, `DonationIntakeService`, `CampaignDTO`, `DonorRecognitionDTO` |
| Apex (pruebas) | `CampaignPortalControllerTest`, `DonorRecognitionServiceTest`, `DonationIntakeServiceTest`, `PortalTestDataFactory` |
| LWC | `donationPortal` (contenedor), `campaignList`, `campaignDetail`, `campaignProgress`, `donorRecognitionList`, `donationForm` |
| LWC de apoyo | `portalMessages`, `portalUtils`, `portalDemoData`, `portalTheme`, `donationFormMessages`, `donationFormRules` |

Los objetos y campos de D1 ya están desplegados en `donations-dev`.

Comandos (desde la raíz del repositorio). El primero **no guarda nada** en el org; el segundo despliega y requiere autorización explícita:

```bash
# 1) Validación (check-only)
sf project deploy start --dry-run --source-dir force-app/main/default/lwc --source-dir force-app/main/default/classes --test-level RunSpecifiedTests --tests DonationIntakeServiceTest --tests CampaignPortalControllerTest --tests DonorRecognitionServiceTest --target-org donations-dev --wait 30

# 2) Despliegue real (solo con autorización)
sf project deploy start --source-dir force-app/main/default/lwc --source-dir force-app/main/default/classes --test-level RunSpecifiedTests --tests DonationIntakeServiceTest --tests CampaignPortalControllerTest --tests DonorRecognitionServiceTest --target-org donations-dev --wait 30
```

Nota: en la máquina de desarrollo la CLI sale con código 1 aunque el resultado sea correcto (`status: 0`). Revisa siempre el campo `status` del JSON o el detalle en *Setup > Deployment Status*.

## 1. Crear el sitio LWR

El sandbox ya tiene un sitio heredado, **"Donaciones"**, con prefijo `donaciones` (Aura, de 2019, con componentes de NPSP y PayPal). No lo reutilices ni uses ese prefijo.

**Desde la interfaz**

1. *Setup > Digital Experiences > All Sites > New*.
2. Plantilla: **Build Your Own (LWR)**.
3. Nombre: `Portal de Donaciones`. Prefijo de URL: `portal` (solo caracteres alfanuméricos).
4. Espera a que termine la creación (es asíncrona). El primer sitio LWR de un org tarda más porque inicializa servicios.

**Desde la CLI (equivalente)**

```bash
sf community create --name "Portal de Donaciones" --template-name "Build Your Own (LWR)" --url-path-prefix portal --target-org donations-dev
```

Si el comando no existe en tu versión de la CLI, crea el sitio desde la interfaz.

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

- *Builder > Settings > General*: enlace al **perfil del usuario invitado** (Guest User Profile). Los pasos 2.2 a 2.4 se hacen en ese perfil.
- El **usuario invitado** (para zona horaria y regla de compartición) se localiza en *Setup > Sites* > tu sitio > *Public Access Settings* > *View Users*.

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

### 2.3 Acceso a clases Apex

En el perfil invitado, *Enabled Apex Class Access*, habilita **solo**:

- `CampaignPortalController`
- `DonorRecognitionService`
- `DonationIntakeService`

Cuando se conecte Workstream A, A pide además `DonationPaymentController` y el permission set `Mercado_Pago_Callout` para el invitado (`docs/payments-api.md` en la rama de A). Confirma con A cómo asignarlo a un usuario invitado en tu org antes de hacerlo.

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
- **Closed**: DON-02 exige abrir el detalle de campañas cerradas por enlace directo. Mientras la regla no incluya `Closed`, el código usa un **workaround temporal** (`CampaignPortalController.ClosedCampaignReader`, `without sharing` y limitado a campañas `Closed`). Cuando agregues `Closed` a la regla, ese lector se puede borrar. Funciona con o sin la regla.
- Riesgo ya aceptado en el modelo: una campaña `Active` con fecha de inicio futura queda compartida con el invitado aunque el portal no la muestra. Es dato de campaña, no de donantes.

Equivalente en metadatos (referencia; **no se generó el archivo en el repo**, porque requiere el `CommunityNickname` del usuario invitado y cambiar compartición necesita autorización):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<SharingRules xmlns="http://soap.sforce.com/2006/04/metadata">
    <sharingGuestRules>
        <fullName>Campanas_Publicas_Invitado</fullName>
        <accessLevel>Read</accessLevel>
        <includeHVUOwnedRecords>false</includeHVUOwnedRecords>
        <label>Campañas públicas para el invitado</label>
        <sharedTo>
            <guestUser>[CommunityNickname del usuario invitado]</guestUser>
        </sharedTo>
        <criteriaItems>
            <field>Status__c</field>
            <operation>equals</operation>
            <value>Active,Paused,Closed</value>
        </criteriaItems>
    </sharingGuestRules>
</SharingRules>
```

Archivo destino: `force-app/main/default/sharingRules/Fundraising_Campaign__c.sharingRules-meta.xml` (un solo archivo por objeto; si ya existe, recupéralo primero y agrega la regla).

### 2.6 Zona horaria del invitado (V-01)

`TODAY()` y `Date.today()` usan la zona horaria del usuario invitado. Edita ese usuario (*Setup > Sites > Public Access Settings > View Users > Edit*) y fija **America/Mexico_City**. Sin esto, entre las 18:00 y las 24:00 hora de Mérida una campaña que inicia mañana podría mostrarse hoy.

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

## 5. Revisión visual y de accesibilidad (manual, pendiente)

En vista previa, con el tamaño de ventana en **360 px** de ancho:

- [ ] Sin desplazamiento horizontal en catálogo, detalle y formulario.
- [ ] Todo se opera con teclado (Tab, Shift+Tab, Enter, Espacio, flechas en los montos).
- [ ] El foco se ve en tarjetas, píldoras y botones.
- [ ] Con *Reducir movimiento* activado en el sistema operativo no hay animación de la barra ni del contador.
- [ ] Los estados Activa, Pausada, Cerrada y Finalizada se distinguen por texto, no solo por color.
- [ ] Lector de pantalla: la barra de avance anuncia el porcentaje real (por ejemplo "120% de la meta").

## 6. Pruebas funcionales en el sandbox

Prepara datos con campañas de prueba (el script opcional de datos aún no existe; créalas a mano o pídelo). No insertes donaciones falsas.

| # | Escenario | Resultado esperado |
|---|---|---|
| 1 | Entrar a `/portal/` sin sesión | Tarjetas de campañas activas vigentes y pausadas; sin borradores ni cerradas |
| 2 | Sin campañas disponibles | Mensaje exacto "No hay campañas disponibles por ahora" |
| 3 | Abrir el detalle desde una tarjeta | URL `?campana=<Id>`, sin recarga completa; botón "Volver a las campañas" |
| 4 | Botones Atrás y Adelante | Recorren catálogo, detalle y formulario |
| 5 | Campaña pausada | Insignia "Pausada", sin botón "Donar" activo |
| 6 | Campaña cerrada por enlace directo | Detalle visible, informativo; "Donaciones cerradas" |
| 7 | Campaña `Active` con fecha de cierre vencida | Insignia "Campaña finalizada" y el texto acordado |
| 8 | Borrador y activa futura por enlace directo | "No encontramos esta campaña…" |
| 9 | `?campana=abc` | Mensaje centralizado y regreso al catálogo |
| 10 | Avance con meta superada | Porcentaje real mayor a 100 %, barra llena, campaña sigue activa |
| 11 | Reconocimiento | Solo nombre y monto de donaciones `Confirmed` y `Public`, más reciente primero |
| 12 | Formulario anónimo | Solo correo; `Visibility = Anonymous` |
| 13 | Formulario público | Pide nombre público (máx. 80) |
| 14 | Factura + anónimo | Pide datos fiscales y sigue anónimo |
| 15 | RFC `GODE561331GR8` (mes 13) | Rechazado: "El RFC no tiene un formato válido." |

Pruebas de seguridad del visitante (SEG-01, `docs/security.md`, sección 1): sin sesión, intentar leer `Donation__c` y `Payment_Attempt__c` por URL directa, REST y búsqueda global debe fallar, y los datos de correo o fiscales no deben aparecer en ninguna respuesta. Registra los resultados reales en esa tabla; no los llenes por adelantado.

## 7. Qué ya se verificó y qué no

**Verificado (en el repositorio y con validación check-only, sin guardar nada en el org):**

- Compilación de las clases y componentes en `donations-dev` y pruebas Apex aprobadas.
- Pruebas Jest de todos los componentes, incluida la navegación del contenedor con un enrutador simulado.
- Que el contenedor solo cambia de vista por el estado de la URL.

**No verificado todavía (requiere el sitio):**

- Que `comm__namedPage` con `state` actualice la URL sin recarga completa en una plantilla LWR real. El código está aislado en `donationPortal.navigateTo` por si hay que ajustar el tipo de página de navegación.
- Que `CurrentPageReference` entregue `campana` y `donar` desde el query string.
- Los nombres reales de las variables `--dxp-g-*` y su efecto visual.
- Acceso real del usuario invitado: FLS, clases Apex y regla de compartición (las pruebas Apex usan un usuario `Minimum Access` como simulación, que no equivale a un invitado).
- Que `window.location.assign` lleve al pago en un sitio publicado.
- Diseño desde 360 px, contraste y teclado (sección 5).

## 8. Antes de publicar

- [ ] Workstream A fusionó su PR #47 y confirmó el contrato de `DonationPaymentController`.
- [ ] El `MockPaymentGateway` se reemplazó por un gateway que usa el código de A, y la prueba de extremo a extremo con tarjetas de prueba de Mercado Pago pasó.
- [ ] Etiqueta personalizada `Donation_Return_Url` con la URL real de la página de gracias.
- [ ] Permisos del invitado revisados contra la sección 2 y registrados en `docs/security.md`.
- [ ] Tabla SEG-01 completada con resultados reales y repetida por una segunda persona.
- [ ] Sin datos reales de personas en el sandbox.
- [ ] Autorización explícita para publicar.

Para publicar: *Builder > Publish*. Un sitio publicado es accesible desde Internet, aun en un sandbox.

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
| El formulario redirige a `example.com` | Es el gateway simulado (sección 8) |
