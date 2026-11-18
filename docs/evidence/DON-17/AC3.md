# DON-17 — Evidencia del AC3

**Historia:** [DON-17 — Corregir datos inválidos](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/13)  
**Criterio:** AC3  
**Workstream:** B — Portal público y objetos Salesforce

## Criterio de aceptación

> **AC3.** Dado que ocurre un error interno, cuando intento continuar, entonces no veo mensajes técnicos ni datos internos.

## Resultado

La implementación de DON-17 en el workspace traduce los errores inesperados del servidor a mensajes genéricos en español y evita mostrar al donante detalles internos de Apex, de la plataforma o información personal.

Los errores de validación que sí son seguros para el donante conservan su mensaje y pueden asociarse al campo correspondiente. Los errores que no pertenecen a un campo se muestran como un aviso general. Si el error no tiene el formato esperado, el formulario muestra el mensaje genérico en lugar de exponer su contenido.

**Estado de la evidencia:** AC3 está respaldado por pruebas automatizadas de LWC y Apex. No se realizó una prueba manual en navegador y no se desplegaron estos cambios a la Sandbox.

## Evidencia de implementación

### 1. Manejo seguro en el formulario

En `force-app/main/default/lwc/donationForm/donationForm.js`, el formulario interpreta los errores recibidos del servidor mediante el manejo de errores de DON-17. Los mensajes con formato reconocido se procesan como errores de validación; los errores inesperados o con una estructura ajena se sustituyen por un mensaje genérico en español.

El formulario no debe mostrar directamente excepciones, stack traces, nombres internos de clases, respuestas técnicas ni datos personales incluidos en un error.

**Archivo relacionado:** `force-app/main/default/lwc/donationForm/donationForm.js`

### 2. Manejo seguro en Apex

En `force-app/main/default/classes/DonationIntakeService.cls`, los errores inesperados se traducen a mensajes seguros antes de regresar al componente. Los mensajes de validación que son aptos para el donante se conservan; los errores técnicos o inesperados no se presentan directamente.

No se agregó un mecanismo nuevo de logging ni se incorporó información personal a mensajes de depuración. El registro persistente y seguro de errores queda fuera de esta implementación y debe tratarse como una decisión técnica separada.

**Archivo relacionado:** `force-app/main/default/classes/DonationIntakeService.cls`

## Evidencia de pruebas automatizadas

### Pruebas LWC — Jest

Ejecución reportada: `npm run test:unit`.

- **Resultado:** 7 suites y 155 pruebas aprobadas; 0 fallos.
- Las pruebas de DON-17 comprueban que errores técnicos de Apex, errores de plataforma, errores con datos personales en el mensaje y errores con una estructura no reconocida no se exponen al donante.
- También se comprueba que un fallo al abrir el pago (`openPayment`) muestra un mensaje amigable y no revela el detalle técnico.

**Archivo de pruebas:** `force-app/main/default/lwc/donationForm/__tests__/donationForm.test.js`

### Pruebas Apex — check-only

Ejecución reportada contra la Sandbox, sin despliegue:

| Dato | Resultado |
|---|---|
| Deployment ID | `0AfVC00000PHuXF0A1` |
| Estado | `Succeeded` |
| `checkOnly` | `true` |
| Componentes validados | 2 de 2 |
| Pruebas `DonationIntakeServiceTest` | 58 de 58 aprobadas |
| Cobertura de `DonationIntakeService` | 167 de 167 líneas (100%) |
| Errores | 0 |

Entre las pruebas nuevas se incluye un caso en el que Apex recibe una excepción cuyo mensaje contiene un correo, un RFC y el nombre de una clase. La prueba verifica que esos datos no lleguen al mensaje mostrado al donante. También se prueban errores sin campo, mensajes vacíos o predeterminados y mensajes provenientes de Workstream A.

**Archivo de pruebas:** `force-app/main/default/classes/DonationIntakeServiceTest.cls`

**Nota:** el check-only valida los componentes y las pruebas indicadas; no despliega los cambios ni demuestra por sí solo el comportamiento visual del portal.

## Evidencia visual pendiente

No se realizó una prueba manual del portal en navegador porque los cambios todavía no se han desplegado. Por tanto, no se adjunta una captura de pantalla ni se afirma que se haya verificado visualmente en la Sandbox.

Si se decide agregar una demostración manual posteriormente, debe hacerse en un entorno de prueba y con datos ficticios. La captura debe mostrar únicamente el mensaje amigable que recibe el donante; no debe incluir consola, stack trace, correos, RFC, nombres reales ni credenciales.

## Conclusión

**AC3 está respaldado por la implementación y las pruebas automatizadas ejecutadas en el workspace:** los errores internos se traducen a mensajes seguros y las pruebas verifican que no se filtren detalles técnicos ni datos personales.

La verificación manual en navegador permanece pendiente. Los cambios no se han desplegado, no se ha realizado commit ni push y no se modificaron registros de Salesforce.
