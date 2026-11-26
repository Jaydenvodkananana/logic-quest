class_name BusView
extends Control
## Сорилтын түвшин (цаасан диорама): автобус, карт уншигч, зорчигчид, тайлбарын тэмдэглэл (bubble_text).
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

const SHIRTS := UiTheme.SHIRTS
const SKINS := UiTheme.SKINS
const GREEN := Color("7EE2A8")   # уншигчийн дэлгэц дээр (харанхуй)
const RED := Color("FF8A80")
const IDLE := Color("5FD4C4")
const SPACING := 62.0

var speed := 1.0
var running := false
var bubble_text := ""
var reader_text := "---"
var reader_color := IDLE
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
	return size.x * 0.55


func _door_x() -> float:
	return _bus_x() + 96.0


func _reader_pos() -> Vector2:
	return Vector2(_door_x() - 142.0, _ground() - 96.0)


func _spot_x() -> float:
	return _door_x() - 196.0


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
	reader_color = IDLE
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
	var g := _ground()
	UiTheme.diorama(self, Rect2(Vector2.ZERO, size), Color("DDF1ED"), Color("B9E0D8"), Color("95D0C4"), size.y - g, 11)
	_draw_bus(g)
	for r in riders:
		_draw_rider(r)
	if bubble_text != "":
		_draw_note()


func _draw_bus(g: float) -> void:
	var h := 112.0 if compact else 140.0
	var bx := _door_x() - 114.0
	UiTheme.bus(self, Rect2(bx, g - h, size.x - 16.0 - bx, h - 12.0), door_open, true)
	# Карт уншигч (шон дээр, автобусны өмнө): дэлгэц дээр төлсөн үнэ.
	var rp := _reader_pos()
	draw_style_box(UiTheme.paper(Color("8B8FA3"), 3, 2, UiTheme.INK, 0), Rect2(Vector2(rp.x - 4, rp.y + 30), Vector2(8, g - rp.y - 30)))
	var rr := Rect2(rp - Vector2(28.0, 22.0), Vector2(56.0, 52.0))
	UiTheme.box(self, rr, UiTheme.CARD, 8, 2, 4)
	var scr := Rect2(rr.position + Vector2(5, 5), Vector2(46, 22))
	draw_style_box(UiTheme.paper(UiTheme.CODE_BG, 4, 0, UiTheme.INK, 0), scr)
	UiTheme.text_in(self, scr, reader_text, 13, reader_color, UiTheme.font("mono_b"))
	draw_style_box(UiTheme.paper(UiTheme.CARD_BLUE, 3, 1.5, UiTheme.INK, 0), Rect2(rr.position + Vector2(16, 32), Vector2(24, 12)))


## Тайлбар/алдааны цаасан тэмдэглэл (зүүн дээд буланд). Яриа биш: хэн ч «хэлэхгүй».
func _draw_note() -> void:
	var f := UiTheme.font("bold")
	var w := minf(_bus_x() - 40.0, 560.0)
	var text_h := f.get_multiline_string_size(bubble_text, HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 15).y
	var r := Rect2(14.0, 12.0, w, 18.0 + text_h)
	UiTheme.box(self, r, Color("FFF6D6"), 10, 2, 4)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(6, r.size.y - 4)), UiTheme.GLOW)
	draw_multiline_string(f, r.position + Vector2(18, 8 + f.get_ascent(15)), bubble_text, HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 15, -1, UiTheme.INK)


func _draw_rider(p: Rider) -> void:
	if p.alpha < 0.05:
		return   # автобусанд суусан (алга болсон) зорчигч
	var a := p.alpha
	var x := p.pos.x
	var g := p.pos.y
	var s := 0.8 if p.age < 14 else 1.0   # хүүхэд жижиг
	if compact:
		s *= 0.78
	UiTheme.person(self, p.pos, p.shirt, p.skin, s, a, p.card == 1, p.age >= 60)
	# Нас: толгой дээрх цаасан шошго (карттай эсэх нь гарт байгаа цэнхэр картаар харагдана).
	var tr := Rect2(x - 18.0, g - 108.0 * s - 4.0, 36.0, 22.0)
	draw_style_box(UiTheme.paper(Color(UiTheme.CARD, a), 6, 2, Color(UiTheme.INK, a), 0), tr)
	UiTheme.text_in(self, tr, str(p.age), 15, Color(UiTheme.INK, a), UiTheme.font("xbold"))
	# Төлсөн үнэ + ✓/✗: биеийн баруун талд.
	if p.label != "" and p.mark != 0:
		var ok := p.mark == 1
		var txt := "%s %s" % [p.label, "✓" if ok else "✗"]
		var f := UiTheme.font("bold")
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 14.0
		var lr := Rect2(x + 14.0, g - 70.0 * s, w, 20.0)
		draw_style_box(UiTheme.paper(Color(UiTheme.TRUE if ok else UiTheme.FALSE, maxf(a, 0.85)), 10, 0, UiTheme.INK, 0), lr)
		UiTheme.text_in(self, lr, txt, 13, Color.WHITE, f)
