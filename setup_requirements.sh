#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")" || exit 1

echo "🔧 Splendor environment requirements check (Unix)"
echo

JUNIT_JAR="lib/junit-platform-console-standalone-1.10.2.jar"
JUNIT_URL="https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.2/junit-platform-console-standalone-1.10.2.jar"
PLANTUML_JAR="docs/diagrams/plantuml.jar"
PLANTUML_URL="https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar"

check_cmd() {
  local cmd="$1"
  local label="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "✅ $label: $(command -v "$cmd")"
  else
    echo "❌ $label: missing"
    MISSING=1
  fi
}

MISSING=0

check_cmd java "Java runtime"
check_cmd javac "Java compiler"
check_cmd javadoc "Javadoc tool"
check_cmd node "Node.js"
check_cmd npm "npm"
check_cmd python3 "Python 3"
check_cmd pip3 "pip3"
check_cmd dot "Graphviz dot (for PlantUML PNG rendering)"

if [ -d node_modules ] && [ -f node_modules/.bin/mmdc ]; then
  echo "✅ Mermaid CLI (local): node_modules/.bin/mmdc"
else
  echo "ℹ️ Installing Node.js dependencies (Mermaid CLI)..."
  npm install
fi

if [ -f "$JUNIT_JAR" ]; then
  echo "✅ JUnit console jar: $JUNIT_JAR"
else
  echo "ℹ️ Downloading JUnit console jar..."
  mkdir -p lib
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$JUNIT_URL" -o "$JUNIT_JAR"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$JUNIT_JAR" "$JUNIT_URL"
  else
    echo "❌ Unable to download JUnit jar: curl or wget is required"
    MISSING=1
  fi
fi

if [ -f "$PLANTUML_JAR" ]; then
  echo "✅ PlantUML jar: $PLANTUML_JAR"
else
  echo "ℹ️ Downloading PlantUML jar..."
  mkdir -p docs/diagrams
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$PLANTUML_URL" -o "$PLANTUML_JAR"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$PLANTUML_JAR" "$PLANTUML_URL"
  else
    echo "❌ Unable to download PlantUML jar: curl or wget is required"
    MISSING=1
  fi
fi

if [ ! -f "$JUNIT_JAR" ]; then
  echo "❌ JUnit console jar: missing at $JUNIT_JAR"
  MISSING=1
fi

if [ ! -f "$PLANTUML_JAR" ]; then
  echo "❌ PlantUML jar: missing at $PLANTUML_JAR"
  MISSING=1
fi

echo
if [ "$MISSING" -eq 0 ]; then
  echo "🎉 All required tooling is present."
  exit 0
fi

echo "Some dependencies are missing."
echo "Install guidance:"
echo "  - Ubuntu/Debian: sudo apt-get install openjdk-17-jdk nodejs npm python3 python3-pip graphviz"
echo "  - macOS (Homebrew): brew install openjdk@17 node python graphviz"
echo "  - Re-run ./setup_requirements.sh after installing system packages"
exit 1
