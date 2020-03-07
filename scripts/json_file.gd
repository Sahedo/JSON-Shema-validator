class_name JSONFile extends File

var schema_validator : JSONSchema
var json_schema : String

func save_data(a) -> void: # argument is untyped Variant
	if is_open():
		store_line(to_json(a))
	pass

func load_data() -> String:
	var result : String
	if is_open():
		result = get_as_text()
		var err : String
		if schema_validator:
			err = schema_validator.validate(result, json_schema) 
		else:
			err = validate_json(result)
		if err:
			result = err
		else:
			result = parse_json(result)
	return result
