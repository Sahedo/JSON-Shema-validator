# JSON-Schema-validator
This is script for Godot Engine, that validate JSON files by JSON Schema.

# How to use
1. Create new `JSONSchema` object in your script (this script automatically register class in Godot ClassDB).
Call its function `validate(json_data, json_schema)` where
`json_data` - is your data in string format;
`json_schema` - is your json_schema in string format.
2. Use helper class. Create new `JSONFile` object, open it as it described in ancestor `File` class (and don't forget to close afterall!) use `schema_validator` field to asigh validator class instance, use `json_schema` field to assign schema string, use functions `load_data()` and `save_data()` to work with your files.
Example:
```gdscript
	var jf := JSONFile.new()
	jf.schema_validator = JSONSchema.new()
	jf.json_schema = to_json(some_schema_dictionary)
	jf.open("user://some_data.txt", File.WRITE)
	my_data = jf.load_data() #if my_data turned to String, check if it is error message
	jf.close()
 ```
# Links
More about schemas and validation here: https://json-schema.org
