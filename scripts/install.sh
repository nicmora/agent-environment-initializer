#!/usr/bin/env bash
#
# Instala, actualiza o desinstala el agente envinit en un proyecto,
# para Claude Code, OpenCode o ambos.
#
# Uso:
#   scripts/install.sh [--tool claude|opencode|claude,opencode] [--target <ruta>] [--uninstall]
#
# Si falta la ruta o la herramienta y la terminal es interactiva, se preguntan.
# Compatible con bash 3.2+ (macOS), Linux y Git Bash. Sin dependencias externas.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
AGENT_SRC=$REPO_ROOT/agent

# Skills de la versión anterior, cuando el agente se llamaba env-initializer.
LEGACY_SKILLS="detect-environment plan-environment compose-builder native-setup service-recipes external-mocks verify-environment document-environment"

TOOL_ARG=""
TARGET=""
UNINSTALL=0
ASKED=0
WANT_CLAUDE=0
WANT_OPENCODE=0
TOOLS=""
SUMMARY=""
NL='
'

usage() {
  cat <<'EOF'
Instala el agente envinit en un proyecto.

Uso:
  install.sh [--tool <herramientas>] [--target <ruta-del-proyecto>] [--uninstall]

Opciones:
  --tool <herramientas>  claude (Claude Code), opencode (OpenCode) o las dos
                         separadas por coma: claude,opencode.
                         Si falta y la terminal es interactiva, se muestra una
                         lista para marcarlas.
  --target <ruta>        Raíz del proyecto donde se instala. Debe existir.
                         Si falta y la terminal es interactiva, se pregunta.
  --uninstall            Quita el agente del proyecto en lugar de instalarlo.
  -h, --help             Muestra esta ayuda.

Si el script hace alguna pregunta, al final pide confirmación antes de
escribir. Con --tool y --target no pregunta nada.

Ejemplos:
  scripts/install.sh
  scripts/install.sh --tool claude --target ~/proyectos/mi-app
  scripts/install.sh --tool claude,opencode --target ~/proyectos/mi-app
  scripts/install.sh --tool opencode --target ~/proyectos/mi-app --uninstall
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

# Lee una línea de la terminal. Si la entrada se cierra, termina sin escribir nada.
ask() {
  printf '%s' "$1"
  read -r ANSWER || { echo; fail "se cerró la entrada antes de responder. No se hizo ningún cambio."; }
  ANSWER=$(trim "$ANSWER")
}

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

# Limpia una ruta pegada: comillas alrededor, ~ inicial y espacios escapados con \.
clean_path() {
  local p
  p=$(trim "$1")
  case "$p" in
    \"*\"|\'*\') p=${p#?}; p=${p%?} ;;
  esac
  case "$p" in
    "~") p=$HOME ;;
    "~/"*) p=$HOME/${p#"~/"} ;;
  esac
  case "$p" in
    [A-Za-z]:*) ;;  # ruta de Windows: la \ es el separador, no un escape
    *) p=$(printf '%s' "$p" | sed 's/\\\(.\)/\1/g') ;;
  esac
  printf '%s' "$p"
}

# Valida un destino. Si sirve, deja la ruta absoluta en TARGET_OK y devuelve 0;
# si no, deja el motivo en TARGET_ERROR y devuelve 1.
check_target() {
  TARGET_OK=""
  TARGET_ERROR=""
  if [ ! -e "$1" ]; then
    TARGET_ERROR="la carpeta '$1' no existe."
    return 1
  fi
  if [ ! -d "$1" ]; then
    TARGET_ERROR="'$1' no es una carpeta."
    return 1
  fi
  if [ "$(CDPATH= cd -- "$1" && pwd -P)" = "$REPO_ROOT" ]; then
    TARGET_ERROR="'$1' es el repositorio del agente. El agente se instala en otro proyecto, no en este repo."
    return 1
  fi
  TARGET_OK=$(CDPATH= cd -- "$1" && pwd)
}

