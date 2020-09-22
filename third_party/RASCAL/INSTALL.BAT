@Echo off
Echo                 Welcome to R A S C A L installation!
Echo.
Echo   Please change drive to floppy disk by typing "b:" and
Echo     then type "install C:\RASCAL" or any other directory.
Echo.
Echo  RASCAL is to be installed in %1
Echo.
Pause
if exist %1 goto next
mkdir %1
:next
rasexe.exe %1
Echo  Do you want to install source codes?  Press Ctrl-C to stop.
Pause
mkdir %1\source
rassor.exe %1\source
Echo    Installation complete!
Echo on

