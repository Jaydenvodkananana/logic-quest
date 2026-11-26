class_name Levels
extends RefCounted
## 1-р хэсгийн түвшингүүд. Тоонууд оролдлого бүрт санамсаргүй өөрчлөгдөнө ({A}, {B}... нь параметр).
## Програмын мөрүүд C++ хэлээр бичигдэнэ (Interp-ийг үз).
## "map": бүлгийн дэлгэц дээрх богино нэр (байхгүй бол title).
## "chapter": бүлэг ("var" = Хувьсагч, "cond" = Нөхцөл; UiTheme.CHAPTERS-ийг үз).
## mode "predict": `ask` хувьсагчийн эцсийн утгыг таа.
## mode "arrange": мөрүүдийг зөв дараалалд оруулж `goal_var`-г {G} болго.
## mode "guard": автобусны хаалганы дүрмийг (age, card) өөрөө бүтээ.
## mode "flow": if / if-else-ийн блок схем. Тайлбар (3 алхам) + мини тест (3 зөв хариулт).
##   kind "if"/"ifelse", in_var/out_var хувьсагч, t_val/f_val блокийн өгөх утга, {T} хил, ops операторууд.


static func get_levels() -> Array:
	return [
		{
			"title": "Хайрцаг",
			"mode": "tutorial",
			"chapter": "var",
			"map": "Хайрцаг",
			"story": "Хувьсагч = нэртэй хайрцаг.  Зорчигчдыг тоолно.",
			"hint": "",
		},
		{
			"title": "Хуулбар",
			"mode": "predict",
			"chapter": "var",
			"ask": "note",
			"params": {"A": [2, 9], "B": [1, 5]},
			"story": "Тоог дэвтэрт (note) хуулав. Дараа нь хүн нэмэгдэв.",
			"hint": "int note = people; нь утгыг хуулна. Хайрцгууд холбогдохгүй.",
			"lines": ["int people = {A};", "int note = people;", "people = people + {B};"],
		},
		{
			"title": "Шинэчлэх",
			"mode": "predict",
			"chapter": "var",
			"ask": "people",
			"params": {"A": [2, 8], "B": [2, 4]},
			"story": "Тоолуур: хүн суух бүрт хуучин тоон дээр нэмнэ.",
			"hint": "people = people + 1; хуучин утгыг уншиж, нэмээд дарж бичнэ.",
			"lines": ["int people = {A};", "people = people + 1;", "people = people + {B};"],
		},
		{
			"title": "/ ба %",
			"mode": "predict",
			"chapter": "var",
			"ask": "ans",
			"params": {"X": [11, 29], "D": [2, 4]},
			"nonzero_rem": ["X", "D"],
			"story": "Микро бүрт {D} хүн.   int:  17 / 3 = 5 дүүрэн,  17 % 3 = 2 үлдэнэ",
			"hint": "int-д / үлдэгдлийг хаяна, % зөвхөн үлдэгдлийг өгнө.",
			"lines": ["int people = {X};", "int full = people / {D};", "int left = people % {D};", "int ans = full * 10 + left;"],
		},
		{
			"title": "Дараалал",
			"mode": "arrange",
			"chapter": "var",
			"goal_var": "total",
			"params": {"A": [2, 5], "B": [2, 4], "C": [1, 9]},
			"story": "Өдрийн орлого: total = {G} болго. Мөрөө чирж зөө (W / S).",
			"hint": "Эхлээд зарла, дараа нь ашигла:  {A} * {B} + {C} = {G}",
			"lines": ["int total = {A};", "total = total * {B};", "total = total + {C};"],
		},
		{
			"title": "if",
			"mode": "flow",
			"chapter": "cond",
			"kind": "if",
			"in_var": "temp",
			"out_var": "fan",
			"t_val": 1,
			"f_val": 0,
			"params": {"T": [25, 32]},
			"ops": [">", ">=", "=="],
			"explain_ops": true,   # тайлбарт оператор бүрийг тоон шулуунаар үзүүлнэ; тест хил орчмын утгаар
			"story": "Автобус халуун бол сэнс асна.",
			"hint": "if: үнэн бол блок ажиллана, худал бол алгасна.  > тэнцүүг оруулахгүй, >= оруулна, == зөвхөн тэнцүү.",
		},
		{
			"title": "if / else",
			"mode": "flow",
			"chapter": "cond",
			"kind": "ifelse",
			"in_var": "score",
			"out_var": "pass",
			"t_val": 1,
			"f_val": 0,
			"params": {"T": [50, 70]},
			"ops": [">=", ">", "<=", "<"],
			"story": "Жолоочийн шалгалт: оноо хүрвэл тэнцэнэ, үгүй бол тэнцэхгүй.",
			"hint": "if / else: хоёр замын яг нэг нь ажиллана.",
		},
		{
			"title": "Хоёр дүрэм (&& / ||)",
			"map": "&& / ||",
			"mode": "guard",
			"chapter": "cond",
			"rules": 2,
			"params": {"T": [16, 21]},
			"story": "Шөнийн рейс: {T}+ настай БӨГӨӨД картай хүн л сууна.  card: 1 = картай, 0 = картгүй.  Холбох: && (БӨГӨӨД), || (ЭСВЭЛ).",
			"hint": "'&&' нь хоёр нөхцөл ХОЁУЛАА үнэн байхыг шаарддаг. '||' нь аль нэг нь үнэн бол хангалттай.",
		},
		{
			"title": "Сорилт",
			"map": "Сорилт",
			"mode": "challenge",
			"chapter": "cond",
			"optional": true,
			"story": "",
			"hint": "",
		},
	]


static func make(tpl: Dictionary) -> Dictionary:
	var inst: Dictionary = tpl.duplicate(true)
	var vals := {}
	var tries := 0
	while true:
		vals = {}
		var params: Dictionary = tpl.get("params", {})
		for k in params:
			var r: Array = params[k]
			vals[k] = randi_range(r[0], r[1])
		tries += 1
		if tries > 100 or not tpl.has("nonzero_rem"):
			break
		var pair: Array = tpl.nonzero_rem
		if vals[pair[0]] % vals[pair[1]] != 0:
			break
	var lines: Array = []
	for l in tpl.get("lines", []):
		lines.append(_fmt(l, vals))
	inst.lines = lines
	if tpl.mode == "arrange":
		var ip := Interp.new()
		ip.load_program(lines)
		while not ip.is_done():
			ip.step()
		inst.goal = ip.vars.get(tpl.goal_var)
		vals["G"] = inst.goal
		var shuffled := lines.duplicate()
		var n := 0
		while n < 50:
			shuffled.shuffle()
			if shuffled != lines:
				break
			n += 1
		inst.lines = shuffled
	inst.story = _fmt(tpl.story, vals)
	inst.hint = _fmt(tpl.hint, vals)
	inst.vals = vals
	return inst


static func _fmt(s: String, vals: Dictionary) -> String:
	var out := s
	for k in vals:
		out = out.replace("{%s}" % k, str(vals[k]))
	return out
