class_name Interp
extends RefCounted
## "name = expression" ба "if cond: name = expression" мөрүүдийг нэг нэгээр ажиллуулдаг жижиг интерпретатор.

var lines: Array = []
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
	if text.begins_with("if "):
		var colon := text.find(":")
		if colon == -1:
			return _fail(res, "'if' мөрийн нөхцлийн ард ':' шаардлагатай.")
		var cond_text := text.substr(3, colon - 3).strip_edges()
		var stmt := text.substr(colon + 1).strip_edges()
		var c := _eval(cond_text)
		if not c.ok:
			return _fail(res, c.error)
		if typeof(c.value) != TYPE_BOOL:
			return _fail(res, "'%s' нь тийм/үгүй асуулт биш. a > 3 гэх мэт харьцуулалт ашигла." % cond_text)
		if not c.value:
			res.skipped = true
			res.note = "%s гэдэг үнэн үү?  Үгүй.  Тиймээс энэ мөр алгасагдана." % cond_text
			return res
		res = _assign(stmt, res)
		if res.ok:
			res.note = "%s гэдэг үнэн үү?  Тийм.  Тиймээс: %s" % [cond_text, res.note]
		return res
	return _assign(text, res)


func _assign(stmt: String, res: Dictionary) -> Dictionary:
	var rx := RegEx.new()
	rx.compile("^([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*([^=].*)$")
	var m := rx.search(stmt)
	if m == null:
		return _fail(res, "Энэ мөрийг уншиж чадсангүй. Ингэж бич:  нэр = утга")
	var var_name := m.get_string(1)
	var r := _eval(m.get_string(2))
	if not r.ok:
		return _fail(res, r.error)
	var old = vars.get(var_name, null)
	vars[var_name] = r.value
	res.var = var_name
	var old_text := "хоосон" if old == null else str(old)
	res.note = "Эхлээд баруун тал: %s = %s.  Дараа нь '%s' хайрцагт хадгална  (өмнө нь: %s)." % [m.get_string(2).strip_edges(), str(r.value), var_name, old_text]
	return res


func _eval(expr_text: String) -> Dictionary:
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
		return {"ok": false, "error": _explain(expr_text)}
	return {"ok": true, "value": value}


func _explain(expr_text: String) -> String:
	var rx := RegEx.new()
	rx.compile("[A-Za-z_][A-Za-z0-9_]*")
	for m in rx.search_all(expr_text):
		var w := m.get_string()
		if not vars.has(w) and not (w in ["true", "false", "and", "or", "not", "null"]):
			return "'%s' хайрцагт утга байхгүй байна. Энэ мөрөөс өмнө түүнд юу ч хадгалагдаагүй." % w
	return "Энэ бодолт боломжгүй (тэг рүү хуваасан уу?)."


func _fail(res: Dictionary, msg: String) -> Dictionary:
	res.ok = false
	res.error = msg
	pc = lines.size()
	return res
