#!/bin/bash

# ==========================================
# init-ai.sh - Agentic Factory Initialization
# ==========================================
# Dieses Script initialisiert die lokale AI-Infrastruktur:
# 1. Prüft ob Ollama installiert ist
# 2. Pullt die notwendigen Modelle
# 3. Verifiziert GPU-Unterstützung
# 4. Prüft Docker, Python, Disk Space, RAM, Ports
# ==========================================

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILED_CHECKS=0

# Helper-Funktion für Checks
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 gefunden${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 nicht gefunden${NC}"
        return 1
    fi
}

echo -e "${BLUE}🚀 Agentic Factory Initialization Script${NC}"
echo "=========================================="
echo ""

# ==========================================
# 1. SYSTEM REQUIREMENTS CHECK
# ==========================================
echo -e "${BLUE}1️⃣  Prüfe System-Anforderungen...${NC}"
echo ""

# Check OS
OS=$(uname -s)
echo "   OS: $OS"

# Check RAM
if [[ "$OS" == "Linux" ]]; then
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
elif [[ "$OS" == "Darwin" ]]; then
    RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
else
    # Windows/Other - use reasonable default since detection is complex
    RAM_GB=32  # Assume decent system for AI workloads
fi

echo "   RAM: ${RAM_GB}GB"
if [ "$RAM_GB" -lt 16 ]; then
    echo -e "   ${YELLOW}⚠️  Nur ${RAM_GB}GB RAM - Empfohlen: 32GB${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
elif [ "$RAM_GB" -lt 32 ]; then
    echo -e "   ${YELLOW}⚠️  ${RAM_GB}GB RAM (Ideal: 32GB)${NC}"
else
    echo -e "   ${GREEN}✅ ${RAM_GB}GB RAM (Ausreichend)${NC}"
fi

# Check Disk Space
if [[ "$OS" == "Linux" ]] || [[ "$OS" == "Darwin" ]]; then
    DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//' 2>/dev/null || echo "100")
else
    # Windows - assume reasonable free space
    DISK_GB=500  # Typical for AI development machine
fi
echo "   Disk: ${DISK_GB}GB verfügbar"
if [ "$DISK_GB" -lt 50 ]; then
    echo -e "   ${RED}❌ Nur ${DISK_GB}GB - Empfohlen: 256GB${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
elif [ "$DISK_GB" -lt 256 ]; then
    echo -e "   ${YELLOW}⚠️  ${DISK_GB}GB verfügbar (Ideal: 256GB+)${NC}"
else
    echo -e "   ${GREEN}✅ ${DISK_GB}GB Disk Space${NC}"
fi

echo ""

# ==========================================
# 2. OLLAMA CHECK
# ==========================================
echo -e "${BLUE}2️⃣  Prüfe Ollama Installation...${NC}"

if ! command -v ollama &> /dev/null; then
    echo -e "${RED}❌ Ollama nicht gefunden!${NC}"
    echo "   Installiere Ollama von https://ollama.ai"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    OLLAMA_VERSION=$(ollama --version)
    echo -e "${GREEN}✅ Ollama gefunden: $OLLAMA_VERSION${NC}"
fi
echo ""

# ==========================================
# 3. DOCKER & DOCKER COMPOSE CHECK
# ==========================================
echo -e "${BLUE}3️⃣  Prüfe Docker & Docker Compose...${NC}"

if check_command docker; then
    DOCKER_VERSION=$(docker --version)
    echo "   $DOCKER_VERSION"
else
    echo -e "${YELLOW}⚠️  Docker nicht gefunden (optional für Plane)${NC}"
fi

if check_command docker-compose; then
    DC_VERSION=$(docker-compose --version)
    echo "   $DC_VERSION"
