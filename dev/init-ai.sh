#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_CHECKS=0
CONFIG_FILE="config/models.yaml"

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}OK $1${NC}"
        return 0
    else
        echo -e "${RED}X $1${NC}"
        return 1
    fi
}

echo -e "${BLUE}Agentic Factory Initialization${NC}"
echo "========================================"
echo ""

echo -e "${BLUE}1. System Requirements${NC}"
echo ""

OS=$(uname -s)
echo "   OS: $OS"

if [[ "$OS" == "Linux" ]]; then
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
elif [[ "$OS" == "Darwin" ]]; then
    RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
else
    RAM_GB=32
fi

echo "   RAM: ${RAM_GB}GB"
if [ "$RAM_GB" -lt 16 ]; then
    echo -e "   ${YELLOW}W: ${RAM_GB}GB RAM - Recommended: 32GB${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
elif [ "$RAM_GB" -lt 32 ]; then
    echo -e "   ${YELLOW}W: ${RAM_GB}GB RAM (Ideal: 32GB)${NC}"
else
    echo -e "   ${GREEN}OK: ${RAM_GB}GB RAM${NC}"
fi

if [[ "$OS" == "Linux" ]] || [[ "$OS" == "Darwin" ]]; then
    DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//' 2>/dev/null || echo "100")
else
    DISK_GB=500
fi
echo "   Disk: ${DISK_GB}GB available"
if [ "$DISK_GB" -lt 50 ]; then
    echo -e "   ${RED}X: Only ${DISK_GB}GB - Recommended: 256GB${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
elif [ "$DISK_GB" -lt 256 ]; then
    echo -e "   ${YELLOW}W: ${DISK_GB}GB available (Ideal: 256GB+)${NC}"
else
    echo -e "   ${GREEN}OK: ${DISK_GB}GB${NC}"
fi

echo ""

echo -e "${BLUE}2. Ollama Installation${NC}"
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}X Ollama not found!${NC}"
    echo "   Install from https://ollama.ai"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    OLLAMA_VERSION=$(ollama --version)
    echo -e "${GREEN}OK Ollama: $OLLAMA_VERSION${NC}"
fi
echo ""

echo -e "${BLUE}3. Docker & Docker Compose${NC}"
if check_command docker; then
    DOCKER_VERSION=$(docker --version)
    echo "   $DOCKER_VERSION"
fi
if check_command docker-compose; then
    DC_VERSION=$(docker-compose --version)
    echo "   $DC_VERSION"
elif check_command docker; then
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}OK docker compose plugin${NC}"
    fi
fi
echo ""

echo -e "${BLUE}4. Python${NC}"
PYTHON_CMD=""
PYTHON_PATHS=("/c/Users/Michael/miniconda3/python" "python3" "python")
for py_path in "${PYTHON_PATHS[@]}"; do
    if command -v "$py_path" &> /dev/null; then
        PYTHON_VERSION_CHECK=$("$py_path" -c "import sys; print(sys.version_info.major)" 2>/dev/null)
        if [ "$PYTHON_VERSION_CHECK" = "3" ]; then
            PYTHON_CMD="$py_path"
            break
        fi
    fi
done

