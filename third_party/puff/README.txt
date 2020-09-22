==================================================================
  PUFF - Computer Aided Design for Microwave Integrated Circuits
==================================================================
Now available on Linux under GPLv3!            (pa3fwm, 2010-1-27)
==================================================================


History
-------
Puff originally was an old MS-DOS program for analysing microwave
circuits, developed in the 1980s and 1990s at CalTech, by Scott
W. Wedge, Richard Compton and David Rutledge, and later enhanced
by Andreas Gerstlauer.
It was distributed for a very modest fee, together with an instruction
book and Pascal source code.
The latter made it possible to compile it also on Linux, albeit with
some modifications and additional code to handle the graphics;
I (Pieter-Tjerk de Boer) made instructions for this available in late
2000.
In early 2010, Leland C. Scott got in touch with the original authors,
who then agreed to make the code freely available under the GPLv3
license. Also, we got permission to distribute the original manual in
pdf form.
This opens up the possibility to distribute a complete Linux version
on the internet for free, and encourages further development of the
program.


Building
--------
Compiling the program from source should be trivial on any i386 or
amd64 Linux system on which the Free Pascal compiler is installed,
by simply typing 'make'.
This procedure may also work on other architectures and perhaps
other unix-like operating systems; reports on this would be much
appreciated!


Usage & getting started
-----------------------
The program and its user interface are firmly rooted in 1980s personal
computer technology: no mouse, few colours, graphics that use a fixed
text font size (in fact, originally the entire screen resolution was
fixed). Without mouse control and menus, some learning is needed to
use the program, but once one gets used to it, it works quite quickly.

For those who don't have the patience for the complete 60 page manual
(included in pdf format), here's a quick tutorial for analyzing a
simple (non-microwave) low-pass filter:

First start puff, e.g. by typing ./puff in the directory where you 
compiled puff, and press any key except escape to actually enter the
program.
Next, follow the following steps:

what to type:             what it does:

 [F3]                     go to the parts window
 lumped 10 [alt-M] H      first component is a coil of 10 microhenry
 [down arrow]             go to next component
 lumped 100 pF            a capacitor of 100 pF
 [F1]                     go to the layout window
 b                        choose component b, i.e., our 100 pF cap
 [down arrow]             place one cap
 =                        connect to ground
 [up arrow]               walk back over the cap
 1                        connect to in/output 1
 a                        choose component a, i.e. our coil
 [right arrow]            place the coil
 2                        connect to in/output 2
 b                        choose component b again
 [down arrow]             place another copy of this cap
 =                        ground it
 [F2]                     go to the analysis window
 p                        make a plot

You now have a plot of S-parameters that are listed in the top-left
window (S11 and S21 by default, i.e., input return loss on port 1
and transfer function from port 1 to port 2).
You can change the frequency and dB range by using the up and down
arrows to go the axis start and end points and typing different
values there; for the present network, a range from 0 to 10 MHz makes
much more sense than the default. Type 'p' to replot.

Some more hints:
- F1/F2/F3/F4 choose the window to activate;
- F10 displays help for the current window;
- in the F1 window, shift + arrow key erases a component.
- in the F2 window, PageUp and PageDown move a cursor over the
  plot to look inspect the exact values at different frequencies.
- use the 'esc' key to leave the program.


More information
----------------

http://wwwhome.cs.utwente.nl/~ptdeboer/ham/puff.html
http://www.its.caltech.edu/~mmic/puff.html
http://www.gerstlauer.de/puff/


