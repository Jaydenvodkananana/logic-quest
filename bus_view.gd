class_name BusView
extends Control
## Сорилтын түвшин: Батаа жолоочтой автобус, яриа (bubble), карт уншигч, зорчигчид.
## Турших үед зорчигчид нэг нэгээр карт уншуулж, уншигч үнийг харуулна, ✓/✗ тэмдэглэнэ.

class Rider extends RefCounted:
	var age := 0
	var card := 0
	var pos := Vector2.ZERO
	var alpha := 1.0
	var mark := 0         # 0 хоосон, 1 зөв, 2 буруу
	var label := ""       # толгой дээрх бичиг (жишээ: "250₮")
	var shirt := Color(0.3, 0.5, 0.8)
	var skin := Color(0.9, 0.75, 0.6)

const SHIRTS := [Color(0.3, 0.5, 0.8), Color(0.75, 0.35, 0.35), Color(0.35, 0.65, 0.45), Color(0.7, 0.55, 0.25), Color(0.55, 0.4, 0.7)]
const SKINS := [Color(0.92, 0.76, 0.62), Color(0.8, 0.6, 0.45), Color(0.6, 0.42, 0.3), Color(0.95, 0.82, 0.7)]
const GREEN := Color(0.4, 0.9, 0.5)
const RED := Color(1.0, 0.45, 0.45)
const SPACING := 62.0

var speed := 1.0
var running := false
var bubble_text := ""
var reader_text := "---"
var reader_color := Color(0.5, 0.9, 1.0)
var door_open := 0.0
var riders: Array = []
var compact := false   # засварын үед жижиг (програмын талбайд илүү зай)


func _ready() -> void:
	custom_minimum_size = Vector2(600, 200)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	# Үзэгдлийн өндөр өөрчлөгдвөл (compact) зорчигчид шинэ газар дээрээ буух ёстой.
	resized.connect(func():
		for r in riders:
			if not running:
				r.pos.y = _ground())


func _process(_delta: float) -> void:
	queue_redraw()


## Засварын үед үзэгдэл намхан, зорчигчид жижиг болно.
func set_compact(on: bool) -> void:
	compact = on
	custom_minimum_size.y = 150.0 if on else 200.0


func _d(t: float) -> float:
	return maxf(0.001, t * speed)


# ---------------------------------------------------------------- геометр (автобусны урд хэсэг зүүн талд)

func _ground() -> float:
	return size.y - 18.0


func _bus_x() -> float:
	return size.x * 0.52


func _door_x() -> float:
	return _bus_x() + 96.0


func _reader_pos() -> Vector2:
	return Vector2(_door_x() + 44.0, _ground() - 86.0)


func _spot_x() -> float:
	return _door_x() - 48.0


# ---------------------------------------------------------------- турших

func set_queue(cases: Array) -> void:
	riders.clear()
	for k in cases.size():
		var r := Rider.new()
		r.age = cases[k].age
		r.card = cases[k].card
		r.pos = Vector2(_spot_x() - k * SPACING, _ground())
		r.shirt = SHIRTS[k % SHIRTS.size()]
		r.skin = SKINS[(k * 3 + 1) % SKINS.size()]
		riders.append(r)