if [ -n "$PYTHON_CMD" ]; then
    PYTHON_VERSION=$($PYTHON_CMD --version)
    echo -e "${GREEN}OK $PYTHON_VERSION${NC}"
    echo "   Checking dependencies..."
    REQUIRED_PACKAGES=("requests" "python-dotenv" "pyyaml")
    MISSING_PACKAGES=()
    for package in "${REQUIRED_PACKAGES[@]}"; do
        IMPORT_NAME=${package//python-/}
        IMPORT_NAME=${IMPORT_NAME//-/_}
        if $PYTHON_CMD -c "import ${IMPORT_NAME}" 2>/dev/null; then
            echo -e "   ${GREEN}OK $package${NC}"
        else
            echo -e "   ${RED}X $package${NC}"
            MISSING_PACKAGES+=("$package")
        fi
    done
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Install missing: pip install -r requirements.txt${NC}"
    fi
else
    echo -e "${RED}X Python 3 not found${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

echo -e "${BLUE}5. Git${NC}"
if check_command git; then
    GIT_VERSION=$(git --version)
    echo "   $GIT_VERSION"
fi
echo ""

echo -e "${BLUE}6. Port Availability${NC}"
PORTS=("11434:Ollama" "8000:Plane-API" "8080:Plane-Web")
for PORT_INFO in "${PORTS[@]}"; do
    PORT=${PORT_INFO%%:*}
    NAME=${PORT_INFO##*:}
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "   ${YELLOW}W: Port $PORT ($NAME) in use${NC}"
    else
        echo -e "   ${GREEN}OK: Port $PORT ($NAME)${NC}"
    fi
done
echo ""

echo -e "${BLUE}7. Internet Connectivity${NC}"
if timeout 5 curl -s https://ollama.ai &>/dev/null || timeout 5 ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}OK Internet available${NC}"
else
    echo -e "${YELLOW}W: No internet (Cloud API needed)${NC}"
fi
echo ""

echo -e "${BLUE}8. Ollama Models${NC}"
echo ""

if [ -f "$CONFIG_FILE" ]; then
    MODELS=$($PYTHON_CMD -c "import yaml; print(' '.join(yaml.safe_load(open('$CONFIG_FILE'))['ollama_models']))" 2>/dev/null || echo "deepseek-coder:6.7b llama3:8b phi3:mini")
else
    echo -e "${YELLOW}W: Config not found, using defaults${NC}"
    MODELS="deepseek-coder:6.7b llama3:8b phi3:mini"
fi

MODELS_LOADED=0
for MODEL in $MODELS; do
    echo "   Checking $MODEL..."
    if ollama list | grep -q "$MODEL"; then
        echo -e "      ${GREEN}OK: $MODEL${NC}"
        MODELS_LOADED=$((MODELS_LOADED + 1))
    else
        echo -e "      ${YELLOW}Pulling $MODEL...${NC}"
        if ollama pull "$MODEL"; then
            echo -e "      ${GREEN}OK: $MODEL loaded${NC}"
            MODELS_LOADED=$((MODELS_LOADED + 1))
        else
            echo -e "      ${RED}X: $MODEL failed${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
    fi
done

echo ""

echo -e "${BLUE}9. GPU Verification${NC}"
echo ""
echo "   Testing phi3..."
if command -v timeout &> /dev/null; then
    timeout 10 ollama run phi3 "test" > /dev/null 2>&1 || true
else
    ollama run phi3 "test" > /dev/null 2>&1 &
    sleep 3
    pkill -f "ollama run phi3" 2>/dev/null || true
fi

sleep 2
GPU_OUTPUT=$(ollama ps 2>&1 || true)

if echo "$GPU_OUTPUT" | grep -q "100%"; then
    echo -e "   ${GREEN}OK: GPU at 100%${NC}"
elif echo "$GPU_OUTPUT" | grep -q "GPU"; then
    echo -e "   ${YELLOW}W: GPU partially used${NC}"
else
    echo -e "   ${YELLOW}W: GPU not used - CPU fallback${NC}"
fi

echo ""

echo -e "${BLUE}10. Cloud API Keys${NC}"
echo ""

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

FREE_PROVIDERS=("GEMINI_API_KEY:Google Gemini" "GROQ_API_KEY:Groq" "OPENROUTER_API_KEY:OpenRouter" "HF_API_KEY:HuggingFace")
CLOUD_PROVIDERS_AVAILABLE=0
for PROVIDER_INFO in "${FREE_PROVIDERS[@]}"; do
    VAR_NAME=${PROVIDER_INFO%%:*}
    DESC=${PROVIDER_INFO##*:}
    if [ -n "${!VAR_NAME}" ]; then
        echo -e "   ${GREEN}OK $VAR_NAME${NC}"
        CLOUD_PROVIDERS_AVAILABLE=$((CLOUD_PROVIDERS_AVAILABLE + 1))
    else
        echo -e "   ${YELLOW}X $VAR_NAME (optional)${NC}"
    fi
done

echo ""
echo "   Cloud providers: $CLOUD_PROVIDERS_AVAILABLE/4"

if [ -f "$CONFIG_FILE" ]; then
    echo ""
    echo "   Routing (from config):"
    $PYTHON_CMD -c "
import yaml
with open('$CONFIG_FILE') as f:
    cfg = yaml.safe_load(f)
    for role, spec in cfg['roles'].items():
        print(f'      {role}: {spec[\"provider\"]} -> {spec[\"model\"]}')" 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo -e "${BLUE}Summary${NC}"
echo "=========================================="

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}ALL CHECKS PASSED${NC}"
else
    echo -e "${YELLOW}$FAILED_CHECKS ISSUES FOUND${NC}"
fi

echo ""
echo "Ollama models: $MODELS_LOADED"
echo "RAM: ${RAM_GB}GB | Disk: ${DISK_GB}GB"

echo ""
echo -e "${BLUE}Next Steps:${NC}"
if [ ! -f .env ]; then
    echo "   1. cp .env.example .env"
    echo "   2. Edit .env with your API keys"
    echo ""
fi
if ! command -v docker &> /dev/null; then
    echo "   Docker (optional): https://docs.docker.com/get-docker/"
else
    echo "   Start Plane: docker-compose up -d"
fi
echo "   Test gatekeeper: python gatekeeper.py"
echo "   Feature branch: git checkout -b feature/my-feature"