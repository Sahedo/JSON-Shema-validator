# JSON Schema main script
# Inherits from Reference for easy use

class_name JSONSchema extends Reference 

const DEF_KEY_NAME = "schema root"
const DEF_ERROR_STRING = "##error##"

const JST_ARRAY = "array"
const JST_BOOLEAN = "boolean"
const JST_INTEGER = "integer"
const JST_NULL = "null"
const JST_NUMBER = "number"
const JST_OBJECT = "object"
const JST_STRING = "string"

const JSKW_TYPE = "type"
const JSKW_PROP = "properties"
const JSKW_REQ = "required"
const JSKW_TITLE = "title"
const JSKW_DESCR = "description"
const JSKW_DEFAULT = "default"
const JSKW_EXAMPLES = "examples"
const JSKW_COMMENT = "$comment"
const JSKW_ENUM = "enum"
const JSKW_CONST = "const"
const JSKW_ITEMS = "items"
const JSKW_CONTAINS = "contains"
const JSKW_ADD_ITEMS = "additionalItems"
const JSKW_MIN_ITEMS = "minItems"
const JSKW_MAX_ITEMS = "maxItems"
const JSKW_UNIQUE_ITEMS = "uniqueItems"
const JSKW_MULT_OF = "multipleOf"
const JSKW_MINIMUM = "minimum"
const JSKW_MIN_EX = "exclusiveMinimum"
const JSKW_MAXIMUM = "maximum"
const JSKW_MAX_EX = "exclusiveMaximum"
const JSKW_PROP_ADD = "additionalProperties"
const JSKW_PROP_PATTERN = "patternProperties"
const JSKW_PROP_NAMES = "propertyNames"
const JSKW_PROP_MIN = "minProperties"
const JSKW_PROP_MAX = "maxProperties"
const JSKW_DEPEND = "dependencies"
const JSKW_LENGTH_MIN = "minLength"
const JSKW_LENGTH_MAX = "maxLength"
const JSKW_PATTERN = "pattern"
const JSKW_FORMAT = "format"

const JSM_GREATER = "greater"
const JSM_GREATER_EQ = "greater or equal"
const JSM_LESS = "less"
const JSM_LESS_EQ = "less or equal"
const JSM_OBJ_DICT = "object (dictionary)"

const ERR_SCHEMA_FALSE = "Schema declared as deny all"
const ERR_WRONG_SCHEMA_GEN = "Schema error: "
const ERR_WRONG_SCHEMA_TYPE = "Schema error: schema must be empty object or object with 'type' keyword or boolean value"
const ERR_WRONG_SHEMA_NOTA = "Schema error: expected that all elements of '%s.%s' must be '%s'"
const ERR_WRONG_PROP_TYPE = "Schema error: any schema item must be object with 'type' keyword"
const ERR_REQ_PROP_GEN = "Schema error: expected array of required properties for '%s'"
const ERR_REQ_PROP_MISSING = "Missing required property: '%s' for '%s'"
const ERR_INVALID_JSON_GEN = "Validation fails with message: %s"
const ERR_INVALID_JSON_EXT = "Invalid JSON data passed with message: %s"
const ERR_TYPE_MISMATCH_GEN = "Type mismatch: expected %s for '%s'"
const ERR_MULT_D = "Key %s that equal %d must be multiple of %d"
const ERR_MULT_F = "Key %s that equal %f must be multiple of %f"
const ERR_RANGE_D = "Key %s that equal %d must be %s than %d"
const ERR_RANGE_F = "Key %s that equal %f must be %s than %f"
const ERR_RANGE_S = "Length of '%s' (%d) %s than declared (%d)"
const ERR_WRONG_PATTERN = "Content of '%s' does not match its corresponding pattern"

# This is one and only function that need you to call outside
# If all validation checks passes, this return empty String
func validate(json_data : String, schema: String) -> String:
	var error : String = ""
	
	# General validation input data as JSON file
	error = validate_json(json_data)
	if error: return ERR_INVALID_JSON_EXT % error
	
	# General validation input schema as JSONSchema file
	error = validate_json(schema)
	if error: return ERR_WRONG_SCHEMA_GEN + error
	var parsed_schema = parse_json(schema)
	match typeof(parsed_schema):
		TYPE_BOOL:
			if !parsed_schema:
				return ERR_INVALID_JSON_GEN % ERR_SCHEMA_FALSE
			else: 
				return ""
		TYPE_DICTIONARY:
			if parsed_schema.empty():
				return ""
			elif parsed_schema.keys().size() > 0 && !parsed_schema.has(JSKW_TYPE):
				return ERR_WRONG_SCHEMA_TYPE
		_: return ERR_WRONG_SCHEMA_TYPE
	
	# All inputs seems valid. Begin type validation
	error = _type_selection(json_data, parsed_schema)
	
	# Normal return empty string, meaning OK
	return error

