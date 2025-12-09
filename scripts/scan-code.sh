#!/bin/bash

# ==============================================================================
# Tarea T-12: SAST Engine (Static Application Security Testing)
# Herramienta: Semgrep (OSS)
# Propósito: Orquestar el análisis de código estático con reglas personalizadas
# ==============================================================================

# --- Configuración Visual ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Detección Dinámica de Rutas ---
# Obtiene la ruta absoluta donde está guardado ESTE script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Busca el ruleset.yml relativo a la ubicación del script
if [ -f "$SCRIPT_DIR/ruleset.yml" ]; then
    RULES_FILE="$SCRIPT_DIR/ruleset.yml"
elif [ -f "$SCRIPT_DIR/scripts/sast/ruleset.yml" ]; then
    RULES_FILE="$SCRIPT_DIR/scripts/sast/ruleset.yml"
else
    RULES_FILE="ruleset.yml" # Último intento en el directorio actual de ejecución
fi

REPORT_DIR="./reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
JSON_REPORT="$REPORT_DIR/sast_report_$TIMESTAMP.json"
VENV_DIR="$SCRIPT_DIR/.venv_sast"  # El entorno virtual se crea junto al script

# --- Funciones de Logging ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# --- 1. Verificación del Entorno ---
log_info "Iniciando Motor SAST..."
log_info "Buscando reglas en: $RULES_FILE"

# Verificar si el archivo de reglas existe antes de seguir
if [ ! -f "$RULES_FILE" ]; then
    log_error "No se encuentra 'ruleset.yml'. Asegúrate de que esté en la misma carpeta que este script."
    exit 1
fi

mkdir -p "$REPORT_DIR"

# Lógica de Semgrep / Entorno Virtual
if command -v semgrep &> /dev/null; then
    SEMGREP_CMD="semgrep"
    log_info "Semgrep global detectado."
else
    if [ ! -f "$VENV_DIR/bin/semgrep" ]; then
        log_warn "Creando entorno virtual en $VENV_DIR..."
        python3 -m venv "$VENV_DIR" || { log_error "Fallo al crear venv. Instala 'python3-venv'."; exit 1; }

        log_info "Instalando Semgrep..."
        "$VENV_DIR/bin/pip" install semgrep
    fi
    SEMGREP_CMD="$VENV_DIR/bin/semgrep"
fi

# --- 2. Ejecución del Análisis ---
log_info "Escaneando código..."


$SEMGREP_CMD scan \
    --config "$RULES_FILE" \
    --json \
    --output "$JSON_REPORT" \
    --no-git-ignore \
    .

SCAN_STATUS=$?

if [ $SCAN_STATUS -ne 0 ]; then
    log_error "Error al ejecutar Semgrep."
    exit 1
fi

# --- 3. Resultados ---
COUNT=0
if command -v jq &> /dev/null; then
    COUNT=$(jq '.results | length' "$JSON_REPORT")
else
    COUNT=$(grep -o '"check_id":' "$JSON_REPORT" | wc -l)
fi

echo ""
if [ "$COUNT" -gt 0 ]; then
    log_error " FALLO DE SEGURIDAD: Se detectaron $COUNT vulnerabilidades."
    echo -e "${YELLOW}--- Detalle Rápido ---${NC}"
    $SEMGREP_CMD scan --config "$RULES_FILE" --error --quiet
    exit 1
else
    log_success " Código Limpio."
    exit 0
fi
