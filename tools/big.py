import struct, sys, os

class Big:
    def __init__(self, path):
        self.path = path
        f = open(path,'rb'); self.f = f
        magic = f.read(8)
        assert magic == b'_ARCHIVE', magic
        self.version = struct.unpack('<I', f.read(4))[0]
        f.read(16)
        self.name = f.read(128).decode('utf-16-le').rstrip('\0')
        f.read(16)
        self.headerLen, self.dataOffset = struct.unpack('<II', f.read(8))
        self.hdrBase = f.tell()   # 0xB4
        (tocOff, tocCnt, dirOff, dirCnt, fileOff, fileCnt,
         nameOff, nameCnt) = struct.unpack('<IHIHIHIH', f.read(24))
        self.nameBase = self.hdrBase + nameOff

        f.seek(self.hdrBase + dirOff)
        self.dirs = [struct.unpack('<IHHHH', f.read(12)) for _ in range(dirCnt)]
        f.seek(self.hdrBase + fileOff)
        self.files = [struct.unpack('<IBIII', f.read(17)) for _ in range(fileCnt)]
        f.seek(self.hdrBase + tocOff)
        self.tocs = []
        for _ in range(tocCnt):
            alias = f.read(64).split(b'\0')[0].decode('latin1')
            nm    = f.read(64).split(b'\0')[0].decode('latin1')
            self.tocs.append((alias, nm) + struct.unpack('<HHHHH', f.read(10)))

    def s(self, off):
        self.f.seek(self.nameBase + off)
        out = b''
        while True:
            c = self.f.read(64)
            if not c: break
            if b'\0' in c:
                out += c[:c.index(b'\0')]; break
            out += c
        return out.decode('latin1')

    def walk(self):
        """yield (fullpath, fileindex)"""
        for d in self.dirs:
            nameOff, fs, ls_, ff, lf = d
            dname = self.s(nameOff)
            for fi in range(ff, lf):
                yield (dname + '/' + self.s(self.files[fi][0]), fi)

    def extract(self, fi, dest):
        nameOff, vt, dOff, onDisk, length = self.files[fi]
        self.f.seek(self.dataOffset + dOff)
        data = self.f.read(onDisk)
        if onDisk != length:
            import zlib
            data = zlib.decompress(data)
        open(dest,'wb').write(data)
        return len(data)

if __name__ == '__main__':
    b = Big(sys.argv[1])
    print('archive:', b.name, 'v', b.version, file=sys.stderr)
    print('tocs:', b.tocs, file=sys.stderr)
    print('dirs:', len(b.dirs), 'files:', len(b.files), file=sys.stderr)
    for p, fi in b.walk():
        print(p)
