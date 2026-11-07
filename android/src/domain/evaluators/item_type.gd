class_name ItemType
extends RefCounted
## Identificadores de los tipos de ítem del formato de paquete v1.
## Los de prioridad P2 y P3 (respuesta breve, tocar en la imagen, ¿tiene sentido? y simulación)
## se agregan con su evaluador y su vista, sin tocar la sesión del nivel.

const MULTIPLE_CHOICE := &"multiple_choice"
const MULTI_SELECT := &"multi_select"
const TRUE_FALSE := &"true_false"
const ORDERING := &"ordering"
const MATCHING := &"matching"
const CLASSIFICATION := &"classification"
const FILL_BLANK := &"fill_blank"
const NUMERIC := &"numeric"
const READING_UNIT := &"reading_unit"
