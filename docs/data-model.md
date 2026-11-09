# Data Model — Mexico Dreamin Donation Portal

**Owner:** Alan Pérez (workstream C) · **Version:** draft 1 · 2026-11-08
**Sources:** backlog v2, project guide, Q&A session, and the client's answers on Slack (Maliachi, 2026-11-04).

This document is the single reference for objects, fields and API names. Any new field or rename is proposed here before it is created in the org.

**Conventions**
- API names in English, capitalized words joined by underscores: `Start_Date__c`.
- Labels (what users see) in Spanish: "Fecha de inicio". The portal and the internal UI are in Spanish.
- Picklist values: English API name (`Anonymous`), Spanish label ("Anónima"). Formulas and code always use the API name.
- Validation error messages in Spanish, because users see them.
- Currency: MXN, `Currency(16, 2)`.
- **Milestone:** D1 = Delivery 1, D2 = Delivery 2.

---

## 1. Overview

```
Fundraising_Campaign__c 1 ──< N Donation__c         (master-detail: total via roll-up summary)
Fundraising_Campaign__c 1 ──< N Payment_Attempt__c  (lookup: an attempt is NOT a donation)
Rejected_Notice__c                                   (standalone, D2)
Donation_Amount_Setting__mdt                         (custom metadata, D2)
```

| Object | Label (UI) | What it stores | Workstream | Milestone |
|---|---|---|---|---|
| `Fundraising_Campaign__c` | Campaña | Campaigns, goal and progress | C (management), B (portal) | D1 |
| `Payment_Attempt__c` | Intento de pago | What the donor entered before paying (PAY-07) | A, B | D1 |
| `Donation__c` | Donación | A donation whose payment the provider has confirmed | A (creates), C (reads) | D1 |
| `Rejected_Notice__c` | Aviso rechazado | Provider notices that were rejected (ADM-12, RF-S4) | A | D2 |
| `Donation_Amount_Setting__mdt` | Configuración de montos | Suggested amounts and minimum (ADM-13) | B | D2 |

A custom campaign object is used instead of the standard `Campaign` (decision D-02). The relationship fields on the child objects are named `Campaign__c` (relationship name `Campaign__r`).

---

## 2. `Fundraising_Campaign__c` — Campaña

| Label (UI) | API name | Type | Notes | Milestone |
|---|---|---|---|---|
| Nombre de la campaña | `Name` | Text(80) | Required | D1 |
| Descripción | `Description__c` | Long Text Area(5000) | Required to activate | D1 |
| Meta | `Goal__c` | Currency(16, 2) | Required, > 0. Field history enabled (GES-09) | D1 |
| Fecha de inicio | `Start_Date__c` | Date | Required | D1 |
| Fecha de cierre | `End_Date__c` | Date | Optional. Blank = stays open | D1 |
| Estado | `Status__c` | Picklist (restricted) | `Draft` (default) "Borrador", `Active` "Activa", `Paused` "Pausada", `Closed` "Cerrada" | D1 |
| Campaña general | `Is_General__c` | Checkbox | Always-open campaign for general donations, requested by the client | D1 |
| URL de la imagen | `Image_URL__c` | URL | Decision D-03 | D1 |
| Texto alternativo de la imagen | `Image_Alt_Text__c` | Text(255) | Accessibility | D1 |
| Total recaudado | `Total_Raised__c` | Roll-Up Summary (SUM `Donation__c.Amount__c`) | Only confirmed donations exist, so no filter is needed | D1 |
| Número de donaciones | `Donation_Count__c` | Roll-Up Summary (COUNT `Donation__c`) | GES-15 | D1 |
| Porcentaje de avance | `Progress_Percent__c` | Formula (Percent) | `Total_Raised__c / Goal__c`. Not capped at 100% | D1 |
| Acepta donaciones | `Accepts_Donations__c` | Formula (Checkbox) | Checked on the server before a payment is opened | D1 |
| Visible en el portal | `Is_Publicly_Visible__c` | Formula (Checkbox) | Used by the portal to list campaigns | D1 |
| Causa de cierre | `Close_Reason__c` | Picklist | `By_Date` "Por fecha", `Manual` "Manual" | D2 |

**Formulas**

```
Accepts_Donations__c =
AND(
  ISPICKVAL(Status__c, "Active"),
  Start_Date__c <= TODAY(),
  OR(ISBLANK(End_Date__c), End_Date__c >= TODAY())
)

Is_Publicly_Visible__c =
AND(
  OR(ISPICKVAL(Status__c, "Active"), ISPICKVAL(Status__c, "Paused")),
  Start_Date__c <= TODAY()
)
```

