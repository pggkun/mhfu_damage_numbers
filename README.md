# MHFU Damage Numbers Display

Adds damage number display to Monster Hunter Freedom Unite.



https://github.com/user-attachments/assets/91ed1a7f-5e9a-4886-824c-8869f379616b



## Compiling

In a Linux environment, you will need Make and CMake. Use `make deps` to install the dependencies and `make` to generate the binaries and the text file.


## Patching

If you don't want to use this feature as a cheat, you can patch your ISO. To do that, you'll need:

- A MHP2ndG file in .iso format in the tools folder (it also works with MHFUComplete ISOs)
- A decrypted EBOOT.BIN in the root of the project (you can get it using PPSSPP or UMD_Gen)
    - if you use a MHFUComplete iso, the eboot file should match!
- Download [UMD-replace](https://www.romhacking.net/utilities/891/) and extract it into the tools folder

Once you have all these files and the other dependencies, run `make` to compile the binaries and `make patch` to generate your patched iso file.

## Notes

For now, it only works on the Japanese `ULJM-05500` version, but I plan to implement it for the American `ULUS-10391` and European `ULES-01213` versions as well. It's working on PPSSPP and has also been tested on PSVita PCH-1000 and PSP 2000 using TempAR (unfortunately, for some reason, CWCheat causes some crashes).

## Credits

- Thanks to [Kurogami2134](https://github.com/Kurogami2134), for the development tips (if you want MHP3rd Damage Numbers, [check this](https://github.com/Kurogami2134/mhp3rd_dmg_numbers)).
- Thanks to [IncognitoMan](https://github.com/IncognitoMan), for help testing.
