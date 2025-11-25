# intune-conditional-access-enrollment-exclusions

This repository documents practical guidance and examples for configuring Conditional Access in Entra ID to support reliable Microsoft Intune enrollment while maintaining strong security controls. It focuses on safely excluding the **Microsoft Intune** and **Microsoft Intune Enrollment** applications from broad MFA policies, handling hybrid-joined Windows devices, preserving Primary Refresh Token (PRT) health, and blocking personal device enrollments. You’ll find design rationale, example policies, and implementation notes that help balance user experience, device compliance, and protection against rogue or unmanaged endpoints.

## Background and Problem Summary

In many environments, broad “require MFA” Conditional Access (CA) policies are applied directly to **all cloud apps**, including:

- **Microsoft Intune**  
  `0000000a-0000-0000-c000-000000000000`
- **Microsoft Intune Enrollment**  
  `d4ebce55-015a-49b5-a083-c84d1797ae8c`

While this looks good on paper, it can interfere with the background token and enrollment flows that Windows relies on—especially for **hybrid Entra ID joined** devices. CA prompts at the wrong time can block or break:

- Primary Refresh Token (**PRT**) issuance and refresh  
- Intune enrollment and compliance reporting  
- Device sync and policy application

The end-user impact is familiar:

- “**Problem with your work or school account**” toasts  
- “**Access work or school – Needs attention**” in Settings  
- Devices stuck in non-compliant or partially enrolled states

This repo documents a pattern that improves reliability for hybrid-joined Windows devices while **maintaining** a strong security posture.

---

## Scope and Target Audience

This repository is intended for:

- Entra ID / identity engineers  
- Intune / endpoint management engineers  
- Security architects and Conditional Access admins

It assumes you are already:

- Managing Windows devices with Microsoft Intune  
- Using Entra ID Conditional Access with MFA  
- Familiar with hybrid Entra ID join and PRT concepts

---

## Design Goals

The proposed design aims to:

1. Preserve **PRT health** and stable Windows SSO for hybrid-joined devices.
2. Avoid breaking or degrading **Intune enrollment** and compliance reporting.
3. Keep strong **MFA and device-based** controls in front of business applications.
4. Prevent attackers from enrolling or using **rogue Windows devices**.
5. Clearly separate **background service flows** from **interactive user access**.

---

## Key Components

The design is built around:

- **Microsoft Intune** (`0000000a-0000-0000-c000-000000000000`)  
- **Microsoft Intune Enrollment** (`d4ebce55-015a-49b5-a083-c84d1797ae8c`)  
- **Entra ID Conditional Access** (MFA, compliant/hybrid-joined device conditions)  
- **Windows device enrollment restrictions** (blocking personal Windows devices)  
- **Privileged Identity Management (PIM)** for Intune administration  
- **Microsoft Graph** access restrictions from non-compliant devices

---

## Conditional Access Design

### 1. Excluding Intune Apps from Broad MFA Policies

We propose excluding the **Microsoft Intune** and **Microsoft Intune Enrollment** applications from broad, catch-all MFA policies (for example, “All cloud apps – Require MFA”).

These two apps underpin:

- Device join and registration pipelines  
- Intune enrollment flows  
- Ongoing compliance and sync operations  
- PRT issuance and refresh on hybrid-joined Windows devices

Allowing them to operate without generic MFA prompts prevents CA from breaking background token flows and significantly reduces:

- Enrollment failures  
- “Problem with your work or school account” prompts  
- Devices stuck in a non-compliant or “needs attention” state

### 2. Enforcing MFA at Device Registration

Instead of forcing MFA directly on the Intune and Intune Enrollment apps, we enforce MFA where it adds the most value:

- At the **device registration**
- On **business applications** that access corporate data

This ensures that:

- Users are **strongly authenticated** when onboarding a device  
- Access to sensitive workloads is still protected by MFA + device state  
- Background processes (PRT refresh, sync) are not repeatedly challenged

### 3. Blocking Personal Windows Device Enrollment

