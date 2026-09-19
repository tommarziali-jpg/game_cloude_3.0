extends RefCounted
class_name IconGenerator

## Generates small procedural pixel-art icons (sword/bow/spear/dagger/mace/
## claws/potion bottles) entirely in code, so the Merchant shop can show
## real weapon/potion silhouettes without needing any external art files.
## Icons are tinted by rarity/potion color for quick visual read.

static func make_icon(kind: String, tint: Color, size: int = 40) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		"sword": _draw_sword(img, size, tint)
		"bow": _draw_bow(img, size, tint)
		"spear": _draw_spear(img, size, tint)
		"dagger": _draw_dagger(img, size, tint)
		"mace": _draw_mace(img, size, tint)
		"claws": _draw_claws(img, size, tint)
		"potion_heal": _draw_potion(img, size, Color(0.9, 0.2, 0.25))
		"potion_str": _draw_potion(img, size, Color(0.85, 0.35, 0.15))
		"potion_speed": _draw_potion(img, size, Color(0.3, 0.85, 0.95))
		"potion_fortitude": _draw_potion(img, size, Color(0.9, 0.8, 0.2))
		"potion_shield": _draw_shield(img, size, Color(0.4, 0.7, 1.0))
		"potion_shard": _draw_shard(img, size, Color(0.75, 0.45, 1.0))
		"card_fire": _draw_card(img, size, Color(0.95, 0.45, 0.1), "flame")
		"card_storm": _draw_card(img, size, Color(0.3, 0.75, 0.95), "bolt")
		"card_frost": _draw_card(img, size, Color(0.55, 0.85, 0.95), "snowflake")
		"card_shadow": _draw_card(img, size, Color(0.4, 0.2, 0.55), "moon")
		"card_nature": _draw_card(img, size, Color(0.35, 0.8, 0.4), "leaf")
		"card_void": _draw_card(img, size, Color(0.55, 0.1, 0.65), "eye")
		"card_corrupted": _draw_card(img, size, Color(0.75, 0.15, 0.25), "crack")
		"card_astral": _draw_card(img, size, Color(0.65, 0.35, 1.0), "star")
		"card_major": _draw_card(img, size, Color(1.0, 0.75, 0.2), "gem")
		"artifact_common": _draw_gem(img, size, Color(0.75, 0.75, 0.75))
		"artifact_rare": _draw_gem(img, size, Color(0.3, 0.55, 1.0))
		"artifact_legendary": _draw_gem(img, size, Color(1.0, 0.65, 0.15))
		_: _draw_sword(img, size, tint)
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------- HELPERS

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

static func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(min(y0, y1), max(y0, y1) + 1):
		for x in range(min(x0, x1), max(x0, x1) + 1):
			_px(img, x, y, c)

static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color, thickness: int = 1) -> void:
	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x := x0
	var y := y0
	var half := int(thickness / 2)
	while true:
		_rect(img, x - half, y - half, x + half, y + half, c)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

static func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if Vector2(x - cx, y - cy).length() <= r:
				_px(img, x, y, c)

static func _outline_rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	_line(img, x0, y0, x1, y0, c)
	_line(img, x0, y1, x1, y1, c)
	_line(img, x0, y0, x0, y1, c)
	_line(img, x1, y0, x1, y1, c)

# --------------------------------------------------------------------- ICONS

static func _draw_sword(img: Image, s: int, tint: Color) -> void:
	var blade := Color(0.85, 0.87, 0.9, 1)
	_line(img, s * 0.5, s * 0.08, s * 0.5, s * 0.62, blade, 4)
	_line(img, s * 0.5, s * 0.08, s * 0.5, s * 0.62, tint, 2)
	_line(img, s * 0.3, s * 0.62, s * 0.7, s * 0.62, Color(0.5, 0.4, 0.25), 4)
	_line(img, s * 0.5, s * 0.62, s * 0.5, s * 0.85, Color(0.35, 0.25, 0.15), 5)
	_circle(img, s * 0.5, s * 0.88, s * 0.05, Color(0.7, 0.6, 0.3))

static func _draw_bow(img: Image, s: int, tint: Color) -> void:
	var cx := s * 0.35
	var steps := 16
	var prev := Vector2(cx, s * 0.1)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var y: float = lerp(s * 0.1, s * 0.9, t)
		var bulge: float = sin(t * PI) * s * 0.22
		var p := Vector2(cx + bulge, y)
		_line(img, prev.x, prev.y, p.x, p.y, tint, 3)
		prev = p
	_line(img, cx, s * 0.1, cx, s * 0.9, Color(0.9, 0.9, 0.85), 1)
	_line(img, cx, s * 0.48, cx + s * 0.32, s * 0.5, Color(0.8, 0.7, 0.5), 2)