**Validation rules**

| Rule | Error condition | Message (UI) | Story |
|---|---|---|---|
| `Goal_Must_Be_Positive` | `Goal__c <= 0` | "La meta debe ser mayor a cero." | GES-03 |
| `End_Date_After_Start` | `NOT(ISBLANK(End_Date__c)) && End_Date__c < Start_Date__c` | "La fecha de cierre no puede ser anterior a la de inicio." | GES-03, GES-09 |
| `Activation_Requires_Description` | `ISPICKVAL(Status__c, "Active") && ISBLANK(Description__c)` | "Agrega una descripción antes de activar la campaña." | GES-06 |
| `General_Campaign_Always_Open` | `Is_General__c && (NOT(ISBLANK(End_Date__c)) \|\| ISPICKVAL(Status__c, "Closed"))` | "La campaña general no lleva fecha de cierre ni se puede cerrar." | General campaign |

(In the tables, `\|\|` is Markdown escaping; in Salesforce it is written `||`.)

**Other settings**
- No project role can delete campaigns: with master-detail, deleting a campaign would delete its donations (GES-03).
- When `Image_URL__c` is blank, the portal shows a neutral image (DON-01).
- The general campaign can be paused but never closed. It has a reference goal like any other campaign, because progress is total ÷ goal.

---

## 3. `Payment_Attempt__c` — Intento de pago (PAY-07)

Created before the payment opens, from the form. It is not a donation: it does not count toward progress, is never public and never appears in donation lists. Its Id is sent to the provider as `external_reference`.

| Label (UI) | API name | Type | Notes | Milestone |
|---|---|---|---|---|
| Folio | `Name` | Auto Number `ATT-{000000}` | | D1 |
| Campaña | `Campaign__c` | Lookup(`Fundraising_Campaign__c`) | Required | D1 |
| Monto | `Amount__c` | Currency(16, 2) | Minimum $50 MXN | D1 |
| Correo | `Email__c` | Email | Always required. The Email type validates the format (DON-10) | D1 |
| Visibilidad | `Visibility__c` | Picklist | `Anonymous` "Anónima", `Public` "Pública" | D1 |
| Nombre público | `Public_Name__c` | Text(80) | Required if `Public` (see section 7, minimization) | D1 |
| Solicita factura | `Invoice_Requested__c` | Checkbox | Independent from visibility | D1 |
| Nombre o razón social | `Legal_Name__c` | Text(254) | Required with invoice | D1 |
| RFC | `RFC__c` | Text(13) | Required with invoice. Normalized by a before-save flow (section 10); the form also removes spaces so the value fits in 13 characters | D1 |
| Tipo de persona | `Taxpayer_Type__c` | Formula (Text) | `IF(LEN(RFC__c) = 12, "Moral", IF(LEN(RFC__c) = 13, "Física", ""))` | D1 |
| Código postal fiscal | `Tax_Postal_Code__c` | Text(5) | Required with invoice | D1 |
| Régimen fiscal | `Tax_Regime__c` | Picklist | SAT catalog c_RegimenFiscal codes (appendix) | D1 |
| Acepta aviso de privacidad | `Privacy_Notice_Accepted__c` | Checkbox | DON-13 | D2 |
| Fecha de aceptación | `Privacy_Notice_Accepted_At__c` | Date/Time | DON-13 | D2 |
| Estado | `Status__c` | Picklist | `Started` (default), `Confirmed`, `Rejected`, `Cancelled`. Owned by workstream A | D1 |
| Id de preferencia | `Preference_Id__c` | Text(64) | Returned by the provider when the payment is created. Owned by workstream A | D1 |

**Validation rules** (they also run when records are inserted by automation, so they act as server-side validation)

| Rule | Error condition | Message (UI) | Story |
|---|---|---|---|
| `Minimum_Amount` | `Amount__c < 50` | "El monto mínimo es de $50 MXN." | DON-08, DON-09 |
| `Public_Name_Required` | `ISPICKVAL(Visibility__c, "Public") && ISBLANK(Public_Name__c)` | "Escribe el nombre con el que quieres aparecer." | DON-11 |
| `Invoice_Data_Required` | `Invoice_Requested__c && (ISBLANK(Legal_Name__c) \|\| ISBLANK(RFC__c) \|\| ISBLANK(Tax_Postal_Code__c) \|\| ISPICKVAL(Tax_Regime__c, ""))` | "Para pedir factura faltan datos fiscales." | DON-12 |
| `RFC_Format` | see below | "El RFC no tiene un formato válido." | DON-12 |
| `Tax_Postal_Code_Format` | `Invoice_Requested__c && NOT(REGEX(Tax_Postal_Code__c, "^[0-9]{5}$"))` | "El código postal debe tener 5 dígitos." | DON-12 |