ask_target() {
  echo
  while :; do
    ask "Ruta del proyecto (puedes pegarla): "
    if [ -z "$ANSWER" ]; then
      echo "  Escribe o pega la ruta del proyecto."
      continue
    fi
    if check_target "$(clean_path "$ANSWER")"; then
      TARGET=$TARGET_OK
      return
    fi
    echo "  No sirve: $TARGET_ERROR"
  done
}

mark() {
  if [ "$1" -eq 1 ]; then printf 'x'; else printf ' '; fi
}

ask_tools() {
  local verb=instalar
  [ "$UNINSTALL" -eq 0 ] || verb=quitar
  while :; do
    echo
    echo "¿Para qué herramientas quieres $verb envinit?"
    echo "  [$(mark "$WANT_CLAUDE")] 1) Claude Code"
    echo "  [$(mark "$WANT_OPENCODE")] 2) OpenCode"
    ask "Escribe un número para marcar o desmarcar, y Enter para continuar: "
    case "$ANSWER" in
      1) WANT_CLAUDE=$((1 - WANT_CLAUDE)) ;;
      2) WANT_OPENCODE=$((1 - WANT_OPENCODE)) ;;
      "")
        if [ "$WANT_CLAUDE" -eq 1 ] || [ "$WANT_OPENCODE" -eq 1 ]; then
          return
        fi
        echo "  Marca al menos una herramienta para continuar." ;;
      *) echo "  Opción no válida: '$ANSWER'. Escribe 1, 2 o solo Enter." ;;
    esac
  done
}

# Marca las herramientas de una lista separada por comas.
parse_tools() {
  local old_ifs=$IFS t
  set -f
  IFS=,
  for t in $1; do
    t=$(trim "$t")
    case "$t" in
      claude) WANT_CLAUDE=1 ;;
      opencode) WANT_OPENCODE=1 ;;
      "") ;;
      *) IFS=$old_ifs; fail "herramienta no válida: '$t' (usa claude, opencode o claude,opencode)." ;;
    esac
  done
  IFS=$old_ifs
  set +f
}

tool_label() {
  case "$1" in
    claude) printf 'Claude Code' ;;
    opencode) printf 'OpenCode' ;;
  esac
}

confirm() {
  local labels="" tool
  for tool in $TOOLS; do
    labels="${labels:+$labels, }$(tool_label "$tool")"
  done
  echo
  if [ "$UNINSTALL" -eq 1 ]; then
    echo "Voy a quitar el agente envinit de:"
  else
    echo "Voy a instalar el agente envinit en:"
  fi
  echo "  Proyecto:     $TARGET"
  echo "  Herramientas: $labels"
  while :; do
    ask "¿Continuar? (S/n): "
    case "$ANSWER" in
      ""|s|S|si|Si|SI|sí|Sí|SÍ|y|Y|yes|Yes|YES) return ;;
      n|N|no|No|NO)
        echo
        echo "No se hizo ningún cambio."
        exit 0 ;;
      *) echo "  Responde s (sí) o n (no)." ;;
    esac
  done
}

add_summary() {
  SUMMARY=$SUMMARY$1$NL
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
  local skill
  if remove_path "$TOOL_DIR/env-initializer"; then
    REMOVED_LEGACY="$REMOVED_LEGACY    $TOOL_DIR_NAME/env-initializer/$NL"
  fi
  if remove_path "$TOOL_DIR/agents/env-initializer.md"; then
    REMOVED_LEGACY="$REMOVED_LEGACY    $TOOL_DIR_NAME/agents/env-initializer.md$NL"
  fi
  for skill in $LEGACY_SKILLS; do
    if remove_path "$TOOL_DIR/skills/$skill"; then
      REMOVED_LEGACY="$REMOVED_LEGACY    $TOOL_DIR_NAME/skills/$skill/$NL"
    fi
  done
}

remove_current() {
  local skill
  remove_path "$TOOL_DIR/envinit" || true
  remove_path "$TOOL_DIR/agents/envinit.md" || true
  for skill in "$TOOL_DIR"/skills/envinit-*; do
    remove_path "$skill" || true
  done
}