static func _draw_spear(img: Image, s: int, tint: Color) -> void:
	_line(img, s * 0.2, s * 0.85, s * 0.75, s * 0.15, Color(0.5, 0.35, 0.2), 3)
	_line(img, s * 0.6, s * 0.28, s * 0.75, s * 0.15, tint, 5)
	_line(img, s * 0.68, s * 0.35, s * 0.85, s * 0.05, tint, 3)
	_line(img, s * 0.52, s * 0.2, s * 0.75, s * 0.15, tint, 3)

static func _draw_dagger(img: Image, s: int, tint: Color) -> void:
	_line(img, s * 0.5, s * 0.15, s * 0.5, s * 0.55, Color(0.85, 0.87, 0.9), 5)
	_line(img, s * 0.5, s * 0.15, s * 0.5, s * 0.55, tint, 2)
	_line(img, s * 0.36, s * 0.55, s * 0.64, s * 0.55, Color(0.4, 0.3, 0.2), 3)
	_line(img, s * 0.5, s * 0.55, s * 0.5, s * 0.75, Color(0.3, 0.2, 0.12), 4)

static func _draw_mace(img: Image, s: int, tint: Color) -> void:
	_line(img, s * 0.5, s * 0.35, s * 0.5, s * 0.85, Color(0.4, 0.3, 0.2), 4)
	_circle(img, s * 0.5, s * 0.22, s * 0.16, tint)
	_circle(img, s * 0.5, s * 0.22, s * 0.16, Color(0, 0, 0, 0.0))
	for i in range(8):
		var a: float = TAU * i / 8.0
		var p := Vector2(s * 0.5, s * 0.22) + Vector2(cos(a), sin(a)) * s * 0.2
		_circle(img, p.x, p.y, s * 0.03, Color(0.6, 0.6, 0.65))

static func _draw_claws(img: Image, s: int, tint: Color) -> void:
	for i in range(3):
		var ox: float = s * (0.28 + i * 0.22)
		_line(img, ox, s * 0.75, ox + s * 0.08, s * 0.15, tint, 3)

static func _draw_potion(img: Image, s: int, liquid: Color) -> void:
	_rect(img, s * 0.42, s * 0.08, s * 0.58, s * 0.22, Color(0.6, 0.55, 0.5))
	_outline_rect(img, s * 0.28, s * 0.32, s * 0.72, s * 0.85, Color(0.75, 0.8, 0.85, 0.9))
	_rect(img, s * 0.3, s * 0.4, s * 0.7, s * 0.83, liquid)
	_line(img, s * 0.3, s * 0.5, s * 0.7, s * 0.5, Color(1, 1, 1, 0.35), 1)

static func _draw_shield(img: Image, s: int, color: Color) -> void:
	_line(img, s * 0.5, s * 0.12, s * 0.82, s * 0.24, color, 3)
	_line(img, s * 0.82, s * 0.24, s * 0.82, s * 0.5, color, 3)
	_line(img, s * 0.82, s * 0.5, s * 0.5, s * 0.86, color, 3)
	_line(img, s * 0.5, s * 0.86, s * 0.18, s * 0.5, color, 3)
	_line(img, s * 0.18, s * 0.5, s * 0.18, s * 0.24, color, 3)
	_line(img, s * 0.18, s * 0.24, s * 0.5, s * 0.12, color, 3)
	_line(img, s * 0.5, s * 0.28, s * 0.5, s * 0.64, Color(1, 1, 1, 0.7), 2)

static func _draw_shard(img: Image, s: int, color: Color) -> void:
	_line(img, s * 0.5, s * 0.1, s * 0.75, s * 0.45, color, 3)
	_line(img, s * 0.75, s * 0.45, s * 0.5, s * 0.9, color, 3)
	_line(img, s * 0.5, s * 0.9, s * 0.25, s * 0.45, color, 3)
	_line(img, s * 0.25, s * 0.45, s * 0.5, s * 0.1, color, 3)
	_line(img, s * 0.5, s * 0.1, s * 0.5, s * 0.9, Color(1, 1, 1, 0.5), 1)

static func _draw_gem(img: Image, s: int, color: Color) -> void:
	_line(img, s * 0.5, s * 0.15, s * 0.85, s * 0.4, color, 3)
	_line(img, s * 0.85, s * 0.4, s * 0.65, s * 0.85, color, 3)
	_line(img, s * 0.65, s * 0.85, s * 0.35, s * 0.85, color, 3)
	_line(img, s * 0.35, s * 0.85, s * 0.15, s * 0.4, color, 3)
	_line(img, s * 0.15, s * 0.4, s * 0.5, s * 0.15, color, 3)
	_line(img, s * 0.5, s * 0.15, s * 0.35, s * 0.4, Color(1, 1, 1, 0.5), 1)
	_line(img, s * 0.5, s * 0.15, s * 0.65, s * 0.4, Color(1, 1, 1, 0.5), 1)
	_line(img, s * 0.35, s * 0.4, s * 0.65, s * 0.4, Color(1, 1, 1, 0.4), 1)

# ---------------------------------------------------------------- CARD FRAME

