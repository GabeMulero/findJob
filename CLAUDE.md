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
- **Terraform state:** dedicated storage account (`TFS` in the architecture diagram), blob
  container set to **Private**. Public network access is intentionally left open — GitHub-hosted
  runners have no stable IP to restrict on — access is meant to be governed entirely by
  Entra ID/RBAC. **Not yet confirmed: shared-key access disabled on the storage account.** Until
  that's off, RBAC isn't actually the only door in — verify/set this before relying on it.
- **CI/CD identity:** App Registration, OIDC-federated with GitHub Actions — no stored Azure
  credentials in GitHub. Federated Identity Credential scoped to the GitHub Environment
  `FindJobEnvironment` on `GabeMulero/findJob`.

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

**Still open:**

- RBAC role assignment on the Service Principal above — no scope or role picked yet. Needs a
  decision (Contributor on the resource group vs. something narrower) before Terraform can
  actually run via CI.
- Protection rules on `FindJobEnvironment` (required reviewers) — not configured; currently
  nothing gates a run against that environment.
- Disable shared-key access on the TF state storage account (see above).
- Terraform file/module structure itself — nothing written yet.

**Constraints to hold to regardless of mode:**

- Real-world patterns over toy shortcuts — least privilege, no public database, secrets never in
  the repo, infrastructure defined as code.
- Cost-conscious — a budget alert is already set; call out anything likely to move the bill
  meaningfully.
- Everything reproducible from the repo. A couple of bootstrap resources (the state storage
  account, the App Registration, the FIC, the GitHub Environment) were created by hand out of
  necessity — that's fine, it's the standard chicken-and-egg bootstrap pattern — but don't let it
  happen again for anything Terraform can own going forward.
