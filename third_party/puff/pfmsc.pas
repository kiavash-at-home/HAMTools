{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pfmsc;

(*******************************************************************

	Overlayed Unit PFMSC;

	PUFF MISCELLANEOUS CODE

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer.

        Modifications for Linux compilation 2000-2007 Pieter-Tjerk de Boer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.


	Contains code for:
		VGA/EGA Smith Charts,
		Help Commands,
		Device file s-parameter reading.

********************************************************************)

Interface

Uses
  Dos, 		{Unit found in Free Pascal RTL's}
  xgraph,	{Custom replacement unit for TUBO's "Crt" and "Graph" units}
  pfun1,	{Add other puff units}
  pfun2;


Procedure Draw_EGA_Smith(imped_chart : boolean);
Procedure Write_Commands;
Procedure Board_HELP_window;
procedure Device_Read(tcompt : compt; indef : boolean);
(*
   Device_Read uses and includes the routines:
   procedure Get_Device_Params(tcompt : compt; var fname : file_string;
    				var len : double);
   procedure pars_tplate(tp:file_string;var n_c,n_s:integer;var f_p:boolean);
   procedure read_number(var s : double);
*)


Implementation



Procedure Draw_EGA_Smith(imped_chart : boolean);
{*
	Draw the smith chart with radius rho_fac.
	If imped_chart = true then draw impedance chart
			      else draw admittance chart.
*}
var
  I: INTEGER;

  RG_reye,reye{,Angle_2}                : integer;
  theta_start_high,theta_start_low,
  theta_in{,a,b},beta{,arc_length}		: double;

     {*****************************************************}
     Procedure Get_thetas(a,b,cir_rad : double; delta_x : integer);
     {*
        Find maximum angle allowed before an arc circle
        goes outside the Smith chart.
        Must have a<>0, b<>0.
     *}
     var
        x : double;
     begin
        if ((a+b)<=cir_rad) then begin
	  {if entire circle inside radius}
          theta_start_high:=0;
          theta_start_low:=0;
          theta_in:=180;
        end
        else begin
          x:=0.5*(a/b + b/a - sqr(1.0*cir_rad)/(a*b));
	  	{ Cos(theta_in) = x }
          theta_in:=90 - 180*arctan(x/sqrt(1.0 - sqr(x)))/Pi;
	  {this ArcCos function valid for -1 < x < 1}
	  if imped_chart or (delta_x > 0) then begin
             theta_start_high:=270 - beta - theta_in;
             theta_start_low:=450 + beta - theta_in;
          end
	  else begin  {admittance chart}
             theta_start_high:=270 + beta - theta_in;
             theta_start_low:=450 - beta - theta_in;
	  end;
          if imped_chart and (delta_x<0) then
             theta_start_high:=360 - theta_in;
          if not(imped_chart) and (delta_x>0) then
             theta_start_high:=180 - theta_in;
        end;
     end;

     {*********************************************************}
     Procedure Make_Dot_Arcs(Arc_Rad,RG_delta_x,clip_rad : integer);
     {*
     		Make dotted arcs inside the smith chart
     *}
     var
        a,b : double;
        i,j: INTEGER;
{     	k : integer; }

     begin
{       Angle_2:= Round( 180* Arc_length / (Pi * Arc_Rad) );
       if Angle_2 = 0 then Angle_2 := 1; }
       a:= Arc_rad;
       if RG_delta_x=0 then begin  {b is the distance between circle centers}
          b:= sqrt(sqr(1.0*reye)+sqr(a));  {right triangle for XB circles}
          beta:=180*arctan(1.0*reye/a)/Pi;
          if b<(a+clip_rad) then begin
	     Get_thetas(a,b,clip_rad,0);
(*	     for k:= 1 to Trunc(2*theta_in) div Angle_2 do begin
                ths:= Round(theta_start_high) + (k-1)*Angle_2;
	        Arc(centerx+RG_reye,centery-Round(yf*Arc_Rad),
	     		ths,ths+1,Arc_Rad);
	        {plotting one degree makes a single arc point}
                ths:= Round(theta_start_low) + (k-1)*Angle_2;
	        Arc(centerx+RG_reye,centery+Round(yf*Arc_Rad),
	     		ths,ths+1,Arc_Rad);
             end; {for k}
*)
             i:= rad + RG_reye;

             j:= Round(theta_start_high + (2*theta_in) + 0.5);
             { BUG fix: Arc doesn't like coordinates outside of screen!! }
             WHILE (Trunc(cos(Pi * j / 180) * Arc_rad) >= rad-RG_reye) DO Dec(j);
             Arc(i, rad - Round(yf * Arc_rad),
                     Trunc(theta_start_high), j, Arc_Rad);

             j:= Trunc(theta_start_low);
             WHILE (Trunc(cos(Pi * j / 180) * Arc_rad) >= rad-RG_reye) DO Inc(j);
             Arc(i, rad + Round(yf * Arc_Rad),
                  j, Round(theta_start_low + (2*theta_in) + 0.5),
                  Arc_Rad);
          end; {if b<}
       end
       else begin
          b:= 1.0*abs(RG_delta_x);  {mag of delta_x for RG circles}
          beta:=90;
          if (a<b+clip_rad) and (b<a+clip_rad) then begin
	     Get_thetas(a,b,clip_rad,RG_delta_x);
(*	     for k:=1 to Trunc(2*theta_in) div Angle_2 do begin
                ths:= Round(theta_start_high) + (k-1)*Angle_2;
	        Arc(centerx+RG_delta_x,centery,ths,ths+1,Arc_rad);
	        {plotting one degree makes a single arc point}
	        {plot continuously for the circle}
             end; {for k}
*)
             Arc(rad + RG_delta_x, rad, Trunc(theta_start_high),
                 Round(theta_start_high + (2 * theta_in) + 0.5), Arc_rad);
          end; {if a< and b<}
       end;
     end;
     {*********************************************************}

Begin  {*Draw_EGA_Smith*}
  SetViewPort(centerx-rad, centery-rad, centerx+rad, centery+rad, TRUE);
  SetFillStyle(SolidFill, black);

  SetCol(Green);

  reye:= Round (rad / rho_fac);
  if imped_chart then RG_reye:= reye
                 else RG_reye:= -reye;
  if rho_fac > 0.29 then begin  {ignore lines for tiny smith chart}

        { If very large raw just outer circle }

        if (rho_fac <= 15) then begin

(*	  if Large_Smith then
	  	{* Set arc length to 10 degrees (0.2618 radians)x .25 reye *}
		Arc_length:= 0.036*reye*rho_fac
	  else
	  	{* Set arc length to 15 degrees (0.2618 radians)x .25 reye *}
		Arc_length:= 0.055*reye*rho_fac;
*)
          { r circles, except smallest one }
          FOR I:= 2 TO 5 DO BEGIN
            Make_Dot_Arcs ((I * reye) DIV 6, ((6 - I) * RG_reye) DIV 6, rad);
          END;

          { If large chart then draw r circles outside eye }
          if rho_fac > 1.5 then begin
             Make_Dot_Arcs (reye,      2 * RG_reye,  rad);
             Make_Dot_Arcs (3 * reye, -2 * RG_reye,  rad);
             Make_Dot_Arcs (3 * reye,  4 * RG_reye,  rad);
          end;
(*             Make_Dot_Arcs(reye div 2,0,rad);  {center 0 calls xb circles}
{	     Make_Dot_Arcs(reye,0,rad); }
	     Make_Dot_Arcs(2*reye,0,rad);
          end
          else begin
{             IF (rho_fac > 1.0) THEN BEGIN
               FOR I:= 1 TO 3 DO BEGIN
                 Make_Dot_Arcs ((I * reye) DIV 3, 0, reye);
               END;
               FOR I:= 1 TO 2 DO BEGIN
                 Make_Dot_Arcs ((3 * reye) DIV I, 0, reye);
               END;
             END ELSE BEGIN *)

          { draw xb circles }
          Make_Dot_arcs (reye * 5, 0, rad);
          Make_Dot_arcs (reye * 2, 0, rad);
          Make_Dot_arcs (reye DIV 2, 0, rad);

          { Draw smallest r circle and clear area inside (if visible)
            This makes the xb circles stop at the inner r circle }
          IF (rho_fac > 0.66) THEN
            FillEllipse((5 * RG_reye) DIV 6 + rad, rad, reye DIV 6, reye DIV 6);
          { if necessary also left side }
          IF (rho_fac > 1.0) THEN
            FillEllipse((7 * RG_reye) DIV 6 + rad, rad, reye DIV 6, reye DIV 6);

          { Now draw xb circles that cut smallest r circle }
          Make_Dot_Arcs (reye DIV 5, 0, rad);
          Make_Dot_Arcs (reye, 0, rad);
       end; {if not(rho_fac>15)}
  end      {rho > 0.3}
  else if rho_fac > 0.18 then begin   {if .18<rho_fac<.3 then tick and cir}
{        Arc_length:= 0.05*reye*2*rho_fac; }
	Make_Dot_Arcs(reye div 2, RG_reye div 2, rad);
        Line(rad, rad-3, rad, rad+3);
  end      {rho > 0.18}
  else begin   {if rho_fac < .18 then just draw a tick mark}
       Line(rad, rad-3, rad, rad+3);
  end;
  { real axis }
  Line(0, rad , 2*rad, rad);

  { outer circles }
  SetCol(lightgreen);
  IF rho_fac > 1.0 THEN BEGIN
    Circle(rad, rad, reye);
  END;
  IF (blackwhite) THEN SetColor(lightgreen);
  Circle(rad, rad, rad); {draw outer circle}

  { overpaint overetched arc parts }
  reye:= 2 * rad;
  FloodFill(0, 0, lightgreen);
  FloodFill(0, reye, lightgreen);
  FloodFill(reye, 0, lightgreen);
  FloodFill(reye, reye, lightgreen);

  IF (blackwhite) THEN BEGIN
    SetColor(white);
    Circle(rad,rad,rad);
  END;

(*  { mark at (1 0) }
  SetCol(green);
  IF (blackwhite) THEN SetFillStyle(solidFill, white) ELSE SetFillStyle(solidFill, green);
  FillEllipse(rad, rad, 2, 2);
{  Circle(rad, rad, 2); }
*)

  SetViewPort(xmin[12], ymin[12], xmax[12], ymax[12], False)
end; {*Draw_EGA_Smith*}


Procedure Write_Commands;
{*
	Write commands in help box.
*}
Const    {* Commands for help window *}
 command: array[1..3,1..9,1..4] of string[17]=(
 (( #27' '#26' '#24' '#25,' draw part','',''),
  ('=','  ground '#132'      ','',''),
  ('1..4',' connect path','',''),
  ('a..r','  select part','',''),
  ('Ctrl-e',' erase crct','',''),
  ('Ctrl-n',' go to node','',''),
  ('Shift',' move/erase','',''),
  ('F10','  toggle help','',''),
  ('Esc','  exit        ','','')),
 (( #27' '#26' '#24' '#25,'   cursor ','',''),
  ('p,Ctrl-p','  plot   ','',''),
  ('PgUp,PgDn',' marker ','',''),
  ('Ctrl-s','  save file','',''),
  ('Ctrl-a','  artwork  ','',''),
  ('i,s',' impulse, step','',''),
  ('Tab',' toggle Smith','',''),
  ('Alt-s',' large Smith','',''),
  ('F10, Esc',' help, exit   ','','')),
 (( #27' '#26' '#24' '#25,'   cursor ','',''),
  ('Del,Backspace,Ins','','',''),
  ('Alt-o ',Omega,'   Alt-m ', Mu),
  ('Alt-d ',Degree,'   Alt-p ',Parallel),
  ('Ctrl-e',' erase crct','',''),
  ('Ctrl-r',' read file ','',''),
  ('Tab','  extra parts','',''),
  ('F10','  toggle help','',''),
  ('Esc','  exit        ','','')));

Var
  i,imax    : integer;

Begin
  imax:=ymax[4]-ymin[4]+1;
  if (imax>9) then imax:=9;
  if not((window_number=3) and read_kbd 
		and circuit_changed) then erase_message;
  Make_Text_Border(xmin[4]-1,ymin[4]-1,xmax[4]+1,ymax[4]+1,
  	col_window[window_number],true);
  for i:=1 to imax do begin   {write help window elements}
	GotoXY(xmin[4],ymin[4]-1+i); {position of command window}
	TextCol(white);
	write(command[window_number,i,1]);
	TextCol(lightgray);
	write(command[window_number,i,2]);
	TextCol(white);
	write(command[window_number,i,3]);
	TextCol(lightgray);
	write(command[window_number,i,4]);
  end;
  write_compt(col_window[window_number],command_f[window_number]);
  	{Write header for help window}
end; {* Write_Commands *}


Procedure Board_HELP_window;
{*
	Erase parts list area, write zd and fd,
	draw window box, list parts.
	Called only by Read_Net.
*}
Begin
  Make_Text_Border(xmin[3]-1,ymin[3]-1,xmax[3]+1,ymax[3]+1,
  	col_window[4],true);  	{clear and write border }
  write_compt(col_window[4],command_f[4]);    {write BOARD Header}
  Window(xmin[3],ymin[3],xmax[3],ymax[3]);
  TextCol(lightgray);
  WriteLn('zd : norm. impedance');
  WriteLn('fd : design freq.');
  WriteLn('er : diel. constant');
  WriteLn('h  : sub. thickness');
  WriteLn('s  : board size');
  WriteLn('c  : conn. separation');
  WriteLn('Tab : toggle type');
  Window(1,1,Max_Text_X,Max_Text_Y);  {Default}
end; {* Board_HELP_window *}


procedure Get_Device_Params(tcompt:compt;var fname:file_string;var len:double);
{*
	Read device description from parts window (tcompt^.descript)
	and extract filename and length information.
*}
const
  potential_numbers: set of char = ['+','-','.',',','0'..'9'];

var
  p1,p2,code,i,j,long  	: integer;
  c_string,s_value	: line_string;
  found_value		: boolean;

begin
  len:=0.0;        { default length was Manh_length}
  fname:=tcompt^.descript; {* fname = e.g. 'e device fsc10 2mm' *}
  for j:=1 to 2 do begin
        p1:=Pos(' ',fname); {find index for blanks in descript}
        Delete(fname,1,p1); {delete through blanks in descript}
  end;
  p2:=Length(fname); {get string length} {now fname = 'fsc10 2mm  ' }
  while fname[p2]=' ' do begin  {remove any blanks at end}
	Delete(fname,p2,1);
  	Dec(p2);  
  end;
  p1:=Pos(' ',fname); {here fname = 'fsc10 2mm' or 'fsc10' }
  c_string:=fname; {now c_string = 'fsc10 2mm' }
  if p2 = 0 then begin
    	ccompt:=tcompt;
	bad_compt:=true;
	message[1]:='Invalid device';
	message[2]:='specification';
	exit;
   end 
   else if (p1 > 0) then
	Delete(fname,p1,p2); {now fname = 'fsc10'}
  if not(Manhattan(tcompt) or (p1=0) ) then begin
     Delete(c_string,1,p1);      {now c_string = '2mm'}
     long:=length(c_string);
     while c_string[long]=' ' do Dec(long);  {remove blanks at end}
     found_value:=false;
     s_value:='';
     j:=1;
     while (c_string[j] = ' ') and (j < long+1) do Inc(j);   {Skip spaces}
     repeat
       if c_string[j] in potential_numbers then begin
         if not(c_string[j]='+') then begin   {ignore + }
              if c_string[j]=',' then s_value:=s_value+'.'  {. for ,}
                    		 else s_value:=s_value+c_string[j];
         end; {+ check } 
         Inc(j);
       end 
       else 
     	 found_value:=true;
     until (found_value or (j=long+1));
     Val(s_value,len,code); 	{convert string to double number}
     if (code<>0) or (Pos('m',c_string) = 0) or (long=0) then begin
    	ccompt:=tcompt;
	bad_compt:=true;
        message[1]:='Invalid length';
        message[2]:='or filename';
	exit;
     end;  {Here j is right of the number}
     while (c_string[j] = ' ') and (j < long+1) do Inc(j);   {Skip spaces}
     {* if j=long then j must point to an 'm' *}
     if (c_string[j] in Eng_Dec_Mux) and (j<long) then begin
        if c_string[j]='m' then begin   {is 'm' a unit or prefix?}
	  i:=j+1;	
          while (c_string[i] = ' ') and (i < long+1) do Inc(i);   
	  {* Skip spaces to check for some unit *}
	  if (c_string[i]='m') then begin 
	     {it's the prefix milli 'm' next to an 'm'}
	     len:=Eng_Prefix('m')*len;
	     j:=i; {make j point past the prefix, to the unit}
	  end;
        end  {if 'm' is a unit do nothing}
        else begin  {if other than 'm' factor in prefix}
          len:=Eng_Prefix(c_string[j])*len;
	  Inc(j);  {advance from prefix toward unit}
        end;
     end;  {if in Eng_Dec_Mux}
     len:=1000*len; {return length in millimeters, not meters}
     while (c_string[j] = ' ') and (j < long+1) do Inc(j);   
     if (len<0) or (c_string[j]<>'m') then begin
        ccompt:=tcompt;
        bad_compt:=true;
        message[1]:='Negative length';
        message[2]:='or invalid unit';
        exit;
     end;
  end; {if not Manhattan}
end; {* Get_Device_Params *}


{************************************************************************}

PROCEDURE Device_Read(tcompt : compt; indef : boolean);
{*
	Device equivalent of tline.
	Included within are Pars_tplate and Read_Number.

	Only to be used when action= true  
		get device parameters (filename,draw length)
		check that file exists.
		Check for .puf or .dev files.

	Indef specifies whether or not to enable the generation
	of indefinite scattering parameters (extra port).

	type compt has the following s_param records:
		tcompt^.s_begin,
		tcompt^.s_file,
		tcompt^.s_ifile,
		tcompt^.f_file
*}
label
  read_finish;

var
  fname        			: file_string;
  c_ss,c_f			: s_param;
{  s1,s2        			: array[1..10,1..10] of Tcomplex; }
  template     			: string[128];
  ext_string			: string[3];
  first_char			: string[1];
  char1,char2			: char;
  freq_present,
  Eesof_format		     	: boolean;
  i,j,number_of_s,code1,
  number_of_ports,Eesof_ports	: integer;
  f1,mag,ph                     : double;


  	{**************************************************************}

Procedure Pars_tplate(tp:file_string;var n_c,n_s:integer;var f_p:boolean);
{*
	Partition template. Extract number of connectors and frequencies. 
	template (tp:file_string) is in the form ' f  s11  s21  s12  s22 '
*}
var
  i,j,i1,i2,x,code 	: integer;
  ijc 			: array[1..16] of string[2];

begin
  if (Pos('f',tp) > 0) or (Pos('F',tp) > 0) then 
  		f_p:=true 
	else 
		f_p:=false;
  n_s:=0;
  repeat
    	i1:=Pos('s',tp); 
	i:=i1;
	i2:=Pos('S',tp);
	if i1 < i2 then begin
	  	if i1 > 0 then i:=i1 else i:=i2;
	end 
	else begin
	  	if i2 > 0 then i:=i2 else i:=i1;
	end;
	if i>0 then begin
		Delete(tp,1,i);
		n_s:=n_s+1;
		if length(tp) >= 2 then begin
			ijc[n_s]:=tp;
			Delete(tp,1,2);
		end;
	end;
  until (length(tp)=0) or (i=0);
  n_c:=1;
  for i:=1 to n_s do begin
	Val(ijc[i],x,code);
	if code <> 0 then begin
		bad_compt:=true;
		message[1]:='Bad port number';
		message[2]:='in device';
		message[3]:='file template';
		exit;
	end;
	iji[i,1]:=x div 10;
	iji[i,2]:=x-iji[i,1]*10;
	if (iji[i,1] < 1) or (iji[i,2] < 1) then begin
		bad_compt:=true;
		message[1]:='0 port number';
		message[2]:='in device';
		message[3]:='file template';
		exit;
	end;
	if iji[i,1] > n_c then n_c:=iji[i,1];
	if iji[i,2] > n_c then n_c:=iji[i,2];
	for j:=1 to i-1 do
		if (iji[i,1]=iji[j,1]) and (iji[i,2]=iji[j,2]) then begin
			bad_compt:=true;
			message[1]:='Repeated sij';
			message[2]:='in device';
			message[3]:='file template';
			exit;
		end;
  end; {for i := 1 to n_s}
  if n_s=0 then begin
	bad_compt:=true;
	message[1]:='No port numbers';
	message[2]:='in device';
	message[3]:='file template';
  end;
end; {Pars_tplate}

		{********************************************************}

Procedure Read_Number(var s: double);
{*
	Read s-parameter values from files.
*}
var
  ss		:string[128];
  char1		:char;
  code		:integer;
  found		:boolean;

begin
  ss:=first_char;  {first_char is the very first valid file character}
  found:=false;
  if (ss='') then  {search for first valid character if not in first_char}
    if not(EOF(dev_file)) then begin 	{goto next number}
	Repeat 	{keep reading characters until a valid one is found}
	   if SeekEoln(dev_file) then ReadLn(dev_file);
	   	 {if blank line then advance to next line}
	   Read(dev_file,char1); 	{read single character}
	   if char1 in [lbrack,'#','!'] then ReadLn(dev_file);
	   	 {skip potential comment lines}
	   if char1 in ['+','-','.',',','0'..'9','e','E','\'] then begin
		  ss:=char1;
		  found:=true;
	   end;
	Until found or EOF(dev_file);
  end;
  found:=false;
  if not EOF(dev_file) then
     Repeat {continue reading characters and add to string ss until invalid}
     	Read(dev_file,char1);
	if char1 in ['+','-','.',',','0'..'9','e','E'] then 
		ss:=ss+char1 
             else 
	        found:=true;
     until found or Eoln(dev_file) or EOF(dev_file);
  Val(ss,s,code); { turn string ss into double number }
  if (code<>0) or (length(ss)=0) then begin
	bad_compt:=true;
	message[1]:='Extra or missing';
	message[2]:='number in';
	message[3]:='device file';
  end; {if code <> 0}
end; {read_number}

		{********************************************************}

Procedure Seek_File_Start(temp_exists : boolean);
{*
	Look for the start of useable data in a file
	    including a template or numbers.
	Do so via a character search for:
	     'f', 'F', 's' or 'S' for templates,
	      or any numeric character for Eesof files.
*}
Var
   char1  : char;
   found  : boolean;

Begin
  found:=false;
  first_char:='';
  Repeat   {keep reading characters until a valid one is found}
    while SeekEoln(dev_file) do ReadLn(dev_file);
      {Advance past any blank lines}
    repeat
       Read(dev_file,char1); 	{find single character}
    until (char1<>' ') or Eof(dev_file);
    if char1 in [lbrack,'#','!'] then ReadLn(dev_file);
      {Skip lines with comments }
    if temp_exists then begin
    	if char1 in ['f','F','s','S'] then begin
    	  first_char:=char1;
	  found:=true;
        end;
    end
    else begin 
       if char1 in ['+','-','.',',','0'..'9'] then begin
    	  first_char:=char1;
	  found:=true;
       end;
    end;
  Until found or EOF(dev_file);
end;
		{********************************************************}


BEGIN  {* Device_Read *}
    Get_Device_Params(tcompt,fname,tcompt^.lngth); {get filename and length}
    if bad_compt then exit;
    {! length check moved from this location}
    Eesof_format:=false;
    i:=Pos('.',fname);
    if (i=0) then
    	fname:=fname+'.dev' {add .dev extension}
    else begin   {Check for Eesof type extension}
        ext_string:= Copy(fname,i+1,3);  {copy 3 character extension}
	if (Length(ext_string)=3) then begin
	   if (ext_string[1] in ['s','S'])
	   	and (ext_string[2] in ['1'..'4'])
		  and (ext_string[3] in ['p','P'])
		     then begin
			Val(ext_string[2],Eesof_ports,code1);
			if code1=0 then Eesof_format:=true;
           end; {eesof check}
	end; {length check}
    end; {ext check}
    if (tcompt^.f_file = nil) or tcompt^.changed then
      if fileexists(true,dev_file,fname) then begin
        with tcompt^ do begin
	  if Eesof_format then begin
	     Seek_File_Start(false);
	     {Skip lines looking for start of data}
	     {! WARNING Seek_File_Start stores the first
	        data character in first_char!}
	     number_of_ports:=Eesof_ports;
	     number_of_s:=Sqr(number_of_ports);
	     freq_present:=true;
	     {* set up iji[] array *}
	     for i:=1 to number_of_ports do 
	       for j:=1 to number_of_ports do begin
	          iji[number_of_ports*(i-1)+j,1]:=i;
	          iji[number_of_ports*(i-1)+j,2]:=j;
	     end;	
	     {* Must correct for 2-ports since their order is goofy *}
	     if (number_of_ports=2) then begin
	         iji[2,1]:=2; iji[2,2]:=1;
		 iji[3,1]:=1; iji[3,2]:=2; 
	     end;
	  end
	  else begin
	    while SeekEoln(dev_file) do ReadLn(dev_file);
	    	{Advance past any blank lines}
	    ReadLn(dev_file,template); { read first line string }
	    if Pos('\b',template) > 0 then begin  {* if a .PUF file *}
	       Repeat				{* then move to \s section *} 
                  ReadLn(dev_file,char1,char2);
               Until ((char1='\') and (char2 in ['s','S'])) or Eof(dev_file);
               if EOF(dev_file) then begin
	     	 bad_compt:=true;
		 message[1]:='s-parameters';
		 message[2]:='not found in';
		 message[3]:='device file';
		 goto read_finish;
               end;
            end; {if Pos('\b')}
	    { now check for valid template = e.g. ' f   s11  s21  s12  s22 '}
	    while (template[1]=' ') do Delete(template,1,1);
	       {delete leading blanks}
	    if (template[1] in ['f','F','s','S']) then
	       Pars_tplate(template,number_of_ports,number_of_s,freq_present)
               {have a potentially valid template, get info}
	    else begin
	       Seek_File_Start(true);
		 {Skip lines looking for template}
               if EOF(dev_file) then begin
	     	 bad_compt:=true;
		 message[1]:='template';
		 message[2]:='not found in';
		 message[3]:='device file';
		 goto read_finish;
               end;
	       ReadLn(dev_file,template);
	       Insert(first_char,template,1); 
	         {Put back character removed by Seek_File_Start}
	       first_char:=''; {This to initialize Read_Number}  
	       Pars_tplate(template,number_of_ports,number_of_s,freq_present);
	  	 {get info from template}
	    end; { end template search}
	    {* Number_of_ports is how many are in the file *}
	    {* Number_of_con is how many will result *}
	  end;  { else Eesof_format }
	  if indef then number_of_con:=number_of_ports+1
	  	   else number_of_con:=number_of_ports;
	  {* Initialize sdevice elements to zero *}
	  for j:= 1 to number_of_con do
	  	for i:= 1 to number_of_con do begin
			sdevice[i,j].r:=0;
			sdevice[i,j].i:=0;
	  end;
(*	  width:=0;   *)
	  {! This section moved from 4th line--get_device returns 0 for Manh }
	  if Manhattan(tcompt) or (tcompt^.lngth=0) then begin
	     if (number_of_con > 1) then 
    		tcompt^.lngth:=Manh_length*(number_of_con-1)
	     else 	
    		tcompt^.lngth:=Manh_length;
	  end;	
	  tcompt^.width:=tcompt^.lngth;  {symmetrical}
	  if tcompt^.lngth<=resln then begin
	     bad_compt:=true;
	     message[1]:='Device length';
	     message[2]:='must be';
	     message[3]:='>'+sresln;
	     goto read_finish;
	  end;
	  con_space:=0.0;
	  c_ss:=nil;        
	  c_f:=nil;
	  f1:=-1.0;  {use f1 to detect start of noise parameters}
	  {* LOOP to read in s-parameters from file *}
	  repeat
	    if freq_present then begin
		if c_f=nil then begin
		       New_s(tcompt^.f_file);
		       c_f:=tcompt^.f_file;
		end
		else begin
		       New_s(c_f^.next_s);
		       c_f:=c_f^.next_s;
		end; {c_f=nil}
		c_f^.next_s:=nil;
                New_c (c_f^.z);
		Read_Number(c_f^.z^.c.r);
		  {Must set up next call to Read_Number in case}
		  {on the first pass first_char was set. This}
		  {only occurs with Eesof files, effecting only}
		  {the first frequency data point}
		first_char:='';
		{* Compare with last freq. for start of noise parameters *}
		if (f1 > c_f^.z^.c.r)   {if last frequency was larger}
		   or bad_compt then begin {have reached EOF}
	    	  	erase_message;
			bad_compt:=false;
			goto read_finish;
	        end; {if bad_compt}
		f1:=c_f^.z^.c.r;  {Save last freq point}
             end {if freq_present=true}
	     else
	        tcompt^.f_file:=nil; {end else}
             for i:=1 to number_of_s do begin
		Read_Number(mag);
		if bad_compt then begin
		     if (i=1) and not(freq_present) then begin
		     		{reached EOF}
			  erase_message;
			  bad_compt:=false;
		     end; {if i=1}
		     goto read_finish;
		end; {if bad_compt=true}
		Read_Number(ph);
		if bad_compt then goto read_finish;
		sdevice[iji[i,1],iji[i,2]].r:= one*mag*cos(ph*pi/180);
		sdevice[iji[i,1],iji[i,2]].i:= one*mag*sin(ph*pi/180);
	     end; {for i:=1 to number_of_s}
	     {* Here sdevice[] is filled with s-parameters
	        for a single frequency. Indef_Matrix will
	        generate additional scattering parameters
	        to fill an additional port number.	   *}
	     if indef then Indef_Matrix(sdevice,number_of_ports);
	     for j:= 1 to number_of_con do
	      for i:= 1 to number_of_con do begin
	  	if c_ss=nil then begin
			New_s(tcompt^.s_file);
			c_ss:=tcompt^.s_file;
	        end
		else begin
			New_s(c_ss^.next_s);
			c_ss:=c_ss^.next_s;
		end;
		c_ss^.next_s:=nil;
                New_c (c_ss^.z);
		c_ss^.z^.c.r:=sdevice[i,j].r; {fill parameters}
		c_ss^.z^.c.i:=sdevice[i,j].i;
	     end; {for j,i:= 1 to number_of_con}
         until EOF(dev_file); {end repeat}
        end; {with}
 read_finish:
	close(dev_file);
      end 	{if (tcompt^.f_file = nil) and fileexists=true }
      else   	{if fileexists = false}
     	bad_compt:=true;
END; {* Device_Read *}

{*********************************************************************}




End. 
{Unit implementation}
