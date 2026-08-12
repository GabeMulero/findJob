# CLAUDE.md — job-search-infrastructure

## Mode: build it

This project started as a teaching exercise — the git history and `docs/architecture.md` still
carry that reasoning. That constraint is now lifted, at my request. **Write the code.** Terraform,
the GitHub Actions workflow, application code, migrations — implement it directly. Don't wait for
me to type it, don't hold back the answer, don't quiz me on it.

---

## How to work

- **Explain notable decisions as you make them** — not a lecture, just enough that I know what
  got built and why, especially anywhere there's a real trade-off (cost, security scope,
  architecture). A sentence or two is usually enough.
- **Flag before anything destructive, costly, or hard to reverse** — `terraform apply` against
  real resources, deleting/recreating something, anything that spends real money or changes state
  outside this repo. Show me the plan or the diff first; I'll say go.
- **Don't ask permission for the routine stuff** — writing `.tf` files, editing workflow YAML,
  running `terraform plan`, reading/inspecting resources. Just do it.
- If I want a walkthrough of something later — for an interview, or just to understand it — I'll
  ask. Default to building, not teaching, unless I say otherwise.
- Keep `docs/architecture.md` current as things get built — it's the living reference, still worth
  maintaining even though the rest of this file's rules changed.

---

## Project context

**Goal:** a small, real cloud environment on Azure — right patterns, personal-project scale and
cost — hosting a persistent agent environment and, as the first concrete piece, a database
tracking job applications and recruiter follow-ups.

**Decided:**

- **Cloud:** Azure, personal tenant (`GabePersonal`) — confirmed independent of any employer or
  university
- **IaC:** Terraform
- **Compute:** Azure Container Apps Job, cron-scheduled (workload is idle most of the time;
  Kubernetes deferred to a possible phase 2 — see `docs/architecture.md` §4)
- **Database:** Azure Database for PostgreSQL Flexible Server, Burstable tier, private endpoint
  only, no public access
- **Terraform state:** storage account `jobsearchstorageaccount` in resource group
  `jobsearch-infrastructure`, container `terraform`, blob container **Private**. Public network
  access left open on purpose (GitHub-hosted runners have no stable IP); **shared-key access is
  disabled** — Entra ID/RBAC is genuinely the only door in, for both CI and local runs.
- **App infrastructure resource group:** `jobsearch-app` (southcentralus) — separate from the
  bootstrap RG above, on purpose, so Terraform never needs access to the account holding its own
  state. Terraform-managed (imported after hand-creation, same bootstrap pattern as the state
  storage account).
- **CI/CD identity:** App Registration, OIDC-federated with GitHub Actions — no stored Azure
  credentials in GitHub. **Two Federated Identity Credentials**, not one — see below for why.
- **RBAC:** the CI/CD Service Principal has `Storage Blob Data Contributor` on the state storage
  account and `Contributor` on `jobsearch-app`. The signed-in local user (`az login`) has the
  identical pair — local `terraform` runs need Entra ID access too, now that shared keys are off.
- **CI/CD pipeline:** `.github/workflows/terraform.yml`, two jobs. `plan` runs unrestricted on
  every push to `main` touching `terraform/**`. `apply` depends on `plan`, references
  `environment: FindJobEnvironment`, and applies the exact plan `plan` produced (not a fresh one)
  — so what gets approved is what gets applied. `FindJobEnvironment` has a required-reviewer
  protection rule (reviewer: me) — every `apply` run pauses for manual approval before it does
  anything.
- **Why two FICs:** the first FIC was scoped to the GitHub Environment subject
  (`environment:FindJobEnvironment`) — correct for `apply`, but `plan` doesn't reference an
  environment, so its OIDC token carries a branch-scoped subject instead
  (`ref:refs/heads/main`) and got rejected by Entra ID (`AADSTS700213`, discovered via a real
  failed run). Fixed by adding a second FIC (`github-plan-main-branch`) scoped to the branch
  subject specifically. Both live on the same App Registration.

**Key identifiers** (plain IDs, not secrets — safe to reference directly):

| What | Value |
|---|---|
| Azure Tenant ID | `91f7038a-dde6-40e7-baaf-a748d56ffb7a` |
| Azure Subscription ID | `5bb6ec37-2e7f-4018-8dcb-8a895d8c22ff` |
| App Registration (Client/App ID) | `1b7fc364-b21d-47f5-a790-660892919e6f` |
| App Registration Object ID | `b7519627-a93d-4bcb-a985-a8eb4efd498b` |
| Service Principal Object ID | `57e2f3a3-e2b7-4216-a41b-ee3e7e83f93d` |
| GitHub repo | `GabeMulero/findJob` |
| GitHub Environment | `FindJobEnvironment` |
| Bootstrap resource group (state only) | `jobsearch-infrastructure` |
| App resource group (Terraform-managed) | `jobsearch-app` |

**Still open:**

- The actual application infrastructure — VNet, Postgres Flexible Server, Key Vault, Container
  Registry, the Container Apps Job, Log Analytics. Only the resource group skeleton exists so far;
  `terraform plan` currently reports no changes because there's nothing else defined yet.
- A real `apply` run is sitting in GitHub Actions right now waiting on the required-reviewer
  approval (triggered manually to verify the pipeline works end to end — see run history on
  `GabeMulero/findJob`). Nothing to approve *of substance* yet (the plan is empty), but the gate
  itself is proven live.
- Database schema for the job-applications tracker — not designed yet.

**Constraints to hold to regardless of mode:**

- Real-world patterns over toy shortcuts — least privilege, no public database, secrets never in
  the repo, infrastructure defined as code.
- Cost-conscious — a budget alert is already set; call out anything likely to move the bill
  meaningfully.
- Everything reproducible from the repo. A couple of bootstrap resources (the state storage
  account, the App Registration, the FIC, the GitHub Environment) were created by hand out of
  necessity — that's fine, it's the standard chicken-and-egg bootstrap pattern — but don't let it
  happen again for anything Terraform can own going forward.
