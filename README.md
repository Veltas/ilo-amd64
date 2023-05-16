AMD64 ilo VM
============

Get ilo from http://ilo.retroforth.org/

64-bit x86 ilo VM for Linux, under MIT license. Available as part of the main
ilo distribution, this repository is left here for posterity.

Building
--------

    as -oilo.o ilo.s
    ld -oilo ilo.o

Running
-------

Needs `ilo.blocks` and `ilo.rom` from main ilo distribution in local directory,
or specify alternative block file and ROM.

    ./ilo [blocks-file [rom-file]]

License
-------

Available under MIT License, see `COPYING`.
