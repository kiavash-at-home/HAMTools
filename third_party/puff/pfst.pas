{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pfst;

(*******************************************************************

	Unit PFST;

	PUFF STARTUP CODE

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998 A.Gerstlauer

        Modifications for Linux compilation 2000-2007,2010,2018 Pieter-Tjerk de Boer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.


	Contains code for:
		System detect screen,
		Data structure initialization.



********************************************************************)

Interface

Uses
  Dos, 		{Unit found in Free Pascal RTL's}
  xgraph,	{Custom replacement unit for TUBO's "Crt" and "Graph" units}
  pfun1,	{Add other puff units}
  pfun2;

{*
   internal:
   Procedure Make_coord_and_parts_listO;
   Procedure Make_Titles;
   Function CommandLine;
   Procedure Init_Puff_Parameters;
*}
Procedure Puff_Start;
Procedure Screen_Init;
Procedure Screen_Plan;


Implementation


Procedure Make_coord_and_parts_listO;
{*
	Set up linked list of components for all
	parameters in the Plot window and
	Board Window.

	Called by Puff_Start.
*}
var
	tcompt : compt;
	i      : integer;
Begin
  {set-up coordinates linked list}
  for i:=1 to 10 do
    if i=1 then begin
       New (coord_start);
       tcompt:=coord_start;
    end
    else begin
       New (tcompt^.next_compt);
       tcompt^.next_compt^.prev_compt:=tcompt;
       tcompt:=tcompt^.next_compt;
  end;
  tcompt^.next_compt:=coord_start;
  coord_start^.prev_compt:=tcompt;

  {set-up parts linked list}
  for i:=1 to 18 do begin
    if i=1 then begin
      New (part_start);
      tcompt:=part_start;
      tcompt^.prev_compt:=nil;
      tcompt^.yp:=ymin[3];
    end
    else begin
      New (tcompt^.next_compt);
      tcompt^.next_compt^.prev_compt:=tcompt;
      tcompt:=tcompt^.next_compt;
      tcompt^.yp:=tcompt^.prev_compt^.yp+1;
    end;
    with tcompt^ do begin
      descript:=char(ord('a')+i-1)+' ';
      changed:=false;
      right:=false;
      parsed:=false;
      sweep_compt:=false;
      f_file:=nil;  {initialize for device and indef}
      s_file:=nil;
      s_ifile:=nil;
      used:=0;
      x_block:=2;
      if (i <= 9) then begin
      	xp:=xmin[3];
	xmaxl:=xmax[3]-xmin[3];
      end
      else begin
      	xp:=xmin[5];
	xmaxl:=xmax[5]-xmin[5];
      end;
    end; {with}
  end; {i}
  tcompt^.next_compt:=nil;

  {set-up board linked list beginning at board_start}
  for i:=1 to 6 do begin
    if i=1 then begin
      New (board_start);
      tcompt:=board_start;
      tcompt^.prev_compt:=nil;
    end
    else begin
      New (tcompt^.next_compt);
      tcompt^.next_compt^.prev_compt:=tcompt;
      tcompt:=tcompt^.next_compt;
    end;
         end; {i}
  tcompt^.next_compt:=nil;
end; {* Make_coord_and_parts_listsO*}


Procedure Make_Titles;
{*
	Set up titles for the three windows.
*}
var
	i : integer;

begin
  for i:=1 to 4 do begin   {was to 3}
    new (window_f[i]);
    new (command_f[i]);
    case i of
     1 : begin
           with window_f[1]^ do begin
             xp:=layout_position[1];
	     yp:=layout_position[2];
	     descript:=' F1 : LAYOUT '; {xp was 2}
           end;
           with command_f[1]^ do begin
	     descript:=' LAYOUT HELP ';
             xp:=1 + (xmax[4]+xmin[4]-Length(descript)) div 2;
	     {place header above board window}
	     yp:=ymin[4]-1;
           end;
         end;
     2 : begin
           with window_f[2]^ do begin
	     descript:=' F2 : PLOT ';{xp was 41}
             xp:=1 + (xmax[2]+xmin[2]-Length(descript)) div 2;
	     yp:=ymin[2]-1;
           end;
           with command_f[2]^ do begin
	     descript:=' PLOT HELP ';
             xp:=1 + (xmax[4]+xmin[4]-Length(descript)) div 2;
	     yp:=ymin[4]-1;
           end;
         end;
     3 : begin
           with window_f[3]^ do begin
	     descript:=' F3 : PARTS '; {xp was 2}
             xp:=1 + (xmax[3]+xmin[3]-Length(descript)) div 2;
	     yp:=ymin[3]-1;
           end;
           with command_f[3]^ do begin
	     descript:=' PARTS HELP ';
             xp:=1 + (xmax[4]+xmin[4]-Length(descript)) div 2;
	     {place header above board window}
	     yp:=ymin[4]-1;
           end;
         end;
     4 : begin
           with window_f[4]^ do begin
	     descript:=' F4 : BOARD ';  {xp was 2}
             xp:=1 + (xmax[4]+xmin[4]-Length(descript)) div 2;
	     yp:=ymin[4]-1;
           end;  { board values are drawn over the command box }
           with command_f[4]^ do begin
	     descript:=' BOARD HELP ';
             xp:=1 + (xmax[3]+xmin[3]-Length(descript)) div 2;
	     yp:=ymin[3]-1;
           end;  { board help window is drawn over parts window }
         end;
    end; {case}
  end; {for i}
end; {* Make_Titles *}


Function CommandLine : file_string;
{*
	Get information which might follow initial
	PUFF command eg. c> puff lowpass.
	Use -D to put in demo mode.
*}
var
  Buffer : file_string;
  i: integer;
Begin
  Buffer := ParamStr(1); {returns first command line parameter}
  if Pos('-D',buffer) > 0 then begin
      buffer:='';
      demo_mode:=true;
  end
  else
      demo_mode:=false;
  if Pos('-BW', buffer) > 0 then begin
    buffer:= ParamStr(2);
    blackwhite:= true;
    for i:= 1 to 4 do begin
      col_window[i]:= white;
      s_color[i]:= white;
    end;
  end else blackwhite:= FALSE;
  if (buffer='') then commandline:='setup'
                 else commandline:=buffer;
end; {* Commandline *}


Procedure Prep_to_Read_Board;
{*
	Preparation required before reading board
*}
Var
  i : integer;
Begin
  for i:=1 to 8 do begin
     s_board[i,1]:=' ';  {initialize board values}
     s_board[i,2]:=' ';  {initialize board unit prefixes}
  end;
  board_read:=false;
  for i:=1 to 12 do board[i]:=false;
end; {* Prep_to_Read_Board *}


Procedure Init_Puff_Parameters;
{*
	Initializes linked lists and windows.
	Set up to be called only after the board
	parameters have been read, but before the key!
	Set_Up_Board must be called sometime after
	this procedure when reading new graphics.
*}
Var
   i,ij    : integer;
   cspc    : spline_param;

Begin
  {* Initialize s-parameter linked lists *}
  for xpt:=0 to ptmax do begin
    if xpt=0 then begin
      new (spline_start);
      cspc:=spline_start;
    end
    else begin
      new (cspc^.next_c);
      cspc^.next_c^.prev_c:=cspc;
      cspc:=cspc^.next_c;
    end;
    for ij:=1 to max_params do
    if xpt=0 then begin
      new (plot_start[ij]);
      c_plot[ij]:=plot_start[ij];
    end
    else begin
      new (c_plot[ij]^.next_p);
      c_plot[ij]^.next_p^.prev_p:=c_plot[ij];
      c_plot[ij]:=c_plot[ij]^.next_p;
    end;
  end; {xpt}
  Make_Coord_and_Parts_ListO;
  compt1:=nil;
  Make_Titles;
  {* Prep to read key *}
  for i:=1 to 6 do s_key[i]:=' ';
  for i:=7 to 10 do s_key[i]:='';
  Set_Up_KeyO;   {pfun2}

  admit_chart:=false;     {begin with impedance Smith chart}
end; {* Init_Puff_Parameters *}


Procedure Puff_Start;
{*
	Start puff and print mode information.
*}
var


  memK   		: longint;
  i 			: integer;

  Ch			: char;

  	{***********************************************}
	Procedure Blank_Blue_Cursor;
	Begin
 	  GotoXY(64,22);	{Put cursor near bottom of screen}
 	  { on Linux we don't blank the cursor }
	end;

	{*****************************************************}

Begin  {* Puff_Start *}
  SetTextBuf(dev_file,big_text_buf); {2K buffer for device files}
  SetTextBuf(net_file,big_text_buf); {2K buffer for net_files }
  OrigMode := Lastmode;			{ Remember initial text mode }
  TextMode(co80);			{ Put in 80x25 Color Display Mode}
  puff_file:=Commandline;		{ Read input string for file name }
  memK:=2000*1024;   { MemAvail is not available with the fpc compiler }
  if puff_file = 'setup' then begin
    {* if setup.puf to be loaded then display information *}
    TextBackground(blue);  {make border does a ClrScr to black}
    ClrScr;
    (**** Make_Text_Border doesn't work here *****)
    TextCol(yellow);
    for i := 2 to 23 do begin     {* Draw Border for startup screen *}
       GotoXY(2,i);Write(#186);
       GotoXY(79,i);Write(#186);
    end;
    for i := 3 to 78 do begin
       GotoXY(i,2);Write(#205);
       GotoXY(i,24);Write(#205);
    end;
    GotoXY(2,2);Write(#201);
    GotoXY(79,2);Write(#187);
    GotoXY(2,24);Write(#200);
    GotoXY(79,24);Write(#188);
    GotoXY(17,24);
    Write(' Press Esc to abort, any other key to run Puff ');
    TextCol(white);
    GotoXY(32,4);          Write('PUFF, Version 20181104');
    Gotoxy(31,7);          Write('Copyright (C) 1991');
    GotoXY(15,8);
    Write('Scott W. Wedge, Richard Compton, David Rutledge');
    GotoXY(30,10);     Write('(C) 1997, 1998 Andreas Gerstlauer');
    GotoXY(8,13);
    Write('2010 - Code released under the GNU General Public License version 3');
    GotoXY(25,16); Write('Linux version by:');
    GotoXY(25,18); Write('2000-2018 Pieter-Tjerk de Boer');
    GotoXY(25,19); Write('     2009 Leland C. Scott');
    GotoXY(2,27); Write('For more information, see:');
    GotoXY(2,29); Write('http://www.its.caltech.edu/~mmic/puff.html -> for the original version');
    GotoXY(2,31); Write('http://wwwhome.cs.utwente.nl/~ptdeboer/ham/puff.html -> for the Linux version');
    TextCol(white);
    message_color:=white;
    Blank_Blue_Cursor;		   { make cursor invisible }
    repeat Ch:= ReadKey until (Ch<>screenresize);
    if (Ch = #0) then Ch:=char(ord(ReadKey)+128);
    if Ch = Esc then begin       { Has the Esc key been pressed? }
	TextMode(OrigMode);
	ClrScr;
	Halt(2);        { Abort and restore textmode if Esc pressed}
    end;
  end; {if 'setup' }
  TextBackground(Black);
  ClrScr; 	{erase blue and yellow to leave black screen }

  {Initialize message box, in case early errors result}
  Max_Text_Y:=25;
  Max_Text_X:=80;
  message_color:=lightred;
  xmin[6]:=32;
  ymin[6]:=11;
  xmax[6]:=49;
  ymax[6]:=13;

  insert_key:=true;
  Large_Smith:=false;
  Large_Parts:=false;
  Extra_Parts_Used:=false;
  co(co1,1.0,0);   		{define complex variable co1 = 1+j0}
  key_end:=0;			{erase key list}
  {**
       Check here for enough memory to run Puff
         - Additional data structures require 17,296 bytes.
	 - Simple circuit will require 36,864 bytes.
	 - 128 bytes/point required for plot data.
       Minimum is 50 points.
  **}
  memK:=Round(memK/1024);
  case memK of
        1..80  : begin
                  message[2]:='Insufficient';
                  message[3]:='memory to run Puff';
                  shutdown;
                 end;
       81..100 : ptmax:=50;
      101..150 : ptmax:=100;
      151..200 : ptmax:=250;
     201..1000 : ptmax:=500;
    else ptmax:=1000;
  end;{case}

  {* Init_Puff_Parameters; *}

  Prep_to_Read_Board;

  read_kbd:=true;
  if pos('.',puff_file)=0 then puff_file:=puff_file+'.puf';
  if not(fileexists(puff_file<>'setup.puf',net_file,puff_file)) then begin
    	if not(setupexists(puff_file)) then begin
		erase_message;
		message[2]:='setup.puf not found';
		message[3]:='reinstall the package.';
		shutdown;
	end;
  end;
  Close(net_file);
end; {* Puff_Start *}


procedure Set_Up_Char;
{*
	Set up extendended graphics characters.
	Called by Screen_Init.
*}
begin

end; {*Set_Up_Char*}


{******************** GRAPHICS INITIALIZATION *******************}
Procedure Screen_Plan;
{*
	Plan how to subdivide the total screen into our "windows".
*}

var
	i	: integer;
	parts_height : integer;
	board_height : integer;

begin   {Screen_Plan}

   xmin[12]:=0;
   ymin[12]:=0;
   xmax[12]:=ScreenWidth;
   ymax[12]:=ScreenHeight;
   yf:=1.0;  {1:1 aspect ratio for VGA}

{
   xmax[12]:=639;
   ymax[12]:=479;
   if (not its_VGA) then begin
     its_VGA:=True;
      xmax[12]:=1279;
      ymax[12]:=959;
   end;
}

{*********************************************
	 Graphics Parameter Constants

	 Window indexing system:
	 [1] : Layout window (graphics),
	 [2] : Plot window (text),
	 [3] : Parts window (text),
	 [4] : Board window (text),
	 [5] : Extra parts (text),
	 [6] : Help window (text),
	 [7] : Smith chart (graphics),
	 [8] : x-y plot (graphics),
	 [9] : Layout erase region (graphics),
	 [10]: Smith erase region (graphics),
	 [11]: x-y plot erase region (graphics),
	 [12]: full window size (graphics).
************************************************}
  xmin[2] := 2;  xmax[2] := 23;
  xmin[3] := 2;  xmax[3] := 23;
  xmin[4] := 2;  xmax[4] := 23;
  xmin[5] := 2;  xmax[5] := 23;
  xmin[6] := 2;  xmax[6] := 23;
  i:=ymax[12] DIV 14;  { total number of text rows }
  { from the excess rows beyond 34, first 1 or 2 are used to expand the BOARD window (to make the entire help message fit); anything left is used to expand the PARTS window }
  board_height:=7;
  parts_height:=9;
  if (i=35) then board_height:=8;
  if (i>=36) then begin
     board_height:=9;
     parts_height:=i-27;
     if (parts_height>18) then parts_height:=18;
  end;
  ymin[2] := 2;          ymax[2] := 8;                       { plot window }
  ymin[3] := 16;         ymax[3] := ymin[3]+parts_height-1;  { parts window }
  ymin[4] := ymax[3]+3;  ymax[4] := ymin[4]+board_height-1;  { board window }
  ymin[5] := ymax[3]+1;  ymax[5] := ymin[3]+17;              { extra parts window }
  ymin[6] := 11;         ymax[6] := 13;                      { help window }

  i:= 14 * ((ymax[12]+1) DIV 28);   { half of screen height, rounded down to a multiple of character height }
  { in principle, that's the height at which we put the boundary between layout+smith and plot }
  { however, both layout and smith need to be more or less square/round, so this may not fit }
  { in that case, move this boundary up until it fits }
  { I'm lazy, so just make it a loop, instead of computing the right values straight away... }
  i:=i+14;
  xmin[9] := (xmax[2]+1) * 8;
  ymin[9] := 0;
  ymin[10] := 0;
  xmax[10] := xmax[12]+1;
  repeat begin
     i:=i-14;
     ymax[9] := i-14;
     ymax[10] := i;
     xmin[10] := 8 * ((xmax[10]-i+14) DIV 8);
     xmax[9] := xmin[10];
  end until (xmax[9]-xmin[9] >= ymax[9]-ymin[9]);
  ymin[11] := i;
  ymax[11] := 14*((ymax[12]+1) DIV 14);
  xmin[11] := xmin[9];
  xmax[11] := xmax[12]+1;

  xmin[1] := xmin[9]+11;   { compute layout window corner coordinates from its erase coordinates }
  ymin[1] := ymin[9]+12;
  xmax[1] := xmax[9]-10;   { xmax[1] is never used }
  ymax[1] := ymax[9]-12;
  layout_position[1]:=xmin[9] DIV 8 +8;   { position of text "F1 : LAYOUT", in text coordinates }
  layout_position[2]:=1;
  xmin[8] := xmin[11]+50;   { compute plot window corner coordinates from its erase coordinates }
  ymin[8] := ymin[11]+7;
  xmax[8] := xmax[11]-32;
  ymax[8] := ymax[11]-16;
  xmin[7] := xmin[10]+12;   { compute Smith window corner coordinates from its erase coordinates }
  ymin[7] := ymin[10]+1;    { note: these aren't used anywhere, and may be meaningless/wrong }
  xmax[7] := xmax[10]-4;
  ymax[7] := ymax[10]-51;
  centerx:=(xmax[10]+xmin[10]) DIV 2 - 1;   { center of Smith chart }
  centery:=(ymax[10]+ymin[10]-10) DIV 2;
  rad:=(xmax[10]-xmin[10]) DIV 2 - 4;  {radius of Smith chart}

  if (Large_Smith) then begin
     xmin[10] := xmin[11];
     xmax[10] := xmax[12];
     ymin[10] := 0;
     ymax[10] := ymax[12];
     centerx := (xmin[10]+xmax[10]) div 2;
     centery := (ymin[10]+ymax[10]-18) div 2;
     rad := (xmax[10]-xmin[10]) div 2 - 7;
     if (rad>centery-13) then rad:=centery-13;
  end;

  Max_Text_Y:=ymax[12] DIV 14;
  Max_Text_X:=xmax[12] DIV 8;
 {* Specify (x,y) text positions for text in the x-y plots *}
 {*  x_y_plot_text
 		    [1,x] : dBmax
 		    [2,x] : |S|
		    [3,x] : dBmin
		    [4,x] : fmin
		    [5,x] : f _Hz
		    [6,x] : fmax
 *}
  x_y_plot_text[1][1] := xmin[8] DIV 8 + 1;
  x_y_plot_text[2][1] := xmin[8] DIV 8 - 3;
  x_y_plot_text[3][1] := xmin[8] DIV 8 + 1;
  x_y_plot_text[4][1] := xmin[8] DIV 8 + 1;
  x_y_plot_text[5][1] := (xmin[8]+xmax[8]) DIV 16 - 1;
  x_y_plot_text[6][1] := xmax[8] DIV 8 + 1;
  x_y_plot_text[1][2] := ymin[8] DIV 14 + 2;
  x_y_plot_text[2][2] := (ymin[8]+ymax[8]) DIV 28 + 0;
  x_y_plot_text[3][2] := ymax[8] DIV 14 + 1;
  x_y_plot_text[4][2] := ymax[8] DIV 14 + 2;
  x_y_plot_text[5][2] := ymax[8] DIV 14 + 2;
  x_y_plot_text[6][2] := ymax[8] DIV 14 + 2;
  filename_position[1] := xmin[9] DIV 8 + 3;
  filename_position[2] := 1 + ymax[9] DIV 14;
  filename_position[3] := xmax[9] DIV 8;   { end of this field }
  checking_position[1] := xmin[9] DIV 8 + 4;
  checking_position[2] := ymax[9] DIV 28;
  layout_position[1] := xmin[9] DIV 8 + 8;
  layout_position[2] := 1;

  i:=(xmax[1]-xmin[1] - (3+ymax[1]-ymin[1]));
  if (i>0) then begin
     { if there's a lot of horizontal room, more or less center the layout window }
     i:=i DIV 16;
     xmin[1]:=xmin[1] + 8*i;
     layout_position[1]:=layout_position[1]+i;
  end;
  Make_Titles;

end;  {* Screen_Plan *}




Procedure Screen_Init;
{*
	Initialize VGA mode.
		
	Called by Read_Net();
*}

var
	Gr_Error_Code	: integer;

begin   {Screen_Init}

  Screen_Plan;

  clear_window_gfx(xmin[12],ymin[12],xmax[12],ymax[12]);

  Init_Puff_Parameters;
  InitGraph(GraphDriver,GraphMode,'');
  Gr_Error_Code := GraphResult;
  if Gr_Error_Code <> grOk then begin
	TextMode(OrigMode);
	WriteLn('Graphics error: ', GraphErrorMsg(Gr_Error_Code));
	Halt(4);
  end; {error message}
  DirectVideo := false; 	{ Write text characters thru BIOS  }
  				{ DirectVideo is a CRT unit var    }
				{ needed to mix text with graphics }
  Set_Up_Char;
  message_color:=lightred;
  {* MESSAGE Box *}
  Make_Text_Border(xmin[6]-1,ymin[6]-1,xmax[6]+1,ymax[6]+1,LightRed,true);
  {* PLOT Box *}
  Make_Text_Border(xmin[2]-1,ymin[2]-1,xmax[2]+1,ymax[2]+1,Green,true);
  bad_compt:=false;
  write_compt(col_window[2],window_f[2]);
  key:=F3;
  compt3:=part_start;
  cx3:=compt3^.x_block;
end; {* Screen_Init *}



End.
{Unit implementation}
