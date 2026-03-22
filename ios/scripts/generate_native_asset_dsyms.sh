#!/bin/sh

set -eu

FRAMEWORK_NAME="objective_c.framework"
FRAMEWORK_BINARY_NAME="objective_c"
FRAMEWORK_PATH="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/${FRAMEWORK_NAME}"
BINARY_PATH="${FRAMEWORK_PATH}/${FRAMEWORK_BINARY_NAME}"
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${FRAMEWORK_NAME}.dSYM"

if [ ! -f "${BINARY_PATH}" ]; then
  exit 0
fi

if ! command -v dsymutil >/dev/null 2>&1; then
  echo "warning: dsymutil not found; skipping dSYM generation for ${FRAMEWORK_NAME}"
  exit 0
fi

mkdir -p "${DWARF_DSYM_FOLDER_PATH}"

echo "Generating dSYM for ${FRAMEWORK_NAME}"
rm -rf "${DSYM_PATH}"
dsymutil "${BINARY_PATH}" -o "${DSYM_PATH}"
