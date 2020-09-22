{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pfun3;

(*******************************************************************

	Unit PFUN3;

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer.

        Modifications for Linux compilation 2000-2007 Pieter-Tjerk de Boer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.


	Potentially hazardous code is denoted by {!xxx} comments

	Contains code for:
		writing text info to screen,
		saving and moving markers,
		basic editing commands,
		basic circuit cursor motion,
		basic circuit drawing.

********************************************************************)

Interface

Uses
  Dos, 		{Units found in the Free Pascal's RTL's}
  Printer, 	{Unit found in TURBO.TPL}
  xgraph,	{Custom replacement unit for TUBO's "Crt" and "Graph" units}
  pfun1,	{Add other puff units}
  pfun2;


procedure write_freqO;
procedure write_sO(ij : integer);
procedure HighLight_Window;
procedure Toggle_Circuit_Type;
procedure Write_Board_Parameters;
procedure Write_Expanded_Parts;
procedure Write_Parts_ListO;
Procedure Write_Plot_Prefix(time2 : boolean);
procedure Write_Coordinates(time : boolean);
procedure Write_BigSmith_Coordinates;
procedure restore_boxO(ij : integer);
procedure move_boxO(xn,yn,nb : integer);
procedure draw_ticksO(x1,y1,x2,y2 : integer; incx,incy : double);
procedure Write_File_Name(fname : file_string);
procedure calc_posO(x,y,theta,scf: double;sfreq: integer;dash: boolean);
procedure Smith_and_Magplot(lighten,dash,boxes : boolean);
(* Included in Smith and Magplot are:
 	procedure splineO(ij : integer);
	procedure smith_plotO(x1,y1,col : integer; Var linex : boolean);
	procedure rect_plotO(x1,y1,col : integer;Var linex : boolean);	*)
procedure Draw_Graph(x1,y1,x2,y2 : integer; time : boolean);
(* Component Editing *)
procedure del_char(tcompt : compt);
procedure back_char(tcompt : compt);
procedure add_char(tcompt : compt);
procedure choose_part(ky : char);
procedure draw_net(tnet : net);
function con_found : boolean;
function new_net(ports : integer; choice : boolean) : net;
procedure dispose_net(vnet : net);
function new_con(tnet : net; dirt : integer) : conn;
procedure dispose_con(vcon : conn);
procedure draw_port(mnet : net; col : integer);
procedure draw_to_port(tnet : net; port_number : integer);
procedure draw_ports(tnet : net);
procedure node_look;
procedure goto_port(port_number : integer);
procedure new_port(x,y : double; port_number : integer);
procedure Draw_Circuit;
function off_boardO(step_size : double) : boolean;
procedure Get_Key;
(*	Get_Key includes:
	procedure draw_cursorO;
	procedure erase_cursorO; 
	procedure ggotoxy(var cursor_displayed : boolean);   *)
procedure ground_node;
procedure unground;
procedure join_port(port_number,ivt : integer);

{*******************************************************************}

Implementation

procedure write_freqO;
{* 
	Write frequency in the plot window box 
		as the marker is moved.
	Makes it's own calculation to determine freq.
*}
begin
  TextCol(lightgray);
  if Alt_Sweep then 
      x_sweep.Label_Plot_Box
      { if alt_sweep put in x_sweep part label and unit label }
  else begin  {else put in 'f' and 'Hz'}
      GotoXY(xmin[2]+4,ymin[2]+2);
      Write('f');
      GotoXY(xmin[2]+16,ymin[2]+2);
      Write(freq_prefix,'Hz');
      { Frequency prefix (k,M,G,etc.) is freq_prefix }
  end;
  {Now write the number}
  freq:=fmin+xpt*finc;   {These parameters are all normalized}
  TextCol(green);
  GotoXY(xmin[2]+6,ymin[2]+2);   {was 40,20}
  Write(freq:8:4);
end; {write_freqO}


procedure write_sO(ij : integer);
{*	
	Write s-parameters in plot window box as marker is moved.
*}
var
  rho,lnrho,deg : double;

begin
  GotoXY(xmin[2]+5,ymin[2]+2+ij);   {was mgotoxy, was 43,20}
  rho:=sqr(c_plot[ij]^.x)+sqr(c_plot[ij]^.y);
  deg:=atan2(c_plot[ij]^.x,c_plot[ij]^.y);
  if rho>1.0e-10 then begin
     if rho<1.0e+10 then begin
        lnrho:=10*ln(rho)/ln10;
        if s_param_table[ij]^.descript[2]in['f','F'] then
                                             lnrho:=lnrho/2.0;
        Write(lnrho:7:2,'dB',deg:6:1,degree);
     end 
     else begin 
        Write('   ',infin,ity,'           ');
     end;	   
  end 
  else begin
     Write('   0            ');
  end;
end; {* Write_sO *}


Procedure HighLight_Window;
{*
	Causes F# key to be highlighted on the screen
	when that window has been selected.
*}
Begin
  GotoXY(window_f[window_number]^.xp+1,window_f[window_number]^.yp);
  TextCol(white);
  Write('F',window_number);   {highlight selected window}
end; {* Highlight_Window *}


Procedure Toggle_Circuit_Type;
{*
	Toggle between stripline and microstrip.
	Called by Board4 in PUFF20.
*}
Begin
  Board_Changed:=true;
  TextCol(lightgray);
  GotoXY(xmin[4],ymin[4]+6);
  Write('Tab  ');
  if Manhattan_Board then begin
        stripline:=true;
	Manhattan_Board:=false;
	Write('stripline ');
  end
  else if stripline then begin
  	stripline:=false;
	Write('microstrip');
  end
  else begin
  	Manhattan_Board:=true;
	stripline:=true; {make calculations easier}
	Write('Manhattan ');
  end;
end;



Procedure Write_Board_Parameters;
{*
	Write board parameter in screen area.
*}
var
  tcompt     : compt;



Begin
  Make_Text_Border(xmin[4]-1,ymin[4]-1,xmax[4]+1,ymax[4]+1,
  		   col_window[4],true);
  {erase and write border in board color}
  write_compt(col_window[4],window_f[4]);    {write BOARD Header}
  if board_start <> nil then begin
	tcompt:=nil;
	repeat
	   if tcompt=nil then tcompt:=board_start 
			 else tcompt:=tcompt^.next_compt;
	   write_compt(lightgray,tcompt);
	until tcompt^.next_compt=nil;
	TextCol(lightgray);
	GotoXY(xmin[4],ymin[4]+6);
	Write('Tab  ');
	if Manhattan_Board then Write('Manhattan ')
	 else if stripline then Write('stripline ')
  	 		   else Write('microstrip');
  end;
end; {* Write_Board_Parameters *}


procedure Write_Expanded_Parts;
{*
	Erase parts list area, write zd and fd,
	draw window box, list parts.
	Called only by Read_Net.
*}
var
  tcompt     : compt;

begin
  Make_Text_Border(xmin[3]-1,ymin[3]-1,xmax[5]+1,ymax[5]+1,
  	col_window[3],true);
  write_compt(col_window[3],window_f[3]);
  if (window_number=3) then Highlight_Window;
  if part_start <> nil then begin
	tcompt:=nil;
	repeat
	   if tcompt=nil then tcompt:=part_start
			 else tcompt:=tcompt^.next_compt;
	   write_compt(lightgray,tcompt);
	until tcompt^.next_compt=nil;
  end;
end; {* Write_Expanded_Parts *}


procedure Write_Parts_ListO;
{*
	Erase parts list area, write zd and fd,
	draw window box, list parts.
	Called only by Read_Net.
*}
var
  tcompt     : compt;
  y          : integer;



begin
  Make_Text_Border(xmin[3]-1,ymin[3]-1,xmax[3]+1,ymax[3]+1,
  	col_window[3],true);
  write_compt(col_window[3],window_f[3]);
  if part_start <> nil then begin
	tcompt:=nil;
	y:=ymin[3];
	repeat
	   if tcompt=nil then tcompt:=part_start 
			 else tcompt:=tcompt^.next_compt;
	   write_compt(lightgray,tcompt);
	   y:=y+1;
	until y=ymax[3]+1;
  end;
end; {* Write_Parts_ListO *}


Procedure Write_Plot_Prefix(time2 : boolean);
{* 
	Find the frequency or time unit prefix and write
	it in the plot window.
*}
const
  Freq_Prefix : string = 'EPTGMk m'+Mu+'npfa';
  Time_Prefix : string = 'afpn'+Mu+'m kMGTPE';

var  
  i : integer;

begin
  GotoXY(x_y_plot_text[5,1]+2,x_y_plot_text[5,2]);
  TextCol(lightgray);
  if time2 then begin
    i:=0;
    repeat i:=i+1 until (Freq_Prefix[i]=s_board[2,2]);
    {find index for frequency prefix}
    Write(Time_Prefix[i]); {write time prefix}
  end
  else 
    Write(s_board[2,2]); {write frequency prefix}
end; {* Write_Plot_Prefix *}


Procedure Write_Coordinates(time : boolean);
{*
	Write parameters in the plot window
*}

var
  i      : integer;
  tcompt : compt;
  temp   : line_string;

begin
  Inc(WindMax); {to prevent scrolling}
  if time then begin
     TextCol(lightgray);
     temp:=rho_fac_compt^.descript;
     Delete(temp,1,13);
     gotoxy(x_y_plot_text[1,1]-Length(temp),x_y_plot_text[1,2]);{was 56-}
     write(temp);
     temp:='-'+temp;
     gotoxy(x_y_plot_text[3,1]-Length(temp),x_y_plot_text[3,2]);
     write(temp);    {was 56-}
     gotoxy(x_y_plot_text[4,1],x_y_plot_text[4,2]);	
     write(sxmin:6:3);	{was 56,13}
     gotoxy(x_y_plot_text[6,1]-6,x_y_plot_text[6,2]);	
     write(sxmax:6:3);
     Gotoxy(x_y_plot_text[2,1],x_y_plot_text[2,2]);  
     write(' S');   		{was 53,6}
     gotoxy(x_y_plot_text[5,1],x_y_plot_text[5,2]); 
     write('t  sec');	{was 66,13}
  end 
  else begin
    for i:=1 to 10 do begin 
      if i=1 then tcompt:=coord_start 
      	     else tcompt:=tcompt^.next_compt;
      with tcompt^ do begin
        if right then xp:=xorig-Length(descript);
        if (length(descript) > x_block) or (i < 7) then begin
           write_compt(lightgray,tcompt);
           if i in [7..10] then 
	   	pattern(xmin[2]*charx-1,(ymin[2]+2+i-6)*chary-8,i-6,0);
	   	{write the marker patterns box, X, diamond, and +}
        end;
      end; {with}
    end; {for}
    TextCol(lightgray);
    Gotoxy(x_y_plot_text[2,1],x_y_plot_text[2,2]);  
    write(the_bar,'S',the_bar);  {was 53,6}
    gotoxy(x_y_plot_text[2,1],x_y_plot_text[2,2]+1);  
    write(' dB');		{was 53,7}
    if not(Alt_Sweep) then begin
    	gotoxy(x_y_plot_text[5,1],x_y_plot_text[5,2]); 
	write('f  Hz');
    end
    else
        x_sweep.Label_Axis;  {use alternate sweep data}
  end; {do_time}
  if not(Alt_Sweep) then Write_Plot_Prefix(time);  {write x-coordinate prefix}
  Dec(WindMax);  {Restore to normal scrolling}
end; {* Write_Coordinates *}


Procedure Write_BigSmith_Coordinates;
{*
	Write coordinates for the VGA Big Smith window

	Linked list for coordinates has been reduced to
	8 elements (no dBmax, dBmin).
*}

var
  i      : integer;
  tcompt : compt;


begin
  {Erase key area}
  clear_window(xmin[2],ymin[2],xmax[2],ymax[2]); {clear key area}
  TextCol(lightgray);
  Inc(WindMax); {to prevent scrolling}
  for i:=3 to 10 do begin
      if i=3 then tcompt:=coord_start 
      	     else tcompt:=tcompt^.next_compt;
      with tcompt^ do begin
        if right then xp:=xorig-Length(descript);
        if (length(descript) > x_block) or (i < 7) then begin
           write_compt(lightgray,tcompt);
           if i in [7..10] then 
	   	pattern(xmin[2]*charx-1,(ymin[2]+2+i-6)*chary-8,i-6,0);
	   	{write the marker patterns box, X, diamond, and +}
        end;
      end; {with}
  end; {for}
  TextCol(lightgray);
  Gotoxy(x_y_plot_text[4,1],x_y_plot_text[4,2]-1); 
  Write('Start');
  Gotoxy(x_y_plot_text[6,1]-4,x_y_plot_text[6,2]-1); 
  Write('Stop');
  if not(Alt_Sweep) then begin
     Gotoxy(x_y_plot_text[5,1],x_y_plot_text[5,2]); 
     Write('f  Hz');  	
     Write_Plot_Prefix(false);  {write x-coordinate prefix}
  end
  else
     x_sweep.Label_Axis;  {use alternate sweep data}    
  Dec(WindMax);  {Restore to normal scrolling}
end; {* Write_BigSmith_Coordinates *}


procedure restore_boxO(ij : integer);
{*
	Restore pixels that were covered by marker.
*}
var
  nb,k,xn,yn 	: integer;

begin
  for k:=0 to 1 do begin
    nb:=ij+k*max_params;
    if box_filled[nb] then begin
      xn:=box_dot[1,nb];
      yn:=box_dot[2,nb];
      PutBox(nb, xn-4, yn-4, 9, 9);
    end; {if box_filled}
  end; {for k}
end; {restore_boxO}


procedure move_boxO(xn,yn,nb : integer);
{*
	Move marker by first storing the dots that will be covered.
	EGA routine saves in an array.
*}



begin
  box_filled[nb]:=true;
  box_dot[1,nb]:=xn; 
  box_dot[2,nb]:=yn;
  GetBox(nb, xn-4, yn-4, 9, 9);
end; {move_boxO}


procedure draw_ticksO(x1,y1,x2,y2 : integer; incx,incy : double);
{*
	Draw ticks on rectangular plot.
*}
var
  i,xinc,yinc : integer;

begin
    SetLineStyle(UserBitLn,$8888,NormWidth); {was 8080}
    SetCol(Green);
    for i:=1 to 9 do begin
	xinc:=Round(i*(x2-x1)/10.0);
	yinc:=Round(i*(y2-y1)/5.0);
	Line(x1+xinc,y1-1,x1+xinc,y2);
	if (i<5) then Line(x1,y1+yinc,x2-1,y1+yinc);
    end; {for}
    SetLineStyle(SolidLn,0,NormWidth);
end; {draw_ticksO}


procedure Write_File_Name(fname : file_string);
{*
	Write file name above Parts.
	Remove any subdirectory information and .puf
*}
var
 i          : integer;
 temp_str   : string[19];

begin
  {Erase old file name}
  GotoXY(filename_position[1],filename_position[2]);
  for i:=filename_position[1] to filename_position[3] do write(' '); 
  {Remove dir from filename}
  Repeat
    i:=Pos('\',fname);
    if i > 0 then Delete(fname,1,i);
  Until i=0;
  {Write filename on screen} 
  temp_str:='file : '+fname;
  TextCol(col_window[1]);
  GotoXY(filename_position[1]+(filename_position[3]-filename_position[1]-Length(temp_str)) div 2,
  			filename_position[2]); 
  Write(temp_str);
end; {* Write_File_Name *}


procedure calc_posO(x,y,theta,scf: double; sfreq: integer; dash: boolean);
{*
	Given the complex s-parameter co(x,y):=rho find where the dot 
	should be plotted on screen. Plotting parameters which are 
	returned are (spx,spy) for the Smith plot and (spp) for the
	rectangular plot. Clipping is also performed here by checking
	the values of the returned parameters to see if they lie within
	the limits of symin,symax and xmin[8],xmax[8]. If not they are
	put at ymax[8] and ymin[8].

	Screen magnification set by:
	if its_EGA then scf:=1 else scf:=hir;
	in Smith_and_Magplot
*}
var
  p2,p3,p4 : double;

begin
   p2:=sqr(x)+sqr(y);
   if sqrt(p2)<1.02*rho_fac then begin
      spline_in_smith:=true;
      if abs(theta) > 0 then begin
          (**disabled*** 
	  thet:=theta*freq/design_freq;
	  sint:=sin(thet);  
	  cost:=cos(thet);
	  spx:=Round(centerx+(x*cost-y*sint)*rad/rho_fac);
	  spy:=Round((centery-(x*sint+y*cost)*rad*yf/rho_fac))*scf); 
	  **disabled***)
      end 
      else begin
	  spx:=Round(centerx+(x*rad/rho_fac));
	  spy:=Round((centery-(y*rad*yf/rho_fac))*scf);
      end;
   end 
   else 
     	spline_in_smith:=false;  {* end if sqrt(p2)<1.02*rho_fac *} 
   if p2 > 1.0/infty then begin  
 	p4 := Ln(p2);   {!*	was Ln_Asm
				When compiled in the $N+ mode this
				Ln function worked only intermitently. 
				The Ln function has therefore been 
				rewritten in assembler. *!}

	p3 := 10.0 * p4 / ln10 ; {10*log(p2)}
	p2:=p3;
   end
   else 
    	p2:=-1.0*infty;
   if betweenr(symin,p2,symax,sigma) then begin {check to see if it fits }
   	if not(Large_Smith) then spline_in_rect:=true;
        spp:=Round((ymax[8]-(p2-symin)*sfy1)*scf);
   end 
   else begin
        spline_in_rect:=false;
        if p2 > symax then 
     	     spp:=Round((ymin[8]-5)*scf)  {Put just at the top of the graph}
          else   		    { was ymin[8]-5 and ymax[8]+5 }
	     spp:=Round((ymax[8]+5)*scf); {Put at the bottom of the graph}
   end; {else}
   if dash and not(betweeni(xmin[8],sfreq,xmax[8])) then begin
      spline_in_rect:=false;
      spline_in_smith:=false;
   end;
end; {calc_posO}


{***********************************************************************}

PROCEDURE Smith_and_Magplot(lighten,dash,boxes : boolean);
{* 
	Plot s-parameter curves.  This is done after all
	the data points have been calculated
	from the Analysis procedure.

	Now includes Smith_PlotO, Rect_PlotO, SplineO
*}

var
  jxsdif,scf,cx1,cx2,cx3,cx4,cy1,
  cy2,cy3,cy4,sqfmfj,sqfjmf,fmfj,
  fjmf,spar1,spar2 			: double;
  sfreq,jfreq,j,nopts,ij,col,txpt 	: integer;
  line_s,line_r 			: boolean;
  cplt         				: plot_param;
  cspc         				: spline_param;

  	{****************************************************************}

  	procedure splineO(ij : integer);
	{*
	Calculate spline coefficients. 
	Johnson and Riess Numerical Analysis p41,241.
	*}

	var
		zx,zy,u : array[0..1000] of double;
		m,i     : integer;
		li      : double;
		cplt    : plot_param;
		cspc    : spline_param;

begin {SplineO}
  m:=npts-1;
  for i:=0 to m do begin
     if i=0 then begin
	cplt:=plot_start[ij];
	cspc:=spline_start;
     end 
     else begin
	cplt:=cplt^.next_p;
	cspc:=cspc^.next_c;
     end;
     with cspc^ do with cplt^ do begin
	h:=sqrt(sqr(yf*(next_p^.y-y))+sqr(next_p^.x-x));
	if h<0.000001 then h:=0.000001;
     end;
  end; {for i:=0 to m}
  spline_end:=cspc^.next_c;
  cplt:=plot_start[ij];
  cspc:=spline_start;
  u[1]:=2*(cspc^.next_c^.h+cspc^.h);                   {u_11=a_11}
  zx[1]:=6*((cplt^.next_p^.next_p^.x-cplt^.next_p^.x)/cspc^.next_c^.h
    -(cplt^.next_p^.x-cplt^.x)/cspc^.h);   {y_1=b_1}
  zy[1]:=6*((cplt^.next_p^.next_p^.y-cplt^.next_p^.y)/cspc^.next_c^.h
    -(cplt^.next_p^.y-cplt^.y)/cspc^.h);   {y_1=b_1}
  for i:= 2 to m do begin
      cplt:=cplt^.next_p;    
      cspc:=cspc^.next_c;
      with cspc^ do with cplt^ do begin
          li:=h/u[i-1];      {a_i-1i=a_ii-1=h_i-1,a_ii=2(h_i+h_i-1)}
	  u[i]:=2*(next_c^.h+h)-h*li;   {u_ii=a_ii-L_i.i-1a_i-1,i}
	  zx[i]:=6*((next_p^.next_p^.x-next_p^.x)/next_c^.h-
                	(next_p^.x-x)/h)-li*zx[i-1];                 {2.33}
	  zy[i]:=6*((next_p^.next_p^.y-next_p^.y)/next_c^.h-
                	(next_p^.y-y)/h)-li*zy[i-1];
      end; {with}
   end; {for i}
  cspc:=spline_end;    
  cspc^.sx:=0;            
  cspc^.sy:=0;
  cspc:=cspc^.prev_c;  
  cspc^.sx:=zx[m]/u[m];   
  cspc^.sy:=zy[m]/u[m];
  for i:=1 to m-1 do begin
      cspc:=cspc^.prev_c;
      with cspc^ do begin
          sx:=(zx[m-i]-h*next_c^.sx)/u[m-i];
	  sy:=(zy[m-i]-h*next_c^.sy)/u[m-i];
      end;
  end;
  cspc:=cspc^.prev_c;  
  cspc^.sx:=0;
  cspc^.sy:=0;
end; {splineO}

	{**************************************************************}

	procedure smith_plotO(x1,y1,col : integer; Var linex : boolean);
	{*
	     Plot curve on Smith plot
	*}
        begin {Smith_PlotO}
	  if spline_in_smith then begin 
	      if linex then begin
	        SetCol(col);
		Line(xvalo[1],yvalo[1],x1,y1);
	      end; {if linex}
              linex:=true;
          end {if spline_} 
          else 
	      linex:=false;
          xvalo[1]:=x1; 
          yvalo[1]:=y1;
        end; {smith_plotO}

	{************************************************************}

	procedure rect_plotO(x1,y1,col : integer;Var linex : boolean);
	{*
	Line plotting routine for making curves in
	the rectangular plot. y1 is usually equal to spp.
	*}

Begin {Rect_PlotO}
  SetViewPort(xmin[8],ymin[8]-1,xmax[8],ymax[8],true);
     { clip rectangular plot, plot with relative positioning, }
     { and reset the graphics pointer }
  if linex then begin
      SetCol(col);
      Line(xvalo[2]-xmin[8],yvalo[2]-ymin[8]+1,x1-xmin[8],y1-ymin[8]+1);
  end;
  linex:=true;
  SetViewPort(xmin[12],ymin[12],xmax[12],ymax[12],false); {Remove clipping}
  xvalo[2]:=x1;
  yvalo[2]:=y1;
end; {rect_plotO}

	{**********************************************************}

BEGIN  {* Smith_and_Magplot *}
  jxsdif:=sfx1*finc; {difference in x between plot points}
  scf:=1;
  if npts > 1 then
   for ij:=1 to max_params do
     if s_param_table[ij]^.calc then begin
	splineO(ij);
	col:=s_color[ij];  
	if lighten then col:=col-8;
	line_s:=false;     
	line_r:=false;
	for txpt:=0 to npts do begin
(*	   if keypressed then begin
		key := ReadKey;
		if key in['h','H'] then begin
		   message[2]:='      HALT       ';
		   write_message;
		   exit;
		end; {if key in}
		beep;
	   end;{if key_pressed}  *)
           if txpt=0 then begin
		cplt:=plot_start[ij];
		cspc:=spline_start;
	   end 
	   else begin
		cplt:=cplt^.next_p;
		cspc:=cspc^.next_c;
	   end;
           freq:=fmin+txpt*finc;
	   sfreq:=xmin[8]+Round((freq-sxmin)*sfx1);
	   if cplt^.filled then begin
		calc_posO(cplt^.x,cplt^.y,0,scf,sfreq,dash);
		if not(Large_Smith) then begin
		   rect_plotO(sfreq,spp,col,line_r);
		   if spline_in_rect and boxes then 
		   	box(sfreq,Round(spp/scf),ij);
		end;
		smith_plotO(spx,spy,col,line_s);
		if spline_in_smith and boxes then box(spx,Round(spy/scf),ij);
		if txpt < npts then
		   with cspc^ do with cplt^ do 	begin
			cx1:=sx/(6*h);   
			cx2:=next_c^.sx/(6*h);
			cy1:=sy/(6*h);   
			cy2:=next_c^.sy/(6*h);
			cx3:=next_p^.x/h-next_c^.sx*h/6;  
			cx4:=x/h-sx*h/6;
			cy3:=next_p^.y/h-next_c^.sy*h/6;  
			cy4:=y/h-sy*h/6;
			if h*rad/rho_fac>40 then nopts:=10 
                              else nopts:=Round(h*rad/(rho_fac*4))+1;
			for j:=1 to nopts-1 do begin
			   fmfj:=j*h/nopts;    
			   fjmf:=h-fmfj;
			   sqfmfj:=sqr(fmfj);  
			   sqfjmf:=sqr(fjmf);
			   spar1:=(cx1*sqfjmf+cx4)*fjmf
					+(cx2*sqfmfj+cx3)*fmfj;
			   spar2:=(cy1*sqfjmf+cy4)*fjmf
					+(cy2*sqfmfj+cy3)*fmfj;
			   jfreq:=Round(j*jxsdif/nopts);
			   calc_posO(spar1,spar2,0,scf,sfreq+jfreq,dash);
			   if not(Large_Smith) then
			         rect_plotO(sfreq+jfreq,spp,col,line_r);
			   smith_plotO(spx,spy,col,line_s);
			end; {j:=1 to nopts-1}
		    end;{if txpt}
		end;{if cpt^ filled}
	end;{for txpt}
  end; {ij}
END; {*Smith_and_Magplot*}

{***************************************************************************}
  

procedure Draw_Graph(x1,y1,x2,y2 : integer; time : boolean);
{*
	Draw rectangular graph.
*}
begin
  clear_window_gfx(xmin[11],ymin[11],xmax[11],ymax[11]);
  	{erase previous graph}

  if not(time) then 
	clear_window(xmin[2],ymin[2],xmax[2],ymax[2]); {clear key area}
  TextCol(lightgray);
  Write_Coordinates(time);
  draw_box(x1,y1,x2,y2,lightgreen);
  draw_ticksO(x1,y1,x2,y2,(x2-x1)/4.0,(y2-y1)/4.0);
end; {* Draw_Graph *}


{******************  START COMPONENT MANIPULATION   ****************}


procedure del_char(tcompt : compt);
{*
	Delete character -- Del.
*}
begin
  if (window_number=2) then Inc(WindMax); {prevent scrolling}
  tcompt^.changed:=true;
  delete(tcompt^.descript,cx+1,1);
  write_compt(lightgray,ccompt);
  write(' ');
  gotoxy(tcompt^.xp+cx,tcompt^.yp);
  if (window_number=2) then Dec(WindMax); {allow scrolling}
end; {del_char}


procedure back_char(tcompt : compt);
{*
	Backspace and delete character.
*}
begin
  if cx > tcompt^.x_block then begin
	gotoxy(tcompt^.xp+cx,tcompt^.yp);
	cx:=cx-1;
	del_char(tcompt);
  end;
end; {back_char}


procedure add_char(tcompt : compt);
{*
	Add character to parameter or part.
	Allows only 1..4 to be added to s-parameters
*}
var
  i,lendes 	: integer;
  an_s		: boolean;

begin
  TextCol(white);
  an_s:= false;
  for i:= 1 to 4 do begin
     if (s_param_table[i]=tcompt) then an_s:=true;  
  end;
  if an_s and not(key in [' ','1'..'4']) then beep 
  	{ignore if not 1..4 for S's}
  else with tcompt^ do begin
        if not(insert_key) then delete(descript,cx+1,1);
        insert(key,descript,cx+1);
	lendes:=length(descript) ;
	if lendes > xmaxl then begin
     	   erase_message;
	   message[2]:='Line too long';
	   delete(descript,lendes,1);
	   write_message;
        end;
	cx:=cx+1; 
	if cx > xmaxl then cx:=cx-1;
	if (window_number=2) then Inc(WindMax); {prevent scrolling}
	if right then
     	  if(xp+length(descript)-1 >= xorig) or (xp+cx >= xorig) then begin
		gotoxy(xorig-1,yp);
		write(' ');
		xp:=xp-1;
        end;
        write_compt(lightgray,tcompt);
        changed:=true;
        gotoxy(xp+cx,yp);
        if (window_number=2) then Dec(WindMax); {allow scrolling} 
  end; {else with tcompt}
end; {add_char}


procedure Choose_Part(ky : char);
{*
	Select one of the parts [a..r].
*}
var
  tcompt : compt;
  found  : boolean;

begin
  if ky in ['A'..'R'] then ky:=char(ord(ky)+32);
  tcompt:=nil; 
  found:=false;
  missing_part:=false;
  repeat
    if tcompt=nil then tcompt:=part_start 
    		  else tcompt:=tcompt^.next_compt;
    if (tcompt^.descript[1]=ky) and tcompt^.parsed then found:=true
  until (tcompt^.next_compt=nil) or found;
  if found and not((ky in ['j'..'r']) and not(Large_Parts)) then begin
	write_compt(lightgray,compt1);
	compt1:=tcompt;
	write_compt(white,compt1);    
  end 
  else begin
	message[1]:=ky+' is not a';
	message[2]:='valid part';
	update_key:=false;
	missing_part:=true;
  end;
end; {* Choose_Part *}

{*******************  CIRCUIT DRAWING Functions ******************}

Procedure Draw_Net(tnet : net);
{*
	Calls routine to draw net on circuit board.
	Drawing routines are in PFUN2
*}
begin
  lengthxy(tnet); 
  if read_kbd or demo_mode then
  case tnet^.com^.typ of
    't'  : Draw_tline(tnet,true,false);
    'q'  : Draw_tline(tnet,true,false);
    'l'  : Draw_tline(tnet,false,false);
    'x'  : Draw_xformer(tnet); {transformer}
    'a'  : Draw_tline(tnet,false,false); {attenuator}
    'd','i'  : Draw_device(tnet);
    'c'  : begin
             Draw_tline(tnet^.other_net,true,false);
             Draw_tline(tnet,true,true);
           end;
  end; {case}
end; {* Draw_Net *}


function con_found : boolean;
{*
	Looks for ccon on cnet in direction of arrow. 
	On exit cnet=network to remove or step over. 
	If ccon is connected to an external port then
	cnet is unchanged.
*}
var
  found : boolean;

begin
  ccon:=nil;
  found:=false; 
  port_dirn_used:=false;
  if cnet <> nil then begin
	repeat
	    if ccon = nil then ccon:=cnet^.con_start 
	    		  else ccon:=ccon^.next_con;
	    if (dirn and ccon^.dir) > 0 then found:=true;
	until found or (ccon^.next_con=nil);
	if found then begin
	    if ext_port(ccon) then begin
		message[1]:='Cannot go over';
		message[2]:='path to port';
		port_dirn_used:=true;
		update_key:=false;
	    end 
	    else     {* Delete to disallow "Paths over ports" *}
		cnet:=ccon^.mate^.net;
	end; {if found}
  end; {if cnet}
  con_found:=found;
end; {con_found}


function new_net(ports : integer; choice : boolean) : net;
{*
	Makes a new network on the end of the linked list.
	If choice then network is node else network is part.
*}
var
  tnet : net;

begin
  if net_start = nil then begin
	New_n(net_start);
	tnet:=net_start;
  end
  else begin
	tnet:=net_start;
	while tnet^.next_net <> nil do tnet:=tnet^.next_net;
	New_n(tnet^.next_net);
	tnet:=tnet^.next_net;
  end;
  with tnet^ do begin
	next_net:=nil;
	node:=choice;
	con_start:=nil;
	ports_connected:=0;
	number_of_con:=ports;
	xr:=xm;
	yr:=ym;
	if node then begin
	   grounded:=false;
	   com:=nil;
	end
	else
	   com:=compt1;
  end;{with}
  new_net:=tnet;
  if not(tnet^.node)then
  if compt1^.typ = 'c' then begin
	New_n(tnet^.other_net);
	tnet:=tnet^.other_net;
	with tnet^ do begin
	    com:=compt1;
	    dirn_xy;
	    xr:=xm+yii*compt1^.con_space;
	    yr:=ym+xii*compt1^.con_space;
	end; {with}
  end; {if ccompt1}
end; {new_net}

procedure dispose_net(vnet : net);
{*
	Remove a network form the linked list.
*}
var
  found : boolean;
  tnet  : net;

begin
  tnet:=nil;
  found:=false;
  repeat
    if tnet = nil then begin
	tnet:=net_start;
	if tnet=vnet then begin
		net_start:=net_start^.next_net;
		tnet:=net_start;
		found:=true;
	end {if tnet=vnet}
    end
    else begin {if tnet <> nil}
	if tnet^.next_net=vnet then begin
		found:=true;
		tnet^.next_net:=tnet^.next_net^.next_net
	end
	else
	     	tnet:=tnet^.next_net
    end {if tnet <> nil}
  until found or (tnet^.next_net=nil);
  if not(found) then begin
	message[2]:='dispose_net';
	shutdown;
  end;
end; {dispose_net}


function new_con(tnet : net; dirt : integer) : conn;
{*
	Make a new connector.
*}
var
  tcon : conn;

begin
  if tnet^.con_start=nil then begin
	New_conn(tnet^.con_start);
	tcon:=tnet^.con_start;
  end
  else begin
	tcon:=tnet^.con_start;
	while tcon^.next_con <> nil do tcon:=tcon^.next_con;
	New_conn(tcon^.next_con);
	tcon:=tcon^.next_con;
  end;
  with tcon^ do begin
	port_type:=0;
	next_con:=nil;
	net:=tnet;
	cxr:=xm; 
	dir:=dirt;
	cyr:=ym;
  end; {with tcon^}
  with tnet^ do
     if node and (number_of_con > 1) then begin
		xr:=(xr*(number_of_con-1)+xm)/number_of_con;
		yr:=(yr*(number_of_con-1)+ym)/number_of_con;
  end;
  new_con:=tcon;
end; {new_con}


procedure dispose_con(vcon : conn);
{*
	Dispose a connector.
*}
var
  found : boolean;
  tcon  : conn;
  vnet  : net;
  i     : integer;

begin
  tcon:=nil;
  found:=false;
  vnet:=vcon^.net;
  vnet^.number_of_con:=vnet^.number_of_con-1;
  if vnet^.number_of_con=0 then
      dispose_net(vnet)
  else begin
    repeat
	if tcon = nil then begin
	   tcon:=vnet^.con_start;
	   if tcon=vcon then begin
		vnet^.con_start:=vcon^.next_con;
		found:=true
	   end
	end
	else begin
	   if tcon^.next_con=vcon then begin
		found:=true;
		tcon^.next_con:=tcon^.next_con^.next_con
	   end
	   else
		tcon:=tcon^.next_con
	end;
    until found or (tcon^.next_con=nil);
    if not(found) then begin
	message[2]:='dispose_con';
	shutdown;
    end;
  end; {if vcon}
  with vnet^ do
  if node and (number_of_con > 0) then
  for i:=1 to number_of_con do begin
	if i=1 then begin
	    tcon:=vnet^.con_start;
	    xr:=0;
	    yr:=0;
	end
	else
	    tcon:=tcon^.next_con;
	xr:=xr+tcon^.cxr/number_of_con;
	yr:=yr+tcon^.cyr/number_of_con;
   end; {for i}
end; {dispose_con}


Procedure Draw_Port(mnet : net; col : integer);
{*
	Draws a small box and number for an external port.
*}
var
  x,y,i,yj : integer;

begin
  SetCol(col);
  x:=xmin[1]+Round(mnet^.xr/csx);
  y:=ymin[1]+Round(mnet^.yr/csy);
  i:=0; yj:=0;
  case mnet^.ports_connected of
    	1,3 : begin
		SetTextJustify(RightText,CenterText);  {i:= 0;}
		i:=-3;
	      end;
	2,4 : begin
		SetTextJustify(LeftText,CenterText);  {i:= 2;}
		i:=5;
	      end;
  end; {case}
  yj:=y;
  OutTextXY(x+i,yj,Chr(48+mnet^.ports_connected)); {write number}
  fill_box(x-2,y-2,x+2,y+2,col);
end; {draw_port}


procedure draw_to_port(tnet : net; port_number : integer);
{*
	Draws a connectinon to an external port.
*}
var
  xp,yp,offset,xli,yli,xsn,ysn : integer;

begin
  portnet[port_number]^.node:=true;
  xsn:=cwidthxZ02;
  ysn:=cwidthyZ02;
  case port_number of
    1,3 : offset:= 2;
    2,4 : begin 
    	    offset:=-2; 
    	    xsn:=-xsn  
	  end;
  end;{case}
  xli:=Round(tnet^.xr/csx)+xmin[1];
  yli:=Round(tnet^.yr/csy)+ymin[1];
  xp:=Round(portnet[port_number]^.xr/csx)+offset+xmin[1];
  yp:=Round(portnet[port_number]^.yr/csy)+ymin[1];
  if yli < yp then ysn:=-ysn;
  if abs(tnet^.yr - portnet[port_number]^.yr) < widthz0/2.0 then begin
	puff_draw(xp,yp+ysn,xli,yp+ysn,lightgray);
	puff_draw(xli,yp-ysn,xli,yp+ysn,lightgray);
	puff_draw(xp,yp-ysn,xli,yp-ysn,lightgray);
  end 
  else begin
	puff_draw(xli-xsn,yli,xli+xsn,yli,lightgray);
	puff_draw(xli+xsn,yli,xli+xsn,yp,lightgray);
	puff_draw(xli+xsn,yp,xli,yp-ysn,lightgray);
	puff_draw(xli,yp-ysn,xp,yp-ysn,lightgray);
	puff_draw(xp,yp+ysn,xli-xsn,yp+ysn,lightgray);
	puff_draw(xli-xsn,yp+ysn,xli-xsn,yli,lightgray);
  end;
  Draw_port(portnet[port_number],LightRed)
end; {draw_to_port}


procedure draw_ports(tnet : net);
{*
	Loops over tnet's connections to external ports.
*}
var
  tcon : conn;

begin
  tcon:=nil;
  repeat
     if tcon=nil then tcon:=tnet^.con_start 
    	  	 else tcon:=tcon^.next_con;
     if ext_port(tcon) then draw_to_port(tnet,tcon^.port_type);
  until tcon^.next_con=nil;
end; {draw_ports}


procedure node_look;
{*
	Looks for a node at current cursor postion.
*}
var
  tnet : net;

begin
  cnet:=nil;
  tnet:=nil;
  if net_start <> nil then
   repeat
     if tnet = nil then tnet:=net_start 
     		   else tnet:=tnet^.next_net;
     with tnet^ do
       if (con_start <> NIL) THEN
       begin
         if (abs(con_start^.cxr-xm)< resln) and node and
             (abs(con_start^.cyr-ym)< resln) then begin
	    	  cnet:=tnet;
		  exit;
         end;
       end;
  until tnet^.next_net=nil;
end; {node_look}


procedure goto_port(port_number : integer);
{*
	Go to an external port.
*}
begin
  xm := portnet[port_number]^.xr;     
  ym := portnet[port_number]^.yr;
  if port_number=0 then begin
	xrold:=xm;  
	yrold:=ym;
  end;
  xi:=Round(xm/csx); 
  yi:=Round(ym/csy);
  node_look;
end; {goto_port}


procedure new_port(x,y : double; port_number : integer);
{*
	Make a new external port.
*}
begin
  New_n(portnet[port_number]);
  with portnet[port_number]^ do begin
	next_net:=nil;
	number_of_con:=0;
	con_start:=nil;
	xr:=x;
	yr:=y;
	ports_connected:=port_number;
	node:=false; {not_connected yet}
  end; {with}
end; {new port}


procedure Draw_Circuit;
{* 
	Draw the entire circuit.
*}
var
  tnet 		: net;
  port_number,
  xb,yb,xo,yo   : integer;

begin
  xo:=xmin[1];  
  xb:=Round(bmax/csx)+xo;
  yo:=ymin[1];     
  yb:=Round(bmax/csy)+yo;

  {* Clear Layout screen *}
  clear_window_gfx(xmin[9],ymin[9],xmax[9],ymax[9]);
  Draw_Box(xo,yo-7,xb,yb+2,col_window[1]);  
  Draw_Box(xo,yo-5,xb,yb,col_window[1]);
  {* Draw double box to look like text border *}
  Write_Compt(col_window[1],window_f[1]);
  {* write "LAYOUT" header *}
  if net_start= nil then begin
	new_port(bmax/2.0,bmax/2.0,0);
	new_port(0.0,(bmax-con_sep)/2.0,1);
	new_port(bmax,(bmax-con_sep)/2.0,2);
	min_ports:=2; 
	if con_sep <> 0 then begin
		new_port(0.0,(bmax+con_sep)/2.0,3);
		new_port(bmax,(bmax+con_sep)/2.0,4);
		min_ports:=4;
	end;
  end; {if net_start}
  for port_number:=1 to min_ports do 
  	draw_port(portnet[port_number],Brown);
  if net_start <> nil then begin
	tnet:=nil; 
	iv:=1;
	repeat
	  if tnet=nil then tnet:=net_start 
	  	      else tnet:=tnet^.next_net;
	  dirn:=tnet^.con_start^.dir;
	  if tnet^.node then begin
	      if tnet^.grounded then draw_groundO(tnet^.xr,tnet^.yr)
	  end 
	  else 
	      Draw_Net(tnet);
	until tnet^.next_net = nil;
	tnet:=nil;
	repeat
	  if tnet=nil then tnet:=net_start 
	  	      else tnet:=tnet^.next_net;
	  if tnet^.ports_connected > 0 then draw_ports(tnet);
	until tnet^.next_net = nil;
	xi:=Round(xm/csx);
	yi:=Round(ym/csy);
  end 
  else {if net_start=nil}
     	goto_port(0);
end; {draw_circuit}


function off_boardO(step_size : double) : boolean;
{*
	Check to see if part will fit on circuit board.
*}
var
  xrep,yrep,xrem,yrem : double;
  off_boardt   : boolean;

begin
  dirn_xy;
  with compt1^ do
    if step_size=1 then begin
	xrep:=xm+lngth*xii+yii*(width/2.0+con_space);
	yrep:=ym+lngth*yii+xii*(width/2.0+con_space);
	xrem:=xm+lngth*xii-yii*width/2.0;
	yrem:=ym+lngth*yii-xii*width/2.0;
	if betweenr(0,xrep,bmax,0) and betweenr(0,yrep,bmax,0)
		and betweenr(0,xrem,bmax,0) and betweenr(0,yrem,bmax,0)
		then off_boardt:=false 
		else off_boardt:=true;
    end 
    else begin {if step_size<>1} 
	xrep:=xm+(lngth*xii+yii*con_space)/2.0;
	yrep:=ym+(lngth*yii+xii*con_space)/2.0;
	if  betweenr(0,xrep,bmax,0) and betweenr(0,yrep,bmax,0)
		then off_boardt:=false 
		else off_boardt:=true;
  end; {else,with}
  if off_boardt then begin
	if not(read_kbd) then begin
		key:=F3;
		read_kbd:=true;
		compt3:=compt1; 
		cx3:=compt3^.x_block;
		draw_circuit;
	end;
	erase_message;
	message[1]:='The part lies';
	message[2]:='outside the board';
	update_key:=false;
  end; {if off_}
  off_boardO:=off_boardt;
end; {off_boardO}

{*********************************************************************}

PROCEDURE Get_Key;
{*
	Get key from keyboard. See Turbo manual Appendix K.

	Includes Draw_Cursor, Erase_Cursor, and Ggotoxy
*}
label
  end_blink;

var
  cursor_displayed 	: boolean;
  key_ord		: integer;




  		{***************************************************}

Procedure Draw_Cursor;
{*
	Draw circuit cursor X by first storing
	the dots that will be covered.
*}
var
  i,j,x_ii,y_ii,xo,yo	: integer;

begin
  cross_dot[1]:=xi+xmin[1];
  cross_dot[2]:=yi+ymin[1];
  j:=4;
  xo:=cross_dot[1];
  yo:=cross_dot[2];
  GetBox(0, xo-5, yo-4, 11, 9);
  PutPixel(xo,yo,white);
  x_ii:=1;
  y_ii:=1;
  for i:=1 to 8 do begin
    PutPixel(xo+x_ii,yo+y_ii,white);
    PutPixel(xo+x_ii,yo-y_ii,white);
    PutPixel(xo-x_ii,yo+y_ii,white);
    PutPixel(xo-x_ii,yo-y_ii,white);
    if odd(i) then x_ii:=x_ii+1
      else y_ii:=y_ii+1;
    j:=j+4;
  end;
end; {Draw_Cursor}

		{*****************************************************}

Procedure Erase_Cursor;
{*
	Erase cursor and restore covered pixels.
*}
var
  xo,yo  :integer;

begin
  xo:=cross_dot[1];
  yo:=cross_dot[2];
  PutBox(0, xo-5, yo-4, 11, 9);
end; {Erase_Cursor}

		{******************************************************}

Procedure ggotoxy(var cursor_displayed : boolean);
{*
	Activate flashing cursor.
*}
var
  x,y,i,imax : integer;

begin
  if ccompt <> nil then begin
     x:=ccompt^.xp+cx;
     if (x > Max_Text_X) then x:=Max_Text_X;
     y:=ccompt^.yp;
     if cursor_displayed then begin
        Inc(WindMax); {prevent scrolling}
      	TextCol(lightgray);
        IF (cx >= length(ccompt^.descript)) THEN
          Write(' ')
        ELSE
          Write(ccompt^.descript[cx+1]);
	GotoXY(x,y);
        Dec(WindMax); {allow scrolling}
     end
     else begin
      	GotoXY(x,y);
	if insert_key then imax:=6
		      else imax:=2;
	SetCol(white);
	for i:=imin to imax do
	  Line(charx*(x-1),chary*y-i-2,charx*x-2,chary*y-i-2);
     end; {if cursor_displayed}
     cursor_displayed:=not(cursor_displayed);
  end; {if ccompt <> nil}
end; {ggotoxy}

		{********************************************************}

BEGIN  {* Get_Key *}
  if read_kbd then begin
    if demo_mode then begin
      	readln(key_ord);
	key:=char(key_ord)
    end
    else begin
	cursor_displayed:=false;
	if window_number=1 then Draw_Cursor
			   else ggotoxy(cursor_displayed);
	if not(keypressed) then 		{blink cursor}
	  if window_number <> 1 then
		repeat
                    Delay (200);
                    if  keypressed then goto end_blink;
		    ggotoxy(cursor_displayed);
		until false;
	end_blink:
  	key := ReadKey;
	if key=Alt_o then key:=Omega;  {Ohms symbol}
	if key=Alt_d then key:=Degree;
	if (window_number=2) then begin
	   if key=Alt_s then key:=Mu;
	end
	else
	   if key=Alt_m then key:=Mu;  {! conflict with sh_down}
	   if key=Alt_p then key:=Parallel;
	   if window_number=1 then
    		Erase_Cursor
             else
	        if cursor_displayed then ggotoxy(cursor_displayed);
    end; {if demo}
  end   {if read_kbd}
  else begin    {redraw_circuit}
     if key_i > 0 then
	if key_list[key_i].noden <> node_number then begin
		key:=F3;
		read_kbd:=true;
		compt3:=compt1; 
		cx3:=compt3^.x_block;
		draw_circuit;
		message[1]:='Circuit changed';
		message[2]:='Edit part or';
		message[3]:='erase circuit';
		exit;
	end;
	key_i:=key_i+1;
	if key_i > key_end then begin {end of redraw}
		read_kbd:=true;
		key:=key_o;
		circuit_changed:=false;
		board_changed:=false;
		draw_circuit;
	end 
	else 
		key:=key_list[key_i].keyl;  
		{Apply appropriate draw function from keylist} 
  end; {read_kbd}
END; {* Get_Key *}

{*****************************************************************}

procedure ground_node;
{*
	Ground a node.
*}
begin
  if cnet <> nil then with cnet^ do
	if not(grounded) then begin
		grounded:=true;
		draw_groundO(xr,yr);
  end;
end; {ground_node}


procedure unground;
{*
	Remove a ground.
*}
begin
  if cnet <> nil then with cnet^ do
	if grounded then begin
		grounded:=false;
		if read_kbd then draw_circuit;
  end;
end; {unground}


procedure join_port(port_number,ivt : integer);
{*
	Join cnet to an external port.
*}
var
  found : boolean;
  tcon  : conn;
  dirt  : integer;

begin
  if port_number <= min_ports then
    if ivt=1 then begin {connect}
	if ym > portnet[port_number]^.yr then dirt:=1 
					 else dirt:=8;
	if abs(ym - portnet[port_number]^.yr) < widthz0/2.0 then
		case port_number of
		   1,3 : dirt:=4;
		   2,4 : dirt:=2;
		end; {case}
	if not(portnet[port_number]^.node) then	begin
		if cnet = nil then cnet:=new_net(0,true);
		portnet[port_number]^.node:=true;
		if read_kbd or demo_mode then draw_to_port(cnet,port_number);
		tcon:=new_con(cnet,dirt);
		cnet^.ports_connected:=cnet^.ports_connected+1;
		tcon^.port_type:=port_number;
		tcon^.mate:=nil;
		cnet^.number_of_con:= cnet^.number_of_con+1;
	end 
	else begin
		message[1]:='Port '+char(port_number+ord('0'))+' is';
		message[2]:='already joined';
	end;
    end 
    else begin     {erase}
        iv:=0;     {added for dx_dy}
	tcon:=nil;
	found:=false;
	if cnet <> nil then
		repeat
		  if tcon = nil then tcon:=cnet^.con_start 
		  		else tcon:=tcon^.next_con;
		  if tcon^.port_type=port_number then found:=true;
		until found or (tcon^.next_con=nil);
        if found then begin
		cnet^.ports_connected:=cnet^.ports_connected-1;
		dispose_con(tcon);
		Node_Look;
		portnet[port_number]^.node:=false;
		if read_kbd then Draw_Circuit;
	end 
	else 
	    	Goto_Port(port_number);
    end; {else ivt}
end; {join_port}

End.