```
RFC_Format:
Invoice_Requested__c && NOT(REGEX(RFC__c, "^[A-ZÑ&]{3,4}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$"))
```

The pattern was tested against the backlog examples: it accepts `GODE561231GR8` and `ABC010203XY1`, and rejects `GODE561331GR8` (month 13), 11- and 14-character values, letters in the date and special characters. It checks structure, not calendar validity (February 30 passes), which meets the guide's criterion (RF-F1 CA2).

In D2, the `50` in `Minimum_Amount` is replaced by `$CustomMetadata.Donation_Amount_Setting__mdt.Default.Minimum_Amount__c` so the administrator can change it (ADM-13).

**Retention:** attempts older than 7 days are deleted by a scheduled flow (PAY-07, decision D-01).

---

## 4. `Donation__c` — Donación

Created only by the payment confirmation process (workstream A), after the provider confirms the payment. It copies the attempt's data. No project role can edit the amount, the payment status or the payment reference.

| Label (UI) | API name | Type | Written by | Milestone |
|---|---|---|---|---|
| Folio | `Name` | Auto Number `DON-{000000}` | System | D1 |
| Campaña | `Campaign__c` | Master-Detail(`Fundraising_Campaign__c`) | Confirmation process | D1 |
| Monto | `Amount__c` | Currency(16, 2) | Confirmation process: the amount confirmed by the provider (`transaction_amount`) | D1 |
| Estado del pago | `Payment_Status__c` | Picklist | `Confirmed` "Confirmado" (default); a picklist so more states can be added later | D1 |
| Fecha de confirmación | `Confirmed_At__c` | Date/Time | Confirmation process (`date_approved`) | D1 |
| Id de pago del proveedor | `Provider_Payment_Id__c` | Text(64), Unique, External ID | Confirmation process. Traceability (ADM-07) and duplicate prevention (PAY-03) | D1 |
| Id del intento | `Attempt_Id__c` | Text(18) | Confirmation process (`external_reference`). Kept after the attempt is deleted | D1 |
| Correo | `Email__c` | Email | Confirmation process | D1 |
| Visibilidad | `Visibility__c` | Picklist | Confirmation process; the moderator can change Public → Anonymous (client, Slack 2026-11-04) | D1 |
| Nombre público | `Public_Name__c` | Text(80) | Confirmation process; the moderator can correct it. Field history enabled in D1 (the field setting is part of the D1 metadata; the moderation feature that uses it, MOD-03, is D2) | D1 |
| Modalidad | `Modality__c` | Formula (Text) | See below (RF-S2) | D1 |
| Solicita factura | `Invoice_Requested__c` | Checkbox | Confirmation process | D1 |
| Nombre o razón social | `Legal_Name__c` | Text(254) | Confirmation process | D1 |
| RFC | `RFC__c` | Text(13) | Confirmation process | D1 |
| Tipo de persona | `Taxpayer_Type__c` | Formula (Text) | Same formula as on the attempt | D1 |
| Código postal fiscal | `Tax_Postal_Code__c` | Text(5) | Confirmation process | D1 |
| Régimen fiscal | `Tax_Regime__c` | Picklist | Confirmation process | D1 |
| Acepta aviso de privacidad | `Privacy_Notice_Accepted__c` | Checkbox | Confirmation process | D2 |
| Fecha de aceptación | `Privacy_Notice_Accepted_At__c` | Date/Time | Confirmation process | D2 |
| Origen de la confirmación | `Confirmation_Source__c` | Picklist | `Return_Page` "Página de retorno", `Webhook` "Aviso automático" (RF-S4 CA1) | D2 |
| Constancia enviada | `Receipt_Sent__c` | Checkbox | Prevents sending a second receipt (DON-23) | D2 |

```
Modality__c =
IF(ISPICKVAL(Visibility__c, "Anonymous"), "Anónima", "Con nombre")
& IF(Invoice_Requested__c, " + factura", "")
```

