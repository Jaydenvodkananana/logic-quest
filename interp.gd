class_name Interp
extends RefCounted
## C++-ийн энгийн мөрүүдийг нэг нэгээр нь ажиллуулдаг жижиг интерпретатор.
## Дэмждэг мөрүүд:
##   int name;                 (зарлах, утгагүй)
##   int name = expression;    (зарлаад утга өгөх)
##   name = expression;        (зарлагдсан хувьсагчид шинэ утга өгөх)
##   if (cond) name = expression;
## Бүх тоо int, тиймээс '/' нь C++-тэй адил үлдэгдлийг хаядаг.

const KEYWORDS := ["true", "false", "int"]

var lines: Array = []
## Зарлагдсан хувьсагчид. Утга нь null бол зарлагдсан ч утга өгөөгүй.
var vars: Dictionary = {}
var pc: int = 0


func load_program(program_lines: Array) -> void:
	lines = program_lines.duplicate()
	reset()


func reset() -> void:
	vars = {}
	pc = 0


func is_done() -> bool:
	return pc >= lines.size()


func step() -> Dictionary:
	var res := {"ok": true, "line": pc, "skipped": false, "var": "", "note": "", "error": ""}
	var text: String = str(lines[pc]).strip_edges()
	pc += 1
	if text.begins_with("if"):
		return _step_if(text, res)
	return _statement(text, res)


func _step_if(text: String, res: Dictionary) -> Dictionary:
	var open := text.find("(")
	if open == -1 or text.substr(2, open - 2).strip_edges() != "":
		return _fail(res, "C++-д нөхцөл хаалтанд бичигдэнэ:  if (нөхцөл) ...")
	var close := _matching_paren(text, open)
	if close == -1:
		return _fail(res, "'if' мөрийн хаалт ')' хаагдаагүй байна.")
	var cond_text := text.substr(open + 1, close - open - 1).strip_edges()
	var stmt := text.substr(close + 1).strip_edges()
	var c := _eval(cond_text)
	if not c.ok:
		return _fail(res, c.error)
	var truth: bool
	if typeof(c.value) == TYPE_BOOL:
		truth = c.value
	elif typeof(c.value) == TYPE_INT:
		truth = c.value != 0   # C++: 0 бол худал, бусад тоо үнэн.
	else:
		return _fail(res, "'%s' нь үнэн/худал асуулт биш. a > 3 гэх мэт харьцуулалт ашигла." % cond_text)
	if not truth:
		res.skipped = true
		res.note = "(%s) худал → алгасна" % cond_text
		return res
	res = _statement(stmt, res)
	if res.ok:
		res.note = "(%s) үнэн → %s" % [cond_text, res.note]
	return res


func _matching_paren(text: String, open: int) -> int:
	var depth := 0
	for i in range(open, text.length()):
		if text[i] == "(":
			depth += 1
		elif text[i] == ")":
			depth -= 1
			if depth == 0:
				return i
	return -1


func _statement(stmt: String, res: Dictionary) -> Dictionary:
	if not stmt.ends_with(";"):
		return _fail(res, "C++-д мөр бүр ';' тэмдгээр төгсөнө. Энэ мөрөнд ';' дутуу байна.")
	stmt = stmt.trim_suffix(";").strip_edges()

	var decl_only := RegEx.create_from_string("^int\\s+([A-Za-z_][A-Za-z0-9_]*)$")
	var m := decl_only.search(stmt)
	if m != null:
		var dname := m.get_string(1)
		if vars.has(dname):
			return _fail(res, "'%s' аль хэдийн зарлагдсан. C++-д нэг хувьсагчийг хоёр удаа зарлаж болохгүй." % dname)
		vars[dname] = null
		res.var = dname
		res.note = "шинэ хайрцаг %s  (утга өгөөгүй)" % dname
		return res

	var assign := RegEx.create_from_string("^(int\\s+)?([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*([^=].*)$")
	m = assign.search(stmt)
	if m == null:
		return _fail(res, "Энэ мөрийг уншиж чадсангүй. Ингэж бич:  int нэр = утга;  эсвэл  нэр = утга;")
	var is_decl := m.get_string(1) != ""
	var var_name := m.get_string(2)
	var expr_text := m.get_string(3).strip_edges()
	if is_decl and vars.has(var_name):
		return _fail(res, "'%s' аль хэдийн зарлагдсан. C++-д нэг хувьсагчийг хоёр удаа зарлаж болохгүй." % var_name)
	if not is_decl and not vars.has(var_name):
		return _fail(res, "'%s' хувьсагч зарлагдаагүй байна. C++-д хувьсагчийг эхлээд 'int %s = ...;' гэж зарлах ёстой.\n(Жинхэнэ C++ хөрвүүлэгч ийм програмыг огт ажиллуулахгүй.)" % [var_name, var_name])
	var r := _eval(expr_text)
	if not r.ok:
		return _fail(res, r.error)
	if typeof(r.value) != TYPE_INT:
		return _fail(res, "'%s' хайрцаг зөвхөн бүхэл тоо (int) хадгална, гэтэл '%s' нь бүхэл тоо биш." % [var_name, expr_text])
	var old = vars.get(var_name, null)
	vars[var_name] = r.value
	res.var = var_name
	if is_decl:
		# Богино математик мөр: "шинэ: y = x / 4 = 7" эсвэл "шинэ: x = 29"
		if expr_text == str(r.value):
			res.note = "шинэ: %s = %d" % [var_name, r.value]
		else:
			res.note = "шинэ: %s = %s = %d" % [var_name, expr_text, r.value]
	else:
		# "a: 7 → 10"
		var old_text := "?" if old == null else str(old)
		res.note = "%s: %s → %d" % [var_name, old_text, r.value]
	return res


func _eval(expr_text: String) -> Dictionary:
	# C++ хөрвүүлэгч шиг: ашиглахаасаа өмнө хувьсагч бүр зарлагдсан, утгатай байх ёстой.
	var ident := RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*")
	for m in ident.search_all(expr_text):
		var w := m.get_string()
		if w in KEYWORDS:
			continue
		if not vars.has(w):
			return {"ok": false, "error": "'%s' хувьсагч зарлагдаагүй байна. C++-д хувьсагчийг ашиглахаасаа өмнө зарлах ёстой.\n(Жинхэнэ C++ хөрвүүлэгч ийм програмыг огт ажиллуулахгүй.)" % w}
		if vars[w] == null:
			return {"ok": false, "error": "'%s' зарлагдсан ч утга өгөөгүй байна. C++-д ийм хувьсагчийг уншвал санамсаргүй «хог» утга гарч болно. Эхлээд утга өг." % w}
	var e := Expression.new()
	var names := PackedStringArray()
	var values: Array = []
	for k in vars:
		names.append(str(k))
		values.append(vars[k])
	if e.parse(expr_text, names) != OK:
		return {"ok": false, "error": "Уншиж чадсангүй: " + expr_text}
	var value = e.execute(values, null, false)
	if e.has_execute_failed():
		return {"ok": false, "error": "Энэ бодолт боломжгүй (тэг рүү хуваасан уу?)."}
	return {"ok": true, "value": value}


func _fail(res: Dictionary, msg: String) -> Dictionary:
	res.ok = false
	res.error = msg
	pc = lines.size()
	return res
