#!/bin/sh

set -e

APP_FRAMEWORKS_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks"

if [ ! -d "${APP_FRAMEWORKS_DIR}" ]; then
  exit 0
fi

if [ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
  exit 0
fi

if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ] || [ "${CODE_SIGNING_REQUIRED:-YES}" = "NO" ]; then
  exit 0
fi

find "${APP_FRAMEWORKS_DIR}" -maxdepth 1 -type d -name "*.framework" | while IFS= read -r framework; do
  signature_info="$(/usr/bin/codesign -dv --verbose=4 "${framework}" 2>&1 || true)"

  if ! printf '%s\n' "${signature_info}" | /usr/bin/grep -q "Signature=adhoc"; then
    continue
  fi

  echo "Re-signing adhoc embedded framework: ${framework}"
  code_sign_cmd="/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} ${OTHER_CODE_SIGN_FLAGS:-} --preserve-metadata=identifier,entitlements \"${framework}\""
  eval "${code_sign_cmd}"
done
