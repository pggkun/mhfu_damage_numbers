from cwcheatio import CwCheatIO

file = CwCheatIO("ULUS-10391.TXT")
file.write(f"Damage Numbers [1/4]")
file.write(
    "_L 0x20041DB4 0x0A248238\n"
)
file.write(
    "_L 0x2006941C 0x0A2482A4\n"    
)
file.seek(0x089205E0)
file.write(f"Damage Numbers [2/4]")
with open("bin/DAMAGE_NUMBERS_US.bin", "rb") as bin:
    file.write(bin.read())

file.seek(0x089208E0)
file.write(f"Damage Numbers [3/4]")
with open("bin/DAMAGE_DRAWING_US.bin", "rb") as bin:
    file.write(bin.read())

file.seek(0x08920A90)
file.write(f"Damage Numbers [4/4]")
with open("bin/COPY_MATRIX_US.bin", "rb") as bin:
    file.write(bin.read())

file.close()

file = CwCheatIO("ULJM-05500.TXT")

file.write(f"Damage Numbers [1/4]")
file.write(
    "_L 0x20041DD0 0x0A247700\n"
)
file.write(
    "_L 0x20069414 0x0A24776C\n"    
)
file.seek(0x0891D900)
file.write(f"Damage Numbers [2/4]")
with open("bin/DAMAGE_NUMBERS_JP.bin", "rb") as bin:
    file.write(bin.read())

file.seek(0x0891DC00)
file.write(f"Damage Numbers [3/4]")
with open("bin/DAMAGE_DRAWING_JP.bin", "rb") as bin:
    file.write(bin.read())

file.seek(0x0891DDB0)
file.write(f"Damage Numbers [4/4]")
with open("bin/COPY_MATRIX.bin", "rb") as bin:
    file.write(bin.read())

file.close()