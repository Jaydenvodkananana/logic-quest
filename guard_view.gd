class_name GuardView
extends Control
## Түвшин 8: автобусны хаалга (цаасан диорама). Дараалалд зогсох зорчигчид, хаалганы дүрэм (маршрутын самбар дээр),
## карт уншигч. Дүрэм «true» бол хаалга нээгдэж зорчигч сууна, «false» бол уншигч улаан болж буцна.
## (Дотоод нэрс хуучнаараа: ticket = зорчигчийн карт (card), guard_stop = уншигч «үгүй» гэсэн.)

class Person extends RefCounted:
	var age: int = 0
	var ticket: int = 0
	var pos: Vector2 = Vector2.ZERO
	var alpha: float = 1.0
	var mark: int = 0   # 0 хоосон, 1 зөв, 2 буруу
	var shirt: Color = Color(0.3, 0.5, 0.8)
	var skin: Color = Color(0.9, 0.75, 0.6)

const SPACING := 76.0
const SHIRTS := UiTheme.SHIRTS
const SKINS := UiTheme.SKINS
const ALLOW := Color(0.5, 0.95, 0.55)   # bubble_color тэмдэг: зөвшөөрсөн
const DENY := Color(1.0, 0.5, 0.5)      # bubble_color тэмдэг: татгалзсан

var speed := 1.0
var running := false
var show_ticket := false
var people: Array = []
var door_open := 0.0
var guard_stop := false
var bubble_text := ""
var bubble_color := Color.WHITE
var sign_text := ""


func _ready() -> void:
	custom_minimum_size = Vector2(560, 300)
	clip_contents = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _process(_delta: float) -> void:
	queue_redraw()


func _d(t: float) -> float:
	return maxf(0.001, t * speed)


func _ground() -> float:
	return size.y - 40.0


func _door_x() -> float:
	return size.x - 130.0


func _guard_x() -> float:
	return _door_x() - 142.0   # уншигч автобусны урд, явган зам дээр


func _spot_x() -> float:
	return _guard_x() - 62.0


func reset() -> void:
	people.clear()
	door_open = 0.0
	guard_stop = false
	bubble_text = ""
	running = false


func show_crowd(crowd: Array, two: bool) -> void:
	show_ticket = two
	door_open = 0.0
	guard_stop = false
	bubble_text = ""
	_build_people(crowd)


func _build_people(crowd: Array) -> void:
	people.clear()
	for k in crowd.size():
		var c: Dictionary = crowd[k]
		var p := Person.new()
		p.age = c.age
		p.ticket = c.ticket
		p.pos = Vector2(_spot_x() - k * SPACING, _ground())
		p.shirt = SHIRTS[k % SHIRTS.size()]
		p.skin = SKINS[(k * 3 + 1) % SKINS.size()]
		people.append(p)


## judge: Callable(Dictionary{age, ticket}) -> {allowed, expect, text}. Буцаах: {let_in, denied, wrong: [{age, ticket}]}
func run_test(crowd: Array, two: bool, free: bool, judge: Callable) -> Dictionary:
	running = true
	show_ticket = two
	guard_stop = false
	door_open = 0.0
	bubble_text = ""
	_build_people(crowd)
	var result := {"let_in": 0, "denied": 0, "wrong": []}
	await get_tree().process_frame
	for i in people.size():
		var p: Person = people[i]
		var verdict: Dictionary = judge.call({"age": p.age, "ticket": p.ticket})
		var allowed: bool = verdict.allowed
		bubble_text = verdict.text
		if free:
			bubble_color = Color(0.9, 0.9, 1.0)
		else:
			bubble_color = ALLOW if allowed else DENY
		await get_tree().create_timer(_d(0.6)).timeout
		if not free:
			var ok: bool = verdict.expect == allowed
			p.mark = 1 if ok else 2
			if not ok:
				result.wrong.append({"age": p.age, "ticket": p.ticket})
		if allowed:
			result.let_in += 1
			var tw := create_tween().set_parallel(true)
			tw.tween_property(self, "door_open", 1.0, _d(0.2))
			tw.tween_property(p, "pos", Vector2(_door_x(), p.pos.y), _d(0.6))
			tw.tween_property(p, "alpha", 0.0, _d(0.4)).set_delay(_d(0.25))
			await tw.finished
			create_tween().tween_property(self, "door_open", 0.0, _d(0.2))
		else:
			result.denied += 1
			guard_stop = true
			var tw2 := create_tween().set_parallel(true)
			tw2.tween_property(p, "pos", p.pos + Vector2(-30.0, -50.0), _d(0.7))
			tw2.tween_property(p, "alpha", 0.0, _d(0.7))
			await tw2.finished
			guard_stop = false
		if i + 1 < people.size():
			var shift := create_tween().set_parallel(true)
			for k in range(i + 1, people.size()):
				var q: Person = people[k]
				shift.tween_property(q, "pos", q.pos + Vector2(SPACING, 0.0), _d(0.3))
			await shift.finished
	bubble_text = ""
	running = false
	return result


