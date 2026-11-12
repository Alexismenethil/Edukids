class_name InstallResponse
extends RefCounted
## Resultado de instalar un paquete: instalado, actualizado o sin cambios (ya estaba).

const INSTALLED := &"installed"
const UPDATED := &"updated"
const UNCHANGED := &"unchanged"

var package_id := ""
var title := ""
var version := ""
var previous_version := ""
var outcome: StringName = INSTALLED
var level_count := 0
