#!/usr/bin/env bash
# Verifica la regla de dependencias de Clean Architecture en el juego (RNF-15, CA-20).
#
# 1. Busca en cada capa las API prohibidas (nodos, archivos, red, SQLite, reloj y azar del motor).
# 2. Comprueba que ninguna capa nombre clases de una capa que no le corresponde,
#    usando los class_name declarados en cada carpeta.
#
# Uso: bash tests/architecture/check_dependencies.sh   (desde android/ o desde la raíz del repo)
# Compatible con el bash 3.2 de macOS.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2

DOMAIN="src/domain"
APPLICATION="src/application"
INFRASTRUCTURE="src/infrastructure"
PRESENTATION="src/presentation"
MAIN="src/main"
SCENES="scenes"

violations=0

# Imprime las líneas de código (sin comentarios) de los .gd de una carpeta que cumplen un patrón.
search() {
	local pattern="$1" folder="$2" file
	[ -d "$folder" ] || return 0
	find "$folder" -name '*.gd' -type f | sort | while read -r file; do
		sed 's/#.*//' "$file" | grep -nE "$pattern" | sed "s|^|    $file:|"
	done
}

check_pattern() {
	local description="$1" pattern="$2" hits=""
	shift 2
	local folder
	for folder in "$@"; do
		hits="$hits$(search "$pattern" "$folder")"
	done
	if [ -n "$hits" ]; then
		echo "✗ $description"
		echo "$hits"
		violations=$((violations + 1))
	else
		echo "✓ $description"
	fi
}

# Lista los class_name declarados en una carpeta, separados por "|".
class_names() {
	local folder="$1"
	[ -d "$folder" ] || return 0
	grep -rhoE 'class_name[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' --include='*.gd' "$folder" \
		| awk '{print $2}' | sort -u | paste -sd '|' -
}

check_layer() {
	local description="$1" folder="$2"
	shift 2
	local names="" forbidden
	for forbidden in "$@"; do
		local found
		found="$(class_names "$forbidden")"
		if [ -n "$found" ]; then
			names="${names:+$names|}$found"
		fi
	done
	if [ -z "$names" ]; then
		echo "✓ $description"
		return
	fi
	check_pattern "$description" "(^|[^A-Za-z0-9_])($names)([^A-Za-z0-9_]|$)" "$folder"
}

echo "Regla de dependencias de EduKids"
echo

echo "API prohibidas"
check_pattern "Dominio y aplicación no usan nodos ni escenas" \
	'extends[[:space:]]+(Node|Control|CanvasItem|Resource)|get_tree\(|get_node\(|PackedScene|instantiate\(' \
	"$DOMAIN" "$APPLICATION"
check_pattern "Dominio y aplicación no usan archivos, red ni SQLite" \
	'FileAccess|DirAccess|HTTPRequest|HTTPClient|SQLite|ResourceLoader|ProjectSettings' \
	"$DOMAIN" "$APPLICATION"
check_pattern "Dominio y aplicación usan los puertos Clock y RandomSource" \
	'Time\.|OS\.|randi\(|randf\(|randi_range\(|randf_range\(|RandomNumberGenerator' \
	"$DOMAIN" "$APPLICATION"
check_pattern "Dominio y aplicación no cargan rutas de capas externas" \
	'res://(scenes|src/infrastructure|src/presentation|src/main)/' \
	"$DOMAIN" "$APPLICATION"
check_pattern "Los presentadores no usan nodos, archivos, red ni SQLite" \
	'extends[[:space:]]+(Node|Control|CanvasItem)|get_tree\(|FileAccess|DirAccess|HTTPRequest|SQLite' \
	"$PRESENTATION"
check_pattern "Nadie fuera de main/ usa la raíz de composición" \
	'CompositionRoot' \
	"$DOMAIN" "$APPLICATION" "$INFRASTRUCTURE" "$PRESENTATION" "$SCENES"
check_pattern "Las vistas no usan archivos, red ni SQLite" \
	'FileAccess|DirAccess|HTTPRequest|SQLite' \
	"$SCENES"
echo

echo "Clases por capa"
check_layer "El dominio no conoce otras capas" "$DOMAIN" \
	"$APPLICATION" "$INFRASTRUCTURE" "$PRESENTATION" "$MAIN" "$SCENES"
check_layer "La aplicación solo conoce el dominio" "$APPLICATION" \
	"$INFRASTRUCTURE" "$PRESENTATION" "$MAIN" "$SCENES"
check_layer "La infraestructura no conoce presentadores ni vistas" "$INFRASTRUCTURE" \
	"$PRESENTATION" "$MAIN" "$SCENES"
check_layer "Los presentadores no conocen la infraestructura ni las vistas" "$PRESENTATION" \
	"$INFRASTRUCTURE" "$MAIN" "$SCENES"
check_layer "Las vistas solo conocen presentadores y modelos de vista" "$SCENES" \
	"$DOMAIN" "$APPLICATION" "$INFRASTRUCTURE" "$MAIN"
echo

if [ "$violations" -gt 0 ]; then
	echo "Se encontraron $violations reglas incumplidas."
	exit 1
fi
echo "Todas las capas respetan la regla de dependencias."