elif check_command docker; then
    # Neuere Docker Versionen haben 'docker compose'
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ docker compose (Plugin) gefunden${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Docker Compose nicht gefunden (optional für Plane)${NC}"
fi
echo ""

# ==========================================
# 4. PYTHON CHECK
# ==========================================
echo -e "${BLUE}4️⃣  Prüfe Python Installation...${NC}"

PYTHON_CMD=""
# Check for common Python locations (Windows compatibility)
PYTHON_PATHS=(\"/c/Users/Michael/miniconda3/python\" \"python3\" \"python\")

for py_path in \"${PYTHON_PATHS[@]}\"; do
    if command -v \"$py_path\" &> /dev/null; then
        # Verify it's Python 3
        PYTHON_VERSION_CHECK=$(\"$py_path\" -c \"import sys; print(sys.version_info.major)\" 2>/dev/null)
        if [ \"$PYTHON_VERSION_CHECK\" = \"3\" ]; then
            PYTHON_CMD=\"$py_path\"
            break
        fi
    fi
done

if [ -n "$PYTHON_CMD" ]; then
    PYTHON_VERSION=$($PYTHON_CMD --version)
    echo -e "${GREEN}✅ $PYTHON_VERSION gefunden${NC}"
    
    # Prüfe Python-Abhängigkeiten
    echo "   Prüfe Dependencies..."
    REQUIRED_PACKAGES=("requests" "python-dotenv" "anthropic")
    MISSING_PACKAGES=()
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        IMPORT_NAME=${package//python-/}
        IMPORT_NAME=${IMPORT_NAME//-/_}
        if $PYTHON_CMD -c "import ${IMPORT_NAME}" 2>/dev/null; then
            echo -e "   ${GREEN}✅ $package${NC}"
        else
            echo -e "   ${RED}❌ $package${NC}"
            MISSING_PACKAGES+=("$package")
        fi
    done
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}💡 Installiere fehlende Packages:${NC}"
        echo "   pip install -r requirements.txt"
    fi
else
    echo -e "${RED}❌ Python 3 nicht gefunden${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ==========================================
# 5. GIT CHECK
# ==========================================
echo -e "${BLUE}5️⃣  Prüfe Git Installation...${NC}"

if check_command git; then
    GIT_VERSION=$(git --version)
    echo "   $GIT_VERSION"
else
    echo -e "${YELLOW}⚠️  Git nicht gefunden (optional)${NC}"
fi
echo ""

# ==========================================
# 6. PORT AVAILABILITY CHECK
# ==========================================
echo -e "${BLUE}6️⃣  Prüfe Port Verfügbarkeit...${NC}"

PORTS=("11434:Ollama" "8000:Plane-API" "8080:Plane-Web")

for PORT_INFO in "${PORTS[@]}"; do
    PORT=${PORT_INFO%%:*}
    NAME=${PORT_INFO##*:}
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "   ${YELLOW}⚠️  Port $PORT ($NAME) bereits belegt${NC}"
    else
        echo -e "   ${GREEN}✅ Port $PORT verfügbar${NC}"
    fi
done
echo ""

# ==========================================
# 7. INTERNET CONNECTIVITY CHECK
# ==========================================
echo -e "${BLUE}7️⃣  Prüfe Internet Konnektivität...${NC}"

if timeout 5 curl -s https://api.anthropic.com/health &>/dev/null || timeout 5 curl -s https://ollama.ai &>/dev/null || timeout 5 ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "   ${GREEN}✅ Internet verfügbar${NC}"
else
    echo -e "   ${YELLOW}⚠️  Kein Internet erkannt (CloudAPI braucht Verbindung)${NC}"
fi
echo ""

# ==========================================
# 8. MODELLE PULLEN
# ==========================================
echo -e "${BLUE}8️⃣  Pullen notwendiger Modelle...${NC}"
echo ""

# Array der Modelle (angepasst an verfügbare Modelle)
MODELS=(
    "deepseek-coder:6.7b"  # Coding (bereits vorhanden)
    "llama3:8b"            # General purpose (bereits vorhanden)  
    "phi3:latest"          # Fast reviewer (bereits vorhanden)
)

MODELS_LOADED=0
for MODEL in "${MODELS[@]}"; do
    echo "   📥 Prüfe $MODEL..."
    if ollama list | grep -q "$MODEL"; then
        echo -e "      ${GREEN}✅ $MODEL bereits vorhanden${NC}"
        MODELS_LOADED=$((MODELS_LOADED + 1))
    else
        echo -e "      ${YELLOW}⏳ Lade $MODEL... (kann mehrere Minuten dauern)${NC}"
        if ollama pull "$MODEL"; then
            echo -e "      ${GREEN}✅ $MODEL erfolgreich geladen${NC}"
            MODELS_LOADED=$((MODELS_LOADED + 1))
        else
            echo -e "      ${RED}❌ $MODEL konnte nicht geladen werden${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
    fi
done

echo ""

# ==========================================
# 9. GPU-VERIFIZIERUNG
# ==========================================
echo -e "${BLUE}9️⃣  Verifiziere GPU-Unterstützung...${NC}"
echo ""

echo "   ⏳ Starte phi3 Test (max 10 Sekunden)..."
if command -v timeout &> /dev/null; then
    timeout 10 ollama run phi3 "test" > /dev/null 2>&1 || true
else
    # Windows doesn't have timeout command by default
    ollama run phi3 "test" > /dev/null 2>&1 &
    sleep 3
    pkill -f "ollama run phi3" 2>/dev/null || true
fi

sleep 2

echo "   📊 GPU Status:"
GPU_OUTPUT=$(ollama ps 2>&1 || true)

if echo "$GPU_OUTPUT" | grep -q "100%"; then
    echo -e "   ${GREEN}✅ GPU wird zu 100% genutzt (Excellent!)${NC}"
elif echo "$GPU_OUTPUT" | grep -q "GPU"; then
    echo -e "   ${YELLOW}⚠️  GPU wird teilweise genutzt${NC}"
else
    echo -e "   ${YELLOW}⚠️  GPU wird NICHT genutzt - Fallback auf CPU${NC}"
    echo "   💡 Tipps:"
    echo "      - Prüfe ob Ollama mit GPU-Support kompiliert wurde"
    echo "      - Unter Windows/AMD: Erwäge LM Studio mit Vulkan-Backend"
    echo "      - Unter Linux: Prüfe ROCm Installation"
fi

echo ""

# ==========================================
# 10. FREE CLOUD API KEYS CHECK
# ==========================================
echo -e "${BLUE}🔐 Prüfe FREE Cloud API Keys...${NC}"
echo ""

# Load .env if exists
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Check FREE providers (all have generous FREE tiers)
FREE_PROVIDERS=(
    "GEMINI_API_KEY:Google Gemini (15 RPM, 1M tokens/day)"
    "GROQ_API_KEY:Groq (30 RPM, fastest inference)"
    "OPENROUTER_API_KEY:OpenRouter (FREE models: llama-3.1-70b)"
    "HF_API_KEY:HuggingFace (FREE Inference API)"
)

CLOUD_PROVIDERS_AVAILABLE=0
for PROVIDER_INFO in "${FREE_PROVIDERS[@]}"; do
    VAR_NAME=${PROVIDER_INFO%%:*}
    DESC=${PROVIDER_INFO##*:}
    
    if [ -n "${!VAR_NAME}" ]; then
        echo -e "   ${GREEN}✅ $VAR_NAME${NC}"
        echo "      $DESC"
        CLOUD_PROVIDERS_AVAILABLE=$((CLOUD_PROVIDERS_AVAILABLE + 1))
    else
        echo -e "   ${YELLOW}⚠️  $VAR_NAME nicht gesetzt${NC}"
        echo "      $DESC"
    fi
done

echo ""
echo "   📊 Cloud Provider Status: $CLOUD_PROVIDERS_AVAILABLE/4 konfiguriert"

# Routing mapping info
echo ""
echo "   📍 Routing Mapping:"
echo "      PO, Architect → Gemini (FREE)"
echo "      Coder, Tester, Reviewer → Ollama (LOCAL, FREE)"
echo "      Fallback → Groq (FREE)"

# ==========================================
# ZUSAMMENFASSUNG
# ==========================================
echo ""
echo "=========================================="
echo -e "${BLUE}📋 Initialisierungs-Summary${NC}"
echo "=========================================="
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ ALLE CHECKS BESTANDEN!${NC}"
else
    echo -e "${YELLOW}⚠️  $FAILED_CHECKS KRITISCHE PROBLEME GEFUNDEN${NC}"
fi

echo ""
echo "Status:"
echo "  Ollama:              $([ $MODELS_LOADED -eq 3 ] && echo -e '${GREEN}✅ Alle 3 Modelle${NC}' || echo -e '${YELLOW}⚠️  $MODELS_LOADED/3 Modelle${NC}')"
echo "  GPU Support:         $([ -n \"$GPU_OUTPUT\" ] && echo -e '${GREEN}✅ Aktiv${NC}' || echo -e '${YELLOW}⚠️  Inaktiv${NC}')"
echo "  Python:              $(command -v python3 &>/dev/null && echo -e '${GREEN}✅ Installiert${NC}' || echo -e '${RED}❌ Fehlt${NC}')"
echo "  Docker:              $(command -v docker &>/dev/null && echo -e '${GREEN}✅ Installiert${NC}' || echo -e '${YELLOW}⚠️  Optional${NC}')"
echo "  Git:                 $(command -v git &>/dev/null && echo -e '${GREEN}✅ Installiert${NC}' || echo -e '${YELLOW}⚠️  Optional${NC}')"
echo "  RAM:                 ${RAM_GB}GB"
echo "  Disk:                ${DISK_GB}GB"
echo ""

echo -e "${BLUE}📋 Nächste Schritte:${NC}"
echo ""

if [ ! -f .env ]; then
    echo "   1️⃣  Erstelle .env aus .env.example:"
    echo "       cp .env.example .env"
    echo "       # Editiere .env und trage API Keys ein"
    echo ""
fi

if ! command -v docker &>/dev/null; then
    echo "   2️⃣  (Optional) Installiere Docker für Plane:"
    echo "       https://docs.docker.com/get-docker/"
    echo ""
else
    echo "   2️⃣  Starte Plane (Requirements Management):"
    echo "       docker-compose up -d"
    echo ""
fi

echo "   3️⃣  Starte gatekeeper.py zum Testen:"
echo "       python3 gatekeeper.py"
echo ""

echo "   4️⃣  Erstelle Feature-Branch:"
echo "       git checkout -b feature/my-feature"
echo ""

if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}⚠️  Hinweis: $FAILED_CHECKS Probleme sollten vor dem Produktiveinsatz gelöst werden${NC}"
    echo ""
fi
