#@icon("res://assets/icons/seal_symbol.svg")
# scripts/seal/seal_symbol.gd
class_name SEALSymbol
extends Resource


## --- Symbol specification ---------------------------------------------------
## Grid is always square. 3 ≤ grid_size ≤ 8.
## mirror_type matches the 7 mirroring modes
enum MirrorType  {
	HORIZONTAL,
	VERTICAL,
	CROSS,
	DIAGONAL_TL_BR,
	DIAGONAL_TR_BL,
	CROSS_DIAGONAL,
	SPIRAL
}

@export var grid_size : int = 3 : set = _set_grid_size
@export var mirror_type     : MirrorType   = MirrorType.HORIZONTAL
@export var pattern_bits    : PackedByteArray   # raw unique-rows as bits
## Lazily-updated cache of the packed 16-bit value used for RGBA encoding
var _cached_gb : int = -1

func _set_grid_size(v:int) -> void:
	grid_size = clamp(v, 3, 8)
	_cached_gb = -1

## ---------------------------------------------------------------------------
## Convenience constructor
## Factory method that generates a *new* SEALSymbol with random pattern bits.
## Arguments
##   size   – desired grid size   (3 ≤ size ≤ 8)
##   mirror – one of the 7 MirrorType enum values
## Returns
##   A fully-initialised SEALSymbol resource.
static func create_random(size := 3, mirror := MirrorType.HORIZONTAL) -> SEALSymbol:
	var s := SEALSymbol.new()          # allocate the resource instance

	# ---- Basic metadata ----------------------------------------------------
	s.grid_size   = size               # setter clamps to [3,8]
	s.mirror_type = mirror

	# ---- Determine how many *unique* rows we must store --------------------
	# Horizontal and “cross” mirroring duplicate the lower half of the grid,
	# so we only need ⌈size/2⌉ distinct rows.  All other mirror modes require
	# each row to be unique.
	var row_count : int = (
		ceil(float(size) / 2.0)
		if mirror in [MirrorType.HORIZONTAL, MirrorType.CROSS]
		else size
	)

	# ---- Populate the pattern_bits byte-array ------------------------------
	# Each byte encodes one row: the least-significant `size` bits correspond
	# to the on/off state of each cell in that row.
	for i in range(row_count):
		var random_row : int = randi_range(0, (1 << size) - 1)
		s.pattern_bits.append(random_row)

	return s



## --- Encoding helpers ------------------------------------------------------
## Combine the unique row bits into one integer then normalise to 16-bit space
func to_gb() -> int:
	if _cached_gb >= 0:
		return _cached_gb
	var total_bits := 0
	for b in pattern_bits:
		total_bits = (total_bits << grid_size) | b
	var max_val := (1 << (grid_size * pattern_bits.size())) - 1
	_cached_gb = round(float(total_bits) / float(max_val) * 65535.0)
	return _cached_gb

func to_rgba() -> Color:
	var r := (mirror_type << 3) | (grid_size - 3)        # 5 bits packed in R
	var gb := to_gb()
	var g := (gb >> 8) & 0xFF
	var b := gb & 0xFF
	return Color8(r, g, b, 255)

func _to_string() -> String:
	var mirror_names := [
		"HORIZONTAL", "VERTICAL", "CROSS",
		"DIAGONAL_TL_BR", "DIAGONAL_TR_BL",
		"CROSS_DIAGONAL", "SPIRAL"
	]
	return "SEALSymbol(size=%d, mirror=%s, bits=%s)" % [
		grid_size,
		mirror_names[int(mirror_type)],
		pattern_bits
	]



## --- Mutation --------------------------------------------------------------
func mutate(chance:=0.1) -> void:
	if randf() > chance:
		return
	var idx := randi_range(0, pattern_bits.size() - 1)
	var bit  := randi_range(0, grid_size - 1)
	pattern_bits[idx] ^= 1 << bit
	_cached_gb = -1
