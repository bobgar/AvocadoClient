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
class GenericMessage:
	func _init():
		pass
		
class GameState:
	func _init():
		pass
		
class PlayerJoin:
	func _init():
		pass
		
class Score:
	func _init():
		pass
		
class Bullet:
	func _init():
		pass
		
class Ship:
	func _init():
		pass
		
class ShipUpdate:
	func _init():
		pass
		
class JoinGame:
	func _init():
		pass
		
class SetTeamAndShip:
	func _init():
		pass
		
class UpdateTeamAndShip:
	func _init():
		pass
		
class Login:
	func _init():
		pass
		


class GenericMessage:
	func _init():
		var service
		
		_messageType = PBField.new("messageType", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _messageType
		data[_messageType.tag] = service
		
		_data = PBField.new("data", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = _data
		data[_data.tag] = service
		
	var data = {}
	
	var _messageType
	func get_messageType():
		return _messageType.value
	func clear_messageType():
		_messageType.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_messageType(value):
		_messageType.value = value
	
	var _data
	func get_data():
		return _data.value
	func clear_data():
		_data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_data(value):
		_data.value = value
	
	enum MessageTypeEnum {
		GAME_STATE_UPDATE = 0,
		SHIP_UPDATE = 1,
		JOIN_GAME = 2,
		SET_TEAM_AND_SHIP = 3
	}
	
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
	
class GameState:
	func _init():
		var service
		
		_ships = PBField.new("ships", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _ships
		service.func_ref = funcref(self, "add_ships")
		data[_ships.tag] = service
		
		_bullets = PBField.new("bullets", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _bullets
		service.func_ref = funcref(self, "add_bullets")
		data[_bullets.tag] = service
		
		_scores = PBField.new("scores", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _scores
		service.func_ref = funcref(self, "add_scores")
		data[_scores.tag] = service
		
		_updateTeamAndShip = PBField.new("updateTeamAndShip", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _updateTeamAndShip
		service.func_ref = funcref(self, "add_updateTeamAndShip")
		data[_updateTeamAndShip.tag] = service
		
		_playersJoining = PBField.new("playersJoining", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _playersJoining
		service.func_ref = funcref(self, "add_playersJoining")
		data[_playersJoining.tag] = service
		
		_PlayerLeave = PBField.new("PlayerLeave", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _PlayerLeave
		data[_PlayerLeave.tag] = service
		
	var data = {}
	
	var _ships
	func get_ships():
		return _ships.value
	func clear_ships():
		_ships.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_ships():
		var element = Ship.new()
		_ships.value.append(element)
		return element
	
	var _bullets
	func get_bullets():
		return _bullets.value
	func clear_bullets():
		_bullets.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_bullets():
		var element = Bullet.new()
		_bullets.value.append(element)
		return element
	
	var _scores
	func get_scores():
		return _scores.value
	func clear_scores():
		_scores.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_scores():
		var element = Score.new()
		_scores.value.append(element)
		return element
	
	var _updateTeamAndShip
	func get_updateTeamAndShip():
		return _updateTeamAndShip.value
	func clear_updateTeamAndShip():
		_updateTeamAndShip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_updateTeamAndShip():
		var element = UpdateTeamAndShip.new()
		_updateTeamAndShip.value.append(element)
		return element
	
	var _playersJoining
	func get_playersJoining():
		return _playersJoining.value
	func clear_playersJoining():
		_playersJoining.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func add_playersJoining():
		var element = PlayerJoin.new()
		_playersJoining.value.append(element)
		return element
	
	var _PlayerLeave
	func get_PlayerLeave():
		return _PlayerLeave.value
	func clear_PlayerLeave():
		_PlayerLeave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func add_PlayerLeave(value):
		_PlayerLeave.value.append(value)
	
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
	
class PlayerJoin:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_userName = PBField.new("userName", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _userName
		data[_userName.tag] = service
		
	var data = {}
	
	var _id
	func get_id():
		return _id.value
	func clear_id():
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_id(value):
		_id.value = value
	
	var _userName
	func get_userName():
		return _userName.value
	func clear_userName():
		_userName.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userName(value):
		_userName.value = value
	
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
	
class Score:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_kills = PBField.new("kills", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _kills
		data[_kills.tag] = service
		
		_deaths = PBField.new("deaths", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _deaths
		data[_deaths.tag] = service
		
		_assists = PBField.new("assists", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _assists
		data[_assists.tag] = service
		
		_goals = PBField.new("goals", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _goals
		data[_goals.tag] = service
		
	var data = {}
	
	var _id
	func get_id():
		return _id.value
	func clear_id():
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_id(value):
		_id.value = value
	
	var _kills
	func get_kills():
		return _kills.value
	func clear_kills():
		_kills.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_kills(value):
		_kills.value = value
	
	var _deaths
	func get_deaths():
		return _deaths.value
	func clear_deaths():
		_deaths.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_deaths(value):
		_deaths.value = value
	
	var _assists
	func get_assists():
		return _assists.value
	func clear_assists():
		_assists.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_assists(value):
		_assists.value = value
	
	var _goals
	func get_goals():
		return _goals.value
	func clear_goals():
		_goals.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_goals(value):
		_goals.value = value
	
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
	
enum BulletType {
	NORMAL = 0
}

enum State {
	SPAWN = 0,
	ALIVE = 1,
	DEAD = 2,
	INVULN = 3,
	DESTROY = 4
}

class Bullet:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_ownerId = PBField.new("ownerId", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ownerId
		data[_ownerId.tag] = service
		
		_type = PBField.new("type", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _type
		data[_type.tag] = service
		
		_state = PBField.new("state", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _state
		data[_state.tag] = service
		
		_xPos = PBField.new("xPos", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _xPos
		data[_xPos.tag] = service
		
		_yPos = PBField.new("yPos", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _yPos
		data[_yPos.tag] = service
		
		_xVel = PBField.new("xVel", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _xVel
		data[_xVel.tag] = service
		
		_yVel = PBField.new("yVel", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _yVel
		data[_yVel.tag] = service
		
	var data = {}
	
	var _id
	func get_id():
		return _id.value
	func clear_id():
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_id(value):
		_id.value = value
	
	var _ownerId
	func get_ownerId():
		return _ownerId.value
	func clear_ownerId():
		_ownerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ownerId(value):
		_ownerId.value = value
	
	var _type
	func get_type():
		return _type.value
	func clear_type():
		_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_type(value):
		_type.value = value
	
	var _state
	func get_state():
		return _state.value
	func clear_state():
		_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_state(value):
		_state.value = value
	
	var _xPos
	func get_xPos():
		return _xPos.value
	func clear_xPos():
		_xPos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_xPos(value):
		_xPos.value = value
	
	var _yPos
	func get_yPos():
		return _yPos.value
	func clear_yPos():
		_yPos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_yPos(value):
		_yPos.value = value
	
	var _xVel
	func get_xVel():
		return _xVel.value
	func clear_xVel():
		_xVel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_xVel(value):
		_xVel.value = value
	
	var _yVel
	func get_yVel():
		return _yVel.value
	func clear_yVel():
		_yVel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_yVel(value):
		_yVel.value = value
	
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
	
class Ship:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_state = PBField.new("state", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _state
		data[_state.tag] = service
		
		_xPos = PBField.new("xPos", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _xPos
		data[_xPos.tag] = service
		
		_yPos = PBField.new("yPos", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _yPos
		data[_yPos.tag] = service
		
		_xVel = PBField.new("xVel", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _xVel
		data[_xVel.tag] = service
		
		_yVel = PBField.new("yVel", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _yVel
		data[_yVel.tag] = service
		
		_rot = PBField.new("rot", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _rot
		data[_rot.tag] = service
		
		_rotVel = PBField.new("rotVel", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _rotVel
		data[_rotVel.tag] = service
		
		_health = PBField.new("health", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _health
		data[_health.tag] = service
		
	var data = {}
	
	var _id
	func get_id():
		return _id.value
	func clear_id():
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_id(value):
		_id.value = value
	
	var _state
	func get_state():
		return _state.value
	func clear_state():
		_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_state(value):
		_state.value = value
	
	var _xPos
	func get_xPos():
		return _xPos.value
	func clear_xPos():
		_xPos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_xPos(value):
		_xPos.value = value
	
	var _yPos
	func get_yPos():
		return _yPos.value
	func clear_yPos():
		_yPos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_yPos(value):
		_yPos.value = value
	
	var _xVel
	func get_xVel():
		return _xVel.value
	func clear_xVel():
		_xVel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_xVel(value):
		_xVel.value = value
	
	var _yVel
	func get_yVel():
		return _yVel.value
	func clear_yVel():
		_yVel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_yVel(value):
		_yVel.value = value
	
	var _rot
	func get_rot():
		return _rot.value
	func clear_rot():
		_rot.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_rot(value):
		_rot.value = value
	
	var _rotVel
	func get_rotVel():
		return _rotVel.value
	func clear_rotVel():
		_rotVel.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_rotVel(value):
		_rotVel.value = value
	
	var _health
	func get_health():
		return _health.value
	func clear_health():
		_health.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_health(value):
		_health.value = value
	
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
	
class ShipUpdate:
	func _init():
		var service
		
		_rotLeft = PBField.new("rotLeft", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _rotLeft
		data[_rotLeft.tag] = service
		
		_rotRight = PBField.new("rotRight", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _rotRight
		data[_rotRight.tag] = service
		
		_thrust = PBField.new("thrust", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _thrust
		data[_thrust.tag] = service
		
		_ability1 = PBField.new("ability1", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _ability1
		data[_ability1.tag] = service
		
		_ability2 = PBField.new("ability2", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _ability2
		data[_ability2.tag] = service
		
	var data = {}
	
	var _rotLeft
	func get_rotLeft():
		return _rotLeft.value
	func clear_rotLeft():
		_rotLeft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_rotLeft(value):
		_rotLeft.value = value
	
	var _rotRight
	func get_rotRight():
		return _rotRight.value
	func clear_rotRight():
		_rotRight.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_rotRight(value):
		_rotRight.value = value
	
	var _thrust
	func get_thrust():
		return _thrust.value
	func clear_thrust():
		_thrust.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_thrust(value):
		_thrust.value = value
	
	var _ability1
	func get_ability1():
		return _ability1.value
	func clear_ability1():
		_ability1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_ability1(value):
		_ability1.value = value
	
	var _ability2
	func get_ability2():
		return _ability2.value
	func clear_ability2():
		_ability2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_ability2(value):
		_ability2.value = value
	
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
	
class JoinGame:
	func _init():
		var service
		
		_gameId = PBField.new("gameId", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _gameId
		data[_gameId.tag] = service
		
	var data = {}
	
	var _gameId
	func get_gameId():
		return _gameId.value
	func clear_gameId():
		_gameId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_gameId(value):
		_gameId.value = value
	
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
	
enum ShipTypeEnum {
	HEAVY = 0,
	FORWARD = 1,
	SCOUT = 2
}

class SetTeamAndShip:
	func _init():
		var service
		
		_team = PBField.new("team", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _team
		data[_team.tag] = service
		
		_shipType = PBField.new("shipType", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _shipType
		data[_shipType.tag] = service
		
	var data = {}
	
	var _team
	func get_team():
		return _team.value
	func clear_team():
		_team.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_team(value):
		_team.value = value
	
	var _shipType
	func get_shipType():
		return _shipType.value
	func clear_shipType():
		_shipType.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_shipType(value):
		_shipType.value = value
	
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
	
class UpdateTeamAndShip:
	func _init():
		var service
		
		_id = PBField.new("id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _id
		data[_id.tag] = service
		
		_team = PBField.new("team", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _team
		data[_team.tag] = service
		
		_shipType = PBField.new("shipType", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _shipType
		data[_shipType.tag] = service
		
	var data = {}
	
	var _id
	func get_id():
		return _id.value
	func clear_id():
		_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_id(value):
		_id.value = value
	
	var _team
	func get_team():
		return _team.value
	func clear_team():
		_team.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_team(value):
		_team.value = value
	
	var _shipType
	func get_shipType():
		return _shipType.value
	func clear_shipType():
		_shipType.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_shipType(value):
		_shipType.value = value
	
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
	
class Login:
	func _init():
		var service
		
		_userName = PBField.new("userName", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _userName
		data[_userName.tag] = service
		
		_password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _password
		data[_password.tag] = service
		
	var data = {}
	
	var _userName
	func get_userName():
		return _userName.value
	func clear_userName():
		_userName.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userName(value):
		_userName.value = value
	
	var _password
	func get_password():
		return _password.value
	func clear_password():
		_password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value):
		_password.value = value
	
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
