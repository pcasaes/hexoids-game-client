const PROTO_VERSION = 3

#
# BSD 3-Clause License
#
# Copyright (c) 2018, Oleg Malyavkin
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
const DEBUG_TAB = "  "

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
	func _init(a_name, a_type, a_rule, a_tag, packed, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
	var name
	var type
	var rule
	var tag
	var option_packed
	var value
	var option_default = false

class PBLengthDelimitedField:
	var type = null
	var tag = null
	var begin = null
	var size = null

class PBUnpackedField:
	var offset
	var field

class PBTypeTag:
	var type = null
	var tag = null
	var offset = null

class PBServiceField:
	var field
	var func_ref = null
	var state = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n):
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n):
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value):
		var varint = PoolByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for i in range(9):
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

	static func pack_bytes(value, count, data_type):
		var bytes = PoolByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes, index, count, data_type):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb = StreamPeerBuffer.new()
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

	static func unpack_varint(varint_bytes):
		var value = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type, tag):
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes, index):
		var result = PoolByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes, index):
		var varint_bytes = isolate_varint(bytes, index)
		var result = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.offset = varint_bytes.size()
			var unpacked = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type, tag, bytes):
		var result = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func unpack_length_delimiter(bytes, index):
		var result = PBLengthDelimitedField.new()
		var type_tag = unpack_type_tag(bytes, index)
		var offset = type_tag.offset
		if offset != null:
			result.type = type_tag.type
			result.tag = type_tag.tag
			var size = isolate_varint(bytes, offset)
			if size > 0:
				offset += size
				if bytes.size() >= size + offset:
					result.begin = offset
					result.size = size
		return result

	static func pb_type_from_data_type(data_type):
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

	static func pack_field(field):
		var type = pb_type_from_data_type(field.type)
		var type_copy = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head = pack_type_tag(type, field.tag)
		var data = PoolByteArray()
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
						var signed_value
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
						var obj = v.to_bytes()
						#if obj != null && obj.size() > 0:
						#	data.append_array(pack_length_delimeted(type, field.tag, obj))
						#else:
						#	data = PoolByteArray()
						#	return data
						if obj != null:#
							data.append_array(pack_length_delimeted(type, field.tag, obj))#
						else:#
							data = PoolByteArray()#
							return data#
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes = field.value.to_utf8()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj = field.value.to_bytes()
					#if obj != null && obj.size() > 0:
					#	data.append_array(obj)
					#	return pack_length_delimeted(type, field.tag, data)
					if obj != null:#
						if obj.size() > 0:#
							data.append_array(obj)#
						return pack_length_delimeted(type, field.tag, data)#
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes, offset, field, type, message_func_ref):
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
							var str_bytes = PoolByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes = PoolByteArray()
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

	static func unpack_message(data, bytes, offset, limit):
		while true:
			var tt = unpack_type_tag(bytes, offset)
			if tt.offset != null:
				offset += tt.offset
				if data.has(tt.tag):
					var service = data[tt.tag]
					var type = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res = unpack_field(bytes, offset, service.field, type, service.func_ref)
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

	static func pack_message(data):
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result = PoolByteArray()
		var keys = data.keys()
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
				return null
		return result

	static func check_required(data):
		var keys = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text, nesting):
		var tab = ""
		for i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field, nesting):
		var result = ""
		var text
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
	
	static func field_to_string(field, nesting):
		var result = tabulate(field.name + ": ", nesting)
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
		
	static func message_to_string(data, nesting = 0):
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result = ""
		var keys = data.keys()
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
	
	var _value
	func get_value():
		return _value.value
	func clear_value():
		_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_value(value):
		_value.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _guid
	func get_guid():
		return _guid.value
	func clear_guid():
		_guid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_guid(value):
		_guid.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _ship
	func get_ship():
		return _ship.value
	func clear_ship():
		_ship.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ship(value):
		_ship.value = value
	
	var _x
	func get_x():
		return _x.value
	func clear_x():
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value):
		_x.value = value
	
	var _y
	func get_y():
		return _y.value
	func clear_y():
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value):
		_y.value = value
	
	var _angle
	func get_angle():
		return _angle.value
	func clear_angle():
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_angle(value):
		_angle.value = value
	
	var _spawned
	func get_spawned():
		return _spawned.value
	func clear_spawned():
		_spawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_spawned(value):
		_spawned.value = value
	
	var _name
	func get_name():
		return _name.value
	func clear_name():
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value):
		_name.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _boltId
	func get_boltId():
		return _boltId.value
	func clear_boltId():
		_boltId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltId():
		_boltId.value = GUID.new()
		return _boltId.value
	
	var _ownerPlayerId
	func get_ownerPlayerId():
		return _ownerPlayerId.value
	func clear_ownerPlayerId():
		_ownerPlayerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ownerPlayerId():
		_ownerPlayerId.value = GUID.new()
		return _ownerPlayerId.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _boltId
	func get_boltId():
		return _boltId.value
	func clear_boltId():
		_boltId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltId():
		_boltId.value = GUID.new()
		return _boltId.value
	
	var _ownerPlayerId
	func get_ownerPlayerId():
		return _ownerPlayerId.value
	func clear_ownerPlayerId():
		_ownerPlayerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ownerPlayerId():
		_ownerPlayerId.value = GUID.new()
		return _ownerPlayerId.value
	
	var _x
	func get_x():
		return _x.value
	func clear_x():
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value):
		_x.value = value
	
	var _y
	func get_y():
		return _y.value
	func clear_y():
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value):
		_y.value = value
	
	var _angle
	func get_angle():
		return _angle.value
	func clear_angle():
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_angle(value):
		_angle.value = value
	
	var _startTimestamp
	func get_startTimestamp():
		return _startTimestamp.value
	func clear_startTimestamp():
		_startTimestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_startTimestamp(value):
		_startTimestamp.value = value
	
	var _speed
	func get_speed():
		return _speed.value
	func clear_speed():
		_speed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_speed(value):
		_speed.value = value
	
	var _ttl
	func get_ttl():
		return _ttl.value
	func clear_ttl():
		_ttl.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ttl(value):
		_ttl.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _destroyedByPlayerId
	func get_destroyedByPlayerId():
		return _destroyedByPlayerId.value
	func clear_destroyedByPlayerId():
		_destroyedByPlayerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_destroyedByPlayerId():
		_destroyedByPlayerId.value = GUID.new()
		return _destroyedByPlayerId.value
	
	var _destroyedTimestamp
	func get_destroyedTimestamp():
		return _destroyedTimestamp.value
	func clear_destroyedTimestamp():
		_destroyedTimestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_destroyedTimestamp(value):
		_destroyedTimestamp.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _ship
	func get_ship():
		return _ship.value
	func clear_ship():
		_ship.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ship(value):
		_ship.value = value
	
	var _name
	func get_name():
		return _name.value
	func clear_name():
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value):
		_name.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _x
	func get_x():
		return _x.value
	func clear_x():
		_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value):
		_x.value = value
	
	var _y
	func get_y():
		return _y.value
	func clear_y():
		_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value):
		_y.value = value
	
	var _angle
	func get_angle():
		return _angle.value
	func clear_angle():
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_angle(value):
		_angle.value = value
	
	var _thrustAngle
	func get_thrustAngle():
		return _thrustAngle.value
	func clear_thrustAngle():
		_thrustAngle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_thrustAngle(value):
		_thrustAngle.value = value
	
	var _timestamp
	func get_timestamp():
		return _timestamp.value
	func clear_timestamp():
		_timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value):
		_timestamp.value = value
	
	var _velocity
	func get_velocity():
		return _velocity.value
	func clear_velocity():
		_velocity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_velocity(value):
		_velocity.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _location
	func get_location():
		return _location.value
	func clear_location():
		_location.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_location():
		_location.value = PlayerMovedEventDto.new()
		return _location.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _gained
	func get_gained():
		return _gained.value
	func clear_gained():
		_gained.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_gained(value):
		_gained.value = value
	
	var _timestamp
	func get_timestamp():
		return _timestamp.value
	func clear_timestamp():
		_timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value):
		_timestamp.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _score
	func get_score():
		return _score.value
	func clear_score():
		_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_score(value):
		_score.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _score
	func get_score():
		return _score.value
	func clear_score():
		_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_score(value):
		_score.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _scores
	func get_scores():
		return _scores.value
	func clear_scores():
		_scores.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_scores():
		var element = ScoreEntry.new()
		_scores.value.append(element)
		return element
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _boltExhausted
	func has_boltExhausted():
		if data[1].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_boltExhausted():
		return _boltExhausted.value
	func clear_boltExhausted():
		_boltExhausted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltExhausted():
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
	
	var _boltFired
	func has_boltFired():
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_boltFired():
		return _boltFired.value
	func clear_boltFired():
		_boltFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_boltFired():
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
	
	var _playerFired
	func has_playerFired():
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerFired():
		return _playerFired.value
	func clear_playerFired():
		_playerFired.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerFired():
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
	
	var _playerDestroyed
	func has_playerDestroyed():
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerDestroyed():
		return _playerDestroyed.value
	func clear_playerDestroyed():
		_playerDestroyed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerDestroyed():
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
	
	var _playerJoined
	func has_playerJoined():
		if data[5].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerJoined():
		return _playerJoined.value
	func clear_playerJoined():
		_playerJoined.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerJoined():
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
	
	var _playerLeft
	func has_playerLeft():
		if data[6].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerLeft():
		return _playerLeft.value
	func clear_playerLeft():
		_playerLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerLeft():
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
	
	var _playerMoved
	func has_playerMoved():
		if data[7].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerMoved():
		return _playerMoved.value
	func clear_playerMoved():
		_playerMoved.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerMoved():
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
	
	var _playerSpawned
	func has_playerSpawned():
		if data[8].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerSpawned():
		return _playerSpawned.value
	func clear_playerSpawned():
		_playerSpawned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerSpawned():
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
	
	var _playerScoreIncreased
	func has_playerScoreIncreased():
		if data[9].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerScoreIncreased():
		return _playerScoreIncreased.value
	func clear_playerScoreIncreased():
		_playerScoreIncreased.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerScoreIncreased():
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
	
	var _playerScoreUpdated
	func has_playerScoreUpdated():
		if data[10].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerScoreUpdated():
		return _playerScoreUpdated.value
	func clear_playerScoreUpdated():
		_playerScoreUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerScoreUpdated():
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
	
	var _scoreBoardUpdated
	func has_scoreBoardUpdated():
		if data[11].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_scoreBoardUpdated():
		return _scoreBoardUpdated.value
	func clear_scoreBoardUpdated():
		_scoreBoardUpdated.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_scoreBoardUpdated():
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
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _events
	func get_events():
		return _events.value
	func clear_events():
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_events():
		var element = Event.new()
		_events.value.append(element)
		return element
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _moveX
	func get_moveX():
		return _moveX.value
	func clear_moveX():
		_moveX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_moveX(value):
		_moveX.value = value
	
	var _moveY
	func get_moveY():
		return _moveY.value
	func clear_moveY():
		_moveY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_moveY(value):
		_moveY.value = value
	
	var _angle
	func get_angle():
		return _angle.value
	func clear_angle():
		_angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_angle():
		_angle.value = FloatValue.new()
		return _angle.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _name
	func get_name():
		return _name.value
	func clear_name():
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value):
		_name.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _move
	func has_move():
		if data[1].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_move():
		return _move.value
	func clear_move():
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_move():
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_move.value = MoveCommandDto.new()
		return _move.value
	
	var _fire
	func has_fire():
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_fire():
		return _fire.value
	func clear_fire():
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_fire():
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_fire.value = FireBoltCommandDto.new()
		return _fire.value
	
	var _spawn
	func has_spawn():
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_spawn():
		return _spawn.value
	func clear_spawn():
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_spawn():
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = SpawnCommandDto.new()
		return _spawn.value
	
	var _join
	func has_join():
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_join():
		return _join.value
	func clear_join():
		_join.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_join():
		_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_fire.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_spawn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_join.value = JoinCommandDto.new()
		return _join.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _players
	func get_players():
		return _players.value
	func clear_players():
		_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_players():
		var element = PlayerDto.new()
		_players.value.append(element)
		return element
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _score
	func get_score():
		return _score.value
	func clear_score():
		_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_score(value):
		_score.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _bolts
	func get_bolts():
		return _bolts.value
	func clear_bolts():
		_bolts.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_bolts():
		var element = BoltFiredEventDto.new()
		_bolts.value.append(element)
		return element
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _playerId
	func get_playerId():
		return _playerId.value
	func clear_playerId():
		_playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerId():
		_playerId.value = GUID.new()
		return _playerId.value
	
	var _playersList
	func has_playersList():
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playersList():
		return _playersList.value
	func clear_playersList():
		_playersList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playersList():
		_playerScoreUpdate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_liveBoltsList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playersList.value = PlayersListCommandDto.new()
		return _playersList.value
	
	var _playerScoreUpdate
	func has_playerScoreUpdate():
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_playerScoreUpdate():
		return _playerScoreUpdate.value
	func clear_playerScoreUpdate():
		_playerScoreUpdate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_playerScoreUpdate():
		_playersList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_liveBoltsList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdate.value = PlayerScoreUpdateCommandDto.new()
		return _playerScoreUpdate.value
	
	var _liveBoltsList
	func has_liveBoltsList():
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_liveBoltsList():
		return _liveBoltsList.value
	func clear_liveBoltsList():
		_liveBoltsList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_liveBoltsList():
		_playersList.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_playerScoreUpdate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_liveBoltsList.value = LiveBoltListCommandDto.new()
		return _liveBoltsList.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _time
	func get_time():
		return _time.value
	func clear_time():
		_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_time(value):
		_time.value = value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
	
	var _directedCommand
	func has_directedCommand():
		if data[1].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_directedCommand():
		return _directedCommand.value
	func clear_directedCommand():
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_directedCommand():
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_directedCommand.value = DirectedCommand.new()
		return _directedCommand.value
	
	var _event
	func has_event():
		if data[2].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_event():
		return _event.value
	func clear_event():
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_event():
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = Event.new()
		return _event.value
	
	var _events
	func has_events():
		if data[3].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_events():
		return _events.value
	func clear_events():
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_events():
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = Events.new()
		return _events.value
	
	var _flush
	func has_flush():
		if data[4].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_flush():
		return _flush.value
	func clear_flush():
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_flush():
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = Flush.new()
		return _flush.value
	
	var _clock
	func has_clock():
		if data[5].state == PB_SERVICE_STATE.FILLED:
			return true
		return false
	func get_clock():
		return _clock.value
	func clear_clock():
		_clock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_clock():
		_directedCommand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_event.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_events.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_flush.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		_clock.value = ClockSync.new()
		return _clock.value
	
	func to_string():
		return PBPacker.message_to_string(data)
		
	func to_bytes():
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes, offset = 0, limit = -1):
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