func _draw() -> void:
	var g := _ground()
	UiTheme.diorama(self, Rect2(Vector2.ZERO, size), Color("DDF1ED"), Color("B9E0D8"), Color("95D0C4"), size.y - g, 11)
	_draw_bus(g)
	for p in people:
		_draw_person(p)
	if bubble_text != "":
		# Шалгалтын үр дүн: цаасан шошго (яриа биш).
		var bg := UiTheme.CARD
		if bubble_color == ALLOW:
			bg = UiTheme.TRUE_BG
		elif bubble_color == DENY:
			bg = UiTheme.FALSE_BG
		UiTheme.chip_text(self, Vector2(maxf(170.0, _spot_x()), 34.0), bubble_text, 16, bg, UiTheme.INK)


## Цаасан шар автобус (хаалга нь _door_x()-д), дээр нь маршрутын самбар (дүрэм), урд нь карт уншигч.
func _draw_bus(g: float) -> void:
	var dx := _door_x()
	var bus_r := Rect2(dx - 114.0, g - 150.0, size.x - 16.0 - (dx - 114.0), 138.0)
	UiTheme.bus(self, bus_r, door_open, true)
	# Маршрутын самбар: хаалганы дүрэм (C++ нөхцөл) харанхуй LED самбар дээр.
	if sign_text != "":
		var mf := UiTheme.font("mono_b")
		var tw := mf.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 28.0
		var sr := Rect2(size.x - 16.0 - tw, bus_r.position.y - 48.0, tw, 34.0)
		draw_line(Vector2(sr.position.x + 20, sr.end.y), Vector2(sr.position.x + 20, bus_r.position.y), UiTheme.INK, 2.0)
		draw_line(Vector2(sr.end.x - 20, sr.end.y), Vector2(sr.end.x - 20, bus_r.position.y), UiTheme.INK, 2.0)
		draw_style_box(UiTheme.code_panel(0), sr)
		UiTheme.text_in(self, sr, sign_text, 16, UiTheme.GLOW, mf)
	# Карт уншигч (шон дээр): шалгаж байхад ногоон (нээ) эсвэл улаан (үгүй) асна.
	var rc := UiTheme.COND_ACC
	if guard_stop:
		rc = UiTheme.FALSE
	elif door_open > 0.05:
		rc = UiTheme.TRUE
	var base := Vector2(_guard_x(), g)
	draw_style_box(UiTheme.paper(Color("8B8FA3"), 3, 2, UiTheme.INK, 0), Rect2(base + Vector2(-4, -64), Vector2(8, 64)))
	var b := Rect2(base + Vector2(-24, -108), Vector2(48, 48))
	UiTheme.box(self, b, UiTheme.CARD, 8, 2, 4)
	draw_style_box(UiTheme.paper(rc, 4, 2, UiTheme.INK, 0), Rect2(b.position + Vector2(6, 6), Vector2(36, 18)))
	draw_style_box(UiTheme.paper(UiTheme.CARD_BLUE, 3, 1.5, UiTheme.INK, 0), Rect2(b.position + Vector2(12, 30), Vector2(24, 11)))


func _draw_person(p: Person) -> void:
	var a := p.alpha
	var x := p.pos.x
	var g := p.pos.y
	UiTheme.person(self, p.pos, p.shirt, p.skin, 1.0, a, show_ticket and p.ticket == 1, p.age >= 60)
	if a < 0.05:
		return
	# Нас: толгой дээрх цаасан шошго.
	var tr := Rect2(x - 20.0, g - 112.0, 40.0, 24.0)
	var ts := UiTheme.paper(Color(UiTheme.CARD, a), 6, 2, Color(UiTheme.INK, a), 0)
	draw_style_box(ts, tr)
	UiTheme.text_in(self, tr, str(p.age), 16, Color(UiTheme.INK, a), UiTheme.font("xbold"))
	if p.mark != 0:
		var col := UiTheme.TRUE if p.mark == 1 else UiTheme.FALSE
		draw_arc(Vector2(x, g - 52.0), 50.0, 0.0, TAU, 40, Color(col, a), 3.5, true)