static func _draw_card(img: Image, s: int, symbol_color: Color, symbol: String) -> void:
	var border := Color(0.85, 0.82, 0.9, 0.9)
	_outline_rect(img, s * 0.14, s * 0.06, s * 0.86, s * 0.94, border)
	_outline_rect(img, s * 0.2, s * 0.12, s * 0.8, s * 0.88, Color(border.r, border.g, border.b, 0.4))
	match symbol:
		"flame": _symbol_flame(img, s, symbol_color)
		"bolt": _symbol_bolt(img, s, symbol_color)
		"snowflake": _symbol_snowflake(img, s, symbol_color)
		"moon": _symbol_moon(img, s, symbol_color)
		"leaf": _symbol_leaf(img, s, symbol_color)
		"eye": _symbol_eye(img, s, symbol_color)
		"crack": _symbol_crack(img, s, symbol_color)
		"star": _symbol_star(img, s, symbol_color)
		"gem": _symbol_gem(img, s, symbol_color)

static func _symbol_flame(img: Image, s: int, c: Color) -> void:
	_line(img, s * 0.5, s * 0.78, s * 0.35, s * 0.55, c, 3)
	_line(img, s * 0.35, s * 0.55, s * 0.45, s * 0.32, c, 3)
	_line(img, s * 0.45, s * 0.32, s * 0.5, s * 0.22, c, 3)
	_line(img, s * 0.5, s * 0.22, s * 0.58, s * 0.4, c, 3)
	_line(img, s * 0.58, s * 0.4, s * 0.65, s * 0.55, c, 3)
	_line(img, s * 0.65, s * 0.55, s * 0.5, s * 0.78, c, 3)
	_circle(img, s * 0.5, s * 0.62, s * 0.06, Color(1, 0.9, 0.6, 0.8))

static func _symbol_bolt(img: Image, s: int, c: Color) -> void:
	_line(img, s * 0.58, s * 0.2, s * 0.38, s * 0.52, c, 4)
	_line(img, s * 0.38, s * 0.52, s * 0.55, s * 0.52, c, 4)
	_line(img, s * 0.55, s * 0.52, s * 0.4, s * 0.82, c, 4)

static func _symbol_snowflake(img: Image, s: int, c: Color) -> void:
	var center := Vector2(s * 0.5, s * 0.5)
	for i in range(6):
		var a: float = TAU * i / 6.0
		var p: Vector2 = center + Vector2(cos(a), sin(a)) * s * 0.28
		_line(img, center.x, center.y, p.x, p.y, c, 2)

static func _symbol_moon(img: Image, s: int, c: Color) -> void:
	_circle(img, s * 0.52, s * 0.5, s * 0.22, c)
	_circle(img, s * 0.62, s * 0.44, s * 0.2, Color(0, 0, 0, 0))

static func _symbol_leaf(img: Image, s: int, c: Color) -> void:
	_line(img, s * 0.5, s * 0.22, s * 0.7, s * 0.5, c, 3)
	_line(img, s * 0.7, s * 0.5, s * 0.5, s * 0.78, c, 3)
	_line(img, s * 0.5, s * 0.78, s * 0.3, s * 0.5, c, 3)
	_line(img, s * 0.3, s * 0.5, s * 0.5, s * 0.22, c, 3)
	_line(img, s * 0.5, s * 0.25, s * 0.5, s * 0.75, c, 2)

static func _symbol_eye(img: Image, s: int, c: Color) -> void:
	_circle(img, s * 0.5, s * 0.5, s * 0.22, c)
	_circle(img, s * 0.5, s * 0.5, s * 0.08, Color(0.05, 0.02, 0.08, 1))

static func _symbol_crack(img: Image, s: int, c: Color) -> void:
	_line(img, s * 0.3, s * 0.2, s * 0.5, s * 0.42, c, 3)
	_line(img, s * 0.5, s * 0.42, s * 0.38, s * 0.55, c, 3)
	_line(img, s * 0.38, s * 0.55, s * 0.62, s * 0.78, c, 3)
	_line(img, s * 0.5, s * 0.42, s * 0.68, s * 0.32, c, 2)

static func _symbol_star(img: Image, s: int, c: Color) -> void:
	var center := Vector2(s * 0.5, s * 0.5)
	var pts: Array = []
	for i in range(5):
		var a: float = -PI / 2.0 + TAU * i / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * s * 0.3)
	for i in range(5):
		var a : Vector2 = pts[i]
		var b: Vector2 = pts[(i + 2) % 5]
		_line(img, a.x, a.y, b.x, b.y, c, 2)

static func _symbol_gem(img: Image, s: int, c: Color) -> void:
	_line(img, s * 0.5, s * 0.22, s * 0.72, s * 0.42, c, 3)
	_line(img, s * 0.72, s * 0.42, s * 0.58, s * 0.78, c, 3)
	_line(img, s * 0.58, s * 0.78, s * 0.42, s * 0.78, c, 3)
	_line(img, s * 0.42, s * 0.78, s * 0.28, s * 0.42, c, 3)
	_line(img, s * 0.28, s * 0.42, s * 0.5, s * 0.22, c, 3)
