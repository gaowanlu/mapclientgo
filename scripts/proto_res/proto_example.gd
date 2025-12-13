#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
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

const PROTO_VERSION = 3

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
	var is_map_field : bool = false
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

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
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
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
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

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
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

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
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

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
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
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
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

	static func skip_unknown_field(bytes : PackedByteArray, offset : int, type : int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes : PackedByteArray = isolate_varint(bytes, offset)
			var length : int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
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
							var message = message_func_ref.call()
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
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
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

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
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
					var res : int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
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

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
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
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
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
					result += tabulate(str(i) + ": ", nesting)
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
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class ProtoCSReqExample:
	func _init():
		var service
		
		__testContext = PBField.new("testContext", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __testContext
		data[__testContext.tag] = service
		
	var data = {}
	
	var __testContext: PBField
	func has_testContext() -> bool:
		if __testContext.value != null:
			return true
		return false
	func get_testContext() -> PackedByteArray:
		return __testContext.value
	func clear_testContext() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__testContext.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_testContext(value : PackedByteArray) -> void:
		__testContext.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSResExample:
	func _init():
		var service
		
		__testContext = PBField.new("testContext", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __testContext
		data[__testContext.tag] = service
		
	var data = {}
	
	var __testContext: PBField
	func has_testContext() -> bool:
		if __testContext.value != null:
			return true
		return false
	func get_testContext() -> PackedByteArray:
		return __testContext.value
	func clear_testContext() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__testContext.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_testContext(value : PackedByteArray) -> void:
		__testContext.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSReqLogin:
	func _init():
		var service
		
		__userId = PBField.new("userId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __userId
		data[__userId.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __userId: PBField
	func has_userId() -> bool:
		if __userId.value != null:
			return true
		return false
	func get_userId() -> String:
		return __userId.value
	func clear_userId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__userId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userId(value : String) -> void:
		__userId.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSResLogin:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__sessionId = PBField.new("sessionId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __sessionId
		data[__sessionId.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret() -> int:
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ret(value : int) -> void:
		__ret.value = value
	
	var __sessionId: PBField
	func has_sessionId() -> bool:
		if __sessionId.value != null:
			return true
		return false
	func get_sessionId() -> String:
		return __sessionId.value
	func clear_sessionId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__sessionId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sessionId(value : String) -> void:
		__sessionId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMapNotifyInitData:
	func _init():
		var service
		
		__userId = PBField.new("userId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __userId
		data[__userId.tag] = service
		
		__x = PBField.new("x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service
		
		__y = PBField.new("y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service
		
		__serverTime = PBField.new("serverTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __serverTime
		data[__serverTime.tag] = service
		
		__tileSize = PBField.new("tileSize", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __tileSize
		data[__tileSize.tag] = service
		
		__width = PBField.new("width", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __width
		data[__width.tag] = service
		
		__height = PBField.new("height", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __height
		data[__height.tag] = service
		
		__mapId = PBField.new("mapId", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __mapId
		data[__mapId.tag] = service
		
	var data = {}
	
	var __userId: PBField
	func has_userId() -> bool:
		if __userId.value != null:
			return true
		return false
	func get_userId() -> String:
		return __userId.value
	func clear_userId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__userId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userId(value : String) -> void:
		__userId.value = value
	
	var __x: PBField
	func has_x() -> bool:
		if __x.value != null:
			return true
		return false
	func get_x() -> int:
		return __x.value
	func clear_x() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_x(value : int) -> void:
		__x.value = value
	
	var __y: PBField
	func has_y() -> bool:
		if __y.value != null:
			return true
		return false
	func get_y() -> int:
		return __y.value
	func clear_y() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_y(value : int) -> void:
		__y.value = value
	
	var __serverTime: PBField
	func has_serverTime() -> bool:
		if __serverTime.value != null:
			return true
		return false
	func get_serverTime() -> int:
		return __serverTime.value
	func clear_serverTime() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__serverTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_serverTime(value : int) -> void:
		__serverTime.value = value
	
	var __tileSize: PBField
	func has_tileSize() -> bool:
		if __tileSize.value != null:
			return true
		return false
	func get_tileSize() -> int:
		return __tileSize.value
	func clear_tileSize() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__tileSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_tileSize(value : int) -> void:
		__tileSize.value = value
	
	var __width: PBField
	func has_width() -> bool:
		if __width.value != null:
			return true
		return false
	func get_width() -> int:
		return __width.value
	func clear_width() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_width(value : int) -> void:
		__width.value = value
	
	var __height: PBField
	func has_height() -> bool:
		if __height.value != null:
			return true
		return false
	func get_height() -> int:
		return __height.value
	func clear_height() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_height(value : int) -> void:
		__height.value = value
	
	var __mapId: PBField
	func has_mapId() -> bool:
		if __mapId.value != null:
			return true
		return false
	func get_mapId() -> int:
		return __mapId.value
	func clear_mapId() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__mapId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_mapId(value : int) -> void:
		__mapId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSReqMapPing:
	func _init():
		var service
		
		__clientTime = PBField.new("clientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __clientTime
		data[__clientTime.tag] = service
		
	var data = {}
	
	var __clientTime: PBField
	func has_clientTime() -> bool:
		if __clientTime.value != null:
			return true
		return false
	func get_clientTime() -> int:
		return __clientTime.value
	func clear_clientTime() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__clientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_clientTime(value : int) -> void:
		__clientTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSResMapPong:
	func _init():
		var service
		
		__clientTime = PBField.new("clientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __clientTime
		data[__clientTime.tag] = service
		
		__serverTime = PBField.new("serverTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __serverTime
		data[__serverTime.tag] = service
		
	var data = {}
	
	var __clientTime: PBField
	func has_clientTime() -> bool:
		if __clientTime.value != null:
			return true
		return false
	func get_clientTime() -> int:
		return __clientTime.value
	func clear_clientTime() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__clientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_clientTime(value : int) -> void:
		__clientTime.value = value
	
	var __serverTime: PBField
	func has_serverTime() -> bool:
		if __serverTime.value != null:
			return true
		return false
	func get_serverTime() -> int:
		return __serverTime.value
	func clear_serverTime() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__serverTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_serverTime(value : int) -> void:
		__serverTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSReqMapInput:
	func _init():
		var service
		
		__dirX = PBField.new("dirX", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __dirX
		data[__dirX.tag] = service
		
		__dirY = PBField.new("dirY", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __dirY
		data[__dirY.tag] = service
		
		__seq = PBField.new("seq", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __seq
		data[__seq.tag] = service
		
		__clientTime = PBField.new("clientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __clientTime
		data[__clientTime.tag] = service
		
	var data = {}
	
	var __dirX: PBField
	func has_dirX() -> bool:
		if __dirX.value != null:
			return true
		return false
	func get_dirX() -> int:
		return __dirX.value
	func clear_dirX() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__dirX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_dirX(value : int) -> void:
		__dirX.value = value
	
	var __dirY: PBField
	func has_dirY() -> bool:
		if __dirY.value != null:
			return true
		return false
	func get_dirY() -> int:
		return __dirY.value
	func clear_dirY() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__dirY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_dirY(value : int) -> void:
		__dirY.value = value
	
	var __seq: PBField
	func has_seq() -> bool:
		if __seq.value != null:
			return true
		return false
	func get_seq() -> int:
		return __seq.value
	func clear_seq() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__seq.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_seq(value : int) -> void:
		__seq.value = value
	
	var __clientTime: PBField
	func has_clientTime() -> bool:
		if __clientTime.value != null:
			return true
		return false
	func get_clientTime() -> int:
		return __clientTime.value
	func clear_clientTime() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__clientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_clientTime(value : int) -> void:
		__clientTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoMapPlayerPayload:
	func _init():
		var service
		
		__userId = PBField.new("userId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __userId
		data[__userId.tag] = service
		
		__x = PBField.new("x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service
		
		__y = PBField.new("y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service
		
		__vX = PBField.new("vX", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __vX
		data[__vX.tag] = service
		
		__vY = PBField.new("vY", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __vY
		data[__vY.tag] = service
		
		__lastSeq = PBField.new("lastSeq", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __lastSeq
		data[__lastSeq.tag] = service
		
		__lastClientTime = PBField.new("lastClientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __lastClientTime
		data[__lastClientTime.tag] = service
		
	var data = {}
	
	var __userId: PBField
	func has_userId() -> bool:
		if __userId.value != null:
			return true
		return false
	func get_userId() -> String:
		return __userId.value
	func clear_userId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__userId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userId(value : String) -> void:
		__userId.value = value
	
	var __x: PBField
	func has_x() -> bool:
		if __x.value != null:
			return true
		return false
	func get_x() -> int:
		return __x.value
	func clear_x() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_x(value : int) -> void:
		__x.value = value
	
	var __y: PBField
	func has_y() -> bool:
		if __y.value != null:
			return true
		return false
	func get_y() -> int:
		return __y.value
	func clear_y() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_y(value : int) -> void:
		__y.value = value
	
	var __vX: PBField
	func has_vX() -> bool:
		if __vX.value != null:
			return true
		return false
	func get_vX() -> int:
		return __vX.value
	func clear_vX() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__vX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_vX(value : int) -> void:
		__vX.value = value
	
	var __vY: PBField
	func has_vY() -> bool:
		if __vY.value != null:
			return true
		return false
	func get_vY() -> int:
		return __vY.value
	func clear_vY() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__vY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_vY(value : int) -> void:
		__vY.value = value
	
	var __lastSeq: PBField
	func has_lastSeq() -> bool:
		if __lastSeq.value != null:
			return true
		return false
	func get_lastSeq() -> int:
		return __lastSeq.value
	func clear_lastSeq() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__lastSeq.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_lastSeq(value : int) -> void:
		__lastSeq.value = value
	
	var __lastClientTime: PBField
	func has_lastClientTime() -> bool:
		if __lastClientTime.value != null:
			return true
		return false
	func get_lastClientTime() -> int:
		return __lastClientTime.value
	func clear_lastClientTime() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__lastClientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_lastClientTime(value : int) -> void:
		__lastClientTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMapNotifyStateData:
	func _init():
		var service
		
		__serverTime = PBField.new("serverTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __serverTime
		data[__serverTime.tag] = service
		
		var __players_default: Array[ProtoMapPlayerPayload] = []
		__players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __players_default)
		service = PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
	var data = {}
	
	var __serverTime: PBField
	func has_serverTime() -> bool:
		if __serverTime.value != null:
			return true
		return false
	func get_serverTime() -> int:
		return __serverTime.value
	func clear_serverTime() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__serverTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_serverTime(value : int) -> void:
		__serverTime.value = value
	
	var __players: PBField
	func get_players() -> Array[ProtoMapPlayerPayload]:
		return __players.value
	func clear_players() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__players.value.clear()
	func add_players() -> ProtoMapPlayerPayload:
		var element = ProtoMapPlayerPayload.new()
		__players.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMapEnterReq:
	func _init():
		var service
		
		__mapId = PBField.new("mapId", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __mapId
		data[__mapId.tag] = service
		
	var data = {}
	
	var __mapId: PBField
	func has_mapId() -> bool:
		if __mapId.value != null:
			return true
		return false
	func get_mapId() -> int:
		return __mapId.value
	func clear_mapId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__mapId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_mapId(value : int) -> void:
		__mapId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMapEnterRes:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__mapId = PBField.new("mapId", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __mapId
		data[__mapId.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret() -> int:
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ret(value : int) -> void:
		__ret.value = value
	
	var __mapId: PBField
	func has_mapId() -> bool:
		if __mapId.value != null:
			return true
		return false
	func get_mapId() -> int:
		return __mapId.value
	func clear_mapId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__mapId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_mapId(value : int) -> void:
		__mapId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMapLeaveReq:
	func _init():
		var service
		
		__reserve = PBField.new("reserve", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __reserve
		data[__reserve.tag] = service
		
	var data = {}
	
	var __reserve: PBField
	func has_reserve() -> bool:
		if __reserve.value != null:
			return true
		return false
	func get_reserve() -> int:
		return __reserve.value
	func clear_reserve() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__reserve.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_reserve(value : int) -> void:
		__reserve.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMapLeaveRes:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret() -> int:
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ret(value : int) -> void:
		__ret.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMap3DNotifyInitData:
	func _init():
		var service
		
		__userId = PBField.new("userId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __userId
		data[__userId.tag] = service
		
		__x = PBField.new("x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service
		
		__y = PBField.new("y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service
		
		__serverTime = PBField.new("serverTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __serverTime
		data[__serverTime.tag] = service
		
		__xSize = PBField.new("xSize", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __xSize
		data[__xSize.tag] = service
		
		__ySize = PBField.new("ySize", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ySize
		data[__ySize.tag] = service
		
		__zSize = PBField.new("zSize", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __zSize
		data[__zSize.tag] = service
		
		__mapId = PBField.new("mapId", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __mapId
		data[__mapId.tag] = service
		
		__z = PBField.new("z", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __z
		data[__z.tag] = service
		
	var data = {}
	
	var __userId: PBField
	func has_userId() -> bool:
		if __userId.value != null:
			return true
		return false
	func get_userId() -> String:
		return __userId.value
	func clear_userId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__userId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userId(value : String) -> void:
		__userId.value = value
	
	var __x: PBField
	func has_x() -> bool:
		if __x.value != null:
			return true
		return false
	func get_x() -> int:
		return __x.value
	func clear_x() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_x(value : int) -> void:
		__x.value = value
	
	var __y: PBField
	func has_y() -> bool:
		if __y.value != null:
			return true
		return false
	func get_y() -> int:
		return __y.value
	func clear_y() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_y(value : int) -> void:
		__y.value = value
	
	var __serverTime: PBField
	func has_serverTime() -> bool:
		if __serverTime.value != null:
			return true
		return false
	func get_serverTime() -> int:
		return __serverTime.value
	func clear_serverTime() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__serverTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_serverTime(value : int) -> void:
		__serverTime.value = value
	
	var __xSize: PBField
	func has_xSize() -> bool:
		if __xSize.value != null:
			return true
		return false
	func get_xSize() -> int:
		return __xSize.value
	func clear_xSize() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__xSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_xSize(value : int) -> void:
		__xSize.value = value
	
	var __ySize: PBField
	func has_ySize() -> bool:
		if __ySize.value != null:
			return true
		return false
	func get_ySize() -> int:
		return __ySize.value
	func clear_ySize() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__ySize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ySize(value : int) -> void:
		__ySize.value = value
	
	var __zSize: PBField
	func has_zSize() -> bool:
		if __zSize.value != null:
			return true
		return false
	func get_zSize() -> int:
		return __zSize.value
	func clear_zSize() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__zSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_zSize(value : int) -> void:
		__zSize.value = value
	
	var __mapId: PBField
	func has_mapId() -> bool:
		if __mapId.value != null:
			return true
		return false
	func get_mapId() -> int:
		return __mapId.value
	func clear_mapId() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__mapId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_mapId(value : int) -> void:
		__mapId.value = value
	
	var __z: PBField
	func has_z() -> bool:
		if __z.value != null:
			return true
		return false
	func get_z() -> int:
		return __z.value
	func clear_z() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_z(value : int) -> void:
		__z.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSReqMap3DPing:
	func _init():
		var service
		
		__clientTime = PBField.new("clientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __clientTime
		data[__clientTime.tag] = service
		
	var data = {}
	
	var __clientTime: PBField
	func has_clientTime() -> bool:
		if __clientTime.value != null:
			return true
		return false
	func get_clientTime() -> int:
		return __clientTime.value
	func clear_clientTime() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__clientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_clientTime(value : int) -> void:
		__clientTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSResMap3DPong:
	func _init():
		var service
		
		__clientTime = PBField.new("clientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __clientTime
		data[__clientTime.tag] = service
		
		__serverTime = PBField.new("serverTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __serverTime
		data[__serverTime.tag] = service
		
	var data = {}
	
	var __clientTime: PBField
	func has_clientTime() -> bool:
		if __clientTime.value != null:
			return true
		return false
	func get_clientTime() -> int:
		return __clientTime.value
	func clear_clientTime() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__clientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_clientTime(value : int) -> void:
		__clientTime.value = value
	
	var __serverTime: PBField
	func has_serverTime() -> bool:
		if __serverTime.value != null:
			return true
		return false
	func get_serverTime() -> int:
		return __serverTime.value
	func clear_serverTime() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__serverTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_serverTime(value : int) -> void:
		__serverTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSReqMap3DInput:
	func _init():
		var service
		
		__dirX = PBField.new("dirX", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __dirX
		data[__dirX.tag] = service
		
		__dirY = PBField.new("dirY", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __dirY
		data[__dirY.tag] = service
		
		__dirZ = PBField.new("dirZ", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __dirZ
		data[__dirZ.tag] = service
		
		__seq = PBField.new("seq", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __seq
		data[__seq.tag] = service
		
		__clientTime = PBField.new("clientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __clientTime
		data[__clientTime.tag] = service
		
	var data = {}
	
	var __dirX: PBField
	func has_dirX() -> bool:
		if __dirX.value != null:
			return true
		return false
	func get_dirX() -> int:
		return __dirX.value
	func clear_dirX() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__dirX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_dirX(value : int) -> void:
		__dirX.value = value
	
	var __dirY: PBField
	func has_dirY() -> bool:
		if __dirY.value != null:
			return true
		return false
	func get_dirY() -> int:
		return __dirY.value
	func clear_dirY() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__dirY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_dirY(value : int) -> void:
		__dirY.value = value
	
	var __dirZ: PBField
	func has_dirZ() -> bool:
		if __dirZ.value != null:
			return true
		return false
	func get_dirZ() -> int:
		return __dirZ.value
	func clear_dirZ() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__dirZ.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_dirZ(value : int) -> void:
		__dirZ.value = value
	
	var __seq: PBField
	func has_seq() -> bool:
		if __seq.value != null:
			return true
		return false
	func get_seq() -> int:
		return __seq.value
	func clear_seq() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__seq.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_seq(value : int) -> void:
		__seq.value = value
	
	var __clientTime: PBField
	func has_clientTime() -> bool:
		if __clientTime.value != null:
			return true
		return false
	func get_clientTime() -> int:
		return __clientTime.value
	func clear_clientTime() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__clientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_clientTime(value : int) -> void:
		__clientTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoMap3DPlayerPayload:
	func _init():
		var service
		
		__userId = PBField.new("userId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __userId
		data[__userId.tag] = service
		
		__x = PBField.new("x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service
		
		__y = PBField.new("y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service
		
		__z = PBField.new("z", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __z
		data[__z.tag] = service
		
		__vX = PBField.new("vX", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __vX
		data[__vX.tag] = service
		
		__vY = PBField.new("vY", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __vY
		data[__vY.tag] = service
		
		__vZ = PBField.new("vZ", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __vZ
		data[__vZ.tag] = service
		
		__lastSeq = PBField.new("lastSeq", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __lastSeq
		data[__lastSeq.tag] = service
		
		__lastClientTime = PBField.new("lastClientTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __lastClientTime
		data[__lastClientTime.tag] = service
		
	var data = {}
	
	var __userId: PBField
	func has_userId() -> bool:
		if __userId.value != null:
			return true
		return false
	func get_userId() -> String:
		return __userId.value
	func clear_userId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__userId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_userId(value : String) -> void:
		__userId.value = value
	
	var __x: PBField
	func has_x() -> bool:
		if __x.value != null:
			return true
		return false
	func get_x() -> int:
		return __x.value
	func clear_x() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_x(value : int) -> void:
		__x.value = value
	
	var __y: PBField
	func has_y() -> bool:
		if __y.value != null:
			return true
		return false
	func get_y() -> int:
		return __y.value
	func clear_y() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_y(value : int) -> void:
		__y.value = value
	
	var __z: PBField
	func has_z() -> bool:
		if __z.value != null:
			return true
		return false
	func get_z() -> int:
		return __z.value
	func clear_z() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_z(value : int) -> void:
		__z.value = value
	
	var __vX: PBField
	func has_vX() -> bool:
		if __vX.value != null:
			return true
		return false
	func get_vX() -> int:
		return __vX.value
	func clear_vX() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__vX.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_vX(value : int) -> void:
		__vX.value = value
	
	var __vY: PBField
	func has_vY() -> bool:
		if __vY.value != null:
			return true
		return false
	func get_vY() -> int:
		return __vY.value
	func clear_vY() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__vY.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_vY(value : int) -> void:
		__vY.value = value
	
	var __vZ: PBField
	func has_vZ() -> bool:
		if __vZ.value != null:
			return true
		return false
	func get_vZ() -> int:
		return __vZ.value
	func clear_vZ() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__vZ.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_vZ(value : int) -> void:
		__vZ.value = value
	
	var __lastSeq: PBField
	func has_lastSeq() -> bool:
		if __lastSeq.value != null:
			return true
		return false
	func get_lastSeq() -> int:
		return __lastSeq.value
	func clear_lastSeq() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__lastSeq.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_lastSeq(value : int) -> void:
		__lastSeq.value = value
	
	var __lastClientTime: PBField
	func has_lastClientTime() -> bool:
		if __lastClientTime.value != null:
			return true
		return false
	func get_lastClientTime() -> int:
		return __lastClientTime.value
	func clear_lastClientTime() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__lastClientTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_lastClientTime(value : int) -> void:
		__lastClientTime.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMap3DNotifyStateData:
	func _init():
		var service
		
		__serverTime = PBField.new("serverTime", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __serverTime
		data[__serverTime.tag] = service
		
		var __players_default: Array[ProtoMap3DPlayerPayload] = []
		__players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __players_default)
		service = PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
	var data = {}
	
	var __serverTime: PBField
	func has_serverTime() -> bool:
		if __serverTime.value != null:
			return true
		return false
	func get_serverTime() -> int:
		return __serverTime.value
	func clear_serverTime() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__serverTime.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_serverTime(value : int) -> void:
		__serverTime.value = value
	
	var __players: PBField
	func get_players() -> Array[ProtoMap3DPlayerPayload]:
		return __players.value
	func clear_players() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__players.value.clear()
	func add_players() -> ProtoMap3DPlayerPayload:
		var element = ProtoMap3DPlayerPayload.new()
		__players.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMap3DEnterReq:
	func _init():
		var service
		
		__mapId = PBField.new("mapId", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __mapId
		data[__mapId.tag] = service
		
	var data = {}
	
	var __mapId: PBField
	func has_mapId() -> bool:
		if __mapId.value != null:
			return true
		return false
	func get_mapId() -> int:
		return __mapId.value
	func clear_mapId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__mapId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_mapId(value : int) -> void:
		__mapId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMap3DEnterRes:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__mapId = PBField.new("mapId", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __mapId
		data[__mapId.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret() -> int:
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ret(value : int) -> void:
		__ret.value = value
	
	var __mapId: PBField
	func has_mapId() -> bool:
		if __mapId.value != null:
			return true
		return false
	func get_mapId() -> int:
		return __mapId.value
	func clear_mapId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__mapId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_mapId(value : int) -> void:
		__mapId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMap3DLeaveReq:
	func _init():
		var service
		
		__reserve = PBField.new("reserve", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __reserve
		data[__reserve.tag] = service
		
	var data = {}
	
	var __reserve: PBField
	func has_reserve() -> bool:
		if __reserve.value != null:
			return true
		return false
	func get_reserve() -> int:
		return __reserve.value
	func clear_reserve() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__reserve.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_reserve(value : int) -> void:
		__reserve.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
	
class ProtoCSMap3DLeaveRes:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret() -> int:
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ret(value : int) -> void:
		__ret.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
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
