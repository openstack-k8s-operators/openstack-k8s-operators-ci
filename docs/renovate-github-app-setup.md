# Renovate GitHub App Setup

## Why a GitHub App?

The Renovate self-hosted runner needs to push branches that modify
`.github/workflows/` files (e.g., pinning action SHAs). GitHub requires
the `workflow` scope for PATs to do this, but GitHub Apps use a separate
**Workflows: write** permission which is more granular and scoped to
installed repos only.

## Setup

### 1. Create a GitHub App

Go to **Organization settings → Developer settings → GitHub Apps → New GitHub App**.

Settings:
- **Name**: e.g., `openstack-k8s-operators-renovate`
- **Homepage URL**: org URL
- **Expire user authorization tokens**: Yes (default)
- **Webhook**: Deactivate (not needed for self-hosted Renovate)

**Repository permissions:**
- **Commit statuses**: Read & write
- **Contents**: Read & write
- **Dependabot alerts**: Read-only
- **Metadata**: Read-only (auto-selected)
- **Pull requests**: Read & write
- **Workflows**: Read & write

No organization or account permissions needed.

### 2. Generate a private key

On the App settings page, scroll to **Private keys** → **Generate a private key**.
Save the `.pem` file on the runner machine (e.g., `/home/cloud-user/renovate_github_private_key.pem`).

### 3. Install the App

Go to **Organization settings → Third-party Access → GitHub Apps** → install your
App on the organization. Select the repos Renovate should manage.

### 4. Get the IDs

- **App ID**: On the App settings page, shown at the top
- **Installation ID**: Go to **Organization settings → Third-party Access → GitHub Apps**
  → click **Configure** next to the app. The URL looks like:
  `https://github.com/organizations/YOUR_ORG/settings/installations/12345678`
  — the number at the end (`12345678`) is the Installation ID.

### 5. Configure the runner

Add to `~/.bash_profile` on the runner machine:

```bash
export RENOVATE_GITHUB_APP_ID=<your-app-id>
export RENOVATE_GITHUB_INSTALLATION_ID=<your-installation-id>
export RENOVATE_GITHUB_APP_KEY=/path/to/renovate_github_private_key.pem
```

### 6. Update the renovate script

The script generates an installation token from the App credentials, then
passes it to Renovate:

```bash
# Fetch installation token from GitHub App
RENOVATE_GITHUB_APP_TOKEN=$(podman run --rm \
  -v "${RENOVATE_GITHUB_APP_KEY}:/key.pem:ro,Z" \
  ghcr.io/mshekow/github-app-installation-token:latest \
  "${RENOVATE_GITHUB_APP_ID}" \
  "${RENOVATE_GITHUB_INSTALLATION_ID}" \
  "/key.pem")

# Run Renovate with the App token
podman run -e RENOVATE_TOKEN="${RENOVATE_GITHUB_APP_TOKEN}" \
  -e BINDATA_GIT_ADD=true -e LOG_LEVEL=debug --rm \
  localhost/renovate:local \
  --git-author="OpenStack K8s CI <openstack-k8s@redhat.com>" \
  --update-not-scheduled=false \
  --allowed-post-upgrade-commands="^make manifests generate,^make bindata,^make gowork,^go mod tidy,^make tidy,^make force-bump,^git reset" \
  <repo-list> 2>&1 | tee $log_file
```

The installation token expires after 1 hour. If the Renovate run takes
longer, regenerate the token before each run iteration.