**Master-detail sharing setting:** "Read Only". Read access to the campaign is then enough to edit a donation, provided the user has the object permission. The moderator can correct names without edit access to campaigns.

**Validation rules**

| Rule | Error condition | Message (UI) | Story |
|---|---|---|---|
| `Public_Name_Required` | `ISPICKVAL(Visibility__c, "Public") && ISBLANK(Public_Name__c)` | "Una donación pública necesita nombre." | MOD-03 |
| `Anonymous_Cannot_Become_Public` | `ISCHANGED(Visibility__c) && ISPICKVAL(PRIORVALUE(Visibility__c), "Anonymous")` | "Una donación anónima no se puede hacer pública." | RF-D2, MOD-03 |

Both rules belong to D2 (MOD-03, RF-D2) and are not part of the D1 metadata. The history tracking on `Public_Name__c` (see the field table above) is the only MOD-03-related element delivered in D1.

`Anonymous_Cannot_Become_Public` protects the donor's choice: a moderator can hide a name but can never expose an anonymous donor (RF-D2 CA1).

**List views for staff (D1)**
- "Todas las donaciones": folio, campaign, amount, modality, status, date, email (RF-S2, ADM-03).
- "Solicitan factura": filter `Invoice_Requested__c = true`, showing legal name, RFC, postal code and regime (RF-F2, ADM-05).

---

## 5. Delivery 2 objects

**`Rejected_Notice__c`** "Aviso rechazado" (ADM-12, RF-S4). Owned by workstream A; fields may change.

| Label (UI) | API name | Type |
|---|---|---|
| Folio | `Name` | Auto Number `REJ-{000000}` |
| Fecha de recepción | `Received_At__c` | Date/Time |
| Motivo | `Reason__c` | Picklist: `Invalid_Signature`, `Duplicate_Notice`, `Attempt_Not_Found`, `Amount_Mismatch`, `Unsupported_Type` |
| Id técnico | `Technical_Id__c` | Text(64) |
| Detalle | `Detail__c` | Text(255). Never stores secrets, card data or personal data |

**`Donation_Amount_Setting__mdt`** (ADM-13), with one record named `Default`:

| Label (UI) | API name | Type |
|---|---|---|
| Montos sugeridos | `Suggested_Amounts__c` | Text(255): `100,250,500,1000,2000,5000,10000,20000` |
| Monto mínimo | `Minimum_Amount__c` | Number(16, 2): `50` |

In D1 the suggested amounts are fixed in the portal (DON-08).

---

## 6. Access

### 6.1 Internal roles (permission sets)

Three roles, as defined by the client: campaign manager, moderator and system administrator.

| | `Campaign_Manager` | `Moderator` | `Donation_Admin` |
|---|---|---|---|
| `Fundraising_Campaign__c` | Read, create, edit (no delete) | Read | Read |
| `Donation__c` | Read | Read, edit | Read |
| Editable `Donation__c` fields | None | `Public_Name__c`, `Visibility__c` | None |
| Donor email | Visible | Visible | Visible |
| Tax data | Visible | Visible | Visible (decision D-04) |
| `Payment_Attempt__c` | No access | No access | No access |
| `Rejected_Notice__c` (D2) | No access | No access | Read |
| Assign permission sets | No | No | Yes |

- Email visibility for the three roles was requested by the client.
- No project role has access to `Payment_Attempt__c`: it holds data of people who may never donate, and no daily task needs it. Donation tracing (ADM-07) uses `Provider_Payment_Id__c` on the donation.
- Read-only for every role: `Amount__c`, `Payment_Status__c`, `Provider_Payment_Id__c`, `Confirmed_At__c` and the donation's `Campaign__c` (RNF-03). The confirmation process writes them in system mode.
- The Salesforce System Administrator profile (used to configure the org) can edit everything; this exception is documented under RNF-03.
- Internal org-wide defaults: `Fundraising_Campaign__c` Public Read/Write (object permissions limit who can edit); `Donation__c` Controlled by Parent; `Payment_Attempt__c` Private.

### 6.2 Site guest user