## results: [{price: String, ok: bool}] (case бүрт). Зорчигч бүр уншигч дээр ирж, үнэ гарч, ✓/✗ авна.
func run_test(cases: Array, results: Array) -> void:
	running = true
	set_queue(cases)
	reader_text = "---"
	await get_tree().process_frame
	for i in riders.size():
		var r: Rider = riders[i]
		var res: Dictionary = results[i]
		reader_text = res.price
		reader_color = GREEN if res.ok else RED
		r.label = res.price
		r.mark = 1 if res.ok else 2
		await _wait(0.55)
		var tw := create_tween().set_parallel(true)
		if res.ok:
			tw.tween_property(self, "door_open", 1.0, _d(0.15))
			tw.tween_property(r, "pos", Vector2(_door_x(), r.pos.y), _d(0.45))
			tw.tween_property(r, "alpha", 0.0, _d(0.3)).set_delay(_d(0.2))
		else:
			# Буруу төлбөр: зорчигч хойш ухарч, ✗ тэмдэгтэйгээ үлдэнэ (хэн буруу болсныг харагдуулна).
			tw.tween_property(r, "pos", r.pos + Vector2(-20.0, -6.0), _d(0.35))
			tw.tween_property(r, "alpha", 0.45, _d(0.35))
		await tw.finished
		door_open = 0.0
		if i + 1 < riders.size():
			var shift := create_tween().set_parallel(true)
			for k in range(i + 1, riders.size()):
				var q: Rider = riders[k]
				shift.tween_property(q, "pos", q.pos + Vector2(SPACING, 0.0), _d(0.22))
			await shift.finished
	reader_text = "---"
	reader_color = Color(0.5, 0.9, 1.0)
	# Буруу төлсөн зорчигчдыг зүүн талд эгнээгээр жагсаана: хэн нь буруу байсныг нэг бүрчлэн уншиж болно.
	var k := 0
	var tw2 := create_tween().set_parallel(true)
	for r in riders:
		if r.mark == 2:
			tw2.tween_property(r, "pos", Vector2(36.0 + k * 66.0, _ground()), _d(0.3))
			tw2.tween_property(r, "alpha", 1.0, _d(0.3))
			k += 1
	if k > 0:
		await tw2.finished
	else:
		tw2.kill()
	running = false


func _wait(t: float) -> void:
	await get_tree().create_timer(_d(t)).timeout


# ---------------------------------------------------------------- зураг

func _draw() -> void:
	var font := get_theme_default_font()
	var g := _ground()
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.08, 0.1, 0.18))
	draw_rect(Rect2(0, g, size.x, size.y - g), Color(0.17, 0.19, 0.22))
	_draw_bus(font, g)
	for r in riders:
		_draw_rider(font, r)
	if bubble_text != "":
		_draw_bubble(font)


func _draw_bus(font: Font, g: float) -> void:
	var bx := _bus_x()
	var top := g - (112.0 if compact else 140.0)
	var body := Rect2(bx, top, size.x - bx + 40.0, g - top - 12.0)
	draw_rect(body, Color(0.95, 0.72, 0.18))                       # шар автобус
	draw_rect(Rect2(bx, top + 98.0, body.size.x, 8.0), Color(0.2, 0.2, 0.25))
	# Урд шил + Батаа (жолооч)
	var ws := Rect2(bx + 8.0, top + 12.0, 62.0, 62.0)
	draw_rect(ws, Color(0.55, 0.75, 0.9))
	_draw_bataa(Vector2(ws.position.x + 30.0, ws.position.y + 34.0))
	# Хаалга
	var door := Rect2(_door_x() - 26.0, top + 12.0, 52.0, 116.0)
	draw_rect(door, Color(0.1, 0.1, 0.14))
	draw_rect(Rect2(door.position, Vector2(door.size.x * (1.0 - door_open), door.size.y)), Color(0.4, 0.55, 0.65))
	draw_rect(door, Color(0.2, 0.2, 0.25), false, 3.0)
	# Карт уншигч (дэлгэцтэй)
	var rp := _reader_pos()
	var rr := Rect2(rp - Vector2(22.0, 18.0), Vector2(44.0, 50.0))
	draw_rect(rr, Color(0.15, 0.15, 0.2))
	draw_rect(Rect2(rr.position + Vector2(4, 4), Vector2(36, 18)), Color(0.02, 0.05, 0.08))
	draw_string(font, rr.position + Vector2(0, 19), reader_text, HORIZONTAL_ALIGNMENT_CENTER, 44.0, 13, reader_color)
	draw_rect(Rect2(rr.position + Vector2(10, 28), Vector2(24, 14)), Color(0.3, 0.7, 0.9))   # карт тулгах хэсэг
	# Цонхнууд
	var wx := _door_x() + 74.0
	while wx + 60.0 < size.x:
		draw_rect(Rect2(wx, top + 12.0, 60.0, 46.0), Color(0.55, 0.75, 0.9))
		wx += 72.0
	# Дугуй
	for x in [bx + 60.0, size.x - 70.0]:
		draw_circle(Vector2(x, g - 8.0), 18.0, Color(0.12, 0.12, 0.14))
		draw_circle(Vector2(x, g - 8.0), 7.0, Color(0.6, 0.6, 0.65))
	draw_string(font, Vector2(_door_x() + 80.0, top + 88.0), "Batbus 7", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.2, 0.05))


