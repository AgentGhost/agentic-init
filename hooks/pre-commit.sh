#!/bin/bash
# .git/hooks/pre-commit
# ==========================================
# Pre-Commit Hook - AI-unterstützte Code Quality
# ==========================================
# Dieser Hook führt aus, bevor ein Commit gespeichert wird:
# 1. Basis-Checks (Syntax, Linting)
# 2. Optionales AI-Review via lokales Modell (phi3)
#
# Zu installieren mit:
#   cp hooks/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
# ==========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Pre-Commit Hook: Starte Checks...${NC}"
echo ""

# ==========================================
# 1. GIT DIFF ERFASSEN
# ==========================================
DIFF=$(git diff --cached)
DIFF_FILES=$(git diff --cached --name-only)

echo -e "${GREEN}📝 Zu committende Dateien:${NC}"
echo "$DIFF_FILES"
echo ""

# ==========================================
# 2. BASIS-CHECKS
# ==========================================
echo -e "${YELLOW}✓ Führe Basis-Checks aus...${NC}"

# Prüfe auf Debug-Statements (Python)
if echo "$DIFF_FILES" | grep -E "\.py$" > /dev/null; then
    if git diff --cached | grep -E "^\+.*\b(print|console\.log|debugger)\b" > /dev/null; then
        echo -e "${RED}❌ Debug-Statements gefunden! (print, console.log, debugger)${NC}"
        exit 1
    fi
fi

# Prüfe auf TODO/FIXME Comments ohne Kontext
if git diff --cached | grep -E "^\+.*\b(TODO|FIXME)\b" > /dev/null; then
    echo -e "${YELLOW}⚠️  TODO/FIXME gefunden - bitte überprüfen${NC}"
fi

echo -e "${GREEN}✅ Basis-Checks erfolgreich${NC}"
echo ""

# ==========================================
# 3. OPTIONAL: AI-REVIEW (phi3)
# ==========================================
echo -e "${YELLOW}🤖 Starte optionales AI-Review (phi3)...${NC}"

# Prüfe ob Ollama läuft
if ! command -v ollama &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ollama nicht gefunden - überspringe AI-Review${NC}"
else
    # Versuche phi3 Review (mit Timeout)
    REVIEW_PROMPT="Review this code diff for quality, security and style issues. Be concise:\n\n$DIFF"
    
    if timeout 30 ollama run phi3 "$REVIEW_PROMPT" > /tmp/review.txt 2>&1; then
        echo -e "${GREEN}✅ AI-Review abgeschlossen:${NC}"
        head -20 /tmp/review.txt
        if [ $(wc -l < /tmp/review.txt) -gt 20 ]; then
            echo "... (gekürzt)"
        fi
    else
        echo -e "${YELLOW}⚠️  AI-Review Timeout - überspringe${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Pre-Commit Hook erfolgreich!${NC}"
exit 0
