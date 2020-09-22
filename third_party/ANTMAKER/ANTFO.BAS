200 'The name of this program is "ANTFO.BAS", dated 15 NOV 93
210 'Author  IS  & WA2TIF.
215 'BASED UPON THE DL6WU PROGRAM BY K1DPP, W1JOT, AND WA2TIF
220 'The last update was DEC 1 1993.(Revision 2)
230 '
250 '
270 '
280 'ANTK1FO IS BASED UPON THE DESIGN BY STEVE POWLISHEN, K1FO AS PUBLISHED IN
290 'THE ARRL HANDBOOK OF 1992
310 'THIS PROGRAM WAS DERIVED FROM THE ANTDL6WU PROGRAM DEVELOPED BY WA2TIF,
320 'W1JOT, AND K1DPP
400 ' This program is freely available for NON commercial use."
410 'Please forward copy of all updates and corrections to WA2TIF
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
520 PRINT "       *          for  144, 222, 432,...?                              *"
530 PRINT "       *                                                               *"
540 PRINT "       *     BASED ON THE WORK OF STEVE POWLISHEN,K1FO as published
550 PRINT "       *    THE ARRL HANDBOOK 1992. "
600 PRINT "       *     For best results use 3/16 ins elements from 144 Mhz.      *"
610 PRINT "       *      thru 432 Mhz.  Use 1/8 ins for 902 and above.  The       *"
620 PRINT "       *      program  will NOT give accurate results for signifacant  *"
630 PRINT "       *      departures from these values.                            *"
640 PRINT "       *                                                               *"
650 PRINT "       *       Maximum number of elements (REF,DE,DIR) is 40           *"
660 PRINT "       *       144  MAX ELEMENTS - 19    222  MAX ELEMENTS - 22        *"
670 PRINT "       *       THE MINIMUM NUMBER OF ELEMENTS IS 10                    *"
680 PRINT "       *                                                               *"
690 PRINT "       *                    Dated 8 NOVEMBER,1993                       *"
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
1000 PRINT:COLOR 14, 1
1020 PRINT"                     ***** PROGRAM'S MAIN MENU *****"
1030 PRINT
1040 PRINT
1050 PRINT "     This program can:"
1060 PRINT
1070 PRINT "          1 - Design a Yagi Antenna for VHF/UHF & Microwave Frequencies "
1080 PRINT
1110 PRINT "          2 - Design Coaxial Cable Baluns"
1120 PRINT
1130 PRINT "          3 - Design a T - Match"
1140 PRINT
1150 PRINT "          4 - Provide an Antenna check-out procedure"
1160 PRINT
1170 PRINT "          5 - Provide Lambda for VHF/UHF/Microwave Frequencies
1180 PRINT
1190 PRINT "          6 - Provide sources for materials
1200 PRINT
1210 PRINT "          7 - END THE PROGRAM
1220 PRINT
1230 COLOR 15, 1
1240 PRINT
1250 INPUT "           Which one do you wish to try   <1,2,3,4,5,6, or 7>  ";T$
1260 IF T$ = "1" THEN GOTO 1340                           'Antenna
1280 IF T$ = "2" THEN GOTO 7930                           'Balun
1290 IF T$ = "3" THEN GOTO 7190                           'T - Match
1300 IF T$ = "4" THEN GOTO 5960                           'Check-out procedure
1310 IF T$ = "5" THEN GOTO 9090                           'Lambda calculations
1320 IF T$ = "6" THEN GOTO 9470                           'Materials
1330 IF T$ = "7" THEN GOTO 4310                           'End the program
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
1450 IF N>40 THEN GOTO 5040
1452 IF F >143 AND F< 148 AND N> 19 THEN GOTO 5040
1454 IF F >219 AND F< 238 AND N> 22 THEN GOTO 5040
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
2160 IF Z$ = "Y" OR Z$ = "y" GOTO 2182
2170 IF Z$ = "N" OR Z$ = "n" THEN CLS:RUN 770
2180 GOTO 1820
2182 '--------------- GET ELEMENT SPACING DATA ---------------------------------
2185 GOTO 6290
2190 '-----------------------CALCULATE BOOM LENGTH------------------------------
2200 GOSUB 4710
2210 TL=PG*W*1000
2215 S=1296/F
2220 FOR X=1 TO N-1
2230 DS(X)=SP(X)*S
2240 NEXT X
2320 COLOR 14,1
2330 '----------------------SELECT ELEMENT MATERIAL SIZE-----------------------
2340 '
2350 OPEN "I", #1, "CURVE-36.DAT"           'Data for Directors - only
2360 FOR X = 1 TO 38                        'Number of Directors available
2370 INPUT #1, O$
2380 TS(X) = VAL(O$)
2390 NEXT X
2400 CLOSE 1
2410 CLS:LOCATE 5,20
2420 PRINT"***** PLEASE WAIT FOR CALCULATIONS *****"
2430 RO1 = .0034313
2440 K1 = 1 / RO1: K2 = 1 / RO2
2450 FOR X = 1 TO 36                        'Number of Directors available
2460 FR1(X) = (1 - (10.7575 * (LOG(K1) / LOG(10)) - 8) ^ -1) / (2 * TS(X))
2470 R1(X) = (215.15 * (LOG(K1) / LOG(10)) - 160) * (1 / FR1(X) - FR1(X))
2480 R2(X) = R1(X)
2490 A(X) = R1(X) / (215.15 * (LOG(K2) / LOG(10)) - 160)
2500 FR2(X) = ((A(X) ^ 2 + 4) ^ .5 - A(X)) / 2
2510 TS(X) = (1 - (10.7575 * (LOG(K2) / LOG(10)) - 8) ^ -1) / (2 * FR2(X))
2520 NEXT X
2530 '
2540 '---------------------CALCULATE ELEMENT LENGTHS---------------------------
2550 FOR X = 3 TO 40
2560 IF I = 0 THEN LE(X) = W * TS(X - 2) * 1000+LC ELSE LE(X) = (W * TS(X - 2) * 1000) + BC+LC                                          'Insulated from boom
2570 NEXT X
2580 IF F= > 431 THEN L=.49282   ' -- reflector length---
2582 IF F> 219 AND F< 238 THEN L=.5016001
2584 IF F> 143 AND F< 148 THEN L=.4985
2590 GOSUB 5560
2600 LE(1) = L * W * 1000+LC
2610 IF I = 1 THEN LE(1) = LE(1) + BC                'Not insulated from boom
2620 IF I = 2 THEN LE(1) = LE(1) + BC                'Insulated thru boom
2630 IF F> 431 THEN L=.481
2632 IF F> 219 AND F<238 THEN L=.479
2634 IF F> 143 AND F<148 THEN L=.459
2640 GOSUB 5560
2650 LE(2) = L * W * 1000+LC+BC
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
2840 PRINT #1,"        Program - ANTK1FO.BAS      Date: "; DATE$;:PRINT #1,"     Time: ";TIME$:
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
3005 PRINT #1, "      FRONT TO BACK RATIO               ";USING D$; FB;:PRINT #1 , " DBD"
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
3130 PRINT #1, "      HORIZONTAL BEAM WIDTH", TAB(40); BE; "     degrees"
3140 PRINT #1, "      VERTICAL BEAM WIDTH", TAB(40); BH; "     degrees"
3150 XX=SE*W
3160 PRINT #1, "      HORIZONTAL STACKING DISTANCE   "; USING X$; XX*1000; : GOSUB 4440: PRINT #1, "   mm      = "; USING Y$;(YY*12) + (ZZ);: PRINT #1, " ins"
3170 '
3180 XX=SH*W
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
3410 PRINT #1, " dipole t-match "; : PRINT #1, TAB(30); USING X$; LE(2); : PRINT #1, TAB(56); USING Y$; (LE(2) * J2)
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
3850 PRINT #1, "   REFLECTOR"; TAB(19); "to"; TAB(25); "DRIVEN ELEMENT"; : PRINT #1, TAB(42); USING X$; DS(1); : PRINT #1, TAB(58); USING Y$; (DS(1) * J2)
3860 PRINT #1, " driven element "; TAB(19); "to"; TAB(25); "DIR 1"; : PRINT #1, TAB(42); USING X$; DS(2); : PRINT #1, TAB(58); USING Y$; (DS(2) * J2)
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
4070 Z = 30: PRINT #1, "   BOOM TO REFLECTOR "; : PRINT #1, TAB(41); USING X$; Z; : PRINT #1, TAB(62); USING Y$; (Z * J2)
4080 K = DS(1) + Z: PRINT #1, "   TO driven element"; : PRINT #1, TAB(41); USING X$; K; : PRINT #1, TAB(62); USING Y$; (K * J2)
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
4710 IF N=10 THEN PG=1.8:GD=11.4:LC=0:FB=17:BE=39:BH=42:SE=1.495:SH=1.392
4720 IF N=11 THEN PG=2.2:GD=12!:LC=0:FB=19:BE=36:BH=40:SE=1.612:SH=1.465
4730 IF N=12 THEN PG=2.5:GD=12.5:LC=0:FB=23:BE=34:BH=37:SE=1.715:SH=1.583
4740 IF N=13 THEN PG=2.9:GD=13!:LC=0:FB=20:BE=32:BH=35:SE=1.832:SH=1.671
4750 IF N=14 THEN PG=3.2:GD=13.4:LC=0:FB=18:BE=31:BH=33:SE=1.876:SH=1.758
4760 IF N=15 THEN PG=3.6:GD=13.8:LC=0:FB=20:BE=30:BH=32:SE=1.934:SH=1.817
4770 IF N=16 THEN PG=4!:GD=14.2:LC=0:FB=24:BE=29:BH=30:SE=2.008:SH=1.934
4780 IF N=17 THEN PG=4.4:GD=14.5:LC=0:FB=23:BE=28:BH=29:SE=2.066:SH=1.993
4790 IF N=18 THEN PG=4.8:GD=14.8:LC=0:FB=21:BE=27:BH=28.5:SE=2.14:SH=2.037
4800 IF N=19 THEN PG=5.2:GD=15!:LC=0:FB=22:BE=26:BH=27.5:SE=2.227:SH=2.11
4810 IF N=20 THEN PG=5.3:GD=15.3:LC=0:FB=21:BE=25.5:BH=27:SE=2.271:SH=2.161
4820 IF N=21 THEN PG=5.7:GD=15.55:LC=0:FB=20:BE=25:BH=26.5:SE=2.308:SH=2.198
4830 IF N=22 THEN PG=6.1:GD=15.8:LC=0:FB=22:BE=24:BH=26:SE=2.381:SH=2.271
4840 IF N=23 THEN PG=6.5:GD=16.05:LC=0:FB=27:BE=23.5:BH=25:SE=2.454:SH=2.344
4850 IF N=24 THEN PG=6.9:GD=16.25:LC=1!:FB=29:BE=23:BH=24:SE=2.527:SH=2.418
4860 IF N=25 THEN PG=7.3:GD=16.45:LC=1!:FB=23:BE=22.5:BH=23.5:SE=2.601:SH=2.491
4870 IF N=26 THEN PG=7.7:GD=16.7:LC=1!:FB=22:BE=22:BH=23:SE=2.674:SH=2.564
4880 IF N=27 THEN PG=8.100001:GD=16.9:LC=1!:FB=22:BE=21.5:BH=22.5:SE=2.747:SH=2.637
4890 IF N=28 THEN PG=8.5:GD=17.1:LC=1:FB=25:BE=21:BH=22:SE=2.821:SH=2.747
4900 IF N=29 THEN PG=8.8:GD=17.3:LC=2:FB=25:BE=20.5:BH=21.5:SE=2.894:SH=2.821
4910 IF N=30 THEN PG=9.3:GD=17.45:LC=2:FB=26:BE=20:BH=21:SE=2.93:SH=2.857
4920 IF N=31 THEN PG=9.7:GD=17.8:LC=2:FB=24:BE=19.6:BH=20.5:SE=2.967:SH=2.894
4930 IF N=32 THEN PG=10.2:GD=17.7:LC=2:FB=23:BE=19.3:BH=20:SE=3.004:SH=2.93
4940 IF N=33 THEN PG=10.6:GD=19.9:LC=2:FB=23:BE=19:BH=19.5:SE=3.04:SH=2.967
4950 IF N=34 THEN PG=11!:GD=17.95:LC=2:FB=25:BE=18.8:BH=19.2:SE=3.077:SH=3.004
4960 IF N= 35 THEN PG=11.4:GD=18.1:DE=25:FB=27:BE=18.5:BH=19!:SE=3.114:SH=3.04
4970 IF N=36 THEN PG=11.8:GD=18.2:LC=2:FB=27:BE=18.3:BH=18.8:SE=3.151:SH=3.077
4980 IF N=37 THEN PG=12.2:GD=18.3:LC=2:FB=26:BE=18.1:BH=18.6:SE=3.188:SH=3.114
4990 IF N=38 THEN PG=12.7:GD=18.4:LC=2:FB=25:BE=18.9:BH=18.4:SE=3.225:SH=3.151
5000 IF N=39 THEN PG=13.1:GD=18.5:LC=3:FB=25:BE=18.7:BH=18.2:SE=3.262:SH=3.188
5010 IF N=40 THEN PG=13.5:GD=18.7:LC=3:FB=26:BE=17.5:BH=18:SE=3.299:SH=3.225
5020 RETURN
5030 '-----------------------MAXIMUM NUMBER OF ELEMENTS--------------------------
5040 CLS:COLOR 14,1
5050 LOCATE 5, 25
5060 COLOR 31:PRINT"***** TO MANY ELEMENTS *****"
5070 COLOR 14,1
5080 LOCATE 10, 20
5090 PRINT"          THE TOTAL NUMBER OF ELEMENTS THIS PROGRAM CAN HANDLE IS 40
5100 PRINT:PRINT
5105 PRINT "       MAXIMUM ELEMENTS ON 144 MHZ IS 19       MAXIMUM ON 222 MHZ IS 22"
5107 PRINT:PRINT
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
5510 PRINT #1, " driven element "; : PRINT #1, TAB(33); USING X$; (LE(2) - (BD + 2 * T)) / 2; : PRINT #1, TAB(58); USING Y$; ((LE(2) - (BD + 2 * T)) / 2) * J2
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
5990 PRINT"      Program - ANTFO.BAS         Date: "; DATE$;:PRINT "      Time: ";TIME$
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
6190 PRINT"db improvement in K1FO's figures.
6200 PRINT
6210 COLOR 15, 1
6220 INPUT "            Do you wish to return to the Main Menu   <Y/Q>  ";P$
6230 PRINT
6240 IF P$ = "Y" OR P$ = "y" THEN CLS:COLOR 14, 1:RUN 770
6250 IF P$ = "Q" OR P$ = "q" THEN GOTO 4310
6260 '
6270 '-------------------END OF ORIGINAL DL6WU PROGRAM-------------------------
6280 '
6290 ' -----------------------LOAD ELEMENT SPACING DATA-------------------------
6300 IF F>143 AND F<148 THEN GOTO 6800
6310 IF F>219 AND F<238 THEN GOTO 6700
6320 GOTO 6500
6500 '-------------------  ELEMENT SPACING DATA ------------------------------
6510 '--------------------------- 432 DATA -----------------------------------
6520 DATA 34.670, 14.000, 26.000, 36.000, 44.670, 52.000, 58.67, 64.000, 68.670
6530 DATA 72.670, 76.000, 79.000, 81.000, 83.670, 85.330, 87.00, 88.000, 89.330
6540 DATA 90.330, 91.330, 91.670, 92.670, 92.670, 93.670, 93.67, 94.000, 94.330
6550 DATA 94.670, 95.000, 95.000, 95.000, 95.330, 95.330, 95.33, 95.670, 95.670
6560 DATA 95.670, 95.670, 96.330, 96.333
6570 FOR X=1 TO 40
6580 READ SP(X)
6590 NEXT X
6600 GOTO 2190
6700 '--------------------222 SPACING DATA -------------------------------------
6710 OPEN "I",#2, "CURVE-22.DAT"
6720 FOR X=1 TO 21
6730 INPUT #2,O$
6740 SP(X)=VAL(O$)
6750 NEXT X
6760 CLOSE 2
6770 GOTO 2190
6790 ' ----------------------- 144 SPACING DATA---------------------------------
6800 OPEN "I" ,#3, "CURVE-14.DAT"
6810 FOR X=1 TO 17
6820 INPUT #3,O$
6830 SP(X)=VAL(O$)
6840 NEXT X
6850 CLOSE 3
6860 GOTO 2190
7190 '---------------------------T-MATCH---------------------------------------
7200 COLOR 14, 1
7210 CLS:PRINT
7220 PRINT"      Program - ANTK1FO.BAS      Date: "; DATE$;:PRINT "      Time: ";TIME$
7230 PRINT
7240 PRINT"                          ***** T - MATCH *****
7250 PRINT
7260 PRINT"     The T-Match for this design is described in the ARRL HANDBOOK,"
7270 PRINT"1992 edition, chapter 33 pages 21-29. "
7280 INPUT "        Do you wish to return to Main Menu <Y/Q> ";SS$
7290 IF SS$ = "Y" OR SS$= "y"THEN CLS:COLOR 14, 1:RUN 770
7300 IF SS$ = "N" OR SS$= "n" THEN GOTO 4310
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
9220 PRINT"      Program - ANTF0.BAS         Date: "; DATE$;:PRINT "      Time:  ";TIME$
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
9710 PRINT"  AMERICAN RADIO RELAY LEAGUE  handbook, antenna handbook    203-666-1541
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
10330 COLOR 15,1
10340 LOCATE 24,22
10350 INPUT"Do you wish to return to Main Menu (Y/Q) ";AZ$
10360 IF AZ$ = "Y" OR  AZ$ = "y" THEN CLS:COLOR 14, 1:RUN 770
10370 IF AZ$ = "Q" OR  AZ$ = "q" THEN GOTO 4310
10380 END
10390 'The name of this program is ANTFO.BAS, dated 8 NOVEMBER ,1993
11600 -1700