| | Access | Reason |
|---|---|---|
| `Fundraising_Campaign__c` | Read, public fields only: `Name`, `Description__c`, `Goal__c`, dates, `Status__c`, `Is_General__c`, image fields, `Total_Raised__c`, `Donation_Count__c`, `Progress_Percent__c`, `Accepts_Donations__c`, `Is_Publicly_Visible__c` | Show campaigns and progress (DON-01 to DON-03) |
| Guest sharing rule on `Fundraising_Campaign__c` | Criterion: `Status__c` = Active or Paused | Draft campaigns are never shared. Criteria-based sharing rules cannot use formula fields, so the status is used. Guest sharing rules only grant read access |
| `Donation__c` | No access | Donor recognition (DON-04) is served by a system-mode process that returns only public name and amount for public donations |
| `Payment_Attempt__c` | No access | Created by a system-mode process after server-side validation (PAY-07) |
| `Rejected_Notice__c` | No access | |
| API Enabled | Off | SEG-01 |
| Apex classes and flows | Only those used by the portal | Each one is listed with its reason in `security.md` |

**Known risk:** an Active campaign with a future start date is shared with the guest user even though the portal does not list it. Someone who guesses its Id could read its public fields. This is campaign data, not donor data; the risk is accepted and documented in `security.md`.

---

## 7. Personal data classification

| Data item | Personal data? | Stored? | Purpose | Who can see it |
|---|---|---|---|---|
| Email | Yes | Yes | Send the receipt | The three internal roles |
| Public name | Yes, if it identifies a person | Only if the donor chooses to be public | Donor recognition | Public (public donations) and internal roles |
| Legal name | Yes (individuals) | Only with invoice | Invoice issued outside the system | Internal roles (D-04) |
| RFC | Yes (individuals) | Only with invoice | Invoice | Internal roles (D-04) |
| Tax postal code | Yes | Only with invoice | Invoice | Internal roles (D-04) |
| Tax regime | Yes, linked to the person | Only with invoice | Invoice | Internal roles (D-04) |
| Amount | Yes, when linked to an identifiable person | Yes | Progress and recognition | Public only for public donations; aggregated in progress |
| Card data | Yes | No, captured by the payment provider | Not needed | Nobody in Salesforce |
| Attempt data (the items above, before payment) | Yes | Up to 7 days | Match the payment with the donor's input | No project role (only the System Administrator profile, RNF-03) |
| Separate last names, phone, address, CFDI use | Yes | Not collected | Data minimization | Nobody |

**Minimization:** the form may ask for first and last name separately (DON-11), but a single `Public_Name__c` is stored with the text that will be displayed. For invoices, a single legal name field is used.

---

## 8. Design decisions

| ID | Decision | Rationale | Alternative considered | Status |
|---|---|---|---|---|
| D-01 | Delete all attempts older than 7 days, including confirmed ones | Confirmed attempts are already copied to the donation; keeping them duplicates personal data | Keep confirmed attempts indefinitely | Proposed |
| D-02 | Custom `Fundraising_Campaign__c` instead of the standard `Campaign` | Guaranteed master-detail with roll-up for the total, simple guest permissions, no marketing fields (expected revenue, leads) | Standard `Campaign`: requires the Marketing User setting on every user, and roll-ups from a custom child would need to be verified within the delivery schedule | Proposed |
| D-03 | Campaign image set by URL in D1 | Making uploaded files public for the guest user adds complexity | File upload with public links (moved to D2) | Proposed |
| D-04 | The three internal roles can see tax data | Consistent with the client's decision on email visibility | Only `Donation_Admin`, who handles invoice requests (stricter least privilege) | Open |

---

## 9. Story coverage (workstream C, Delivery 1)

| Story | Model elements |
|---|---|
| GES-02 Campaign status and progress | Campaign list view with status, dates, goal, `Total_Raised__c`, `Accepts_Donations__c` |
| GES-03 Prepare a campaign | Campaign fields, `Goal_Must_Be_Positive`, `End_Date_After_Start`, default `Draft`, no delete permission |
| GES-06 Activate a campaign | `Status__c`, `Activation_Requires_Description`, `Is_Publicly_Visible__c` |
| GES-07 Pause and resume | `Status__c` = Paused sets `Accepts_Donations__c` to false without changing dates |
| GES-09 Update a campaign | Field history on `Goal__c`; progress recalculates through the formula |
| ADM-03 All confirmed donations | "Todas las donaciones" list view; read-only fields |
| ADM-05 Invoice requests | "Solicitan factura" list view; no guest access to `Donation__c` |
| SEG-01 Visitor security test | Section 6.2 |
| General campaign | `Is_General__c`, `General_Campaign_Always_Open` |
| MOD-03 Correct a public name (D2) | `Moderator` permission set, `Anonymous_Cannot_Become_Public`. The field history on `Public_Name__c` is configured in D1 (section 4); the moderation feature is D2 |

