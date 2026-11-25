#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

TMP_DIR=$(mktemp -d -t boz-validate-XXXXXX)
trap 'rm -rf "$TMP_DIR"; find "$REPO_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true' EXIT INT TERM

echo "================================================================"
echo "Bank of Z Comprehensive Local Verification Suite (.archon)"
echo "================================================================"

# ==============================================================================
# STAGE 1: COBOL Layout & Syntax Audit
# ==============================================================================
echo ""
echo "=== STAGE 1: COBOL Layout & Syntax Audit ==="

echo "--- 1.1: Running 80-column layout and copybook resolution audit ---"
python3 -B .archon/scripts/check_cobol_layout.py

echo "--- 1.2: Running cobc syntax check on IMS COBOL modules ---"
IMS_MODULES=(
    "src/base/ims/cobol/IBACSUM.cbl"
    "src/base/ims/cobol/IBGCUDAT.cbl"
    "src/base/ims/cobol/IBLOGOUT.cbl"
    "src/base/ims/cobol/IBSCUDAT.cbl"
    "src/base/ims/cobol/LOADACCT.cbl"
    "src/base/ims/cobol/LOADCUSA.cbl"
    "src/base/ims/cobol/LOADCUST.cbl"
    "src/base/ims/cobol/LOADHIST.cbl"
    "src/base/ims/cobol/LOADTSTA.cbl"
)

mkdir -p "$TMP_DIR/prep"
for ims_mod in "${IMS_MODULES[@]}"; do
    base_name="$(basename "$ims_mod")"
    prep_target="$TMP_DIR/prep/$base_name"
    echo "Checking syntax: $ims_mod"
    python3 -B .archon/scripts/cics_syntax_prep.py "$ims_mod" "$prep_target"
    cobc -fsyntax-only -std=ibm -I .archon/stubs/cpy -I src/base/cics/copy -I src/base/ims/copy "$prep_target"
done

echo "--- 1.3: Preprocessing and checking CICS COBOL modules ---"
mkdir -p "$TMP_DIR/prep"

CICS_MODULES=(
    "src/base/cics/cobol/BNK1CRA.cbl"
    "src/base/cics/cobol/BNK1TFN.cbl"
    "src/base/cics/cobol/CRECUST.cbl"
    "src/base/cics/cobol/ABNDPROC.cbl"
)

for cics_mod in "${CICS_MODULES[@]}"; do
    base_name="$(basename "$cics_mod")"
    prep_target="$TMP_DIR/prep/$base_name"
    echo "Preprocessing $cics_mod -> $prep_target"
    python3 -B .archon/scripts/cics_syntax_prep.py "$cics_mod" "$prep_target"
    echo "Checking syntax: $prep_target"
    cobc -fsyntax-only -std=ibm -I .archon/stubs/cpy -I src/base/cics/copy -I src/base/ims/copy "$prep_target"
done

echo "Stage 1 PASSED: All COBOL layout, IMS syntax, and preprocessed CICS syntax verified."

# ==============================================================================
# STAGE 2: COBOL Arithmetic & Precision Verification
# ==============================================================================
echo ""
echo "=== STAGE 2: COBOL Arithmetic & Precision Verification ==="
mkdir -p "$TMP_DIR/bin"

echo "Compiling test_decimal_precision..."
cobc -x -std=ibm -o "$TMP_DIR/bin/test_decimal_precision" .archon/tests/cobol/test_decimal_precision.cbl
echo "Executing test_decimal_precision..."
"$TMP_DIR/bin/test_decimal_precision"

echo "Compiling test_bounds_validation..."
cobc -x -std=ibm -o "$TMP_DIR/bin/test_bounds_validation" .archon/tests/cobol/test_bounds_validation.cbl
echo "Executing test_bounds_validation..."
"$TMP_DIR/bin/test_bounds_validation"

echo "Stage 2 PASSED: Arithmetic precision and bounds assertions verified."

# ==============================================================================
# STAGE 3: Resource & Configuration Schema Validation
# ==============================================================================
echo ""
echo "=== STAGE 3: Resource & Configuration Schema Validation ==="
python3 -B .archon/scripts/validate_yaml.py
echo "Stage 3 PASSED: All YAML files and CICS resource definition schemas verified."

# ==============================================================================
# STAGE 4: Db2 Template Unit Testing
# ==============================================================================
echo ""
echo "=== STAGE 4: Db2 Template Unit Testing ==="
python3 -B -m unittest discover tests
echo "Stage 4 PASSED: Native Db2 provisioning unit tests verified."

# ==============================================================================
# STAGE 5: Java & API Build (Conditional/Deferred)
# ==============================================================================
echo ""
echo "=== STAGE 5: Java & API Build (Conditional/Deferred) ==="
if command -v gradle >/dev/null 2>&1; then
    echo "Gradle detected. Executing Java and API builds..."
    gradle -p src/api build
    gradle -p src/base/ims/java build
    gradle -p src/base/mq/java build
    echo "Stage 5 PASSED: Java and API components built successfully."
else
    echo "[STAGE 5 SKIPPED: Gradle toolchain deferred]"
fi

# ==============================================================================
# STAGE 6: Repository Governance & DCO Audit
# ==============================================================================
echo ""
echo "=== STAGE 6: Repository Governance & DCO Audit ==="
DIRTY_ENTRIES="$(git status --porcelain)"
if [[ -n "$DIRTY_ENTRIES" ]]; then
    echo "ERROR: Repository working tree is dirty:" >&2
    echo "$DIRTY_ENTRIES" >&2
    exit 1
fi
echo "Working tree cleanliness audit: PASSED"

# Check DCO sign-offs on commits ahead of origin/main
REV_LIST=""
if git rev-parse --verify origin/main >/dev/null 2>&1; then
    REV_LIST="$(git rev-list --no-merges origin/main..HEAD 2>/dev/null || true)"
fi

if [[ -z "$REV_LIST" ]]; then
    PARENT_COUNT="$(git rev-list --parents -n 1 HEAD | awk '{print NF-1}')"
    if [[ "$PARENT_COUNT" -le 1 ]]; then
        REV_LIST="HEAD"
    fi
fi

if [[ -n "$REV_LIST" ]]; then
    for commit_hash in $REV_LIST; do
        if ! git log -1 --format=%B "$commit_hash" | grep -q "^Signed-off-by: "; then
            echo "ERROR: Commit $commit_hash is missing a Signed-off-by trailer." >&2
            exit 1
        fi
    done
    echo "DCO sign-off audit: PASSED"
else
    echo "DCO sign-off audit: No branch commits to audit."
fi

echo "Stage 6 PASSED: Repository governance and DCO verified."

echo ""
echo "================================================================"
echo "All validation stages PASSED successfully."
echo "================================================================"
