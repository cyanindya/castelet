extends RefCounted

var _text = ""
var _stream_length := 0
var _current_index := -1

func _init(file_content : String):
	self._text = file_content
	self._stream_length = len(file_content)
	print_debug("Stream length: ", self._stream_length)


func peek_next_char() -> String:
	# Always check if we've reached end-of-file first
	if not self.is_eof():
		return self._text[self._current_index + 1]
	else:
		return ""

func get_next_char() -> String:

	# Always check if we've reached end-of-file first
	if not self.is_eof():
		self._current_index += 1
		return self._text[self._current_index]
	else:
		return ""

func get_current_char() -> String:
	return self._text[self._current_index]

func get_previous_char():
	return self._text[self._current_index - 1]

func is_eof() -> bool:
	return self._current_index >= self._stream_length - 1

func error(message : String):
	printerr(message)
