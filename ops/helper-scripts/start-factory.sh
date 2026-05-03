#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Agentic Software Factory${NC}"
echo "========================================"
echo ""

echo -e "${BLUE}1. Pre-flight checks${NC}"

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}X Docker not running. Start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}OK Docker running${NC}"

if [ ! -f ../sec/.env ]; then
    echo -e "${YELLOW}W: sec/.env not found. Copy from .env.example${NC}"
    if [ -f ../sec/.env.example ]; then
        cp ../sec/.env.example ../sec/.env
        echo -e "${YELLOW}Edit sec/.env with your values${NC}"
    fi
fi

if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${GREEN}OK Ollama running${NC}"
else
    echo -e "${YELLOW}W Ollama not running. Starting...${NC}"
    if command -v ollama > /dev/null 2>&1; then
        ollama serve > /dev/null 2>&1 &
        sleep 3
        echo -e "${GREEN}OK Ollama started${NC}"
    else
        echo -e "${RED}X Ollama not installed.${NC}"
        exit 1
    fi
fi

echo ""

echo -e "${BLUE}2. Starting infrastructure${NC}"
docker-compose --env-file ../sec/.env up -d
echo -e "${GREEN}OK Docker services started${NC}"
echo ""

echo -e "${BLUE}3. Waiting for services${NC}"

echo "   Plane Database..."
timeout=60
counter=0
while ! docker-compose exec -T plane-db pg_isready -U plane > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}X Plane Database failed${NC}"
        exit 1
    fi
    sleep 1
    counter=$((counter + 1))
done
echo -e "   ${GREEN}OK Plane Database${NC}"

echo "   Plane API..."
timeout=120
counter=0
while ! curl -s http://localhost:8000/api/v1/ > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}X Plane API failed${NC}"
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
done
echo -e "   ${GREEN}OK Plane API${NC}"

echo "   Jenkins..."
timeout=180
counter=0
while ! curl -s http://localhost:8081/login > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}X Jenkins failed${NC}"
        exit 1
    fi
    sleep 3
    counter=$((counter + 3))
done
echo -e "   ${GREEN}OK Jenkins${NC}"

echo ""

echo -e "${BLUE}4. Agent Team Status${NC}"
CONFIG_FILE="config/models.yaml"
if [ -f "$CONFIG_FILE" ]; then
    python3 -c "
import yaml
with open('$CONFIG_FILE') as f:
    cfg = yaml.safe_load(f)
    print('   Role          Provider   Model')
    print('   ' + '-' * 40)
    for role, spec in cfg['roles'].items():
        print(f'   {role:14} {spec[\"provider\"]:10} {spec[\"model\"]}')" 2>/dev/null || echo "   Config parsing failed"
else
    echo -e "   ${YELLOW}W: config/models.yaml not found${NC}"
fi

echo ""

echo -e "${GREEN}Agentic Software Factory is OPERATIONAL${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo "   Plane (Project Management): http://localhost:8080"
echo "   Jenkins (CI/CD):            http://localhost:8081"
echo "   Prometheus:                 http://localhost:9090"
echo "   Grafana:                    http://localhost:3000"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "   1. Visit Plane to create your first project"
echo "   2. Test agent team: python gatekeeper.py"
echo "   3. Create a feature branch"