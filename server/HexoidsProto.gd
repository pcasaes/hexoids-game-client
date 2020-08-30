const PROTO_VERSION = 3

#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2020, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"
const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PoolByteArray:
		var varint : PoolByteArray = PoolByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PoolByteArray:
		var bytes : PoolByteArray = PoolByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PoolByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PoolByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PoolByteArray, index : int) -> PoolByteArray:
		var result : PoolByteArray = PoolByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PoolByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PoolByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PoolByteArray) -> PoolByteArray:
		var result : PoolByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PoolByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PoolByteArray = pack_type_tag(type, field.tag)
		var data : PoolByteArray = PoolByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PoolByteArray = v.to_bytes()
						#if obj != null && obj.size() > 0:
						#	data.append_array(pack_length_delimeted(type, field.tag, obj))
						#else:
						#	data = PoolByteArray()
						#	return data
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PoolByteArray = field.value.to_utf8()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PoolByteArray = field.value.to_bytes()
					#if obj != null && obj.size() > 0:
					#	data.append_array(obj)
					#	return pack_length_delimeted(type, field.tag, data)
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PoolByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call_func()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PoolByteArray = PoolByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PoolByteArray = PoolByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PoolByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PoolByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PoolByteArray = PoolByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) && data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PoolByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += String(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + String(value)
		else:
			result += String(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(String(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) && data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class FloatValue:
	func _init():
		var service
		
		_value = PBField.new("value", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _value
		data[_value.tag] = service
		
	var data = {}
	
	var _value: PBField
	func get_value() -> float:
		return _value.value
	func clear_value() -> void:
		_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_value(value : float) -> void:
		_value.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GUID:
	func _init():
		var service
		
		_guid = PBField.new("guid", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _guid
		data[_guid.tag] = service
		
	var data = {}
	
	var _guid: PBField
	func get_guid() -> String:
		return _guid.value
	func clear_guid() -> void:
		_guid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_guid(value : String) -> void:
		_guid.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_ship = PBField.new("ship", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ship
		data[_ship.tag] = service
		
		_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_angle = PBField.new("angle", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _angle
		data[_angle.tag] = service
		
		_spawned = PBField.new("spawned", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _spawned
		data[_spawned.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _ship: PBField
	func get_ship() -> int:
		return _ship.value
	func clear_ship() -> void:
		_ship.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ship(value : int) -> void:
		_ship.value = value
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		_y.value = value
	
	var _angle: PBField
	func get_angle() -> float:
		return _angle.value
	func clear_angle() -> void:
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_angle(value : float) -> void:
		_angle.value = value
	
	var _spawned: PBField
	func get_spawned() -> bool:
		return _spawned.value
	func clear_spawned() -> void:
		_spawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_spawned(value : bool) -> void:
		_spawned.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BoltExhaustedEventDto:
	func _init():
		var service
		
		_boltId = PBField.new("boltId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _boltId
		service.func_ref = funcref(self, "new_boltId")
		data[_boltId.tag] = service
		
		_ownerPlayerId = PBField.new("ownerPlayerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _ownerPlayerId
		service.func_ref = funcref(self, "new_ownerPlayerId")
		data[_ownerPlayerId.tag] = service
		
	var data = {}
	
	var _boltId: PBField
	func get_boltId() -> GUID:
		return _boltId.value
	func clear_boltId() -> void:
		_boltId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltId() -> GUID:
		_boltId.value = GUID.new()
		return _boltId.value
	
	var _ownerPlayerId: PBField
	func get_ownerPlayerId() -> GUID:
		return _ownerPlayerId.value
	func clear_ownerPlayerId() -> void:
		_ownerPlayerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ownerPlayerId() -> GUID:
		_ownerPlayerId.value = GUID.new()
		return _ownerPlayerId.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BoltFiredEventDto:
	func _init():
		var service
		
		_boltId = PBField.new("boltId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _boltId
		service.func_ref = funcref(self, "new_boltId")
		data[_boltId.tag] = service
		
		_ownerPlayerId = PBField.new("ownerPlayerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _ownerPlayerId
		service.func_ref = funcref(self, "new_ownerPlayerId")
		data[_ownerPlayerId.tag] = service
		
		_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_angle = PBField.new("angle", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _angle
		data[_angle.tag] = service
		
		_startTimestamp = PBField.new("startTimestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _startTimestamp
		data[_startTimestamp.tag] = service
		
		_speed = PBField.new("speed", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _speed
		data[_speed.tag] = service
		
		_ttl = PBField.new("ttl", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ttl
		data[_ttl.tag] = service
		
	var data = {}
	
	var _boltId: PBField
	func get_boltId() -> GUID:
		return _boltId.value
	func clear_boltId() -> void:
		_boltId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltId() -> GUID:
		_boltId.value = GUID.new()
		return _boltId.value
	
	var _ownerPlayerId: PBField
	func get_ownerPlayerId() -> GUID:
		return _ownerPlayerId.value
	func clear_ownerPlayerId() -> void:
		_ownerPlayerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ownerPlayerId() -> GUID:
		_ownerPlayerId.value = GUID.new()
		return _ownerPlayerId.value
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		_y.value = value
	
	var _angle: PBField
	func get_angle() -> float:
		return _angle.value
	func clear_angle() -> void:
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_angle(value : float) -> void:
		_angle.value = value
	
	var _startTimestamp: PBField
	func get_startTimestamp() -> int:
		return _startTimestamp.value
	func clear_startTimestamp() -> void:
		_startTimestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_startTimestamp(value : int) -> void:
		_startTimestamp.value = value
	
	var _speed: PBField
	func get_speed() -> float:
		return _speed.value
	func clear_speed() -> void:
		_speed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_speed(value : float) -> void:
		_speed.value = value
	
	var _ttl: PBField
	func get_ttl() -> int:
		return _ttl.value
	func clear_ttl() -> void:
		_ttl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ttl(value : int) -> void:
		_ttl.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerDestroyedEventDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_destroyedByPlayerId = PBField.new("destroyedByPlayerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _destroyedByPlayerId
		service.func_ref = funcref(self, "new_destroyedByPlayerId")
		data[_destroyedByPlayerId.tag] = service
		
		_destroyedTimestamp = PBField.new("destroyedTimestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _destroyedTimestamp
		data[_destroyedTimestamp.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _destroyedByPlayerId: PBField
	func get_destroyedByPlayerId() -> GUID:
		return _destroyedByPlayerId.value
	func clear_destroyedByPlayerId() -> void:
		_destroyedByPlayerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_destroyedByPlayerId() -> GUID:
		_destroyedByPlayerId.value = GUID.new()
		return _destroyedByPlayerId.value
	
	var _destroyedTimestamp: PBField
	func get_destroyedTimestamp() -> int:
		return _destroyedTimestamp.value
	func clear_destroyedTimestamp() -> void:
		_destroyedTimestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_destroyedTimestamp(value : int) -> void:
		_destroyedTimestamp.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerJoinedEventDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_ship = PBField.new("ship", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ship
		data[_ship.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _ship: PBField
	func get_ship() -> int:
		return _ship.value
	func clear_ship() -> void:
		_ship.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ship(value : int) -> void:
		_ship.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerLeftEventDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerMovedEventDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _x
		data[_x.tag] = service
		
		_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _y
		data[_y.tag] = service
		
		_angle = PBField.new("angle", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _angle
		data[_angle.tag] = service
		
		_thrustAngle = PBField.new("thrustAngle", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _thrustAngle
		data[_thrustAngle.tag] = service
		
		_timestamp = PBField.new("timestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _timestamp
		data[_timestamp.tag] = service
		
		_velocity = PBField.new("velocity", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _velocity
		data[_velocity.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _x: PBField
	func get_x() -> float:
		return _x.value
	func clear_x() -> void:
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		_x.value = value
	
	var _y: PBField
	func get_y() -> float:
		return _y.value
	func clear_y() -> void:
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		_y.value = value
	
	var _angle: PBField
	func get_angle() -> float:
		return _angle.value
	func clear_angle() -> void:
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_angle(value : float) -> void:
		_angle.value = value
	
	var _thrustAngle: PBField
	func get_thrustAngle() -> float:
		return _thrustAngle.value
	func clear_thrustAngle() -> void:
		_thrustAngle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_thrustAngle(value : float) -> void:
		_thrustAngle.value = value
	
	var _timestamp: PBField
	func get_timestamp() -> int:
		return _timestamp.value
	func clear_timestamp() -> void:
		_timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value : int) -> void:
		_timestamp.value = value
	
	var _velocity: PBField
	func get_velocity() -> float:
		return _velocity.value
	func clear_velocity() -> void:
		_velocity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_velocity(value : float) -> void:
		_velocity.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerSpawnedEventDto:
	func _init():
		var service
		
		_location = PBField.new("location", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _location
		service.func_ref = funcref(self, "new_location")
		data[_location.tag] = service
		
	var data = {}
	
	var _location: PBField
	func get_location() -> PlayerMovedEventDto:
		return _location.value
	func clear_location() -> void:
		_location.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_location() -> PlayerMovedEventDto:
		_location.value = PlayerMovedEventDto.new()
		return _location.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerScoreIncreasedEventDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_gained = PBField.new("gained", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _gained
		data[_gained.tag] = service
		
		_timestamp = PBField.new("timestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _timestamp
		data[_timestamp.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _gained: PBField
	func get_gained() -> int:
		return _gained.value
	func clear_gained() -> void:
		_gained.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_gained(value : int) -> void:
		_gained.value = value
	
	var _timestamp: PBField
	func get_timestamp() -> int:
		return _timestamp.value
	func clear_timestamp() -> void:
		_timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value : int) -> void:
		_timestamp.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerScoreUpdatedEventDto:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_score = PBField.new("score", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _score
		data[_score.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _score: PBField
	func get_score() -> int:
		return _score.value
	func clear_score() -> void:
		_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_score(value : int) -> void:
		_score.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ScoreEntry:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_score = PBField.new("score", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _score
		data[_score.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _score: PBField
	func get_score() -> int:
		return _score.value
	func clear_score() -> void:
		_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_score(value : int) -> void:
		_score.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ScoreBoardUpdatedEventDto:
	func _init():
		var service
		
		_scores = PBField.new("scores", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _scores
		service.func_ref = funcref(self, "add_scores")
		data[_scores.tag] = service
		
	var data = {}
	
	var _scores: PBField
	func get_scores() -> Array:
		return _scores.value
	func clear_scores() -> void:
		_scores.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_scores() -> ScoreEntry:
		var element = ScoreEntry.new()
		_scores.value.append(element)
		return element
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Event:
	func _init():
		var service
		
		_boltExhausted = PBField.new("boltExhausted", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _boltExhausted
		service.func_ref = funcref(self, "new_boltExhausted")
		data[_boltExhausted.tag] = service
		
		_boltFired = PBField.new("boltFired", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _boltFired
		service.func_ref = funcref(self, "new_boltFired")
		data[_boltFired.tag] = service
		
		_playerFired = PBField.new("playerFired", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerFired
		service.func_ref = funcref(self, "new_playerFired")
		data[_playerFired.tag] = service
		
		_playerDestroyed = PBField.new("playerDestroyed", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerDestroyed
		service.func_ref = funcref(self, "new_playerDestroyed")
		data[_playerDestroyed.tag] = service
		
		_playerJoined = PBField.new("playerJoined", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerJoined
		service.func_ref = funcref(self, "new_playerJoined")
		data[_playerJoined.tag] = service
		
		_playerLeft = PBField.new("playerLeft", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerLeft
		service.func_ref = funcref(self, "new_playerLeft")
		data[_playerLeft.tag] = service
		
		_playerMoved = PBField.new("playerMoved", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerMoved
		service.func_ref = funcref(self, "new_playerMoved")
		data[_playerMoved.tag] = service
		
		_playerSpawned = PBField.new("playerSpawned", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerSpawned
		service.func_ref = funcref(self, "new_playerSpawned")
		data[_playerSpawned.tag] = service
		
		_playerScoreIncreased = PBField.new("playerScoreIncreased", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerScoreIncreased
		service.func_ref = funcref(self, "new_playerScoreIncreased")
		data[_playerScoreIncreased.tag] = service
		
		_playerScoreUpdated = PBField.new("playerScoreUpdated", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerScoreUpdated
		service.func_ref = funcref(self, "new_playerScoreUpdated")
		data[_playerScoreUpdated.tag] = service
		
		_scoreBoardUpdated = PBField.new("scoreBoardUpdated", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _scoreBoardUpdated
		service.func_ref = funcref(self, "new_scoreBoardUpdated")
		data[_scoreBoardUpdated.tag] = service
		
	var data = {}
	
	var _boltExhausted: PBField
	func has_boltExhausted() -> bool:
		if data[1].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_boltExhausted() -> BoltExhaustedEventDto:
		return _boltExhausted.value
	func clear_boltExhausted() -> void:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltExhausted() -> BoltExhaustedEventDto:
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltExhausted.value = BoltExhaustedEventDto.new()
		return _boltExhausted.value
	
	var _boltFired: PBField
	func has_boltFired() -> bool:
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_boltFired() -> BoltFiredEventDto:
		return _boltFired.value
	func clear_boltFired() -> void:
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltFired() -> BoltFiredEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = BoltFiredEventDto.new()
		return _boltFired.value
	
	var _playerFired: PBField
	func has_playerFired() -> bool:
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerFired() -> BoltFiredEventDto:
		return _playerFired.value
	func clear_playerFired() -> void:
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerFired() -> BoltFiredEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = BoltFiredEventDto.new()
		return _playerFired.value
	
	var _playerDestroyed: PBField
	func has_playerDestroyed() -> bool:
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerDestroyed() -> PlayerDestroyedEventDto:
		return _playerDestroyed.value
	func clear_playerDestroyed() -> void:
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerDestroyed() -> PlayerDestroyedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = PlayerDestroyedEventDto.new()
		return _playerDestroyed.value
	
	var _playerJoined: PBField
	func has_playerJoined() -> bool:
		if data[5].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerJoined() -> PlayerJoinedEventDto:
		return _playerJoined.value
	func clear_playerJoined() -> void:
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerJoined() -> PlayerJoinedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = PlayerJoinedEventDto.new()
		return _playerJoined.value
	
	var _playerLeft: PBField
	func has_playerLeft() -> bool:
		if data[6].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerLeft() -> PlayerLeftEventDto:
		return _playerLeft.value
	func clear_playerLeft() -> void:
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerLeft() -> PlayerLeftEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = PlayerLeftEventDto.new()
		return _playerLeft.value
	
	var _playerMoved: PBField
	func has_playerMoved() -> bool:
		if data[7].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerMoved() -> PlayerMovedEventDto:
		return _playerMoved.value
	func clear_playerMoved() -> void:
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerMoved() -> PlayerMovedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = PlayerMovedEventDto.new()
		return _playerMoved.value
	
	var _playerSpawned: PBField
	func has_playerSpawned() -> bool:
		if data[8].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerSpawned() -> PlayerSpawnedEventDto:
		return _playerSpawned.value
	func clear_playerSpawned() -> void:
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerSpawned() -> PlayerSpawnedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = PlayerSpawnedEventDto.new()
		return _playerSpawned.value
	
	var _playerScoreIncreased: PBField
	func has_playerScoreIncreased() -> bool:
		if data[9].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerScoreIncreased() -> PlayerScoreIncreasedEventDto:
		return _playerScoreIncreased.value
	func clear_playerScoreIncreased() -> void:
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerScoreIncreased() -> PlayerScoreIncreasedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = PlayerScoreIncreasedEventDto.new()
		return _playerScoreIncreased.value
	
	var _playerScoreUpdated: PBField
	func has_playerScoreUpdated() -> bool:
		if data[10].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerScoreUpdated() -> PlayerScoreUpdatedEventDto:
		return _playerScoreUpdated.value
	func clear_playerScoreUpdated() -> void:
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerScoreUpdated() -> PlayerScoreUpdatedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = PlayerScoreUpdatedEventDto.new()
		return _playerScoreUpdated.value
	
	var _scoreBoardUpdated: PBField
	func has_scoreBoardUpdated() -> bool:
		if data[11].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_scoreBoardUpdated() -> ScoreBoardUpdatedEventDto:
		return _scoreBoardUpdated.value
	func clear_scoreBoardUpdated() -> void:
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_scoreBoardUpdated() -> ScoreBoardUpdatedEventDto:
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_scoreBoardUpdated.value = ScoreBoardUpdatedEventDto.new()
		return _scoreBoardUpdated.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Events:
	func _init():
		var service
		
		_events = PBField.new("events", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _events
		service.func_ref = funcref(self, "add_events")
		data[_events.tag] = service
		
	var data = {}
	
	var _events: PBField
	func get_events() -> Array:
		return _events.value
	func clear_events() -> void:
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_events() -> Event:
		var element = Event.new()
		_events.value.append(element)
		return element
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MoveCommandDto:
	func _init():
		var service
		
		_moveX = PBField.new("moveX", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _moveX
		data[_moveX.tag] = service
		
		_moveY = PBField.new("moveY", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _moveY
		data[_moveY.tag] = service
		
		_angle = PBField.new("angle", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _angle
		service.func_ref = funcref(self, "new_angle")
		data[_angle.tag] = service
		
	var data = {}
	
	var _moveX: PBField
	func get_moveX() -> float:
		return _moveX.value
	func clear_moveX() -> void:
		_moveX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_moveX(value : float) -> void:
		_moveX.value = value
	
	var _moveY: PBField
	func get_moveY() -> float:
		return _moveY.value
	func clear_moveY() -> void:
		_moveY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_moveY(value : float) -> void:
		_moveY.value = value
	
	var _angle: PBField
	func get_angle() -> FloatValue:
		return _angle.value
	func clear_angle() -> void:
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_angle() -> FloatValue:
		_angle.value = FloatValue.new()
		return _angle.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class FireBoltCommandDto:
	func _init():
		var service
		
	var data = {}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SpawnCommandDto:
	func _init():
		var service
		
	var data = {}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinCommandDto:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RequestCommand:
	func _init():
		var service
		
		_move = PBField.new("move", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _move
		service.func_ref = funcref(self, "new_move")
		data[_move.tag] = service
		
		_fire = PBField.new("fire", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _fire
		service.func_ref = funcref(self, "new_fire")
		data[_fire.tag] = service
		
		_spawn = PBField.new("spawn", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _spawn
		service.func_ref = funcref(self, "new_spawn")
		data[_spawn.tag] = service
		
		_join = PBField.new("join", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _join
		service.func_ref = funcref(self, "new_join")
		data[_join.tag] = service
		
	var data = {}
	
	var _move: PBField
	func has_move() -> bool:
		if data[1].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_move() -> MoveCommandDto:
		return _move.value
	func clear_move() -> void:
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_move() -> MoveCommandDto:
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_move.value = MoveCommandDto.new()
		return _move.value
	
	var _fire: PBField
	func has_fire() -> bool:
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_fire() -> FireBoltCommandDto:
		return _fire.value
	func clear_fire() -> void:
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_fire() -> FireBoltCommandDto:
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_fire.value = FireBoltCommandDto.new()
		return _fire.value
	
	var _spawn: PBField
	func has_spawn() -> bool:
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_spawn() -> SpawnCommandDto:
		return _spawn.value
	func clear_spawn() -> void:
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_spawn() -> SpawnCommandDto:
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = SpawnCommandDto.new()
		return _spawn.value
	
	var _join: PBField
	func has_join() -> bool:
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_join() -> JoinCommandDto:
		return _join.value
	func clear_join() -> void:
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_join() -> JoinCommandDto:
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = JoinCommandDto.new()
		return _join.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayersListCommandDto:
	func _init():
		var service
		
		_players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _players
		service.func_ref = funcref(self, "add_players")
		data[_players.tag] = service
		
	var data = {}
	
	var _players: PBField
	func get_players() -> Array:
		return _players.value
	func clear_players() -> void:
		_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_players() -> PlayerDto:
		var element = PlayerDto.new()
		_players.value.append(element)
		return element
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerScoreUpdateCommandDto:
	func _init():
		var service
		
		_score = PBField.new("score", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _score
		data[_score.tag] = service
		
	var data = {}
	
	var _score: PBField
	func get_score() -> int:
		return _score.value
	func clear_score() -> void:
		_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_score(value : int) -> void:
		_score.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LiveBoltListCommandDto:
	func _init():
		var service
		
		_bolts = PBField.new("bolts", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _bolts
		service.func_ref = funcref(self, "add_bolts")
		data[_bolts.tag] = service
		
	var data = {}
	
	var _bolts: PBField
	func get_bolts() -> Array:
		return _bolts.value
	func clear_bolts() -> void:
		_bolts.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_bolts() -> BoltFiredEventDto:
		var element = BoltFiredEventDto.new()
		_bolts.value.append(element)
		return element
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DirectedCommand:
	func _init():
		var service
		
		_playerId = PBField.new("playerId", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerId
		service.func_ref = funcref(self, "new_playerId")
		data[_playerId.tag] = service
		
		_playersList = PBField.new("playersList", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playersList
		service.func_ref = funcref(self, "new_playersList")
		data[_playersList.tag] = service
		
		_playerScoreUpdate = PBField.new("playerScoreUpdate", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _playerScoreUpdate
		service.func_ref = funcref(self, "new_playerScoreUpdate")
		data[_playerScoreUpdate.tag] = service
		
		_liveBoltsList = PBField.new("liveBoltsList", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _liveBoltsList
		service.func_ref = funcref(self, "new_liveBoltsList")
		data[_liveBoltsList.tag] = service
		
	var data = {}
	
	var _playerId: PBField
	func get_playerId() -> GUID:
		return _playerId.value
	func clear_playerId() -> void:
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId() -> GUID:
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _playersList: PBField
	func has_playersList() -> bool:
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playersList() -> PlayersListCommandDto:
		return _playersList.value
	func clear_playersList() -> void:
		_playersList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playersList() -> PlayersListCommandDto:
		_playerScoreUpdate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_liveBoltsList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playersList.value = PlayersListCommandDto.new()
		return _playersList.value
	
	var _playerScoreUpdate: PBField
	func has_playerScoreUpdate() -> bool:
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerScoreUpdate() -> PlayerScoreUpdateCommandDto:
		return _playerScoreUpdate.value
	func clear_playerScoreUpdate() -> void:
		_playerScoreUpdate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerScoreUpdate() -> PlayerScoreUpdateCommandDto:
		_playersList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_liveBoltsList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdate.value = PlayerScoreUpdateCommandDto.new()
		return _playerScoreUpdate.value
	
	var _liveBoltsList: PBField
	func has_liveBoltsList() -> bool:
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_liveBoltsList() -> LiveBoltListCommandDto:
		return _liveBoltsList.value
	func clear_liveBoltsList() -> void:
		_liveBoltsList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_liveBoltsList() -> LiveBoltListCommandDto:
		_playersList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_liveBoltsList.value = LiveBoltListCommandDto.new()
		return _liveBoltsList.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Flush:
	func _init():
		var service
		
	var data = {}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ClockSync:
	func _init():
		var service
		
		_time = PBField.new("time", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _time
		data[_time.tag] = service
		
	var data = {}
	
	var _time: PBField
	func get_time() -> int:
		return _time.value
	func clear_time() -> void:
		_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_time(value : int) -> void:
		_time.value = value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Dto:
	func _init():
		var service
		
		_directedCommand = PBField.new("directedCommand", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _directedCommand
		service.func_ref = funcref(self, "new_directedCommand")
		data[_directedCommand.tag] = service
		
		_event = PBField.new("event", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _event
		service.func_ref = funcref(self, "new_event")
		data[_event.tag] = service
		
		_events = PBField.new("events", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _events
		service.func_ref = funcref(self, "new_events")
		data[_events.tag] = service
		
		_flush = PBField.new("flush", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _flush
		service.func_ref = funcref(self, "new_flush")
		data[_flush.tag] = service
		
		_clock = PBField.new("clock", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _clock
		service.func_ref = funcref(self, "new_clock")
		data[_clock.tag] = service
		
	var data = {}
	
	var _directedCommand: PBField
	func has_directedCommand() -> bool:
		if data[1].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_directedCommand() -> DirectedCommand:
		return _directedCommand.value
	func clear_directedCommand() -> void:
		data[_directedCommand.tag].state = PB_SERVICE_STATE.UNFILLED
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_directedCommand() -> DirectedCommand:
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_directedCommand.value = DirectedCommand.new()
		return _directedCommand.value
	
	var _event: PBField
	func has_event() -> bool:
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_event() -> Event:
		return _event.value
	func clear_event() -> void:
		data[_event.tag].state = PB_SERVICE_STATE.UNFILLED
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_event() -> Event:
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = Event.new()
		return _event.value
	
	var _events: PBField
	func has_events() -> bool:
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_events() -> Events:
		return _events.value
	func clear_events() -> void:
		data[_events.tag].state = PB_SERVICE_STATE.UNFILLED
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_events() -> Events:
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = Events.new()
		return _events.value
	
	var _flush: PBField
	func has_flush() -> bool:
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_flush() -> Flush:
		return _flush.value
	func clear_flush() -> void:
		data[_flush.tag].state = PB_SERVICE_STATE.UNFILLED
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_flush() -> Flush:
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = Flush.new()
		return _flush.value
	
	var _clock: PBField
	func has_clock() -> bool:
		if data[5].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_clock() -> ClockSync:
		return _clock.value
	func clear_clock() -> void:
		data[_clock.tag].state = PB_SERVICE_STATE.UNFILLED
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_clock() -> ClockSync:
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = ClockSync.new()
		return _clock.value
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
