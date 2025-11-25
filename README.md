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

---

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

This repository includes a helper script that will create the **Microsoft Intune Enrollment** service principal if it does not already exist in your tenant:

- [`Create-IntuneServicePrincipal.ps1`](https://github.com/markorr321/intune-conditional-access-enrollment-exclusions/blob/main/Create-IntuneServicePrincipal.ps1)

At a high level, the script:

- Connects to Microsoft Graph with the appropriate permissions.
- Checks for an existing service principal with the App ID `d4ebce55-015a-49b5-a083-c84d1797ae8c`.
- Creates the service principal if it does not already exist.

## Excluding the Intune Enrollment Service Principal from Conditional Access

Once the **Microsoft Intune Enrollment** service principal exists in your tenant, you can explicitly exclude it (and the **Microsoft Intune** app) from broad MFA Conditional Access policies.

This section assumes:

- **Microsoft Intune**  
  App ID: `0000000a-0000-0000-c000-000000000000`
- **Microsoft Intune Enrollment**  
  App ID: `d4ebce55-015a-49b5-a083-c84d1797ae8c`  
  (created or verified using the steps/scripts above)

### Step 1: Identify the Policy to Update

1. In the Entra admin portal, navigate to:  
   **Entra ID → Protection → Conditional Access → Policies**.
2. Locate the broad MFA policy you want to adjust, for example:  
   - `Baseline – Require MFA for all users`  
   - `All cloud apps – Require MFA`  
3. Open the policy for editing.

> **Note:** The exact policy name will vary by environment. The important part is that it:
> - Targets **All cloud apps** (or a large set of apps), and
> - Applies a **Require multifactor authentication** control.

### Step 2: Confirm the Policy Targets All Cloud Apps

Within the policy:

1. Under **Assignments**, open **Target resources**.

![Intune CAP Exclusion - Step 1](images/Intune%20CAP%20Exclusion%20-%20Step%201.png)

2. Confirm that the policy is configured to:
   - **Include** → **All cloud apps**

This is the type of policy we are *refining* with exclusions, not disabling.

### Step 3: Add Exclusions for Intune and Intune Enrollment

Still under **Target resources**:

1. In the **Include** tab, leave **All cloud apps** selected.
2. Switch to the **Exclude** tab:

![Intune CAP Exclusion - Step 2](images/Intune%20CAP%20Exclusion%20-%20Step%202.png)

   - Choose **Select apps**.

   - Click **Select resources** and then **Select Specific Resources**.
     
![Intune CAP Exclusion - Step 3](images/Intune%20CAP%20Exclusion%20-%20Step%203.png)

3. In the search box, add the following:

   - Search for `Microsoft Intune`  
     - Select the application where the **Application ID** is  
       `0000000a-0000-0000-c000-000000000000`
       
![Intune CAP Exclusion - Step 4](images/Intune%20CAP%20Exclusion%20-%20Step%204.png)

   - Search for `Microsoft Intune Enrollment`  
     - Select the application where the **Application ID** is  
       `d4ebce55-015a-49b5-a083-c84d1797ae8c`
       
![Intune CAP Exclusion - Step 5](images/Intune%20CAP%20Exclusion%20-%20Step%205.png)

4. Click **Select** to add both apps to the exclusion list.

5. Confirm that under **Exclude** you now see:
   - `Microsoft Intune`
   - `Microsoft Intune Enrollment`

### Step 4: Review and Enable the Policy

1. Review the rest of the policy settings:
   - **Users** / **Groups** in scope.
   - **Grant** controls (for example, **Require multifactor authentication**).
   - **Session** controls, if any.
2. Ensure the policy is set to **On** (or **Report-only** if you are piloting first).
3. Click **Save**.

![Intune CAP Exclusion - Step 6](images/Intune%20CAP%20Exclusion%20-%20Step%206.png)

### Step 5: Validate the Exclusion

After saving:

1. Verify that the policy now shows:
   - **Cloud apps** → **All cloud apps** (Include)  
   - **Exclude** → `Microsoft Intune`, `Microsoft Intune Enrollment`
2. Optionally, run sign-in tests on:
   - A hybrid-joined Windows device going through normal PRT refresh / Intune sync.
   - A user signing in to other apps that should still be challenged for MFA.

You should observe:

- **No new MFA prompts** for background Intune / enrollment flows.
- **Existing MFA behavior** remains enforced for business applications.
- **PRT and device sync** behavior becomes more stable over time, especially on hybrid-joined Windows devices.

These exclusions, combined with:

- MFA enforced at **device registration**,
- Blocking **personal Windows device enrollment**, and
- Requiring **compliant devices** for Intune admin and Graph,

form the basis of the Conditional Access design described in this repository.



