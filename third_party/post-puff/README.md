PUFF is a CAE Tool for RF circuits. It was developed at Caltech [1].
It was originally written in Turbo-Pascal and  was shipped with a manual and the 
sourcecode for a moderate fee. Now it is available under the GPLv3 license and 
Pieter-Tjerk de Boer ported PUFF  to Linux [2]. He use the Free Pascal Compiler 
and rewritten code for the graphic output to use X11.

PUFF is very fast and easy to use, but there is one disadvantage:
The progran didn't calculate the stability factor, "K". Post-Puff reads the PUFF 
file and calculate K and D.

Post-Puff was originally written in Turbo-C and used DOS.  After Peter has done the 
porting to Linux, I ported the main code to Linux too, using GTK and cairo for the GUI.

[1] http://mmic.caltech.edu/puff.html
[2] http://wwwhome.cs.utwente.nl/~ptdeboer/ham/puff/