func _to_string():
	return "[JSONSchema:%d]" % get_instance_id()

# TODO: title, description, default, examples, $comment, enum, const

func _type_selection(json_data: String, schema: Dictionary, key: String = DEF_KEY_NAME) -> String:
	var typearr : Array = _var_to_array(schema.type)
	var parsed_data = parse_json(json_data)
	var error : String = ERR_TYPE_MISMATCH_GEN % [typearr, key]
	for type in typearr:
		match type:
			JST_ARRAY: 
				if typeof(parsed_data) == TYPE_ARRAY:
					error = _validate_array(parsed_data, schema, key)
#				else:
#					error = ERR_TYPE_MISMATCH_GEN % [[JST_ARRAY], key]
			JST_BOOLEAN:
				if typeof(parsed_data) != TYPE_BOOL:
					return ERR_TYPE_MISMATCH_GEN % [[JST_BOOLEAN], key]
				else:
					error = ""
			JST_INTEGER: 
				if typeof(parsed_data) == TYPE_INT:
					error = _validate_integer(parsed_data, schema, key)
				if typeof(parsed_data) == TYPE_REAL && parsed_data == int(parsed_data):
					error = _validate_integer(int(parsed_data), schema, key)
			JST_NULL:
				if typeof(parsed_data) != TYPE_NIL:
					return ERR_TYPE_MISMATCH_GEN % [[JST_NULL], key]
				else:
					error = ""
			JST_NUMBER: 
				if typeof(parsed_data) == TYPE_REAL:
					error = _validate_number(parsed_data, schema, key)
#				else:
#					error = ERR_TYPE_MISMATCH_GEN % [[JST_NUMBER], key]
			JST_OBJECT: 
				if typeof(parsed_data) == TYPE_DICTIONARY:
					error = _validate_object(parsed_data, schema, key)
#				else:
#					error = ERR_TYPE_MISMATCH_GEN % [[JST_OBJECT], key]
			JST_STRING:
				if typeof(parsed_data) == TYPE_STRING:
					error = _validate_string(parsed_data, schema, key)
#				else:
#					error = ERR_TYPE_MISMATCH_GEN % [[JST_STRING], key]
	return error
	

func _var_to_array(variant) -> Array:
	var result : Array = []
	if typeof(variant) == TYPE_ARRAY:
		result = variant
	else:
		result.append(variant)
	return result