To prevent abuse of the excluded Intune apps, we pair the exclusions with a strict device ownership control:

- **Personal Windows device enrollment is blocked**

Only **corporate-owned, IT-approved** Windows devices are allowed to enroll. This prevents scenarios where an attacker:

1. Steals valid credentials (and MFA, if possible)  
2. Enrolls a **personal** laptop or VM  
3. Relies on the exempted Intune apps to gain a “trusted” or compliant device

Instead, all enrollment activity must come through **managed provisioning paths** such as:

- Windows Autopilot  
- Hybrid join + GPO / co-management  
- Other IT-controlled enrollment methods

This keeps background PRT and enrollment flows healthy while strictly governing which devices are allowed to benefit from the Intune CA exclusions.

### 4. Requiring Compliant Devices for Intune Admin and Graph

To further reduce risk:

- **Intune administration** requires **PIM activation** with **MFA** from a **compliant device**.  
- **Microsoft Graph** access is restricted to **compliant endpoints** for relevant clients/users.

An attacker cannot simply:

- Enroll a rogue device (blocked by enrollment restrictions), or  
- Use a non-compliant endpoint to manage Intune or automate actions through Graph.

They would need to compromise an existing compliant device or a privileged identity, which is where PIM approvals, CA, and monitoring controls are focused.

---

## Threat Mitigation Considerations

While the Intune Enrollment and Microsoft Intune applications would be excluded from broad MFA CA policies to preserve reliable PRT and enrollment flows, they are not intended to become an avenue for attackers to hide behind.

Under this proposed model:

- Personal Windows device enrollment is blocked.  
- Intune admin access requires PIM + MFA from a compliant device.  
- Microsoft Graph is blocked from non-compliant endpoints (where applicable).

As a result, an attacker cannot simply enroll a rogue device and rely on the excluded Intune apps to gain a trusted foothold. They must instead compromise an existing compliant device or privileged identity—risks that are already addressed through strong identity protections, Conditional Access, PIM, and monitoring.

## Ensuring the Intune Enrollment Service Principal Exists

In some tenants, the **Microsoft Intune Enrollment** enterprise application (service principal) does not exist by default or does not appear in the **Enterprise applications** list until it has been created or used at least once. Because Conditional Access targets and exclusions are configured against **service principals**, you must ensure that the Intune Enrollment service principal is present in the tenant before you can reliably include or exclude it in policies.

This repository assumes the following app IDs:

- **Microsoft Intune**  
  `0000000a-0000-0000-c000-000000000000`
- **Microsoft Intune Enrollment**  
  `d4ebce55-015a-49b5-a083-c84d1797ae8c`

If you cannot find **Microsoft Intune Enrollment** under *Enterprise applications*, use one of the following approaches to create or surface the service principal.

### Check for Existing Service Principals

1. In the Entra admin portal, go to:  
   **Entra ID → Enterprise applications**.
2. Search for:
   - **Display name:** `Microsoft Intune Enrollment`
   - Or **Application ID:** `d4ebce55-015a-49b5-a083-c84d1797ae8c`
3. If it appears, confirm the **Application ID** matches the value above.  
   You can now use this enterprise application in Conditional Access policies (for both targeting and exclusions).

If it does **not** appear, proceed to creating the service principal.

### Creating the Microsoft Intune Enrollment Service Principal (PowerShell)



## Disclaimer

This repository represents **proposed** design patterns and configuration examples. You should:

- Validate all changes in a **test** or **pilot** environment first.
- Involve your **security**, **identity**, and **endpoint management** teams.
- Adjust policies to match your organization’s **risk appetite**, **regulatory**, and **operational** requirements.

Nothing here is official Microsoft guidance; treat this as community-driven implementation guidance.

---

## Contributing

Contributions, issues, and suggestions are welcome. If you have:

- Alternative CA patterns  
- Improvements to the example policies  
- Real-world experiences or gotchas

…feel free to open an issue or submit a pull request.

---

## License

Specify your chosen license here (for example, MIT):

`TODO: Add LICENSE file and reference it here.`
