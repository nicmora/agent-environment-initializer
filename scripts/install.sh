#!/usr/bin/env bash
#
# Instala, actualiza o desinstala el agente envinit en un proyecto,
# para Claude Code u OpenCode.
#
# Uso:
#   scripts/install.sh --tool claude|opencode --target <ruta-del-proyecto> [--uninstall]
#
# Compatible con bash 3.2+ (macOS), Linux y Git Bash. Sin dependencias externas.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
AGENT_SRC=$(cd "$SCRIPT_DIR/.." && pwd)/agent

# Skills de la versión anterior, cuando el agente se llamaba env-initializer.
LEGACY_SKILLS="detect-environment plan-environment compose-builder native-setup service-recipes external-mocks verify-environment document-environment"

TOOL=""
TARGET=""
UNINSTALL=0
REMOVED_LEGACY=""
REMOVED_ANY=0

usage() {
  cat <<'EOF'
Instala el agente envinit en un proyecto.

Uso:
  install.sh --tool claude|opencode --target <ruta-del-proyecto> [--uninstall]

Opciones:
  --tool <herramienta>  claude (Claude Code) u opencode (OpenCode).
                        Si falta y la terminal es interactiva, se pregunta.
  --target <ruta>       Raíz del proyecto donde se instala. Debe existir.
  --uninstall           Quita el agente del proyecto en lugar de instalarlo.
  -h, --help            Muestra esta ayuda.

Ejemplos:
  scripts/install.sh --tool claude --target ~/proyectos/mi-app
  scripts/install.sh --tool opencode --target ~/proyectos/mi-app --uninstall
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

# Borra una ruta si existe. Devuelve 0 si borró algo.
remove_path() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    rm -rf "$1"
    REMOVED_ANY=1
    return 0
  fi
  return 1
}

remove_legacy() {
  if remove_path "$TOOL_DIR/env-initializer"; then
    REMOVED_LEGACY="$REMOVED_LEGACY  $TOOL_DIR_NAME/env-initializer/\n"
  fi
  if remove_path "$TOOL_DIR/agents/env-initializer.md"; then
    REMOVED_LEGACY="$REMOVED_LEGACY  $TOOL_DIR_NAME/agents/env-initializer.md\n"
  fi
  for skill in $LEGACY_SKILLS; do
    if remove_path "$TOOL_DIR/skills/$skill"; then
      REMOVED_LEGACY="$REMOVED_LEGACY  $TOOL_DIR_NAME/skills/$skill/\n"
    fi
  done
}

remove_current() {
  remove_path "$TOOL_DIR/envinit" || true
  remove_path "$TOOL_DIR/agents/envinit.md" || true
  for skill in "$TOOL_DIR"/skills/envinit-*; do
    remove_path "$skill" || true
  done
}

# --- Argumentos ---------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)
      [ $# -ge 2 ] || fail "falta el valor de --tool (claude u opencode)."
      TOOL=$2; shift 2 ;;
    --tool=*)
      TOOL=${1#--tool=}; shift ;;
    --target)
      [ $# -ge 2 ] || fail "falta el valor de --target (la ruta del proyecto)."
      TARGET=$2; shift 2 ;;
    --target=*)
      TARGET=${1#--target=}; shift ;;
    --uninstall)
      UNINSTALL=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      fail "opción desconocida: $1 (usa --help para ver las opciones)." ;;
  esac
done

# --- Validaciones (antes de escribir nada) ------------------------------------

[ -d "$AGENT_SRC" ] || fail "no se encontró la carpeta del agente en $AGENT_SRC."

[ -n "$TARGET" ] || fail "falta --target: indica la ruta del proyecto."
[ -d "$TARGET" ] || fail "el proyecto '$TARGET' no existe o no es una carpeta."
TARGET=$(cd "$TARGET" && pwd)

if [ -z "$TOOL" ]; then
  if [ -t 0 ]; then
    printf '¿Para qué herramienta?\n  1) claude    (Claude Code)\n  2) opencode  (OpenCode)\nElige 1 o 2: '
    read -r answer || answer=""
    case "$answer" in
      1|claude) TOOL=claude ;;
      2|opencode) TOOL=opencode ;;
      *) fail "opción no válida: '$answer'." ;;
    esac
  else
    fail "falta --tool: indica claude u opencode."
  fi
fi

case "$TOOL" in
  claude)   TOOL_DIR_NAME=.claude;   ADAPTER=claude-code ;;
  opencode) TOOL_DIR_NAME=.opencode; ADAPTER=opencode ;;
  *) fail "herramienta no válida: '$TOOL' (usa claude u opencode)." ;;
esac

TOOL_DIR="$TARGET/$TOOL_DIR_NAME"

# --- Desinstalar --------------------------------------------------------------

if [ "$UNINSTALL" -eq 1 ]; then
  remove_legacy
  remove_current
  echo
  if [ "$REMOVED_ANY" -eq 1 ]; then
    echo "Listo: se quitó el agente envinit."
  else
    echo "No había nada para quitar: el agente envinit no estaba instalado."
  fi
  echo "  Herramienta: $TOOL"
  echo "  Proyecto:    $TARGET"
  echo
  echo "La carpeta local/ del proyecto (tu entorno) no se tocó."
  exit 0
fi

# --- Instalar -----------------------------------------------------------------

remove_legacy
remove_current

mkdir -p "$TOOL_DIR/envinit" "$TOOL_DIR/agents" "$TOOL_DIR/skills"
cp "$AGENT_SRC/AGENT.md" "$TOOL_DIR/envinit/AGENT.md"
cp "$AGENT_SRC/adapters/$ADAPTER/envinit.md" "$TOOL_DIR/agents/envinit.md"
for skill in "$AGENT_SRC"/skills/envinit-*; do
  [ -d "$skill" ] && cp -R "$skill" "$TOOL_DIR/skills/"
done

echo
echo "Listo: se instaló el agente envinit."
echo "  Herramienta: $TOOL"
echo "  Proyecto:    $TARGET"
echo "  Archivos en: $TOOL_DIR"
if [ -n "$REMOVED_LEGACY" ]; then
  echo
  echo "Se quitó la versión anterior (env-initializer):"
  printf '%b' "$REMOVED_LEGACY"
fi
echo
if [ "$TOOL" = claude ]; then
  echo "Para usarlo: abre Claude Code en la raíz del proyecto y escribe @envinit."
else
  echo "Para usarlo: abre opencode en la raíz del proyecto y presiona Tab hasta que aparezca envinit."
fi
