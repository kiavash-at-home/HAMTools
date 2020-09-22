200 'The name of this program is "ANTDL6WU.BAS", dated 1 Oct 93
210 'Authors are  K1DPP, W1JOT, & WA2TIF.
220 'The last update was ----- 1993.(Revision 1)
230 '
240 '         ORIGINAL PROGRAM BY DAVID HOPKINS VK4ZF, 1/10/84
250 '
260 'Amendments by VK1AU, VK3UM, VK2AIT, W2PV, WA2TIF, W1JR, K1DPP, & W1JOT.
270 '
280 'ANTDL6WU is based upon the original "DL6WU.BAS" program.(circa 1984)
290 ' which has been modified to conform to the DL6WU  program in the ARRL UHF/
300 ' Microwave Experimenter's Manual, 1990.
310 '
320 'The following updates were made by WA2TIF on 6/30/93:
330 ' the length of the driven element was corrected - made longer,
340 ' the boom correction factor was made much more accurate, he
350 ' changed the element spacing data to match the original DL6WU design,
360 ' and changed the stacking distances.
370 '
380 '
390 '
400 ' This program is freely available for NON commercial use."
410 'Please forward copy of all updates and corrections to VK4ZF,WA2TIF & W1JOT
420 '   so that all may benefit from your work in the spirit of Amateur Radio.
430 '
440 '**************************************************************************
450 KEY OFF
460 COLOR 14, 1
470 CLS
480 PRINT
490 PRINT "       *****************************************************************"
500 PRINT "       *                                                               *"
510 PRINT "       *                  YAGI ANTENNA DESIGN PROGRAM                  *"
520 PRINT "       *          for 50, 144, 222, 432, 903, 1296, & 2304 Mhz         *"
530 PRINT "       *                                                               *"
540 PRINT "       *     Based on work by Gunter Hock (DL6WU), as published in     *"
550 PRINT "       *    Chap. 9, ARRL UHF/Microwave Experimenter's Manual, 1990    *"
560 PRINT "       *                                                               *"
570 PRINT "       *    ANTDL6WU.BAS optimizes spacing & element length - which    *"
580 PRINT "       *       agree with the published DL6WU 432 Mhz yardstick        *"
590 PRINT "       *                                                               *"
600 PRINT "       *     For best results use 3/16 ins elements from 144 Mhz.      *"
610 PRINT "       *      thru 432 Mhz.  Use 1/8 ins for 902 and above.  The       *"
620 PRINT "       *      program is too general and will NOT give accurate        *"
630 PRINT "       *      results for significant departures from these values.    *"
640 PRINT "       *                                                               *"
650 PRINT "       *       Maximum number of elements (REF,DE,DIR) is 48           *"
660 PRINT "       *                                                               *"
670 PRINT "       * Boom should be at least 2 wavelengths long for best results.  *"
680 PRINT "       *                                                               *"
690 PRINT "       *                    Dated 1 October 1993                       *"
700 PRINT "       *****************************************************************"
710 PRINT
720 '
730 COLOR 15, 1
740 LOCATE 24,22
750 INPUT"Do you wish to continue  (Y/Q)  ";A$
760 IF A$ = "Q" OR A$ = "q" THEN GOTO 4310
770 CLS
780 COLOR 14, 1
790 '
800 '-----------------------------DIMENSIONS---------------------------------
810 '
820 J1 = 25.4: J2 = .03937             'Mm/Inch conversions
830 DIM LE(50)
840 DIM SP(50), DS(50): Q$ = "####": A$ = "###.##": C$ = "####.##"
850 D$="##.##":E$="##.#":F$=".###":X$="#####.##":Y$="###.###"
860 DIM TS(50): DIM FR1(50): DIM FR2(50): DIM R1(50): DIM R2(50): DIM A(50)
870 FA=50:FB=144:FC=222:FD=432:FE=903:FF=1296:FG=2304
880 '
890 '-----------------------LOAD ELEMENT SPACING DATA------------------------
900 '
910 DATA 42.794, 18.274, 41.638, 49.965, 58.293, 65.001, 69.859, 73.329, 76.567
920 DATA 80.037, 83.276, 86.514, 88.365, 89.984, 91.603, 92.991, 92.991, 92.991
930 DATA 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991
940 DATA 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991
950 DATA 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991, 92.991
960 DATA 92.991, 92.991, 92.991, 92.991, 92.991, 92.991
970 FOR X = 1 TO 50
980 READ SP(X)
990 NEXT X
1000 PRINT:COLOR 14, 1
1010 CLOSE 1
1020 PRINT"                     ***** PROGRAM'S MAIN MENU *****"
1030 PRINT
1040 PRINT
1050 PRINT "     This program can:"
1060 PRINT
1070 PRINT "          1 - Design a Yagi Antenna for VHF/UHF & Microwave Frequencies "
1080 PRINT
1090 PRINT "          2 - Design an Equal-Diameter Folded Dipole"
1100 PRINT
1110 PRINT "          3 - Design Coaxial Cable Baluns"
1120 PRINT
1130 PRINT "          4 - Design a T - Match"
1140 PRINT
1150 PRINT "          5 - Provide an Antenna check-out procedure"
1160 PRINT
1170 PRINT "          6 - Provide Lambda for VHF/UHF/Microwave Frequencies
1180 PRINT
1190 PRINT "          7 - Provide sources for materials
1200 PRINT
1210 PRINT "          8 - END THE PROGRAM
1220 PRINT
1230 COLOR 15, 1
1240 PRINT
1250 INPUT "           Which one do you wish to try   <1,2,3,4,5,6,7 or 8>  ";T$
1260 IF T$ = "1" THEN GOTO 1340                           'Antenna
1270 IF T$ = "2" THEN GOTO 6290                           'Folded dipole
1280 IF T$ = "3" THEN GOTO 7930                           'Balun
1290 IF T$ = "4" THEN GOTO 7190                           'T - Match
1300 IF T$ = "5" THEN GOTO 5960                           'Check-out procedure
1310 IF T$ = "6" THEN GOTO 9090                           'Lambda calculations
1320 IF T$ = "7" THEN GOTO 9470                           'Materials
1330 IF T$ = "8" THEN GOTO 4310                           'End the program
1340 COLOR 14, 1 : CLS
1350 '
1360 '---------------------INPUT DESIRED PARAMETERS----------------------------
1370 '
1380 PRINT
1390 PRINT"                       ***** ANTENNA DESIGN *****
1400 PRINT
1410 INPUT"            What is the CENTER FREQUENCY of the ANTENNA in MHz "; F
1420  W = 299.792458# / F                                   'Wavelength in Metres
1430 PRINT
1440 INPUT"            How many ELEMENTS                                  "; N
1450 IF N > 48 THEN CLS: GOTO 5040
1460 PRINT
1470 PRINT"            The program uses ENGLISH and METRIC units."
1480 PRINT
1490 INPUT"            Which unit would you like to use - <E/M>           "; U$
1500 IF U$ = "M" OR U$ = "m" GOTO 1520
1510 IF U$ = "E" OR U$ = "e" GOTO 1590
1520 PRINT
1530 INPUT"            What is the ELEMENT DIAMETER (in mm)               "; ED
1540 WW = 1000 * W
1550 RO2 = ED / (2 * WW)
1560 PRINT
1570 INPUT"            What is the BOOM DIAMETER (in mm)                  "; BD
1580 GOTO 1670
1590 PRINT
1600 INPUT"            What is the ELEMENT DIAMETER (in inches)           "; DE
1610 WW = 1000 * W
1620 ED = DE * J1
1630 RO2 = ED / (2 * WW)
1640 PRINT
1650 INPUT"            What is the BOOM DIAMETER (in inches)              "; DB
1660 BD = DB * J1
1670 PRINT
1680 PRINT"            ELEMENTS can be:
1690 PRINT
1700 PRINT"                      1.  INSULATED THRU the boom"
1710 PRINT
1720 PRINT"                      2.  INSULATED FROM the Boom"
1730 PRINT
1740 PRINT"                      3.  NOT INSULATED from the boom"
1750 PRINT
1760 COLOR 15,1
1770 INPUT"            Select ELEMENT mounting         <1, 2, or 3>   ";AN$
1780 IF AN$ = "1"  THEN I = 2: GOTO  4530
1790 IF AN$ = "2"  THEN I = 0: GOTO  1820
1800 IF AN$ = "3"  THEN I = 1: GOTO  4530
1810 '-------------------------DISPLAY SPECIFICATIONS---------------------------
1820 CLS:COLOR 14,1
1830 PRINT:PRINT
1840 PRINT "            ***** GENERAL CRITERIA FOR THE DESIRED ANTENNA *****"
1850 PRINT "   ------------------------------------------------------------------------"
1860 PRINT
1870 PRINT "        1.  DESIGN FREQUENCY   :   "; USING C$;F; :PRINT "  Mhz"
1880 PRINT "        2.  NUMBER OF ELEMENTS :    "; N
1890 XX=ED: GOSUB 4480
1900 PRINT "        3.  ELEMENT DIAMETER   :    "; USING A$;ED;: PRINT "  mm    = "; USING Y$; ZZ;:PRINT "  ins"
1910 XX = BD: GOSUB 4480
1920 PRINT "        4.  BOOM DIAMETER      :  "; USING X$;BD;: PRINT "  mm    = "; USING Y$; ZZ;:PRINT "  ins"
1930 PRINT "        5.  BOOM CORRECTION FACTOR";USING X$; BC;:PRINT"  mm    = " ;USING Y$;BC/J1;:PRINT "  ins"
1940 PRINT "        6.  DL6WU design with tapered spacing  to optimise gain"
1950 PRINT:PRINT:PRINT
1960 IF I = 0 THEN PRINT "      *** Elements to be INSULATED FROM the boom by a boom diameter ***"
1970 PRINT:PRINT
1980 IF I=0 THEN PRINT ELSE GOTO 2020"
1990 PRINT"     NOTE: When an element is spaced at least one boom diameter"
2000 PRINT"           away from the boom there will be little effect on its "
2010 PRINT"           electrical length - no boom correction necessary."
2020 IF I = 1 THEN PRINT "            ***  Elements are NOT INSULATED from the Boom ***"
2030 IF I = 2 THEN PRINT "           ***  Elements are to be INSULATED THRU the Boom ***"
2040 '
2050 '-----------------------CHECK SPECIFICATIONS-------------------------------
2060 IF BDW<.07 THEN GOTO 2120
2070 CLS
2080 PRINT
2090 '
2100 IF BDW>.07 THEN COLOR 31:PRINT"           ***** BOOM TOO LARGE FOR CORRECTION CALCULATION *****"
2110 GOTO  5630                                 'List max boom diameters
2120 PRINT
2130 COLOR 15, 1
2140 LOCATE 24, 22
2150 INPUT"Is this criteria correct   <Y/N> "; Z$
2160 IF Z$ = "Y" OR Z$ = "y" GOTO 2200
2170 IF Z$ = "N" OR Z$ = "n" THEN CLS:RUN 770
2180 GOTO 1820
2190 '-----------------------CALCULATE BOOM LENGTH------------------------------
2200 TL = 0: S = 1296 / F
2210 FOR X = 1 TO N - 1
2220 DS(X) = SP(X) * S
2230 TL = TL + DS(X)
2240 NEXT X
2250 PG = (TL / 1000) / W
2260 '
2270 '-----------------------CALCULATE BEAM WIDTHS----------------------------
2280 '
2290 GOSUB 4810                            'BH AND BV CALCULATION
2300 GOTO 2320
2310 '
2320 COLOR 14, 1
2330 '----------------------SELECT ELEMENT MATERIAL SIZE-----------------------
2340 '
2350 OPEN "I", #1, "CURVE-46.DAT"           'Data for Directors - only
2360 FOR X = 1 TO 46                        'Number of Directors available
2370 INPUT #1, O$
2380 TS(X) = VAL(O$)
2390 NEXT X
2400 CLOSE 1
2410 CLS:LOCATE 5,20
2420 PRINT"***** PLEASE WAIT FOR CALCULATIONS *****"
2430 RO1 = .0028819
2440 K1 = 1 / RO1: K2 = 1 / RO2
2450 FOR X = 1 TO 46                        'Number of Directors available
2460 FR1(X) = (1 - (10.7575 * (LOG(K1) / LOG(10)) - 8) ^ -1) / (2 * TS(X))
2470 R1(X) = (215.15 * (LOG(K1) / LOG(10)) - 160) * (1 / FR1(X) - FR1(X))
2480 R2(X) = R1(X)
2490 A(X) = R1(X) / (215.15 * (LOG(K2) / LOG(10)) - 160)
2500 FR2(X) = ((A(X) ^ 2 + 4) ^ .5 - A(X)) / 2
2510 TS(X) = (1 - (10.7575 * (LOG(K2) / LOG(10)) - 8) ^ -1) / (2 * FR2(X))
2520 NEXT X
2530 '
2540 '---------------------CALCULATE ELEMENT LENGTHS---------------------------
2550 FOR X = 3 TO 48
2560 IF I = 0 THEN LE(X) = W * TS(X - 2) * 1000 ELSE LE(X) = (W * TS(X - 2) * 1000) + BC                                             'Insulated from boom
2570 NEXT X
2580 L = .49                                   'Was .487 - changed by WA2TIF
2590 GOSUB 5560
2600 LE(1) = L * W * 1000
2610 IF I = 1 THEN LE(1) = LE(1) + BC                'Not insulated from boom
2620 IF I = 2 THEN LE(1) = LE(1) + BC                'Insulated thru boom
2630 L = .473                                  'Was .446 - changed by WA2TIF
2640 GOSUB 5560
2650 LE(2) = L * W * 1000
2660 LOCATE 12, 5
2670 PRINT "   ***************************************************************************"
2680 COLOR 15, 1
2690 PRINT "          ***** IF YOU WANT A HARD COPY TURN ON YOUR PRINTER NOW *****"
2700 COLOR 14, 1
2710 PRINT "   ***************************************************************************"
2720 PRINT:PRINT:PRINT
2730 COLOR 15, 1
2740 LOCATE 24, 20
2750 PRINT"Do you want a hard copy ?    <Y/N/Q(quit)>": R$ = INPUT$(1)
2760 IF R$ = "Y" OR R$ = "y" THEN OPEN "O", #1, "LPT1:"
2770 IF R$ = "N" OR R$ = "n" THEN OPEN "O", #1, "SCRN:"
2780 IF R$ = "Q" OR R$ = "q" THEN GOTO 4310                 'stop the program
2790 IF R$ <> "Y" THEN IF R$ <> "y" THEN IF R$ <> "N" THEN IF R$ <> "n" THEN GOTO 2750
2800 COLOR 14, 1
2810 CLS
2820 '-----------------------FINAL DESIGN DETAILS------------------------------
2830 PRINT #1,
2840 PRINT #1,"        Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT #1,"     Time: ";TIME$:
2850 PRINT #1,
2860 COLOR 14, 1
2870 PRINT #1, "                  ***** YAGI ANTENNA DESIGN DETAILS *****"
2880 PRINT #1,
2890 PRINT #1, "      DESIGN FREQUENCY                "; USING C$; F ; : PRINT #1,   "   Mhz"
2900 '
2910 IF (F>=50)   AND (F<=54)   THEN PRINT #1,"      BAND"TAB(39)"   6 M    BAND"
2920 IF (F>=144)  AND (F<=148)  THEN PRINT #1,"      BAND"TAB(39)"   2 M    Band"
2930 IF (F>=222)  AND (F<=225)  THEN PRINT #1,"      BAND"TAB(39)"   1.25 M Band"
2940 IF (F>=420)  AND (F<=450)  THEN PRINT #1,"      BAND"TAB(39)"  70 CM   Band"
2950 IF (F>=902)  AND (F<=928)  THEN PRINT #1,"      BAND"TAB(39)"  33 CM   Band"
2960 IF (F>=1240) AND (F<=1300) THEN PRINT #1,"      BAND"TAB(39)"  23 CM   Band"
2970 IF (F>=2300) AND (F<=2310) THEN PRINT #1,"      BAND"TAB(39)"  13 CM   Band"
2980 PRINT #1, "      LAMBDA (Wavelength)            "; USING X$;W*1000;:PRINT #1, "   mm      = ";USING Y$; W*39.37;:PRINT #1,"ins"
2990 GOSUB 4730
3000 PRINT #1, "      GAIN (With -15 db side lobes)     ";USING D$; GD;:PRINT #1, "   DBD"
3010 PRINT #1, "      NUMBER OF ELEMENTS", TAB(40); N
3020 XX = ED: GOSUB 4480
3030 PRINT #1, "      DIAMETER OF ELEMENTS           "; USING X$; ED; : PRINT #1, "   mm      = ";
3040 PRINT #1, USING Y$; ZZ; : PRINT #1, " ins"
3050 XX = BD: GOSUB 4480
3060 PRINT #1, "      DIAMETER OF BOOM  (O.D.)       "; USING X$; BD; : PRINT #1, "   mm      = "; :
3070 PRINT #1, USING Y$; ZZ; : PRINT #1, " ins"
3080 XX = TL: GOSUB 4480
3090 PRINT #1, "      BOOM LENGTH                    ";USING X$;PG*W*1000;:PRINT #1, "   mm      = ";USING Y$;(YY*12) + (ZZ);:PRINT #1, " ins"
3100 PRINT #1, "      BOOM WAVELENGTHS "; : PRINT #1, TAB(39); USING C$; PG
3110 PRINT #1, "      BOOM CORRECTION FACTOR         ";USING X$;BC;:PRINT #1, "   mm      = ";USING Y$;BC/J1;:PRINT #1," ins"
3120 PRINT #1, "      TYPICAL BANDWIDTH"; TAB(41);USING D$; (F * .014);:PRINT #1, "   Mhz"
3130 PRINT #1, "      HORIZONTAL BEAM WIDTH", TAB(40); BH; "     degrees"
3140 PRINT #1, "      VERTICAL BEAM WIDTH", TAB(40); BV; "     degrees"
3150 XX = W * (51 / BH)
3160 PRINT #1, "      HORIZONTAL STACKING DISTANCE   "; USING X$; XX*1000; : GOSUB 4440: PRINT #1, "   mm      = "; USING Y$;(YY*12) + (ZZ);: PRINT #1, " ins"
3170 '
3180 XX = W * (51 / BV)
3190 PRINT #1, "      VERTICAL STACKING DISTANCE     "; USING X$; XX*1000; : GOSUB 4440: PRINT #1, "   mm      = "; USING Y$;(YY*12) + (ZZ);: PRINT #1, " ins"
3200 '
3210 PRINT #1, "      DIMENSIONAL TOLERANCE (+/-)       ";USING D$;((W * 1000) * .003);:PRINT #1, "   mm      = "; : PRINT #1, USING Y$; (((W * 1000) * .003)) * .039; : PRINT #1, " ins"
3220 PRINT
3230 IF I = 0 THEN PRINT #1, "     *** Elements to be INSULATED FROM the boom by a boom diameter ***"
3240 IF I = 1 THEN PRINT #1, "                *** Elements are NOT INSULATED from the boom ***"
3250 IF I = 2 THEN PRINT #1, "                  *** Elements are INSULATED THRU the boom ***"
3260 PRINT #1,
3270 COLOR 15, 1
3280 LOCATE 24,18
3290 INPUT"Continue with element length  <Y/N/Q(quit)> "; J$
3300 IF J$ = "N" OR J$ = "n" THEN CLS:RUN 770               'another calculation
3310 IF J$ = "Q" OR J$ = "q" THEN GOTO 4310                 'stop the program
3320 '-------------------------ELEMENT LENGTH----------------------------------
3330 COLOR 14, 1
3340 CLS
3350 PRINT #1,
3360 PRINT #1, "                       ***** ELEMENT LENGTH *****"
3370 PRINT #1,
3380 PRINT #1, TAB(35); "mm"; TAB(59); "ins"
3390 PRINT #1,
3400 PRINT #1, "   REFLECTOR"; : PRINT #1, TAB(30); USING X$; LE(1); : PRINT #1, TAB(56);USING Y$; LE(1) * J2
3410 PRINT #1, "   FOLDED DIPOLE"; : PRINT #1, TAB(30); USING X$; LE(2); : PRINT #1, TAB(56); USING Y$; (LE(2) * J2)
3420 FOR X = 3 TO N
3430 PRINT #1, "   DIRECTOR # "; X - 2; : PRINT #1, TAB(30); USING X$; LE(X); : PRINT #1, TAB(56); USING Y$; (LE(X) * J2)
3440 NEXT X
3450 CLOSE  O
3460 PRINT #1, "   ------------------------------------------------------------------------"
3470 COLOR 15, 1
3480 LOCATE 24,4
3510 IF I = 0 OR I = 1 THEN GOTO 3700
3515 INPUT"Continue with element protrusion  <Y/N/Q>  "; G$
3520 IF G$ = "N" OR G$ = "n" THEN CLS:GOTO 3700             'element spacing
3530 IF G$ = "Q" OR G$ = "q" THEN GOTO 4310                 'stop the program
3540 COLOR 14, 1
3560 '------------------------ELEMENT PROTRUSION--------------------------------
3570 '
3580 PRINT #1,
3590 PRINT #1, "      ***** ELEMENT PROTRUSION FROM BUSHING TO END OF ELEMENT *****"
3600 IF I = 2 THEN GOTO 5180
3610 PRINT #1,
3620 PRINT #1, TAB(37); "mm"; TAB(61); "ins"
3630 PRINT #1,
3640 PRINT #1, "   REFLECTOR"; : PRINT #1, TAB(33); USING X$; (LE(1) / 2) - BD / 2; : PRINT #1, TAB(58); USING Y$; (((LE(1) / 2) - BD / 2) * J2)
3650 PRINT #1, "   FOLDED DIPOLE"; : PRINT #1, TAB(33); USING X$; (LE(2) / 2) - BD / 2; : PRINT #1, TAB(58); USING Y$; (((LE(2) / 2) - BD / 2) * J2)
3660 FOR X = 3 TO N
3670 PRINT #1, "   DIRECTOR # "; X - 2; : PRINT #1, TAB(33); USING X$; (LE(X) / 2) - BD / 2; : PRINT #1, TAB(58); USING Y$; (((LE(X) / 2) - BD / 2) * J2)
3680 NEXT X
3690 PRINT #1, "   ------------------------------------------------------------------------"
3700 COLOR 15, 1
3710 PRINT : PRINT
3720 LOCATE 24,18
3730 INPUT"Continue with element spacing  <Y/N/Q>  "; G$
3740 IF G$ = "N" OR G$ = "n" THEN GOTO 3950:CLS          'progressive spacing
3750 IF G$ = "Q" OR G$ = "q" THEN GOTO 4310              'stop the program
3760 '
3770 '-------------------------ELEMENT SPACING---------------------------------
3780 CLS
3790 COLOR 14,1
3800 PRINT #1,
3810 PRINT #1, "               ***** ELEMENT SPACING  (center to center) *****"
3820 PRINT #1,
3830 PRINT #1, TAB(47); "mm"; TAB(61); "ins"
3840 PRINT #1,
3850 PRINT #1, "   REFLECTOR"; TAB(19); "to"; TAB(25); "FOLDED DIPOLE"; : PRINT #1, TAB(42); USING X$; DS(1); : PRINT #1, TAB(58); USING Y$; (DS(1) * J2)
3860 PRINT #1, "   FOLDED DIPOLE"; TAB(19); "to"; TAB(25); "DIR 1"; : PRINT #1, TAB(42); USING X$; DS(2); : PRINT #1, TAB(58); USING Y$; (DS(2) * J2)
3870 FOR X = 3 TO N - 1
3880 PRINT #1, "   DIR"; X - 2; TAB(19); "to"; TAB(25); "DIR"; X - 1; : PRINT #1, TAB(42); USING X$; DS(X); : PRINT #1, TAB(58); USING Y$; (DS(X) * J2)
3890 NEXT X
3900 PRINT #1, "   ------------------------------------------------------------------------"
3910 '
3920 PRINT"           PROGRESSIVE SPACING must be included in your calculations
3930 PRINT"                    to get the correct boom length.
3940 COLOR 15, 1
3950 LOCATE 24,18
3960 INPUT"Continue with progressive spacing   <Y/Q>  "; H$
3970 IF H$ = "Y" OR H$ = "y" THEN CLS
3980 IF H$ = "Q" OR H$ = "q" THEN GOTO 4310                'stop the program
3990 COLOR 14, 1
4000 '-----------------------PROGRESSIVE SPACING-------------------------------
4010 '
4020 PRINT #1,
4030 PRINT #1, "      ***** PROGRESSIVE SPACING (from reflector end of the boom)*****"
4040 PRINT #1,
4050 PRINT #1, TAB(46); "mm"; TAB(63); " ins"
4060 PRINT #1,
4070 Z = 13: PRINT #1, "   BOOM TO REFLECTOR "; : PRINT #1, TAB(41); USING X$; Z; : PRINT #1, TAB(62); USING Y$; (Z * J2)
4080 K = DS(1) + Z: PRINT #1, "   TO FOLDED DIPOLE "; : PRINT #1, TAB(41); USING X$; K; : PRINT #1, TAB(62); USING Y$; (K * J2)
4090 FOR X = 2 TO N - 1: K = K + DS(X)
4100 PRINT #1, "   TO ELEMENT"; X + 1;
4110 PRINT #1, TAB(20); "(director";
4120 PRINT #1, X - 1;
4130 PRINT #1, ")";
4140 PRINT #1, TAB(41); USING X$; K; : PRINT #1, TAB(62); USING Y$; (K * J2)
4150 NEXT X
4160 PRINT #1, "   ------------------------------------------------------------------------"
4170 PRINT #1, : PRINT #1,
4180 PRINT #1,"              ***** BOOM LENGTH REQUIRED FOR FABRICATION *****"
4190 K = K + 13
4200 PRINT #1,
4210 PRINT #1, TAB(23); USING X$; K     ; : PRINT #1, " mm   = "; : XX = K / 10: GOSUB 4460
4220 PRINT #1, TAB(42);USING Y$;(YY*12)+ ZZ; : PRINT #1, " ins"
4230 CLOSE  O : PRINT #1,
4240 COLOR 15, 1
4250 LOCATE 24,18
4260 INPUT"Do you wish to return to Main Menu <Y/Q> ";TT$
4270 IF TT$ = "Y" OR TT$ = "y" THEN CLS:COLOR 14, 1:RUN 770
4280 IF TT$ = "Q" OR TT$ = "q" THEN GOTO 4310               'stop the program
4290 PRINT
4300 '-------------------------STOP THE PROGRAM--------------------------------
4310 CLS:LOCATE 12, 12
4320 INPUT" DO YOU REALLY WANT TO TERMINATE THE PROGRAM  <Y/N> ";T$
4330 IF T$ = "Y" OR T$ = "y" THEN 4350
4340 IF T$ = "N" OR T$ = "n" THEN RUN 770
4350 SYSTEM
4410 END
4420 '--------------- SUBROUTINE TO CONVERT TO FEET & INCHES ------------------
4430 '
4440 XX = (XX * 1000) * J2:                      'Input for Metres
4450 GOTO 4490
4460 XX = (XX * 10) * J2:                        'Input for Centimeters
4470 GOTO 4490
4480 XX = XX * J2                                'Input for Millimeters
4490 YY = INT(XX / 12):                          'Output in Feet
4500 ZZ = (XX - (YY * 12)):                      'Output in Inches
4510 RETURN
4520 '----------------------------BOOM DIAMETER-----------------------------
4530 BDW = BD / 1000 / W
4540 IF BDW<.005 THEN BCW=.0018:GOTO 4680
4550 IF BDW<.01  THEN BCW=.003 :GOTO 4680
4560 IF BDW<.015 THEN BCW=.005 :GOTO 4680
4570 IF BDW<.02  THEN BCW=.0075:GOTO 4680
4580 IF BDW<.025 THEN BCW=.012 :GOTO 4680
4590 IF BDW<.03  THEN BCW=.014 :GOTO 4680
4600 IF BDW<.035 THEN BCW=.018 :GOTO 4680
4610 IF BDW<.04  THEN BCW=.0225:GOTO 4680
4620 IF BDW<.045 THEN BCW=.027 :GOTO 4680
4630 IF BDW<.05  THEN BCW=.032 :GOTO 4680
4640 IF BDW<.055 THEN BCW=.037 :GOTO 4680
4650 IF BDW<.06  THEN BCW=.043 :GOTO 4680
4660 IF BDW<.065 THEN BCW=.049 :GOTO 4680
4670 IF BDW<.07  THEN BCW=.055 :GOTO 4680
4680 IF I = 1 THEN BC = (BCW*W*1000):               'NOT INSULATED FROM BOOM
4690 IF I = 2 THEN BC=.5*BCW*W*1000:                'INSULATED THRU BOOM
4700 GOTO 1820
4710 '---------------------------ANTENNA GAIN----------------------------------
4720 '
4730 GD = 7.77 * (LOG(PG) / LOG(10)) + 9.2
4740 GD = 100 * GD
4750 GD = INT(GD)
4760 GD = GD / 100
4770 RETURN                                         'TO 2130
4780 '
4790 '--------------------------BOOM WAVELENGTHS-------------------------------
4800 '
4810 IF PG =< 1 THEN BV = 70: BH = 52
4820 IF PG > 1    AND PG =< 1.33 THEN BV = 60: BH = 46
4830 IF PG > 1.33 AND PG =< 1.67 THEN BV = 50: BH = 40
4840 IF PG > 1.67 AND PG =< 2    THEN BV = 43: BH = 36
4850 IF PG > 2    AND PG =< 2.33 THEN BV = 38: BH = 33
4860 IF PG > 2.33 AND PG =< 2.67 THEN BV = 34: BH = 30
4870 IF PG > 2.67 AND PG =< 3    THEN BV = 32: BH = 28
4880 IF PG > 3    AND PG =< 3.33 THEN BV = 30: BH = 27
4890 IF PG > 3.33 AND PG =< 3.67 THEN BV = 29: BH = 26
4900 IF PG > 3.67 AND PG =< 4    THEN BV = 28: BH = 25
4910 IF PG > 4    AND PG =< 4.33 THEN BV = 27: BH = 24
4920 IF PG > 4.33 AND PG =< 5.33 THEN BV = 26: BH = 23
4930 IF PG > 5.33 AND PG =< 7    THEN BV = 24: BH = 22
4940 IF PG > 7    AND PG =< 8    THEN BV = 23: BH = 21
4950 IF PG > 8    AND PG =< 9    THEN BV = 22: BH = 20
4960 IF PG > 9    AND PG =< 10   THEN BV = 21: BH = 19
4970 IF PG > 10   AND PG =< 11   THEN BV = 20: BH = 18
4980 IF PG > 11   AND PG =< 12   THEN BV = 19: BH = 17
4990 IF PG > 12   AND PG =< 15   THEN BV = 18.5: BH = 16.5
5000 IF PG > 15   AND PG =< 18   THEN BV = 18: BH = 16
5010 IF PG > 18                  THEN GOTO 5040
5020 RETURN                                     'To line 2250
5030 '-----------------------MAXIMUM NUMBER OF ELEMENTS--------------------------
5040 CLS:COLOR 14,1
5050 LOCATE 5, 25
5060 COLOR 31:PRINT"***** TO MANY ELEMENTS *****"
5070 COLOR 14,1
5080 LOCATE 10, 20
5090 PRINT"          THE TOTAL NUMBER OF ELEMENTS THIS PROGRAM CAN HANDLE IS 48
5100 PRINT:PRINT
5110 PRINT"    TOTAL NUMBER OF ELEMENTS =  REFLECTOR, DRIVEN ELEMENT AND ALL DIRECTORS"
5120 LOCATE 24,15
5130 COLOR 15,1
5140 INPUT"Do you wish to reduce the number of elements <Y/Q>  ";G$
5150 IF G$ = "Y" OR G$ = "y" THEN CLS:COLOR 14,1:RUN 770
5160 IF G$ = "Q" OR G$ = "q" THEN 4310
5170 IF NOT (Q OR Q) THEN RUN 770
5180 PRINT
5190 PRINT"          Each element has a shoulder bushing on each side of the boom to"
5200 PRINT"     insulate it from the boom.  To measure the element protrusion it is"
5210 PRINT"     necessary to measure the distance from the face of the bushing to"
5220 PRINT"     end of the element."
5230 PRINT
5240 PRINT"            The program uses ENGLISH and METRIC units."
5250 PRINT
5260 COLOR 15,1
5270 INPUT"       Which unit would you like to use for this measurement- <E/M>  "; S$
5280 IF S$ = "M" OR S$ = "m" GOTO 5300
5290 IF S$ = "E" OR S$ = "e" GOTO 5390
5300 COLOR 15,1:PRINT:PRINT
5310 INPUT "         What is the thickness of the shoulder bushing <in mm>  "; T
5320 CLS
5330 COLOR 14,1:GOTO 5340
5340 PRINT #1,:PRINT #1,
5350 PRINT #1, "          ***** ELEMENT PROTUSION FROM BUSHING TO END OF ELEMENT*****"
5360 PRINT #1,:PRINT #1,
5370 PRINT #1, "              The thickness of the shoulder bushing is  "; T; " mm"
5380 PRINT #1,:GOTO 5480
5390 PRINT #1,:PRINT #1,
5400 COLOR 15,1
5410 INPUT "         What is the thickness of the shoulder bushing <in ins>  "; TE
5420 CLS:PRINT #1,:COLOR 14,1
5430 PRINT #1, "          ***** ELEMENT PROTUSION FROM BUSHING TO END OF ELEMENT*****"
5440 PRINT #1,
5450 T = TE * J1
5460 PRINT #1, "              The thickness of the shoulder bushing is  "; TE; "ins"
5470 PRINT #1,
5480 PRINT #1, TAB(38); "mm"; TAB(61); "ins"
5490 PRINT #1,
5500 PRINT #1, "   REFLECTOR"; : PRINT #1, TAB(33); USING X$; (LE(1) - (BD + 2 * T)) / 2; : PRINT #1, TAB(58); USING Y$; ((LE(1) - (BD + 2 * T)) / 2) * J2
5510 PRINT #1, "   FOLDED DIPOLE"; : PRINT #1, TAB(33); USING X$; (LE(2) - (BD + 2 * T)) / 2; : PRINT #1, TAB(58); USING Y$; ((LE(2) - (BD + 2 * T)) / 2) * J2
5520 FOR X = 3 TO N
5530 PRINT #1, "   DIRECTOR # "; X - 2; : PRINT #1, TAB(33); USING X$; (LE(X) - (BD + 2 * T)) / 2; : PRINT #1, TAB(58); USING Y$; ((LE(X) - (BD + 2 * T)) / 2) * J2
5540 NEXT X
5550 GOTO 3690                                  'To continue the program
5560 FR1 = (1 - (10.7575 * (LOG(K1) / LOG(10)) - 8) ^ -1) / (2 * L)
5570 R1 = (215.15*(LOG(K1)/LOG(10))-160)*(1/FR1-FR1)
5580 R2 = R1
5590 A = R2 / (215.15 * (LOG(K2) / LOG(10)) - 160)
5600 FR2 = (-A + (A ^ 2 + 4) ^ (1 / 2)) / 2
5610 TS = (1 - (10.7575 * (LOG(K2) / LOG(10)) - 8) ^ -1) / (2 * FR2)
5620 RETURN
5630 PRINT:PRINT
5640 COLOR 14, 1
5650 PRINT"        The frequency you have selected is:       ";USING C$; F; :PRINT "  Mhz "
5660 PRINT
5670 PRINT"        The boom diameter you have selected is:  ";USING X$;BD;:PRINT" mm =";USING Y$; ZZ;:PRINT" ins"
5680 PRINT
5690 F1=299792.458#/FA                              '6 Meters
5700 F2=299792.458#/FB                              '2 Meters
5710 F3=299792.458#/FC                              '1.25 Meters
5720 F4=299792.458#/FD                              '70 cm
5730 F5=299792.458#/FE                              '33 cm
5740 F6=299792.458#/FF                              '23 cm
5750 F7=299792.458#/FG                              '13 cm
5760 PRINT"        The MAXIMUM boom diameters for each band are:"
5770 PRINT
5780 PRINT"        FREQ            BAND              MM             INCHES
5790 PRINT" ------------------------------------------------------------------
5800 PRINT
5810 PRINT"       50 Mhz           6 Meters       ";USING C$; F1*.07;:PRINT            "          ";USING Y$;F1/J1*.07
5820 PRINT"      144 Mhz           2 Meters       ";USING C$; F2*.07;:PRINT            "          ";USING Y$;F2/J1*.07
5830 PRINT"      222 Mhz           1.25 Meters    ";USING C$; F3*.07;:PRINT            "          ";USING Y$;F3/J1*.07
5840 PRINT"      432 Mhz          70 cm           ";USING C$; F4*.07;:PRINT            "          ";USING Y$;F4/J1*.07
5850 PRINT"      903 Mhz          33 cm           ";USING C$; F5*.07;:PRINT            "          ";USING Y$;F5/J1*.07
5860 PRINT"     1296 Mhz          23 cm           ";USING C$; F6*.07;:PRINT            "          ";USING Y$;F6/J1*.07
5870 PRINT"     2304 MHZ          13 CM           ";USING C$; F7*.07;:PRINT            "          ";USING Y$;F7/J1*.07
5880 COLOR 15, 1
5890 PRINT
5900 PRINT
5910 LOCATE 24,15
5920 INPUT"Do you want to change the boom diameter <Y/Q> ";CC$
5930 IF CC$ = "Y" OR CC$ = "y" THEN CLS:COLOR 14, 1:RUN 770
5940 IF CC$ = "Q" OR CC$ = "q" THEN 4310
5950 '
5960 '-----------------------CHECK OUT PROCEDURE------------------------------
5970 COLOR 14, 1:CLS
5980 PRINT:PRINT
5990 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
6000 PRINT
6010 PRINT"                         ***** CHECK OUT PROCEDURE *****
6020 PRINT
6030 PRINT"     This design was proved with an equal-diameter folded dipole driven"
6040 PRINT"element, with a half wave 4:1 balun.  You can also use a T-Match Dipole with"
6050 PRINT"a 4:1 Balun.  These can be replaced with a balanced dipole and 1:1 balun"
6060 PRINT"with unaltered results.  HOWEVER, matching the feeder to the radiator is"
6070 PRINT"critical with parasitic antennas.  The relationship between antenna geometry"
6080 PRINT"& feedpoint impedance is complex.  DO NOT CHANGE ANY ELEMENT OR SPACING -"
6090 PRINT"other than the driven element."
6100 PRINT"     Temporarily install a 50 ohm pad in the feedline to the Receiver; adjust"
6110 PRINT"the driven element for maximum received signal.  This will ensure that the"
6120 PRINT"driven element is resonant, Note - THE PAD IS MANDATORY.  A suitable (T) pad"
6130 PRINT"can be made using 1% 27 ohm carbon resistors as R1, R2, R3."
6140 PRINT"     Check matching by pointing the antenna skyward, then measure SWR. Make"
6150 PRINT"adjustments if necessary. If the SWR exceeds the expected value, and ALL"
6160 PRINT"MEASUREMENTS are correct, check the balun.  If the balun is OK then the problem"
6170 PRINT"will lie with the driven element position. Adjust the DE position. Do NOT"
6180 PRINT"tweek any other element. TWEEKING will not produce more than a fraction of a"
6190 PRINT"db improvement in DL6WU's figures.
6200 PRINT
6210 COLOR 15, 1
6220 INPUT "            Do you wish to return to the Main Menu   <Y/Q>  ";P$
6230 PRINT
6240 IF P$ = "Y" OR P$ = "y" THEN CLS:COLOR 14, 1:RUN 770
6250 IF P$ = "Q" OR P$ = "q" THEN GOTO 4310
6260 '
6270 '-------------------END OF ORIGINAL DL6WU PROGRAM-------------------------
6280 '
6290 '--------------------------FOLDED DIPOLE----------------------------------
6300 CLS
6310 COLOR 14, 1
6320 PRINT
6330 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
6340 PRINT:PRINT
6350 PRINT"               ***** CALCULATIONS FOR FOLDED DIPOLE *****"
6360 PRINT
6370 PRINT"     Antennas designed with this program have always given satisfactory results"
6380 PRINT"with an equal-diameter Folded Dipole and a 4:1 Coaxial Balun.  The dipole feed"
6390 PRINT"point is balanced and has an impedance of approximately 200 ohms.  The cond-"
6400 PRINT"conductor diameter is not critical, neither is limb separation, which can be"
6410 PRINT"anything from 0.02 to 0.1 Lambda.  The overall folded dipole length must always"
6420 PRINT"be 0.473 Lambda.  The use of RG 141/U Hardline for the balun is strongly"
6430 PRINT"recommended for 432 Mhz through 2304 Mhz."
6440 PRINT
6450 PRINT"     You may substitute a T-MATCH driven element with a 4:1 balun (see Menu)"
6460 PRINT"or you may substitute a split dipole with 1:1 current balun.  The results"
6470 PRINT"will be the same.  Balun information sources are:
6472 PRINT
6474 PRINT"                       QST, June 1991,      Page 30
6480 PRINT"                       QST, September 1993, Page 77
6490 PRINT"                       CQ,  January 1993,   Page 30
6500 COLOR 15, 1
6510 LOCATE 24,22
6520 INPUT"Do you wish to continue <Y/N/Q>  " ;AN$
6530 COLOR 14, 1
6540 IF AN$ = "Y" OR AN$ = "y" THEN CLS:GOTO 6580
6550 IF AN$ = "N" OR AN$ = "n" THEN CLS:COLOR 14, 1:RUN 770
6560 IF AN$ = "Q" OR AN$ = "q" THEN GOTO 4310
6570 PRINT
6580 PRINT:PRINT
6590 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
6600 PRINT:PRINT
6610 INPUT"      What is the center freq of the folded dipole in Mhz "  ;F
6620 W = 299.792458# / F
6630 PRINT
6640 PRINT"      LAMBDA =                            ";USING C$;W*1000;:PRINT "  mm  or ";USING Y$;W*39.37;:PRINT" ins"
6650 PRINT
6660 PRINT"      The Folded Dipole overall length = ";USING X$;(W*1000*.473);:PRINT"  mm  or ";USING Y$;(W*1000*.473)/J1;:PRINT" ins"
6670 PRINT
6680 PRINT"      The Limb separation range is ";USING A$;(W*1000*.02);:PRINT" to ";USING A$;(W*1000*.1);:PRINT" mm or";USING Y$;(W*1000*.02)/25.4;:PRINT" to";USING Y$;(W*1000*.1)/25.4;:PRINT" ins"
6690 PRINT
6700 PRINT"      The suggested conductor diameter range is  2 to 5 mm or .070 to.197 ins"
6710 PRINT
6720 PRINT"               (Use smaller diameter for higher frequencies)
6730 PRINT
6740 PRINT"            |<---------------  OVERALL LENGTH ------------------>|
6750 PRINT"            |  ________________________________________________  |
6760 PRINT"            | /         |                                      \ |
6770 PRINT"            |/          | Limb separation                       \|
6780 PRINT"            |\          |                                       /|
6790 PRINT"              \----------------------   -----------------------/
6800 PRINT"                                   BAL FEED
6810 COLOR 15, 1
6820 INPUT"            Do you wish to calculate another folded dipole <Y/N/Q> ";Z$
6830 IF Z$ = "Y" OR Z$ = "y" THEN CLS:COLOR 14, 1:GOTO 6580
6840 IF Z$ = "N" OR Z$ = "n" THEN CLS:GOTO 6860
6850 IF Z$ = "Q" OR Z$ = "q" THEN 4310
6860 PRINT
6870 PRINT
6880 INPUT"   Would you like to look at a typical folded dipole for 1296 Mhz <Y/N/Q>";EX$
6890 IF EX$ = "Y" OR EX$ = "y" THEN CLS:COLOR 14, 1:GOTO 6920
6900 IF EX$ = "N" OR EX$ = "n" THEN CLS:COLOR 14, 1:RUN 770
6910 IF EX$ = "Q" OR EX$ = "q" THEN 4310
6920 PRINT
6930 PRINT"                          ***** EXAMPLE *****
6940 PRINT
6950 PRINT"                SIMPLE FOLDED DIPOLE/BALUN FEED COMBINATION
6960 PRINT
6970 PRINT"      Frequency =                      1296 Mhz
6980 PRINT
6990 PRINT"      Dipole overall length =          110 mm or 4.330 ins
7000 PRINT
7010 PRINT"      Diameter driven element =        2 - 3 mm or .070 -.118 ins
7020 PRINT
7030 PRINT"      Limb separation =                18 mm or 0.709 ins
7040 PRINT
7050 PRINT"      Connector =                      Type N - chassis
7060 PRINT
7070 PRINT"      BALUN =     Semi-rigid 50 ohm coax cable, (e.g. RG-141/U)"
7080 PRINT"                       88 mm or 3.464 ins long (outer conductor) "
7090 PRINT
7100 PRINT
7110 PRINT"    (Source for above = P 9-7, ARRL UHF/MICROWAVE EXPERIMENTER'S MANUAL)
7120 PRINT
7130 COLOR 15, 1
7140 PRINT:PRINT
7150 INPUT"             Do you wish to return to Main Menu <Y/Q> ";SS$
7160 IF SS$ = "Y" OR SS$ = "y" THEN CLS:COLOR 14, 1:RUN 770
7170 IF SS$ = "Q" OR SS$ = "q" THEN 4310
7180 '
7190 '---------------------------T-MATCH---------------------------------------
7200 COLOR 14, 1
7210 CLS:PRINT
7220 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
7230 PRINT
7240 PRINT"                          ***** T - MATCH *****
7250 PRINT
7260 PRINT"     The T-Match with its balanced feed point is one method of feeding a "
7270 PRINT"Balanced Dipole.  A suitable 4:1 balun is used in conjunction with the"
7280 PRINT"T-Match to perform this function.  The T-Match, with a 4:1 balun and Balanced"
7290 PRINT"Dipole can be substituted for a Folded Dipole with its 4:1 coax balun.  To "
7295 PRINT"construct a 4:1 coax balun see the schematic and the Section on BALUNS for"
7300 PRINT"coax selection and dimensions."
7320 PRINT
7330 PRINT"     Adjustment of the T-Match with a 4:1 balun is simple - just adjust the"
7340 PRINT"position of the shorts on the Arms until you get an acceptable SWR.  For the"
7350 PRINT"lowest SWR it may be necessary to change the length of the Driven Element."
7360 PRINT"After changing the driven element readjust for the lowest SWR."
7370 PRINT
7380 PRINT"     SCHEMATIC:                          Balanced  Dipole
7390 PRINT"                           --------------------------------------------
7400 PRINT"Spacing between Arms &            |                           |  Short
7410 PRINT"Dipole can be anything         ---------------O O----------------
7420 PRINT"convenient for construction                Bal Feed       Arm
7430 PRINT
7440 COLOR 15,1
7450 LOCATE 24, 7
7460 INPUT"Would you like to calculate a T-MATCH for a Balanced Dipole  <Y/N> ";P$
7470 IF P$ = "Y" OR P$ = "y" THEN 7490
7480 IF P$ = "N" OR P$ = "n" THEN RUN 770
7490 CLS
7500 COLOR 14,1
7510 PRINT
7520 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
7530 PRINT
7540 PRINT"                          ***** T - MATCH *****
7550 PRINT
7560 INPUT"      FREQUENCY of the Antenna  (Mhz)                    ";FR
7570 W = 299.792458# / FR
7580 PRINT"      LAMBDA                                  ";USING C$;W*1000;:PRINT "  mm  or ";USING Y$;W*39.37;:PRINT" ins"
7590 PRINT"      DIPOLE                                 ";USING X$;(W*1000*.473);:PRINT"  mm  or ";USING Y$;(W*1000*.473)/J1;:PRINT" ins"
7600 PRINT"      DIPOLE DIAMETER ",
7610 IF (FR>=50)   AND (FR<=54)  THEN PRINT TAB(49)"12.7   mm  or   0.5   ins"
7620 IF (FR>=144)  AND (FR<=148) THEN PRINT TAB(49)" 4.765 mm  or   0.187 ins"
7630 IF (FR>=222)  AND (FR<=225) THEN PRINT TAB(49)" 4.765 mm  or   0.187 ins"
7640 IF (FR>=420)  AND (FR<=450) THEN PRINT TAB(49)" 4.765 mm  or   0.187 ins"
7650 IF (FR>=902)  AND (FR<=928) THEN PRINT TAB(49)" 4.765 mm  or   0.187 ins"
7660 IF (FR>=1240) AND (FR<=1300)THEN PRINT TAB(49)" 3.175 mm  or   0.125 ins"
7670 IF (FR>=2300) AND (FR<=2310)THEN PRINT TAB(49)" 3.175 mm  or   0.125 ins"
7680 LA = W * 1000 * .473  / 2 * .5
7690 PRINT"      ARM LENGTH        ";TAB(51)INT (LA);:PRINT" mm  or  ";INT (LA/J1);:PRINT" ins"
7700 PRINT"      ARM DIAMETER ",
7710 IF (FR>=50)   AND (FR<=54)  THEN PRINT TAB(49)" 6.3   mm  or   0.25  ins"
7720 IF (FR>=144)  AND (FR<=148) THEN PRINT TAB(49)" 4.765 mm  or   0.187 ins"
7730 IF (FR>=222)  AND (FR<=225) THEN PRINT TAB(49)" 4.765 mm  or   0.187 ins"
7740 IF (FR>=420)  AND (FR<=450) THEN PRINT TAB(49)" 3.175 mm  or   0.187 ins"
7750 IF (FR>=902)  AND (FR<=928) THEN PRINT TAB(49)" 3.175 mm  or   0.187 ins"
7760 IF (FR>=1240) AND (FR<=1300)THEN PRINT TAB(49)" 3.175 mm  or   0.125 ins"
7770 IF (FR>=2300) AND (FR<=2310)THEN PRINT TAB(49)" 3.175 mm  or   0.125 ins"
7780 GOTO 7800
7790 PRINT
7800 PRINT"      ELEMENT SPACING: make it convenient for construction"
7810 PRINT
7820 PRINT"     Adjustment of the T-Match with a 4:1 balun is simple - just adjust the"
7830 PRINT"position of the shorts on the Arms until you get an acceptable SWR.  For the"
7840 PRINT"lowest SWR it may be necessary to change the length of the Driven Element."
7850 PRINT"After changing the driven element readjust for the lowest SWR."
7860 PRINT
7870 COLOR 15, 1
7880 LOCATE 24,20
7890 INPUT"Do you wish to return to Main Menu  <Y/Q>  ";TM$
7900 IF TM$ = "Y" OR TM$ = "y" THEN CLS:COLOR 14, 1:RUN 780
7910 IF TM$ = "Q" OR TM$ = "q" THEN 4310
7920 '
7930 '------------------------------BALUN--------------------------------------
7940 COLOR 14, 1
7950 CLS:PRINT
7960 PRINT"                         ***** COAX CABLE BALUN *****"
7970 PRINT
7980 PRINT"      Coaxial cable is frequently used to construct 1:1 and/or 4:1 baluns to"
7990 PRINT"feed power to balanced antenna terminals from unbalanced coax."
8000 PRINT
8010 PRINT"      This Section contains a method for calculating an electrical half-wave"
8020 PRINT"of coax for use as the common 4:1 balun (200 ohms to 50 ohms) for a folded"
8025 PRINT"dipole or balanced dipole (with T-Match).  Included is a table listing popular"
8030 PRINT"coaxial cables with velocity factors."
8040 PRINT
8050 PRINT"     A 1:1 balun can be used to feed a balanced dipole for this antenna"
8060 PRINT"design.  Such a balun can be constructed with ferrite toroidal cores (beads),"
8070 PRINT"with the proper frequency rating, and 50 ohm coaxial cable.   See these"
8080 PRINT"references on baluns:
8082 PRINT
8084 PRINT"                      QST, June 1991,      Page 30
8086 PRINT"                      QST, September 1993, Page 77
8090 PRINT"                      CQ,  January 1993,   Page 30
8100 PRINT
8110 PRINT"     There are several sources for beads(cores) - see section in the program"
8120 PRINT"for SOURCES OF MATERIALS."
8130 COLOR 15,1
8140 LOCATE 24,15
8150 INPUT"Do you wish to check and/or test a balun   <Y/N>  ";R$
8160 IF R$ = "Y" OR R$ = "y" THEN 8850
8170 IF R$ = "N" OR R$ = "n" THEN 8180
8180 COLOR 15, 1
8190 LOCATE 24,8
8200 INPUT"Do you wish to calculate dimensions for a 4:1 coax balun <Y/N/Q>"; B$
8210 IF B$ = "Y" OR B$ ="y" THEN CLS:COLOR 14, 1:GOSUB 8250
8220 CLOSE  O
8230 IF B$ = "N" OR B$ = "n" THEN CLS:COLOR 14, 1:CLOSE O :RUN 770    'Main Menu
8240 IF B$ = "Q" OR B$ = "q" THEN 4310
8250 CLS
8260 COLOR 14,1
8270 PRINT:PRINT
8280 INPUT"              WHAT IS THE BALUN'S CENTER FREQUENCY in MHz "; F
8290 W = 299.792458# / F                'Wavelength in Metres
8300 PRINT
8310 PRINT "     THE VELOCITY FACTORS OF SOME OF THE POPULAR VHF/UHF COAX CABLES ARE:"
8320 PRINT
8330 PRINT "         CABLE             DIELECTRIC               VEL     OHMS"
8340 PRINT "*****************************************************************************"
8350 COLOR 15, 1
8360 PRINT "     (You may wish to substitute your favorite cables here)"
8370 COLOR 14, 1
8380 PRINT "          RG-8/U             POLY                  .66      52"
8390 PRINT "          RG-8/U FOAM        FOAM POLY             .80      50"
8400 PRINT "          RG-9/U             POLY                  .66      51"
8410 PRINT "          RG-11/U            POLY                  .66      75"
8420 PRINT "          RG-58/U            POLY                  .66      53.5"
8430 PRINT "          RG-58/U FOAM       FOAM POLY             .79      50"
8440 PRINT "          RG-59/U            POLY                  .66      73"
8450 PRINT "          RG-59/U FOAM       FOAM POLY             .79      75"
8460 PRINT "          RG-62/U FOAM       FOAM POLY             .79      95"
8470 PRINT "          RG-141/U           TEFLON                .70      50"
8480 PRINT "          RG-142/U           TEFLON                .70      50"
8490 PRINT "          RG-174/U           POLY                  .66      50"
8500 PRINT "          RG-213/U           POLY                  .66      50"
8510 PRINT
8520 LOCATE 23, 6
8530 INPUT "Which coax do you plan to use  "; T$
8540 LOCATE 25, 6
8550 INPUT "What is the velocity factor of the coax to be used "; VP
8560 HWC = W / 2 * VP * 1000                      'half-wave in millimeters
8570 HWI = W / 2 * VP * 39.37                     'half-wave in inches
8580 CLS
8590 PRINT:PRINT
8600 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
8610 PRINT:PRINT
8620 PRINT"                   ***** 4:1 COAXIAL CABLE BALUN *****"
8630 PRINT : PRINT
8640 PRINT"               The frequency selected is:               "; F; " Mhz"
8650 PRINT
8660 PRINT"               The coax you selected is:                 "; T$
8670 PRINT
8680 PRINT"               The velocity factor of the coax selected is:"; VP
8690 PRINT
8700 PRINT"               The physical length of a half-wave coaxial (4:1)"
8710 PRINT
8720 PRINT"                    Balun is:"; INT(HWC);:PRINT" mm  or  ";INT(HWI);:PRINT" ins"
8730 PRINT:PRINT
8740 PRINT"  (NOTE: The PHYSICAL LENGTH is for the shield. Keep the center conductor"
8750 PRINT"         as short as possible.  Keep the insulation long enough for high"
8760 PRINT"         power.  Example: for 432 Mhz use a 5 mm or .197 ins length of"
8770 PRINT"         insulation.)"
8780 PRINT
8790 COLOR 15, 9
8800 INPUT "                 Do you wish to try another type coax  <Y/N/Q> "; CO$
8810 IF CO$ = "Y" OR CO$ = "y" THEN COLOR 14, 1: CLS : GOTO 8250
8820 CLOSE  O
8830 IF CO$ = "N" OR CO$ = "n" THEN CLS:COLOR 14, 1:RUN 770   'Return to Main Menu
8840 IF CO$ = "Q" OR CO$ = "q" THEN 4310            'Stop the program
8850 CLS
8860 COLOR 14,1
8870 PRINT
8880 PRINT"                  ***** BALUN CHECKING PROCEDURE *****
8890 PRINT
8900 PRINT"     To make or check a 4:1 balun when the velocity may be unknown use a "
8910 PRINT".7 factor and cut the coax longer than the formula indicates for the shield."
8920 PRINT"Cut the leads as short as possible but to a useable length, short them"
8930 PRINT"together on one end.  On the other end connect the leads together to form"
8940 '
8950 PRINT"a small loop.  Use a grid-dip oscillator (GDO) with minimum coupling to the"
8960 PRINT"loop and tune for a sharp dip.  Adjust the GDO while listening for the GDO"
8970 PRINT"on your receiver.  Reduce the length of the coax in small increments until the"
8980 PRINT"frequency on the receiver approaches the desired frequency.  With each "
8990 PRINT"adjustment keep the leads just long enough to make the connections."
9000 PRINT
9010 PRINT"     You may also use the above method to check any balun which was made"
9020 PRINT"using this program.  The velocity factor in some coaxial cable has been"
9030 PRINT"found to vary from manufacturers specifications so it is a good idea to"
9040 PRINT"check your balun to make sure it can do the job."
9050 PRINT:PRINT
9060 PRINT"                KEEP THE LEADS SHORT AND USE MINIMUM COUPLING"
9070 GOTO 8170
9080 '
9090 '----------------------------LAMBDA---------------------------------------
9100 CLS
9110 COLOR 14, 1
9120 PRINT
9130 PRINT:PRINT:PRINT                              'FOLLOWING FOR LAMBDA
9140 F1=299792.458#/FA                              '50 MHZ
9150 F2=299792.458#/FB                              '144 MHZ
9160 F3=299792.458#/FC                              '222 MHZ
9170 F4=299792.458#/FD                              '432 MHZ
9180 F5=299792.458#/FE                              '903 MHZ
9190 F6=299792.458#/FF                              '1296 MHZ
9200 F7=299792.458#/FG                              '2304 MHZ
9210 PRINT:PRINT
9220 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time:  ";TIME$
9230 PRINT:PRINT
9240 PRINT"                     ***** LAMBDA (Wavelength) *****"
9250 PRINT
9260 PRINT"                   For VHF/UHF & Microwave Frequencies
9270 PRINT
9280 PRINT"                  Lambda (mm) = 299792.458# / Freq (Mhz)
9290 PRINT
9300 PRINT
9310 PRINT"                  FREQ                MM             INCHES
9320 PRINT"             ------------------------------------------------
9330 PRINT
9340 PRINT"                  50 Mhz          ";USING X$; F1;:PRINT            "          ";USING Y$;F1/J1
9350 PRINT"                 144 Mhz          ";USING X$; F2;:PRINT            "          ";USING Y$;F2/J1
9360 PRINT"                 222 Mhz          ";USING X$; F3;:PRINT            "          ";USING Y$;F3/J1
9370 PRINT"                 432 Mhz          ";USING X$; F4;:PRINT            "          ";USING Y$;F4/J1
9380 PRINT"                 903 Mhz          ";USING X$; F5;:PRINT            "          ";USING Y$;F5/J1
9390 PRINT"                1296 Mhz          ";USING X$; F6;:PRINT            "          ";USING Y$;F6/J1
9400 PRINT"                2304 Mhz          ";USING X$; F7;:PRINT            "          ";USING Y$;F7/J1
9410 PRINT:PRINT
9420 COLOR 15, 1
9430 INPUT"                Do you wish to return to Main Menu <Y/Q>  ";AB$
9440 IF AB$ = "Y" OR AB$ = "y" THEN CLS:COLOR 14, 1:RUN 770
9450 IF AB$ = "Q" OR AB$ = "q" THEN 4310
9460 PRINT
9470 CLS:COLOR 14,1
9480 PRINT
9490 PRINT"      Program - ANTDL6WU.BAS      Date: "; DATE$;:PRINT "      Time:  ";TIME$
9500 PRINT
9510 PRINT"              ***** A FEW SOURCES OF MATERIALS FOR ANTENNAS *****
9520 PRINT
9530 PRINT"       COMPANY                        MATERIALS                 TEL#
9540 PRINT"-----------------------------------------------------------------------------
9550 PRINT
9560 '
9570 '
9580 '
9590 PRINT"  AMIDON ASSOCIATES, INC.          Ferrite beads             310-763-5770
9600 PRINT"  P. O. Box 956
9610 PRINT"  Torrance, CA  90508
9620 PRINT
9630 PRINT"  ANTENNACO                      Antennas & Hardware         603-673-4347
9640 PRINT"  P.O. Box 218                                               (ask for Joe)
9650 PRINT"  Milford, NH 03055
9660 PRINT
9670 PRINT"  ANTENNAS ETC.                    Ferrite beads             508-475-7831
9680 PRINT"  P. O. Box 4215                                             FAX 508-474-8949
9690 PRINT"  Andover, MA 01810
9700 PRINT
9710 PRINT"  AMERICAN RADIO RELAY LEAGUE      Antenna Book              203-666-1541
9720 PRINT"  225 Main Street                                            FAX 203-665-7531
9730 PRINT"  Newington, CT 06111
9740 PRINT
9750 '
9760 '
9770 '
9780 COLOR 15,1
9790 LOCATE 24,22
9800 INPUT"Do you wish to see more (Y/Q/Menu)";SS$
9810 IF SS$="Y" OR SS$="y" THEN GOTO 9840
9820 IF SS$="Q" OR SS$="q" THEN GOTO 4310
9830 IF SS$="M" OR SS$="m" THEN RUN 770
9840 PRINT
9850 COLOR 14,1:CLS
9860 PRINT
9870 PRINT"      COMPANY                        MATERIAL                     TEL#
9880 PRINT"  -----------------------------------------------------------------------
9890 PRINT
9900 PRINT"  ELECTRONIC FASTENERS, INC        Retainer rings            617-890-7780
9910 PRINT"  305 Winter Street                 (Push Nuts)
9920 PRINT"  Waltham, MA 02154
9930 PRINT
9940 PRINT"  PALOMAR ENGINEERS                  Baluns                  619-747-3343
9950 PRINT"  P.O. Box 455                     Ferrite Beads & Cores
9960 PRINT"  Escondido, CA  92033
9970 PRINT
9980 PRINT"  RADIOKIT                         Ferrite beads             603-635-2235
9990 PRINT"  54 Hobbs Road                       hardware               (ask for Carl)
10000 PRINT"  Pelham, NH 03076
10010 PRINT
10020 PRINT"  RUTLAND ARRAYS                  Antenna Hardware           717-774-5298
10030 PRINT"  1703 Warren Street
10040 PRINT"  New Cumberland, PA 17070
10050 PRINT
10060 '
10070 '
10080 '
10090 COLOR 15,1
10100 LOCATE 24,22
10110 INPUT"Do you wish to see more (Y/Q/Menu)";SS$
10120 IF SS$="Y" OR SS$="y" THEN GOTO 10150
10130 IF SS$="Q" OR SS$="q" THEN GOTO 4310
10140 IF SS$="M" OR SS$="m" THEN RUN 770
10150 COLOR 14,1:CLS
10160 PRINT
10170 PRINT"      COMPANY                        MATERIAL                    TEL#
10180 PRINT"  -----------------------------------------------------------------------
10190 PRINT"  LOCAL HAMS                 Assistance and/or Advice           Local
10200 PRINT
10210 PRINT"  LOCAL HARDWARE STORE       Hardware & Miscellaneous           Local
10220 PRINT
10230 PRINT"  LOCAL JUNK YARD            Metals                             Local
10240 PRINT
10250 PRINT"  LOCAL RADIO CLUB           Assistance and/or Advice           Local
10260 PRINT
10270 PRINT"  LOCAL RADIO SHACK          Antenna Hardware                   Local
10280 LOCATE 18,28
10290 '
10300 '
10310 '
10320 '
10330 COLOR 15,1
10340 LOCATE 24,22
10350 INPUT"Do you wish to return to Main Menu (Y/Q) ";AZ$
10360 IF AZ$ = "Y" OR  AZ$ = "y" THEN CLS:COLOR 14, 1:RUN 770
10370 IF AZ$ = "Q" OR  AZ$ = "q" THEN GOTO 4310
10380 END
10390 'The name of this program is ANTDL6WU.BAS, dated 1 October 1993