func _draw_bataa(c: Vector2) -> void:
	var skin := Color(0.85, 0.66, 0.5)
	draw_rect(Rect2(c + Vector2(-16, 8), Vector2(32, 24)), Color(0.2, 0.3, 0.55))   # хүрэм
	draw_circle(c, 13.0, skin)                                                       # толгой
	draw_rect(Rect2(c + Vector2(-15, -16), Vector2(30, 8)), Color(0.15, 0.2, 0.4))   # малгай
	draw_rect(Rect2(c + Vector2(-4, -20), Vector2(8, 5)), Color(0.9, 0.8, 0.2))
	draw_circle(c + Vector2(-5, -1), 1.8, Color.BLACK)
	draw_circle(c + Vector2(5, -1), 1.8, Color.BLACK)
	draw_line(c + Vector2(-6, 6), c + Vector2(6, 6), Color(0.3, 0.2, 0.15), 2.0)     # сахал
	draw_arc(c + Vector2(4, 26), 12.0, PI, TAU, 16, Color(0.15, 0.15, 0.15), 3.0)   # жолоо


func _draw_bubble(font: Font) -> void:
	var w := minf(_bus_x() - 30.0, 640.0)
	var text_h := font.get_multiline_string_size(bubble_text, HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, 16).y
	var r := Rect2(12.0, 8.0, w, 34.0 + text_h)   # бичгийн хэмжээнд тааруулна
	draw_rect(r, Color(0.97, 0.97, 1.0))
	# Батаа руу заасан сүүл
	var tip := Vector2(_bus_x() + 20.0, _ground() - 110.0)
	draw_colored_polygon(PackedVector2Array([r.end - Vector2(40, 2), r.end - Vector2(10, 2), tip]), Color(0.97, 0.97, 1.0))
	draw_string(font, r.position + Vector2(12, 20), "Батаа:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.35, 0.35, 0.5))
	draw_multiline_string(font, r.position + Vector2(12, 42), bubble_text, HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, 16, -1, Color(0.08, 0.08, 0.12))


func _draw_rider(font: Font, p: Rider) -> void:
	if p.alpha < 0.05:
		return   # автобусанд суусан (алга болсон) зорчигч
	var a := p.alpha
	var x := p.pos.x
	var g := p.pos.y
	var skin := Color(p.skin.r, p.skin.g, p.skin.b, a)
	var shirt := Color(p.shirt.r, p.shirt.g, p.shirt.b, a)
	var pants := Color(0.2, 0.2, 0.3, a)
	var s := 0.8 if p.age < 14 else (1.0 if p.age < 60 else 0.95)   # хүүхэд жижиг
	if compact:
		s *= 0.72
	draw_line(Vector2(x - 5, g), Vector2(x - 5, g - 28 * s), pants, 5.0)
	draw_line(Vector2(x + 5, g), Vector2(x + 5, g - 28 * s), pants, 5.0)
	draw_rect(Rect2(x - 11, g - 60 * s, 22, 34 * s), shirt)
	draw_circle(Vector2(x, g - 72 * s), 11.0, skin)
	if p.age >= 60:
		draw_arc(Vector2(x, g - 76 * s), 11.0, PI, TAU, 12, Color(0.85, 0.85, 0.85, a), 4.0)   # буурал үс
	if p.card == 1:
		draw_rect(Rect2(x + 13, g - 46 * s, 14, 10), Color(0.3, 0.7, 0.95, a))                # оюутны карт
	# Нас/карт нь хөлийн доор, төлсөн үнэ ба ✓/✗ нь толгойн хажууд (яриатай давхцахгүй).
	var info := "%d нас" % p.age   # карттай эсэх нь гарт байгаа цэнхэр картаар харагдана
	draw_string(font, Vector2(x - 40, g + 14), info, HORIZONTAL_ALIGNMENT_CENTER, 80.0, 11, Color(1, 1, 1, maxf(a, 0.6)))
	var col := GREEN if p.mark == 1 else RED
	if p.label != "":
		draw_string(font, Vector2(x + 13, g - 74 * s), p.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	if p.mark != 0:
		draw_string(font, Vector2(x + 13, g - 56 * s), "✓" if p.mark == 1 else "✗", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