---

## 10. Automation: Flow or Apex

Declarative tools first; Apex only where Flow cannot do the job. Every Apex class also requires tests and Code Analyzer.

| Piece | Tool | Reason |
|---|---|---|
| Objects, fields, formulas, roll-ups, validation rules, permission sets, sharing, list views | Configuration | |
| RFC to uppercase without spaces (`UPPER(SUBSTITUTE(RFC__c, " ", ""))`) | Before-save record-triggered flow | Runs before validation rules |
| Close campaigns by date (GES-11, D2) | Scheduled-triggered flow | |
| Delete attempts older than 7 days (PAY-07) | Scheduled-triggered flow | |
| Receipt email when a donation is created (DON-23, D2) | Record-triggered flow with Send Email | `Receipt_Sent__c` prevents duplicates |
| Campaign list and detail for the guest (workstream B) | Standard components or LWC UI API / GraphQL wire adapters | The guest user has read access to campaigns |
| Donor recognition for the guest (workstream B) | Apex or a system-context flow | The guest user has no access to `Donation__c` |
| Create the attempt and the provider payment (workstream A, D1) | Apex, or Flow with the HTTP Callout action | Decided by workstream A |
| Receive the provider's webhook and verify its signature (workstream A, D2) | Apex | Flow cannot expose a public endpoint or compute an HMAC signature |

---

## 11. Contract between workstreams

**B → A:** the form sends the validated donation with `campaignId`, `amount`, `email`, `visibility` (`Anonymous`/`Public`), `publicName`, `invoiceRequested`, `legalName`, `rfc`, `taxPostalCode`, `taxRegime` and, in D2, `privacyNoticeAccepted`. These are the `Payment_Attempt__c` field names in camelCase without `__c`.

**A → C:** A creates `Donation__c` with `Payment_Status__c = Confirmed`, copying the attempt. In D2, the receipt is triggered by that creation (DON-23).

---

## 12. Open items to verify in the org

| # | Item | How to verify |
|---|---|---|
| V-01 | Time zone used by `TODAY()` for the site guest user | Between 18:00 and 24:00 Mérida time (already the next day in UTC), create a campaign starting tomorrow and open the portal as a guest. If it is listed before midnight, the guest user's time zone needs fixing (TEC-01) |
| V-02 | Owner of records created through the site | Create an attempt from the portal and check its owner (default owner for guest-created records, TEC-01) |
| V-03 | System permissions needed by `Donation_Admin` to assign permission sets | Assign a permission set while logged in as a test admin user |
| V-04 | Custom metadata reference syntax in validation rules (D2) | Create the rule in the org |
| V-05 | Tax regime catalog | Compare the appendix with c_RegimenFiscal in the SAT's Anexo 20 |

---

## Appendix: tax regime (c_RegimenFiscal)

Pending verification V-05. Picklist value API name = code; label = code + name. The portal filters the list by taxpayer type.

| Code | Regime (label) | Física | Moral |
|---|---|---|---|
| 601 | General de Ley Personas Morales | | ✓ |
| 603 | Personas Morales con Fines no Lucrativos | | ✓ |
| 605 | Sueldos y Salarios e Ingresos Asimilados a Salarios | ✓ | |
| 606 | Arrendamiento | ✓ | |
| 607 | Régimen de Enajenación o Adquisición de Bienes | ✓ | |
| 608 | Demás ingresos | ✓ | |
| 610 | Residentes en el Extranjero sin Establecimiento Permanente en México | ✓ | ✓ |
| 611 | Ingresos por Dividendos (socios y accionistas) | ✓ | |
| 612 | Personas Físicas con Actividades Empresariales y Profesionales | ✓ | |
| 614 | Ingresos por intereses | ✓ | |
| 615 | Régimen de los ingresos por obtención de premios | ✓ | |
| 616 | Sin obligaciones fiscales | ✓ | |
| 620 | Sociedades Cooperativas de Producción que optan por diferir sus ingresos | | ✓ |
| 621 | Incorporación Fiscal | ✓ | |
| 622 | Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras | | ✓ |
| 623 | Opcional para Grupos de Sociedades | | ✓ |
| 624 | Coordinados | | ✓ |
| 625 | Actividades Empresariales con ingresos a través de Plataformas Tecnológicas | ✓ | |
| 626 | Régimen Simplificado de Confianza | ✓ | ✓ |
