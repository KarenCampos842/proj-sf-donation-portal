# DON-12 — Evidencia del AC8

**Criterio de aceptación**

> **AC8.** Dado que completé una donación con factura, cuando se revisa el sistema, entonces no existe ninguna factura ni comprobante fiscal generado por el sistema.

## Resultado

La implementación de la primera etapa respalda que el portal **recibe y conserva los datos fiscales de una solicitud de factura, pero no emite facturas ni CFDI**. El formulario lo comunica expresamente al donante. El código de servidor valida y transmite los datos fiscales al proceso que crea el intento de pago; no contiene una operación de generación de factura.

**Alcance de esta evidencia:** demuestra el comportamiento diseñado e implementado en el repositorio. La auditoría de solo lectura de Salesforce compartida para este proyecto identificó la donación `DON-000014` como una donación del portal con factura solicitada. Sin embargo, esa auditoría no documentó una inspección de sus archivos relacionados ni de todos los posibles registros/documentos fiscales. Por eso, para afirmar que en ese registro concreto no existe ningún archivo adjunto o comprobante, hace falta la comprobación visual indicada al final.

## Evidencia de implementación

### 1. El portal informa explícitamente que no emite facturas

En `donationFormMessages.js`, el bloque `invoice` muestra el texto:

> “Solo guardamos estos datos para atender tu solicitud; el portal no emite facturas.”

También aclara que el RFC solo se revisa por formato y que no se consulta con el SAT.

Fuente: [donationFormMessages.js, bloque invoice](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/donationFormMessages/donationFormMessages.js#L28-L43)

### 2. El servicio valida y prepara los datos fiscales; no genera un documento

`DonationIntakeService.applyInvoiceData()` normaliza el nombre, el RFC, el código postal y el régimen fiscal; comprueba que estén presentes y que tengan formato válido; después los copia al DTO limpio. En este método no se crea un CFDI, PDF, XML ni registro de factura.

Fuente: [DonationIntakeService.cls, applyInvoiceData y validaciones](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeService.cls#L269-L305)

El DTO incluye `invoiceRequested`, `legalName`, `rfc`, `taxPostalCode` y `taxRegime`. La clase delega esos valores a `DonationPaymentController`; no invoca un servicio de facturación ni una integración con el SAT/PAC.

Fuentes:
- [DonationIntakeService.cls, DTO fiscal](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeService.cls#L112-L132) y [delegación de esos campos al controlador](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeService.cls#L337-L352)
- [DonationPaymentController.cls, mapeo de datos y creación del intento](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationPaymentController.cls#L51-L79)

### 3. El modelo de datos almacena la solicitud y los datos fiscales, no una factura emitida

El modelo define en `Payment_Attempt__c` y `Donation__c` campos como:

- `Invoice_Requested__c`
- `Legal_Name__c`
- `RFC__c`
- `Tax_Postal_Code__c`
- `Tax_Regime__c`

En la clasificación de datos personales, el documento especifica que el nombre fiscal, RFC, código postal y régimen se guardan para atender una factura **emitida fuera del sistema**. También indica que el uso de CFDI no se recopila.

Fuentes:
- [data-model.md, campos fiscales de Donation__c](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/data-model.md#L138-L166)
- [data-model.md, clasificación y propósito de los datos fiscales](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/data-model.md#L257-L272)

### 4. La API de pagos trata esos datos como información de la solicitud

El contrato de `startDonation(request)` define `invoiceRequested` y los datos fiscales como campos de entrada. La operación documentada guarda el intento de pago; no describe ni ejecuta la emisión de un comprobante fiscal.

Fuente: [payments-api.md, contrato del formulario](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/payments-api.md#L18-L39)

### 5. Una constancia de donación no equivale a un CFDI

El modelo separa la posible constancia por correo (`Receipt_Sent__c`, planeada para D2/DON-23) de la solicitud de factura y de los datos fiscales. La automatización descrita para esa constancia es un correo de recibo; no se describe como emisión de CFDI.

Fuente: [data-model.md, automatizaciones](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/data-model.md#L303-L318)

## Evidencia del registro de Salesforce

La auditoría de solo lectura compartida en esta conversación reportó que `DON-000014` es una de las donaciones creadas desde el portal y que tiene `Invoice_Requested__c = true`. Esto permite identificar un caso concreto al que aplicar el AC8.

**Limitación:** el reporte no aportó una captura ni el resultado de una consulta de `ContentDocumentLink`, `Attachment` u otros posibles registros/archivos relacionados con `DON-000014`. Por tanto, no debe presentarse esa auditoría por sí sola como prueba de que el registro no tiene ningún documento relacionado.

## Comprobación final recomendada para cerrar el AC8

En Salesforce, abrir `DON-000014` y revisar sus pestañas o listas relacionadas **Files**, **Notes & Attachments** y cualquier objeto de facturación disponible. Guardar una captura donde se vea:

1. El registro `DON-000014` y `Invoice_Requested__c = true`.
2. La sección de archivos/documentos relacionados sin factura, XML, PDF o CFDI generado.
3. Que no existe un registro de factura asociado, si el org tiene un objeto de facturación instalado.

No crear ni adjuntar un documento para producir esta evidencia. Si no hay módulo u objeto de facturación, anotarlo expresamente en la captura o en la evidencia de la revisión.

## Conclusión para el AC8

- **Respaldado por código y documentación:** el portal guarda los datos fiscales de la solicitud y declara que no emite facturas; la lógica inspeccionada valida y transmite datos, no genera CFDI.
- **Caso concreto identificado:** `DON-000014`, donación del portal con factura solicitada, según la auditoría de solo lectura compartida.
- **Pendiente para evidencia de aceptación completa:** documentar visualmente que `DON-000014` no tiene factura ni comprobante fiscal relacionado en el org.

Con la evidencia actual, el AC8 está **respaldado a nivel de implementación**, pero la ausencia de un documento asociado a ese registro concreto aún requiere la captura de revisión en Salesforce.
