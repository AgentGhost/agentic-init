#!/bin/bash

# ==========================================
# init-ai.sh - Agentic Factory Initialization
# ==========================================
# Dieses Script initialisiert die lokale AI-Infrastruktur:
# 1. Prüft ob Ollama installiert ist
# 2. Pullt die notwendigen Modelle
# 3. Verifiziert GPU-Unterstützung
# ==========================================

set -e

echo "🚀 Agentic Factory Initialization Script"
echo "=========================================="
echo ""

# ==========================================
# 1. OLLAMA CHECK
# ==========================================
echo "1️⃣  Prüfe Ollama Installation..."

if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama nicht gefunden!"
    echo "   Installiere Ollama von https://ollama.ai"
    exit 1
fi

OLLAMA_VERSION=$(ollama --version)
echo "✅ Ollama gefunden: $OLLAMA_VERSION"
echo ""

# ==========================================
# 2. MODELLE PULLEN
# ==========================================
echo "2️⃣  Pullen notwendiger Modelle..."
echo ""

# Array der Modelle
MODELS=(
    "qwen2.5-coder:14b"
    "llama3.1:8b"
    "phi3:mini"
)

for MODEL in "${MODELS[@]}"; do
    echo "   📥 Prüfe $MODEL..."
    if ollama list | grep -q "$MODEL"; then
        echo "      ✅ $MODEL bereits vorhanden"
    else
        echo "      ⏳ Lade $MODEL... (kann mehrere Minuten dauern)"
        ollama pull "$MODEL"
        echo "      ✅ $MODEL erfolgreich geladen"
    fi
done

echo ""

# ==========================================
# 3. GPU-VERIFIZIERUNG
# ==========================================
echo "3️⃣  Verifiziere GPU-Unterstützung..."
echo ""

echo "   ⏳ Starte phi3 Test..."
timeout 10 ollama run phi3 "test" > /dev/null 2>&1 || true

sleep 2

echo "   📊 GPU Status:"
GPU_OUTPUT=$(ollama ps 2>&1 || true)

if echo "$GPU_OUTPUT" | grep -q "100%"; then
    echo "   ✅ GPU wird zu 100% genutzt (Excellent!)"
elif echo "$GPU_OUTPUT" | grep -q "GPU"; then
    echo "   ⚠️  GPU wird teilweise genutzt"
else
    echo "   ⚠️  GPU wird NICHT genutzt - Fallback auf CPU"
    echo "   💡 Tipps:"
    echo "      - Prüfe ob Ollama mit GPU-Support kompiliert wurde"
    echo "      - Unter Windows/AMD: Erwäge LM Studio mit Vulkan-Backend"
    echo "      - Unter Linux: Prüfe ROCm Installation"
fi

echo ""
echo "=========================================="
echo "✅ Initialisierung abgeschlossen!"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. git init"
echo "   2. Erstelle .gitignore"
echo "   3. Erstelle .env mit API Keys"
echo "   4. Starte Plane via docker-compose up"
echo "   5. Starte gatekeeper.py"
echo ""