func _validate_array(input_data: Array, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	# TODO: contains additionalItems minItems maxItems uniqueItems
	var error : String = ""
	var items_array : Array
	
	#'items' must be object or Array of objects
	if input_schema.has(JSKW_ITEMS):
		items_array = _var_to_array(input_schema.items)
		for item in items_array:
			if typeof(item) != TYPE_DICTIONARY:
				return ERR_WRONG_SHEMA_NOTA % [property_name, JSKW_ITEMS, JST_OBJECT]
	
	# Check every item of input Array on 
	for idx in input_data.size():
		var suberror : Array = []
		for subschema in items_array:
			suberror.append(_type_selection(JSON.print(input_data[idx]), subschema, property_name+"["+String(idx)+"]"))
		if suberror.find("") < 0: # At least one returned string must be correct (empty). If no one present, it's wrong.
			return ERR_INVALID_JSON_GEN % String(suberror) # Then we post all suberror array for a maintenance.
	
	return error

func _validate_boolean(input_data: bool, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	# nothing to check
	return ""

func _validate_integer(input_data: int, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	# all processing is performed in
	return _validate_number(input_data, input_schema, property_name)

func _validate_null(input_data, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	# nothing to check
	return ""

func _validate_number(input_data: float, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	
	var types: Array = _var_to_array(input_schema.type)
	# integer mode turns on only if types has integer and has not number
	var integer_mode: bool = types.has(JST_INTEGER) && !types.has(JST_NUMBER)
	
	# defining minimums and maximums (if exclusions not present it's consider as false)
	var min_ex : bool = input_schema.has(JSKW_MIN_EX) && input_schema[JSKW_MIN_EX]
	var min_ex_msg: String = JSM_GREATER if min_ex else JSM_GREATER_EQ
	var max_ex : bool = input_schema.has(JSKW_MAX_EX) && input_schema[JSKW_MAX_EX]
	var max_ex_msg: String = JSM_LESS if max_ex else JSM_LESS_EQ
	
	# processing multiple check
	if input_schema.has(JSKW_MULT_OF):
		var mult = float(input_schema[JSKW_MULT_OF]) if input_schema[JSKW_MULT_OF] else 0.0
		mult = int(input_schema[JSKW_MULT_OF]) if integer_mode else mult
		if fmod(input_data, mult) != 0:
			if integer_mode:
				return ERR_MULT_D % [property_name, input_data, mult]
			else:
				return ERR_MULT_F % [property_name, input_data, mult]
	
	# processing minimum check
	if input_schema.has(JSKW_MINIMUM):
		var minimum = float(input_schema[JSKW_MINIMUM]) if input_schema[JSKW_MINIMUM] else 0.0
		minimum = int(input_schema[JSKW_MINIMUM]) if integer_mode else minimum
		var suberror : bool = (input_data <= minimum) if min_ex else (input_data < minimum)
		if suberror:
			if integer_mode:
				return ERR_RANGE_D % [property_name, input_data, min_ex_msg, minimum]
			else:
				return ERR_RANGE_F % [property_name, input_data, min_ex_msg, minimum]
	
	# processing maximum check
	if input_schema.has(JSKW_MAXIMUM):
		var maximum = float(input_schema[JSKW_MAXIMUM]) if input_schema[JSKW_MAXIMUM] else 0.0
		maximum = int(input_schema[JSKW_MAXIMUM]) if integer_mode else maximum
		var suberror : bool = (input_data >= maximum) if max_ex else (input_data > maximum)
		if suberror:
			if integer_mode:
				return ERR_RANGE_D % [property_name, input_data, max_ex_msg, maximum]
			else:
				return ERR_RANGE_F % [property_name, input_data, max_ex_msg, maximum]
	
	return ""

func _validate_object(input_data: Dictionary, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	# TODO: additionalProperties patternProperties propertyNames minProperties maxProperties dependencies
	var error : String = ""
	
	# Process properties
	if input_schema.has(JSKW_PROP):
		
		# Process required
		if input_schema.has(JSKW_REQ):
			if typeof(input_schema.required) != TYPE_ARRAY: return ERR_REQ_PROP_GEN % property_name
			for i in input_schema.required:
				if !input_data.has(i): return ERR_REQ_PROP_MISSING % [i, property_name]
		
		# Continue validating schema subelements
		if typeof(input_schema.properties) != TYPE_DICTIONARY:
			return ERR_WRONG_SCHEMA_GEN + ERR_TYPE_MISMATCH_GEN % [JSM_OBJ_DICT, property_name]
		
		# Process property items
		for key in input_schema.properties:
			if !input_schema.properties[key].has(JSKW_TYPE):
				return ERR_WRONG_PROP_TYPE
			# TODO: additional properties check
			if input_data.has(key):
				error = _type_selection(JSON.print(input_data[key]), input_schema.properties[key], key)
			else:
				pass
			if error: return error
	
	return error

func _validate_string(input_data: String, input_schema: Dictionary, property_name: String = DEF_KEY_NAME) -> String:
	# TODO: format 
	var error : String = ""
	if input_schema.has(JSKW_LENGTH_MIN):
		if not (typeof(input_schema[JSKW_LENGTH_MIN]) == TYPE_INT || typeof(input_schema[JSKW_LENGTH_MIN]) == TYPE_REAL):
			return ERR_TYPE_MISMATCH_GEN % [JST_INTEGER, property_name+"."+JSKW_LENGTH_MIN]
		if input_data.length() < input_schema[JSKW_LENGTH_MIN]:
			return ERR_INVALID_JSON_GEN % ERR_RANGE_S % [property_name, input_data.length(), JSM_LESS ,input_schema[JSKW_LENGTH_MIN]]
	
	if input_schema.has(JSKW_LENGTH_MAX):
		if not (typeof(input_schema[JSKW_LENGTH_MAX]) == TYPE_INT || typeof(input_schema[JSKW_LENGTH_MAX]) == TYPE_REAL):
			return ERR_TYPE_MISMATCH_GEN % [JST_INTEGER, property_name+"."+JSKW_LENGTH_MAX]
		if input_data.length() > input_schema[JSKW_LENGTH_MAX]:
			return ERR_INVALID_JSON_GEN % ERR_RANGE_S % [property_name, input_data.length(), JSM_GREATER, input_schema[JSKW_LENGTH_MAX]]
	
	if input_schema.has(JSKW_PATTERN):
		if not (typeof(input_schema[JSKW_PATTERN]) == TYPE_STRING):
			return ERR_TYPE_MISMATCH_GEN % [JST_STRING, property_name+"."+JSKW_PATTERN]
		var regex = RegEx.new()
		regex.compile(input_schema[JSKW_PATTERN])
		if regex.search(input_data) == null:
			return ERR_INVALID_JSON_GEN % ERR_WRONG_PATTERN % property_name
	
	return error
