This folder is the repo of the 3rd party programs that are needed for the package building scripts.

1. **puff** is from https://www.pa3fwm.nl/software/puff/puff-20181104.tgz released under **GPLv3**.
   1. Manually downloaded and copied here.
0. **post-puff** is from https://github.com/andi-f/post-puff.git released under **GPLv3**.
   1. Used `git subtree add --prefix=third_party/post-puff https://github.com/andi-f/post-puff.git master`
   2. To update use `git subtree pull --prefix=third_party/post-puff https://github.com/andi-f/post-puff.git master`
0. **xseticon** from https://github.com/xeyownt/xseticon release under **GPLv2**.
   1. Used to set the DOS based tools window icon to their specified .png image.
   2. `git subtree add --prefix=third_party/xseticon https://github.com/xeyownt/xseticon.git master`
   3. To update use `git subtree pull --prefix=third_party/xseticon https://github.com/xeyownt/xseticon.git master`
0. **ANTMAKER 6.0** Antenna Maker for common antennas by By: John K. Agrelius, KM6HG released to **PUBLIC DOMAIN FOR NON-COMMERCIAL USE**.
   1. The distribution package also contains **ARIEL 1.7** by J Scott Hedspeth WB4YZA and **ANTDL6WU/ANTFO** by Art Holmes, WA2TIF all released as **Freeware for non-commercial use**.
   2. Manually downloaded from [Simtel](https://en.wikipedia.org/wiki/Simtel) Directory: `/pub/ham/antenna`
0. **ASP 4.0** Amplifier Simulation Program © 1989-1996 by KD9JQ released as **FREEWARE**.
   1. Downloaded from [Wayback Machine](http://web.archive.org/web/19991106021703/http://www.imaxx.net:80/~kd9jq/ASP.html) Internet Archive.
0. **HEAD** published by Alireza Aminian, "Helical Filters and Design Software", Iran University of Science and Technology, 1996.
0. **LINPLAN** published by M. Mikavica, and A. Nešić, "CAD for Linear and Planar Antenna Array of Various Radiating Elements", Artech House, Norwood, MA, 1991.
0. **LPCAD 2.3** Log-Periodic Antenna Design 2.3 by Roger A. Cox  WB0DGF at Telex Communications, Inc. 
   1. Manually downloaded from [Simtel](https://en.wikipedia.org/wiki/Simtel) Directory: `/pub/ham/antenna`
0. **PCAAD 2.1** Personal Computer Aided Antenna Design, published as **Shareware** by Antenna Design Associates, Inc. 
   1. Manually downloaded from PE2BZ https://pe2bz.philpem.me.uk/ElectronicPrograms/-%20RF-Programs/PCCAD-AntennaDesign/
0. **RASCAL 2.1** Interactive Design of Reflector Antennas by Yung-hsiang Lee, Kenneth W. Brown, and Aluizio Prata, Jr. as **FREEWARE**.
   1. Manually downloaded from [Simtel](https://en.wikipedia.org/wiki/Simtel) Directory: `/pub/msdos/electrcl/`
0. **SEDIF** published at "A New Educational Packet for Passive and Active Filter Design," by J. Ruiz, E. Aramendi, and A. Ubierna. COMPUTER APPLICATIONS IN ENGINEERING EDUCATION Software for Vol. 1, No. 3, Page 229, DEC 1992
   1. Manually downloaded from ftp://ftp.wiley.com/public/journals-back/cae/cae13229/cae13229.zip
0. **SNAPMax 5.01** Signal, Noise and Propagation By Crawford MacKeand, **freewave for non-commercial and amateur purposes**.
   1. Manually downloaded from http://hfradio.org/software/snapmax5.zip
0. **VHFProp 1.2** Signal Analysis Program for the 6m through 23cm Amateur Bands.
   1. Manually downloaded from [Simtel](https://en.wikipedia.org/wiki/Simtel) Directory: `/pub/msdos/hamradio`
   2. Minimally changed to be compiled on `ncurses` instead of `Turbo-C 2.0`.
0. **YAGIMAX 3.11** Yagi-Uda antenna simulation by Lew Gordon, K4VX released as **Shareware**.
   1. Manually downloaded from http://xoomer.virgilio.it/ham-radio-manuals/yagim311.zip

All are copyright to their respective owners.
