import struct
import sys

def patch_macho_sdk(binary_path, new_sdk_version=(26, 0, 0)):
    print(f"Opening binary: {binary_path}")
    with open(binary_path, 'rb') as f:
        data = bytearray(f.read())
    
    if len(data) < 32:
        print("Error: Binary is too small")
        return
        
    magic = struct.unpack('<I', data[:4])[0]
    
    headers = []
    if magic == 0xfeedfacf: # 64-bit Little Endian
        headers.append((0, '<'))
    elif magic == 0xcafebabe: # FAT binary
        num_fat = struct.unpack('>I', data[4:8])[0]
        offset = 8
        for _ in range(num_fat):
            cputype, cpusubtype, f_offset, f_size, f_align = struct.unpack('>IIIII', data[offset:offset+20])
            headers.append((f_offset, '<'))
            offset += 20
    else:
        # Check big-endian 64-bit
        if magic == 0xcffaedfe:
            headers.append((0, '>'))
        else:
            print(f"Unknown magic header: {magic:#x}. Trying local 64-bit LE anyway.")
            headers.append((0, '<'))
            
    patched_count = 0
    for base_offset, endian in headers:
        if base_offset + 32 > len(data):
            continue
            
        magic_val = struct.unpack(endian + 'I', data[base_offset:base_offset+4])[0]
        if magic_val != 0xfeedfacf and magic_val != 0xcffaedfe:
            continue
            
        ncmds, sizeofcmds = struct.unpack(endian + 'II', data[base_offset+16:base_offset+24])
        
        cmd_offset = base_offset + 32
        for _ in range(ncmds):
            if cmd_offset + 24 > len(data):
                break
                
            cmd, cmdsize = struct.unpack(endian + 'II', data[cmd_offset:cmd_offset+8])
            if cmd == 0x32: # LC_BUILD_VERSION
                platform, minos, sdk, ntools = struct.unpack(endian + 'IIII', data[cmd_offset+8:cmd_offset+24])
                
                # Encode new SDK version: (major << 16) | (minor << 8) | patch
                new_sdk_val = (new_sdk_version[0] << 16) | (new_sdk_version[1] << 8) | new_sdk_version[2]
                
                print(f"Found LC_BUILD_VERSION. Current SDK: {sdk >> 16}.{(sdk >> 8) & 0xff}.{sdk & 0xff} ({sdk:#x}), Patching to: {new_sdk_version[0]}.{new_sdk_version[1]}.{new_sdk_version[2]} ({new_sdk_val:#x})")
                
                data[cmd_offset+16:cmd_offset+20] = struct.pack(endian + 'I', new_sdk_val)
                patched_count += 1
                
            cmd_offset += cmdsize
            
    if patched_count > 0:
        with open(binary_path, 'wb') as f:
            f.write(data)
        print(f"Successfully patched {patched_count} headers in the Mach-O binary!")
    else:
        print("Warning: No LC_BUILD_VERSION load commands were found to patch.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python patch_binary.py <path_to_binary>")
        sys.exit(1)
    patch_macho_sdk(sys.argv[1])
