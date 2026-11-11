# Experience Builder Guide: Setting Up the Public Portal (Workstream B)

**Audience:** Salesforce team administrator.  
**Sandbox:** `donations-dev` (confirm the local CLI alias before running commands).  
**Scope:** Workstream B stories DON-01, DON-02, DON-03, DON-04, DON-08, DON-10, DON-11 and DON-12 (Delivery 1).

> **Status as of November 10, 2026.** The **Mexico Dreamin Donation Portal** Experience Cloud site (Build Your Own LWR, URL prefix `portal`) is deployed and published in the team Sandbox. The public site is [https://uady--class2026b.sandbox.my.site.com/portal/](https://uady--class2026b.sandbox.my.site.com/portal/). The site has been tested as an unauthenticated Guest visitor. This is a Sandbox demonstration, not a production donation website.
>
> **Payment integration.** The portal no longer uses the mock payment gateway. `DonationIntakeService.DonationPaymentGateway` delegates payment creation and lookup to Workstream A's `DonationPaymentController`, using the `Payment_Attempt_Create` and `Payment_Preference_Create` flows and Mercado Pago test credentials. A manual end-to-end checkout with the project's test buyer account remains a separate validation item; do not use real payment credentials or cards.

## 0. Deployment contents and project components

Salesforce metadata is stored under `force-app/main/default/`.

| Area | Main components |
|---|---|
| Workstream B Apex | `CampaignPortalController`, `DonorRecognitionService`, `DonationIntakeService`, `CampaignDTO`, `DonorRecognitionDTO` |
| Workstream A payment Apex | `DonationPaymentController` (`startDonation`, `openPayment`, `getPaymentResult`), `MercadoPagoPreferenceAction`, `MercadoPagoPaymentLookupAction` |
| Apex tests | `CampaignPortalControllerTest`, `DonorRecognitionServiceTest`, `DonationIntakeServiceTest`, `DonationPaymentControllerTest`, `MercadoPagoPreferenceActionTest`, `MercadoPagoPaymentLookupActionTest`, `PortalTestDataFactory` |
| Main LWCs | `donationPortal`, `campaignList`, `campaignDetail`, `campaignProgress`, `donorRecognitionList`, `donationForm`, `donationThankYou` |
| Supporting LWCs | `portalMessages`, `portalUtils`, `portalDemoData`, `portalTheme`, `donationFormMessages`, `donationFormRules`, `donationThankYouMessages` |
| Custom label | `Donation_Return_Url` = `https://uady--class2026b.sandbox.my.site.com/portal/gracias` |
| Guest security metadata | `profiles/Mexico Dreamin Donation Portal Profile`, `sharingRules/Fundraising_Campaign__c`, `permissionsets/Mercado_Pago_Callout` |
| Experience Cloud metadata | `digitalExperiences`, `digitalExperienceConfigs`, `networks`, `sites` |

The Delivery 1 objects and fields are deployed in the Sandbox. The main custom objects are `Fundraising_Campaign__c`, `Donation__c` and `Payment_Attempt__c`. Supporting metadata also includes `Rejected_Notice__c` for payment notices.

### Deployment commands

Run commands from the repository root. Replace `donations-dev` with the exact local alias shown by `sf org list` if your machine uses another alias. Verify the target org before every deployment.

```bash
# Check-only validation; does not save changes to the org
sf project deploy start --dry-run \
  --source-dir force-app/main/default/classes \
  --source-dir force-app/main/default/lwc \
  --source-dir force-app/main/default/labels \
  --test-level RunSpecifiedTests \
  --tests CampaignPortalControllerTest \
  --tests DonorRecognitionServiceTest \
  --tests DonationIntakeServiceTest \
  --tests DonationPaymentControllerTest \
  --tests MercadoPagoPreferenceActionTest \
  --tests MercadoPagoPaymentLookupActionTest \
  --target-org donations-dev --wait 30

# Actual deployment: run only after review and explicit authorization
sf project deploy start \
  --source-dir force-app/main/default/classes \
  --source-dir force-app/main/default/lwc \
  --source-dir force-app/main/default/labels \
  --test-level RunSpecifiedTests \
  --tests CampaignPortalControllerTest \
  --tests DonorRecognitionServiceTest \
  --tests DonationIntakeServiceTest \
  --tests DonationPaymentControllerTest \
  --tests MercadoPagoPreferenceActionTest \
  --tests MercadoPagoPaymentLookupActionTest \
  --target-org donations-dev --wait 30
```

**Windows development notes:**

- On the team's Windows setup, the CLI may exit with code 1 even when the deployment JSON reports `status: 0`. Check the returned status and *Setup > Deployment Status* rather than relying on the process exit code alone.
- `sf data query` and some CLI arguments containing spaces caused path errors in the team's Windows environment. REST queries were performed with `sf api request rest`; the site was published through the Experience Cloud Connect API when the CLI command failed.

## 1. Experience Cloud LWR site

The Sandbox also contains a legacy Aura site named **Donaciones**, with the `donaciones` prefix. It is an older site and must not be reused for this project.

The project site is already created. **Do not create it again**, because that would create another site/network and Guest user.

| Element | Current value |
|---|---|
| Site name | `Mexico Dreamin Donation Portal` |
| Template | Build Your Own (LWR) |
| URL prefix | `portal` |
| Digital Experience bundle | `Mexico_Dreamin_Donation_Portal1` |
| Network | `Mexico Dreamin Donation Portal` |
| Custom Site | `Mexico_Dreamin_Donation_Portal` |
| Home page | `Home`, route `/`, contains `c:donationPortal` |
| Payment return page | `Gracias`, route `/gracias`, contains `c:donationThankYou` |
| Site language | Spanish (Mexico), `es-MX` |
| Public URL | `https://uady--class2026b.sandbox.my.site.com/portal/` |

### Recreating the site in another org

Only when setting up a separate org, use *Setup > Digital Experiences > All Sites > New*, select **Build Your Own (LWR)**, set the name to `Mexico Dreamin Donation Portal` and URL prefix to `portal`. Site creation is asynchronous. Do not use the old Aura site or its prefix.

Equivalent CLI command (if supported by the installed Salesforce CLI):

```bash
sf community create --name "Mexico Dreamin Donation Portal" \
  --template-name "Build Your Own (LWR)" \
  --url-path-prefix portal --target-org donations-dev
```

### Retrieve the Experience Cloud bundle

To version the live site metadata in the repository:

```bash
sf project retrieve start --metadata DigitalExperienceBundle DigitalExperienceConfig Network CustomSite --target-org donations-dev
```

In Builder, *Settings > Languages* should use **Spanish (Mexico)** as the default language. This affects standard component validation messages and date formatting.

## 2. Guest user security and access

The design follows least privilege. The Guest user reads only the campaign fields needed by the public portal and invokes the small set of Apex classes required by the site. It has no direct object access to donations or payment attempts, and **API Enabled** is disabled. See `docs/security.md` and `docs/data-model.md` for the full security model.

### 2.1 Guest profile and user

- In Builder, open *Settings > General* and follow the **Guest User Profile** link. The profile is `Mexico Dreamin Donation Portal Profile`.
- Find the Guest user under *Setup > Sites > Mexico Dreamin Donation Portal > Public Access Settings > View Users*.
- The Guest user is `Mexico Dreamin Donation Portal Site Guest User`, with nickname `Mexico_Dreamin_Donation_Portal`, timezone `America/Merida` and locale `es_MX`.

### 2.2 Object and field permissions

The Guest profile has the following object access:

| Object | Guest access |
|---|---|
| `Fundraising_Campaign__c` | Read only |
| `Donation__c` | None |
| `Payment_Attempt__c` | None |
| `Rejected_Notice__c` | None |

The public campaign fields are:

`Name`, `Description__c`, `Goal__c`, `Start_Date__c`, `End_Date__c`, `Status__c`, `Is_General__c`, `Image_URL__c`, `Image_Alt_Text__c`, `Total_Raised__c`, `Donation_Count__c`, `Progress_Percent__c`, `Accepts_Donations__c` and `Is_Publicly_Visible__c`.

All are read-only. The retrieved profile has explicit read FLS for 11 fields; `Name`, `Goal__c` and `Start_Date__c` are required fields and remain readable by Salesforce. The Guest profile has no object or field permissions for `Donation__c` or `Payment_Attempt__c`.

### 2.3 Apex class access

Enable only the classes invoked directly by the site:

| Apex class | LWC caller |
|---|---|
| `CampaignPortalController` | `campaignList`, `campaignDetail` |
| `DonorRecognitionService` | `donorRecognitionList` |
| `DonationIntakeService` | `donationForm` (`startDonation`, `openPayment`) |
| `DonationPaymentController` | `donationThankYou` (`getPaymentResult`) |

The `Mercado_Pago_Callout` permission set grants access to the `MercadoPago-MercadoPagoTest` External Credential principal and `UserExternalCredential` read access. It grants no project object access. The Guest user needs it for the Mercado Pago callout.

Do not grant the Guest user direct access to `MercadoPagoPreferenceAction`, `MercadoPagoPaymentLookupAction`, DTO classes or test classes. Internal Apex-to-Apex calls do not require exposing every called class to the Guest profile.

### 2.4 Permissions that must remain disabled

- *System Permissions > API Enabled*: **off**.
- No Guest access to `Donation__c` or `Payment_Attempt__c`.
- No access to standard objects that the public portal does not use.
- Public responses must never expose email, RFC, fiscal information, payment attempts or private donor details.

### 2.5 Campaign sharing rule and publication logic

`Fundraising_Campaign__c` uses a Private external sharing model. The Guest user receives read-only access through the criteria-based Guest User Access rule `Campanas_Publicas_Invitado`.

The current rule shares campaigns whose `Status__c` picklist label is **Active, Paused or Closed** (stored labels in the org: `Activa`, `Pausada`, `Cerrada`). `Draft` is excluded. The rule is read-only and does not grant edit access.

The server-side campaign query and eligibility checks apply additional visibility/date rules. Do not rely on a badge or client-side filtering to protect Draft campaigns or prevent an ineligible payment. `CampaignPortalController` and the donation intake service enforce the public behavior and payment eligibility on the server.

The rule's retrieved metadata stores Spanish picklist labels (`Cerrada,Activa,Pausada`). If recreating it manually, select those three states and verify the result in `Fundraising_Campaign__Share`; do not assume that API values and translated labels are interchangeable in the sharing-rule metadata.

A legacy `ClosedCampaignReader` helper in `CampaignPortalController` was retained as a workaround for the closed-campaign detail route. The sharing rule also includes Closed. Review this helper before removing it; do not remove it as part of routine content maintenance.

### 2.6 Guest timezone

The Guest user's timezone is `America/Merida`. Formula and Apex date comparisons use the executing user's date context. Keep this timezone aligned with the portal's intended local date to avoid campaigns appearing a day early or late around midnight.

## 3. Configure the portal on the Home page

The live Home page contains only the top-level `donationPortal` component. It mounts the catalog, detail, donation form and navigation views internally.

When configuring a separate site or restoring the page in Builder:

1. Open *Workspaces > Builder*.
2. Select *Pages > Home*.
3. Remove template sample content from the main content area while keeping the intended site header and footer.
4. Find the custom component **Portal de donaciones** (`donationPortal`).
5. Drag it into a full-width, single-column section.
6. Set the page API name property to the actual page API name (normally `Home`).
7. Save and preview the page.

Do not place `donationForm` by itself. It requires a campaign ID and is mounted by `donationPortal`.

The portal uses one page and updates the URL without a full page reload:

| URL | View |
|---|---|
| `/portal/` | Public campaign catalog |
| `/portal/?campana=<Id>` | Campaign detail, including eligible closed-campaign history |
| `/portal/?campana=<Id>&donar=1` | Donation form for the selected campaign |

Browser Back and Forward navigate between catalog, detail and form states. An invalid or unavailable campaign ID displays **“No encontramos esta campaña…”** and a link back to the catalog.

## 4. Theme and colors

The portal's `portalTheme.css` provides fallback values for the Salesforce design-system variables:

| Variable | Fallback | Usage |
|---|---|---|
| `--dxp-g-brand` | `#0b5cab` | Accent, progress bar, selected amounts and links |
| `--dxp-g-brand-contrast` | `#ffffff` | Text on accent backgrounds |
| `--dxp-g-root` | `#ffffff` | Content and card backgrounds |
| `--dxp-g-root-contrast` | `#1b1f23` | Main text |

Status labels, borders and neutral grays are fixed in the component styles. To change the site theme, open *Builder > Theme* and adjust Brand, background and text colors. Save and reload the preview.

The actual effect of the Builder `--dxp-g-*` variables was not independently verified in the November 10 review; the components retain the CSS fallbacks in `portalTheme.css`. Recheck computed styles in browser developer tools after changing the branding set. Maintain at least 4.5:1 contrast for normal text and check keyboard focus states.

## 5. Campaign records and public catalog (current Sandbox data)

The five intended portal campaigns are **existing Salesforce records**. They were renamed and their descriptions updated in place; their IDs and donation relationships were preserved. Do not import the original demo JSON again: the tree import plan uses inserts and could create duplicate campaigns and donations.

| Public campaign name | Salesforce record ID | Status | Goal | Current image state |
|---|---|---|---:|---|
| Apoya la participación en Mexico Dreamin 2026 | `a1bVC000008jeEQYAY` | Active; Nov 1–19, 2026 | MXN 15,000 | Stable public Salesforce Files distribution verified |
| Viaje y hospedaje en la Ciudad de México | `a1bVC000008jeERYAY` | Active; Nov 1–19, 2026 | MXN 30,000 | Uploaded image; public distribution/field update must be confirmed |
| Fondo general SF Vibe Lab | `a1bVC000008jeEPYAY` | Active; no end date | MXN 20,000 | Uploaded image; public distribution/field update must be confirmed |
| Kits de bienvenida | `a1bVC000008jeESYAY` | Paused; Nov 1–19, 2026 | MXN 5,000 | Uploaded image; public distribution/field update must be confirmed |
| Transporte local durante el evento | `a1bVC000008jeETYAY` | Draft; starts Nov 10, 2026 | MXN 8,000 | Uploaded image; public distribution/field update must be confirmed; Draft stays hidden |

The four additional image files have been uploaded to Salesforce Files. Do not consider them complete until each file is matched to the correct campaign, receives a public distribution without an expiration date, is accessible without authentication, fits the 255-character `Image_URL__c` limit, and is saved to the corresponding `Image_URL__c` and `Image_Alt_Text__c` fields. The Transportation campaign remains Draft and must not appear in the public catalog even after its image is assigned.

### Mexico Dreamin image

The existing image is `Mexico-Dreamin-2026.png` (`ContentVersion` `068VC00000NdZLfYAN`). Its replacement public distribution is `05DVC0000022fYz2AI`, with `PreferencesExpires=false` and no expiration date. The validated URL is 242 characters, returns the same image without authentication and was rendered in the public portal without a CSP violation. The alt text is **“Imagen representativa de la participación en Mexico Dreamin 2026.”** The old expiring distribution was left in place; it is no longer the URL assigned to the campaign.

### Campaigns used for testing

Three `[PRUEBA]` campaigns that had been visible in the catalog were changed to Draft. Their records and donations were preserved:

| Test campaign | Salesforce ID | Previous status | Current status | Related donations |
|---|---|---|---|---|
| `[PRUEBA] Campaña activa vigente` | `a1bVC000008jepVYAQ` | Active | Draft | 3 confirmed test donations, MXN 10,200; unchanged |
| `[PRUEBA] Campaña general` | `a1bVC000008jesjYAA` | Active | Draft | 0 |
| `[PRUEBA] Campaña pausada` | `a1bVC000008jeuLYAQ` | Paused | Draft | 0 |

The remaining four `[PRUEBA]` records were not changed. Closed and already-ended test campaigns may still be reachable through their direct history URLs as required by DON-02; they are not shown in the current catalog.

As verified after these changes, the public catalog showed exactly four cards: Mexico Dreamin, Fondo general, Viaje y hospedaje and Kits de bienvenida. The three newly Draft test campaign IDs returned **“No encontramos esta campaña”** to Guest visitors. A direct attempt to open the donation form for the previously active test campaign was rejected by the server with **“Esta campaña ya no acepta donaciones.”** No payment attempt was created by that check.

`Fondo general SF Vibe Lab` is the only general campaign shown in the catalog. Kits remains informational and cannot accept donations. Transportation remains Draft and is hidden.

### Donation and donor-recognition data

All campaign and donation records in this Sandbox are demonstration/test data. Totals below are the values reported after the cleanup; they are not real fundraising proceeds.

| Campaign | Confirmed donation count | Total shown | Progress |
|---|---:|---:|---:|
| Apoya la participación en Mexico Dreamin 2026 | 2 | MXN 1,500 | 10% |
| Viaje y hospedaje en la Ciudad de México | 2 | MXN 6,500 | 21.67% |
| Fondo general SF Vibe Lab | 2 | MXN 550 | 2.75% |

Three seeded recognition records were changed from `Public` to `Anonymous` (only `Visibility__c` changed). Their original names remain stored internally for traceability and are no longer returned to the public recognition list. The amounts, campaign relationships, payment statuses and donation totals were preserved. The Guest `getDonorRecognition` response returned an empty list for the three affected campaign details, while campaign progress and confirmed donation counts remained unchanged.

The three confirmed payments on `[PRUEBA] Campaña activa vigente` total MXN 10,200 (204% of its MXN 5,000 goal). They are test-mode records, not real revenue, and the campaign is now Draft. Do not use this value as evidence of real money raised or as a public campaign example.

## 6. Visual, responsive and accessibility checks

The published site was reviewed on November 10, 2026 as an unauthenticated Guest visitor using browser automation and mobile emulation.

- [x] No horizontal overflow at 360 px in the catalog, campaign detail views and donation form with fiscal fields open.
- [x] Keyboard focus order reaches “Skip to Main” and campaign cards; Enter opens a focused card.
- [x] Campaign card focus indicator is visible (2 px outline).
- [x] With reduced motion enabled, portal components have no custom animations/transitions; the template's short Skip to Main transition remains.
- [x] Active, Paused, Closed and ended campaigns are distinguished by text, not color alone.
- [x] Color contrast calculations for the CSS fallback palette met the recorded thresholds: main text 16.6:1, muted text 8.0:1, accent on white 6.7:1, status badges 7.5:1–10.3:1 and progress fill against track 5.4:1.
- [ ] Keyboard interaction for amount pills and form buttons still needs a dedicated check.
- [ ] A screen-reader test has not been completed.

## 7. Functional checks and current verification status

The checks below combine the earlier November 10 functional review with the later campaign-data cleanup. The latest catalog cleanup was separately checked with **32/32 Guest browser checks** at 1280 px and 360 px. This does not mean every payment acceptance criterion has been completed.

| Scenario | Expected behavior | Recorded result |
|---|---|---|
| Open `/portal/` without a session | Show only public, in-date Active campaigns and Paused informational campaigns | Passed: exactly four cards; no Draft or hidden `[PRUEBA]` records |
| General campaign | Only one general campaign is listed | Passed: Fondo general SF Vibe Lab is the only visible general campaign |
| Paused campaign | Visible with Paused label; no active donation action | Passed for Kits de bienvenida |
| Draft campaign | Not listed and unavailable by direct public detail URL | Passed for the three test campaigns changed to Draft and the Transportation Draft record |
| Draft campaign donation URL | Server rejects donation; no payment attempt is created | Passed for the previously active `[PRUEBA]` campaign |
| Closed campaign detail | Informative detail can be opened by direct URL; no donation action | Passed in the earlier functional review |
| Active campaign with end date in the past | Shows ended state and rejects a new donation | Passed in the earlier functional review |
| Invalid or nonexistent campaign ID | Shows a controlled “not found” message and link to catalog | Passed in the earlier functional review |
| Browser Back/Forward | Moves between catalog, detail and form without a full reload | Passed in the earlier functional review |
| Donation progress | Uses confirmed donations; percentage may exceed 100% | Jest/Apex tests covered 50%, 100% and 120%; a live portal case above 100% was not available after cleanup |
| Donor recognition | Only confirmed Public donations return public name and amount | After seeded donations were anonymized, the affected campaign detail pages showed the empty-recognition message; totals remained correct |
| Anonymous donation form | Anonymous is the default; only email is required in the basic flow | Passed in the earlier browser review |
| Public recognition form | Public name appears when the donor opts into recognition | UI behavior passed in the earlier browser review; a new public donation is still needed for current live evidence |
| Invoice + anonymous option | Fiscal fields may be supplied while donor recognition remains Anonymous | UI display passed; a full live invoice submission was not completed |
| Server-side validation | Reject invalid amount, email, public name and RFC; reject ineligible campaigns | Passed in the earlier server checks |
| Thank-you page URL tampering | Query-string status/payment values are not trusted as proof | Passed: fake `payment_id` with `status=approved` did not confirm a payment |
| Guest privacy | Guest cannot query or read Donation or Payment Attempt records directly | REST/Aura/Apex checks reported 404/401 and no email/RFC/fiscal data in public responses |

### Previously reported automated checks

- **Apex deployment:** deployment `0AfVC00000PBhkn0AD` reported `Succeeded`, 31/31 components and 137/137 Apex tests. The check-only validation `0AfVC00000PBhZV0A1` also succeeded.
- **Jest:** 136 tests passed across 7 suites; reported LWC line coverage was 97.2%.
- **Code Analyzer:** no severity 1 or 2 findings were reported. Eight moderate production warnings were recorded. The Flow engine did not start on the development machine because Python was unavailable.

These are previously reported results, not a claim that the entire suite was rerun after the subsequent data-only updates. No full Apex/Jest rerun was requested for the campaign renames, Draft changes or donor-visibility updates.

### Remaining end-to-end and evidence work

- [ ] Complete a manual Checkout Pro test using the project's Mercado Pago **test buyer** account and test card; verify approved, rejected and pending/unknown return behavior as applicable. Do not use production credentials or real cards.
- [ ] Confirm the four newly uploaded Salesforce Files are matched, distributed publicly without expiration, saved to the four campaign records and visible as Guest. Mexico Dreamin's stable image is already verified.
- [ ] Complete keyboard testing for donation amount controls and form buttons.
- [ ] Complete a screen-reader check.
- [ ] Run the full empty-catalog scenario in the live portal if required for evidence; automated tests already cover the empty-state message.
- [ ] Run a live progress-over-100% scenario only if suitable non-sensitive test data is authorized; automated tests already cover the calculation.
- [ ] Complete the SEG-01 repeatability check with a second team member and record evidence in `docs/security.md`.
- [ ] Create a new authorized test donation with Public recognition if live evidence for DON-04 AC1 / DON-11 AC2 is needed. Do not reverse the existing Anonymous donations; the org validation rule prevents that transition.

## 8. Security rules and operational cautions

1. Mercado Pago must remain in **test mode**. Use test seller/buyer accounts and test cards only.
2. Never commit access tokens, webhook secrets, credentials, session IDs, buyer details or card information. Keep secrets in Salesforce Named Credentials / External Credentials or protected settings.
3. The Guest user has no direct access to donations or payment attempts and no `API Enabled` permission.
4. Payment attempts are not donations and must not count toward totals. A `Donation__c` record is created only after the provider confirms the payment through the server-side flow.
5. Do not re-run the original `sf data import tree --plan data/demo/plan.json` import. It uses inserts and may duplicate campaigns/donations. The JSON source is not the live record store.
6. Do not present Sandbox totals as real fundraising revenue. All current campaign and donor records are test/demo data.
7. A published Sandbox Experience Cloud site is internet-accessible. Share the link only with the intended reviewers and keep personal data fictitious.

## 9. Troubleshooting

| Symptom | Likely cause / action |
|---|---|
| Blank page | Confirm `donationPortal` is on the Home page and the page is in the LWR site. |
| “No pudimos cargar las campañas” | Check Guest FLS, Apex class access and the campaign Guest sharing rule (Section 2). |
| Catalog is empty despite Active campaigns | Check campaign start/end dates, Guest timezone and `Campanas_Publicas_Invitado`. |
| Selecting a campaign does not change the view | Check the page API name property on `donationPortal`. |
| Closed campaign detail says “No encontramos…” | Check Guest campaign read access and the `ClosedCampaignReader` path before changing sharing metadata. |
| Campaign image does not load | Check that `Image_URL__c` is HTTPS, under 255 characters, accessible without authentication, and returns an image. For non-Salesforce hosts, verify the Experience Builder `img-src` CSP allowlist. |
| Campaign dates appear one day early/late | Check the Guest user's `America/Merida` timezone. |
| Portal redirects to `example.com` | The org may have an older build with the mock gateway. The current implementation uses `DonationPaymentGateway` and `DonationPaymentController`. |
| Image URL is rejected when saving | `Image_URL__c` has a 255-character limit. Shorten only optional parameters after proving the shortened URL returns the identical image, then recheck Guest access. |

## 10. Publication

For changes made in Experience Builder, use *Builder > Publish* after review. The site was already published and the later campaign-record changes were read live by the catalog, so those data updates did not require republishing. Any metadata or component deployment must follow the check-only and authorization process in Section 0.
