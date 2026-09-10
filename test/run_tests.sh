#!/bin/bash
# Move to project root
cd "$(dirname "$0")/.." || exit 1

echo "=== Splendor Test Suite ==="
echo ""

# Handle arguments
COVERAGE=""
VERBOSE=()
CATEGORY=""
SPECIFIC_CLASS=""
EXCLUDE_PACKAGES=()
INCLUDE_NETWORK=""

require_value() {
    if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
        echo "Missing value for $1" >&2
        exit 2
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --coverage) COVERAGE="true" ;;
        --verbose) VERBOSE=(--details verbose) ;;
        --category) require_value "$@"; CATEGORY="$2"; shift ;;
        --class) require_value "$@"; SPECIFIC_CLASS="$2"; shift ;;
        --exclude-package) require_value "$@"; EXCLUDE_PACKAGES+=("$2"); shift ;;
        --include-network) INCLUDE_NETWORK="true" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Compile main sources first
echo "1. Compiling main sources..."
mkdir -p classes
javac --release 17 -encoding UTF-8 -d classes -sourcepath src \
  src/com/splendor/*.java \
  src/com/splendor/config/*.java \
  src/com/splendor/controller/*.java \
  src/com/splendor/data/*.java \
  src/com/splendor/exception/*.java \
  src/com/splendor/model/*.java \
  src/com/splendor/model/validator/*.java \
  src/com/splendor/network/*.java \
  src/com/splendor/util/*.java \
  src/com/splendor/view/*.java

if [ $? -ne 0 ]; then
    echo "ERROR: Main source compilation failed!"
    exit 1
fi
echo "   Main sources compiled OK."

# Copy resources
cp -r src/resources/* classes/ 2>/dev/null || true

# Compile test sources
echo "2. Compiling test sources..."
mkdir -p test-classes

# Find all test Java files
TEST_FILES=()
while IFS= read -r -d '' file; do
    if [[ -n "$INCLUDE_NETWORK" || "$file" != test/com/splendor/network/* ]]; then
        TEST_FILES+=("$file")
    fi
done < <(find test -name '*.java' -print0)
if [ -z "$INCLUDE_NETWORK" ]; then
    echo "   Network tests excluded from compilation. Use --include-network to include them."
fi
if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo "   No test files found in test/"
    exit 1
fi

# Unix classpath separator
CP_SEP=":"

javac --release 17 -encoding UTF-8 -d test-classes \
  -cp "classes${CP_SEP}lib/junit-platform-console-standalone-1.10.2.jar" \
  -sourcepath test \
  "${TEST_FILES[@]}"

if [ $? -ne 0 ]; then
    echo "ERROR: Test compilation failed!"
    exit 1
fi
echo "   Test sources compiled OK."

# Run tests
echo "3. Running tests..."
echo ""

JUNIT_CMD=(java -jar lib/junit-platform-console-standalone-1.10.2.jar execute --class-path "test-classes${CP_SEP}classes" --fail-if-no-tests)

JUNIT_CMD+=("${VERBOSE[@]}")

if [ -n "$SPECIFIC_CLASS" ]; then
    JUNIT_CMD+=(--select-class "$SPECIFIC_CLASS")
elif [ -n "$CATEGORY" ]; then
    # Assuming category maps to a package or naming convention
    JUNIT_CMD+=(--select-package "$CATEGORY")
else
    JUNIT_CMD+=(--scan-class-path test-classes)
fi

for pkg in "${EXCLUDE_PACKAGES[@]}"; do
    JUNIT_CMD+=(--exclude-package "$pkg")
done

# Network integration tests are opt-in to keep local and CI-like runs deterministic.
if [ -z "$INCLUDE_NETWORK" ]; then
    JUNIT_CMD+=(--exclude-package com.splendor.network)
fi

# Add coverage if requested (requires jacoco agent in lib/ which may not exist, so mock it for the script)
if [ -n "$COVERAGE" ]; then
    echo "[Note: Coverage requires JaCoCo agent which might not be configured. Proceeding with standard run.]"
fi

"${JUNIT_CMD[@]}"
JUNIT_EXIT=$?

if [ $JUNIT_EXIT -ne 0 ]; then
    echo ""
    echo "ERROR: One or more tests failed."
    exit $JUNIT_EXIT
fi

echo ""
echo "=== Test run complete ==="