# Instala o desinstala el agente para una herramienta y agrega su parte del resumen.
run_tool() {
  local tool=$1 skill
  case "$tool" in
    claude)   TOOL_DIR_NAME=.claude;   ADAPTER=claude-code ;;
    opencode) TOOL_DIR_NAME=.opencode; ADAPTER=opencode ;;
  esac
  TOOL_DIR=$TARGET/$TOOL_DIR_NAME
  REMOVED_LEGACY=""
  REMOVED_ANY=0

  add_summary ""
  add_summary "$(tool_label "$tool")"

  remove_legacy
  if [ "$UNINSTALL" -eq 1 ]; then
    remove_current
    if [ "$REMOVED_ANY" -eq 1 ]; then
      add_summary "  Se quitó el agente de $TOOL_DIR"
    else
      add_summary "  No había nada para quitar: el agente no estaba instalado."
    fi
    return
  fi

  remove_current
  mkdir -p "$TOOL_DIR/envinit" "$TOOL_DIR/agents" "$TOOL_DIR/skills"
  cp "$AGENT_SRC/AGENT.md" "$TOOL_DIR/envinit/AGENT.md"
  cp "$AGENT_SRC/adapters/$ADAPTER/envinit.md" "$TOOL_DIR/agents/envinit.md"
  for skill in "$AGENT_SRC"/skills/envinit-*; do
    [ -d "$skill" ] && cp -R "$skill" "$TOOL_DIR/skills/"
  done

  add_summary "  Archivos en: $TOOL_DIR"
  if [ -n "$REMOVED_LEGACY" ]; then
    add_summary "  Se quitó la versión anterior (env-initializer):"
    SUMMARY=$SUMMARY$REMOVED_LEGACY
  fi
  if [ "$tool" = claude ]; then
    add_summary "  Para usarlo: abre Claude Code en la raíz del proyecto y escribe @envinit."
  else
    add_summary "  Para usarlo: abre opencode en la raíz del proyecto y presiona Tab hasta que aparezca envinit."
  fi
}

# --- Argumentos ---------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)
      [ $# -ge 2 ] || fail "falta el valor de --tool (claude, opencode o claude,opencode)."
      TOOL_ARG=$2; shift 2 ;;
    --tool=*)
      TOOL_ARG=${1#--tool=}; shift ;;
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

# --- Validaciones y preguntas (antes de escribir nada) -------------------------

[ -d "$AGENT_SRC" ] || fail "no se encontró la carpeta del agente en $AGENT_SRC."

[ -z "$TOOL_ARG" ] || parse_tools "$TOOL_ARG"

if [ -n "$TARGET" ]; then
  if ! check_target "$TARGET"; then
    case "$TARGET_ERROR" in
      *repositorio*) fail "$TARGET_ERROR" ;;
      *) fail "el proyecto '$TARGET' no existe o no es una carpeta." ;;
    esac
  fi
  TARGET=$TARGET_OK
elif [ -t 0 ]; then
  ask_target
  ASKED=1
else
  fail "falta --target: indica la ruta del proyecto."
fi

if [ "$WANT_CLAUDE" -eq 0 ] && [ "$WANT_OPENCODE" -eq 0 ]; then
  if [ -t 0 ]; then
    ask_tools
    ASKED=1
  else
    fail "falta --tool: indica claude, opencode o claude,opencode."
  fi
fi

if [ "$WANT_CLAUDE" -eq 1 ]; then TOOLS="claude"; fi
if [ "$WANT_OPENCODE" -eq 1 ]; then TOOLS="${TOOLS:+$TOOLS }opencode"; fi

if [ "$ASKED" -eq 1 ]; then
  confirm
fi

# --- Instalar o desinstalar ---------------------------------------------------

for tool in $TOOLS; do
  run_tool "$tool"
done

echo
if [ "$UNINSTALL" -eq 1 ]; then
  echo "Listo: terminó la desinstalación del agente envinit."
else
  echo "Listo: se instaló el agente envinit."
fi
echo "  Proyecto: $TARGET"
printf '%s' "$SUMMARY"
if [ "$UNINSTALL" -eq 1 ]; then
  echo
  echo "La carpeta env-local/ del proyecto (tu entorno) no se tocó."
fi
