#!/usr/bin/env bash
set -Eeuo pipefail

# Clear everything set by the project
project_deactivate
# or: homelab_deactivate

# Clear env.sh run  indicator
hl_clear_activation