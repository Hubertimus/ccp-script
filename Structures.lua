NetObject = {}

-- Could not find where offset came from
function NetObject.get_net_obj(entity_pointer) 
    return memory.read_long(entity_pointer + 0xD0)
end

-- int16_t m_object_type; //0x0008
function NetObject.object_typ(net_object)
    return memory.read_ushort(net_object + 0x08)
end
-- int16_t m_object_id; //0x000A
function NetObject.object_id(net_object)
    return memory.read_ushort(net_object + 0x0A)
end

-- char pad_000C[61]; //0x000C
function NetObject.pad_000C(net_object)
    return memory.read_string(net_object + 0x0C)
end

-- int8_t m_owner_id; //0x0049
function NetObject.owner_id(net_object)
    return memory.read_byte(net_object + 0x49)
end

-- int8_t m_control_id; //0x004A
function NetObject.control_id(net_object)
    return memory.read_ubyte(net_object + 0x4A)
end

-- int8_t m_next_owner_id; //0x004B
function NetObject.next_owner_id(net_object)
    return memory.read_ubyte(net_object + 0x4B)
end

-- bool m_is_remote; //0x004C
function NetObject.is_remote(net_object)
    return memory.read_ubyte(net_object + 0x4C) ~= 0
end

-- bool m_wants_to_delete; //0x004D
function NetObject.wants_to_delete(net_object)
    return memory.read_ubyte(net_object + 0x4D) ~= 0
end

-- char pad_004E[1]; //0x004E
function NetObject.is_high_priority(net_object)
    return memory.read_ubyte(net_object + 0x4E) ~= 0
end

-- bool m_should_not_be_delete; //0x004F
function NetObject.hould_not_be_delete(net_object)
    return memory.read_ubyte(net_object + 0x4F) ~= 0
end
