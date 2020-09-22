{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking}


Unit pfun1;

(*********************************************************************

	UNIT PFUN1.PAS

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer.

        Modifications for Linux compilation 2000-2007 Pieter-Tjerk de Boer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.


	Contents: 	Variable declarations, constants, and types
			Graphics Routines, message routines,
			complex math, microstip and stripline
			models, parsing routines.

	Potentially buggy code is noted by {!xxx} comments

**********************************************************************)

Interface

Uses
  Dos, 		{Unit found in Free Pascal RTL's}
  Printer, 	{Unit found in Free Pascal RTL's}
  LazFileUtils,
  xgraph;	{Custom replacement unit for TUBO's "Crt" and "Graph" units}


CONST
{* The following constants are the keyboard return codes.
   See Turbo Manual Appendix K.
   For the extended codes 27 XX, key=#128+XX 		*}
 not_esc=#0;     Ctrl_a=#1;     Ctrl_d=#4;     Ctrl_e=#5;    backspace=#8;
 Ctrl_n=#14;     Ctrl_p=#16;    Ctrl_r=#18;    Ctrl_s=#19;   Ctrl_c=#3;
 Ctrl_q=#17;
 Esc=#27;        sh_1=#33;       sh_3=#35;    sh_4=#36;      sh_2=#64;
 Alt_o=#152;     Alt_d=#160;    Alt_m=#178;   Alt_p=#153;    Tab=#9;
 sh_down=#178;  sh_left=#180;  sh_right=#182; sh_up=#184;   C_R=#13;
 F1=#187;        F2=#188;       F3=#189;    shift_F3=#214;    F4=#190;
 F5=#191;	 F6=#192;	shift_F5=#216;  F10=#196;   Alt_s=#159;
 up_arrow=#200;  PgUp=#201;     left_arrow=#203; right_arrow=#205;
 down_arrow=#208;PgDn=#209;    Ins=#210;       Del=#211;
 screenresize=#255; { pseudo key, used to report a screen size change in the Linux version }
 {The following characters refer to extended graphics character set}
 {Lambda=#128;} Delta=#235; {Shift_arrow=#130;} the_bar=#179;
 {ground=#132;} infin=#236; ity=#32;
 Parallel=#186; Mu=#230;  Omega=#234; Degree=#248;
 lbrack=#123; rbrack=#125;

 des_len=22;

 {* Number of parts in parts list *}
 max_net_size=9;
 {* Conv_size is maximum matrix size for sdevice et al.*}
 Conv_size=9;

 col_window :array[1..4] of integer=(Lightcyan,Lightgreen,Yellow,Lightblue);
 s_color    :array[1..4] of integer=(Lightred,Lightcyan,Lightblue,Yellow);
 {* Engineering Decimal multipliers *}
 Eng_Dec_Mux : set of char=['E','P','T','G','M','k',
 				'm', Mu,'n','p','f','a'];
 charx=8;
 chary=14;
 key_max=2000;
 max_ports=4;
 max_params=4;

 one:double=0.999999999998765;         {* Attenuation factor for tee's, crosses,
 			           shorts, opens and negative resistors  *}
 minus2 :  integer = -2;        {* Global const needed by the Assembler
 				   Routines for Sine_Asm, Cos_Asm 	*}
 ln10   :  double = 2.302585092994045684;
 Pi     :  double = 3.141592653;  {* Use only 10 digits of Pi to *}
 infty  :  double = 1.0e+37;      {* ensure numerical stability  *}
 nft=256;    			{* Number of FFT points *}
 c_in_mm:double = 3.0e+11;             {* Speed of light in mm/s *}
 Mu_0:double    = 1.25664e-6;		{* Permeability of free space H/m *}

(***** Temp Circuit Board constants ***************)


(**************************************************)

TYPE
 textfile     = text;
 line_string  = String[des_len];
 file_string  = String[127];
 char_s       = array[1..112] of byte;


{* POINTER Types *}

 s_param      = ^s_parameter_record;
 plot_param   = ^plot_record;
 spline_param = ^spline_record;
 net          = ^net_record;
 conn         = ^connector_record;
 compt        = ^compt_record;

 marker       = RECORD
   Used: LONGINT;
 END;


{********************* PUFF DATA STRUCTURES ****************}

 TComplex = record
   r,i : double; 	{! This was changed from a real for speed increase}
 end;

 PMemComplex = ^TMemComplex;
 TMemComplex = RECORD
   c: TComplex;
 END;

 s_parameter_record = RECORD
   z          : PMemComplex;
   next_s     : s_param;
 end;

 plot_record = RECORD
   next_p,prev_p : plot_param;
   filled        : boolean;
   x,y           : double;
 end;

 spline_record = RECORD
   next_c,prev_c : spline_param;
   sx,sy,h       : double;
 end;

 net_record = RECORD
    com                   : compt;
    con_start             : conn;
    xr,yr                 : double; {postion in mm}
    node,chamfer,grounded : boolean;
    next_net,other_net    : net;
    nx1,nx2,ny1,ny2,
    number_of_con,nodet,
    ports_connected 	  : integer;
  end;

 connector_record = RECORD
   port_type,conn_no : integer; {0 norm 1... max_port external 5,6 internal}
   cxr,cyr           : double;    {position in mm}
   dir               : byte;
   net               : net;
   next_con,mate     : conn;
   s_start           : s_param;
 end;

 compt_record = RECORD
   lngth,width,zed,zedo,init_ere,
   alpha_c,alpha_d,alpha_co,alpha_do,
   lngth0,wavelength,wavelengtho,
   zed_e0,zed_o0,zed_S_e0,zed_S_o0,
   e_eff_e0,e_eff_o0,
   u_even,u_odd,g_fac,
   con_space,spec_freq 			: double;
   xp,xmaxl,x_block,
   xorig,yp,number_of_con,used        	: integer;
   s_begin,s_file,s_ifile,f_file        : s_param;
   calc,changed,right,super,
   parsed,step,sweep_compt	 	: boolean;
   next_compt,prev_compt     		: compt;
   descript                  		: line_string;
   typ                       		: char;
 end;

 key_record = record
   keyl      : char;
   noden     : integer;
 end;

{* The following types are defined for S parameter conversions: *}
{* Conv_size is currently set to 9 *}
 s_conv_matrix = array [1..conv_size,1..conv_size] of TComplex;
 s_conv_vector = array [1..conv_size] of TComplex;
 s_conv_index  = array [1..conv_size] of integer;

{**************** PUFF OBJECTS **********************}

 Sweep = Object
   element		   : compt;   {pointer to part}
   id,prefix,units  	   : char;    {ident, prefix and units}
   part_label,unit_label   : string[6]; {labels for plot window}
   prop_const1,prop_const2 : double;  {Proportionality constants}
   index	 	   : integer; {Part type index}
   Omega0,new_value	   : double; {angular frequency at fd and new value}
   used 	 	   : boolean; {has sweep been used?}
   Procedure Init_Use;
   Procedure Init_Element(tcompt : compt; in_id,in_prefix,in_unit : char);
   Procedure Check_Reset(tcompt : compt);
   Procedure Label_Axis;
   Procedure Label_Plot_Box;
   Procedure Load_Prop_Const(const prop_consta,prop_constb : double);
   Procedure Load_Index(i : integer);
   Procedure Load_Data(const sweep_data : double);
 end; {sweep object}




{**************** PUFF VARIABLES ********************}

VAR
 co1           : TComplex;                     {1+j0}
 c_s           : s_param;
 conk,ccon     : conn;
 sresln        : string[9];
 big_text_buf  : array[1..2048] of char; { 2k buffer for net_ and dev_ files}
 sdevice       : s_conv_matrix;
 x_sweep       : sweep;    {x_sweep is the object with x-y plot information}
 iji           : array[1..16,1..2] of integer;
 key_list      : array[1..key_max] of key_record;{List decribing circuit}
 board         : array[1..16] of boolean;        {used in reading board setup}
 s_key         : array[1..10] of line_string;    {plot window paramters}
 s_board       : array[1..12,1..2] of line_string;{board window parameters}
 s_param_table : array[1..max_params] of compt;  {Which s-params to plot}
 xvalo,yvalo   : array[1..4] of integer;         {used by plotting in rcplot}
 cross_dot     : array[1..35] of integer;        {Dot colors under cross}
 box_dot       : array[1..26,0..8] of integer;   {Dot colors under markers}
 box_filled    : array[1..8] of boolean;         {true if box_dot set}
 portnet       : array[0..max_ports] of net;     {Record of port}
 inp,out       : array[1..max_ports] of boolean; {Is port input or output?}
 si,sj         : array[1..max_ports] of integer;
 mate_node     : array[1..4] of net;             {used in layout of clines}
 message       : array[1..3] of file_string;     {Displayed message}

 {* The following graphics variables were constants in Puff 1.5 *}

 xmin : array[1..12] of integer;{These were constants in the EGA version}
 ymin : array[1..12] of integer;{They contain both text and graphics}
 xmax : array[1..12] of integer;{positions for each of the windows}
 ymax : array[1..12] of integer;
 centerx, centery, rad  : integer;  {Smith chart position variables}
 Max_Text_X : integer;   {Needed for extra wide windows on Linux}
 Max_Text_Y : integer;   {Used for 25/34 line EGA/VGA switch}
 yf   : double;   {used to specify aspect ratios}
 x_y_plot_text  : array[1..6,1..2] of integer;
 filename_position  : array[1..3] of integer;
 checking_position,
 layout_position     : array[1..2] of integer;

 puff_file     : file_string;

 net_file,dev_file       : textfile;
 command_f,window_f      : array[1..4] of compt; {was 1..3}
 spline_start,spline_end : spline_param;  {Start and end of list of s-params}
 dirn{,cursor_char}        : byte;          {dirn 1=North 2=East 4=West 8=South}
 name,network_name       : line_string;   {Names put on artwork}
 key,key_o,
 chs,previous_key,         	  {keys for linked list}
 freq_prefix	         : char;  {prefix for design_freq}
 plot_start,plot_end,
 c_plot,plot_des 	 : array[1..max_params] of plot_param;
                                    {start, end, current and design s-params}
 net_beg,		 {Mark() beginning of network for later release}
 dev_beg		 {Mark() beginning of device file data for release}
 			 : marker;

 Box_Sv_Pntr		 : Array [1..8] of Pointer;
 Box_Sv_Size		 : Array [1..8] of Word;

 fmin,finc,              {frequency minimum,frequency increment}
 Z0,                     {characteristic impedance}
 rho_fac,                {radius factor of smith chart}
 q_fac,                  {fd/df=Q}
 resln,                  {resolution of circuit drawing in mm}
 sfx1,sfy1,              {scale factors for pixels for circuit drawing}
 xrold,yrold,sigma,
 sxmax,sxmin,
 symax,symin,		 {max and min values on rectangular plot}
 reduction,              {photographic reduction ratio}
 er,                     {relative substrate dielectric constant}
 bmax,                   {substrate board size in mm}
 substrate_h,            {substrate thickness}
 con_sep,                {connector seperation}
 freq,design_freq,	 {current frequency and design frequency in GHz}
 Rs_at_fd,		 {Sheet resistance at design frequency}
 Lambda_fd,		 {Wavelength in mm, in air, at design freq}
 xm,ym,                  {circuit cursor postion in mm}
 psx,psy,csx,csy,
 artwork_cor,
 miter_fraction,
 widthZ0,                {width of normalizing impedance}
 lengthxm,lengthym,      {length in x and y current part}
 Manh_length,		 {Manhattan layout length - read_board}
 Manh_width,		 {Manhattan layout width - read_board}
 conductivity,		 {units are mhos/meter}
 loss_tangent,           {for dielectric, unitless}
 metal_thickness,  	 {in millimeters}
 surface_roughness       {in micrometers}
 			 : double;

 cwidthxZ02,cwidthyZ02,
 pwidthxZ02,pwidthyZ02,  {screen and mask half width Z0}
 message_color,          {color in message block}
 key_i,key_end,
 xi,xii,yi,yii,
 window_number,          {current window number}
 ptmax,                  {maximum number of graph points}
 spx,spy,spp,            {Re(s),Im(s),|s| dot position}
 displayo,display,
 Art_Form,		 {0 if dot-matrix, 1 LaserJet, 2 HPGL}
 idb,iv,xpt,
 npts,cx,cx3,
 min_ports,imin,
 OrigMode,		{used to remember initial text mode}
 GraphDriver,GraphMode	{Used for graphics initialization}
 			: integer;

 blackwhite: boolean;

 read_kbd,board_read,
 insert_key,
 step_fn,stripline,
 update_key,
 spline_in_rect,
 spline_in_smith,
 Laser_Art,		{True if LaserJet printer selected}
 filled_OK,remain,
 admit_chart,		{admittance smith chart flag}
 circuit_changed,
 board_changed,
 marker_OK,p_labels,
 bad_compt,action,
 demo_mode,
 help_displayed,	{is help window currently displayed?}
 port_dirn_used,
 Extra_Parts_Used,      {True when a part j..r has been used for layout}
 Large_Parts,		{true when extra parts are selected}
 Large_Smith,		{is large Smith chart enabled? VGA only}
 Alt_Sweep, 		{do alternate parameter sweep}
 Manhattan_Board,	{Draw all parts in Manhattan Geometry}
 missing_part		{True if part used in layout was deleted}
			: boolean;

 Points_compt,rho_fac_compt,
 part_start,coord_start,
 board_start,
 ccompt,compt1,compt3,
 dBmax_ptr,
 fmin_ptr		: compt;

 netK,netL,cnet,
 net_start      	: net;

{***** INTERFACE List of Functions and Procedures to be Public *****}

procedure puff_draw(x1,y1,x2,y2,color : integer);
procedure Draw_Box(xs,ys,xm,ym,color : integer);
procedure Make_Text_Border(x1,y1,x2,y2,colour: integer; single : boolean);
procedure fill_box(x1,y1,x2,y2,color : integer);
procedure clear_window(x1, y1, x2, y2 : integer);
procedure clear_window_gfx(x1, y1, x2, y2 : integer);
procedure pattern(x1,y1,ij,pij : integer);
procedure box(x,y,ij : integer);
procedure write_compt(color : integer; tcompt : compt);
procedure write_comptm(m,color : integer; tcompt : compt);
procedure beep;
procedure rcdelay(j : integer);
procedure write_message;
procedure erase_message;
procedure write_error(const time : double);
function input_string(const mess1,mess2 : line_string) : file_string;
procedure dirn_xy;
procedure increment_pos(i : integer);
procedure lengthxy(tnet : net);
function betweenr(const x1,x2,x3,sigma : double) : boolean;
function betweeni(x1,x2,x3 : integer) : boolean;
function ext_port(tcon : conn) : boolean;

(****** These were sine_asm, cosine_asm, ln_asm ****
function Sin_387(theta_in : extended) :extended;
function Cos_387(theta_in : extended) : extended;
function Ln_387(arg_in : extended) : extended;
************* removed for 5.5 testing *****************)
{* Complex Arithmetic *}
procedure prp(var vu: TComplex; const vX,vY : Tcomplex);
procedure supr(var vu: TComplex; const vX,vY : TComplex);
procedure co(var co: TComplex; const s,t : double);
procedure di(var di: TComplex; const s,t : Tcomplex);
procedure su(var su: TComplex; const s,t : Tcomplex);
procedure rc(var rc: TComplex; const z : Tcomplex);
procedure sm(var sm: TComplex; const s : double; const t : Tcomplex);
function co_mag(const z : Tcomplex) : double;
{* Parsing utilities *}
function Eng_Prefix(c : char) : double;
function Manhattan(tcompt : compt) : boolean;
function super_line(tcompt : compt) : boolean;
function goto_numeral(n : integer; x : line_string) : integer;
function Get_Real(tcompt : compt; n : integer) : double;
procedure Get_Param(tcompt : compt; n : integer; var value : double;
 var value_string: line_string; var u1,prefix: char; var alt_param: boolean);
procedure Get_Lumped_Params(tcompt: compt; var v1,v2,v3,v4:double;
 var u,last_ID,last_prefix: char; var alt_param,parallel_cir : boolean);
function arctanh(const x:double) : double;
function kkk(const x:double) : double;
function widtht(const zed:double) : double; {width in mm}
function sinh(const x : double) : double;
function cosh(const x : double) : double;
{* function cl_cosh(x : double) : double; *}
function arccosh(const x : double) : double;
procedure error(const g,wo,ceven : double; var fg,dfg : double);
procedure w_s_stripline_cline(const zede,zedo : double; var woh,soh : double);
procedure w_s_microstrip_cline(const we,wo : double; var woh,soh : double);
procedure shutdown;
function fileexists(note:boolean;var inf:textfile;fname:file_string): boolean;
function setupexists(var fname : file_string) : boolean;
function atan2(const x,y : double) : double;
function enough_space(defaultdrive : integer) : boolean;
function node_number : integer;
procedure update_key_list(nn : integer);
Procedure Carriage_Return;
procedure move_cursor(x1,y1 : integer);
function tanh(const x : double) : double;
function KoK(const k : double) : double;
procedure capac(const W_h,S_h,er : double;var ce,co : double);
procedure ere_even_odd(const W_h,S_h:double;var ee,eo:double);
Procedure Indef_Matrix(Var S : s_conv_matrix; n : integer);
{* Uses internal Procedures:
	LU_Decomp();
	LU_Sub();
	Matrix_Inversion();
	Matrix_Mux();
	Matrix_Conv();
*}
function HeapFunc(Size:word) : integer;
function No_mem_left : boolean;


(******************** Memory management *****************************)


PROCEDURE Init_Mem;

FUNCTION Mem_Left: LONGINT;


PROCEDURE New_c (VAR P: PMemComplex);
PROCEDURE New_s (VAR P: s_param);
PROCEDURE New_plot (VAR P: plot_param);
PROCEDURE New_spline (VAR P: spline_param);
PROCEDURE New_n (VAR P: net);
PROCEDURE New_conn (VAR P: conn);
PROCEDURE New_compt (VAR P: compt);

PROCEDURE Init_Marker (VAR P: marker);
FUNCTION Marked (VAR P: marker): BOOLEAN;
PROCEDURE Mark_Mem (VAR P: marker);
PROCEDURE Release_Mem (VAR P: marker);

PROCEDURE Copy_Networks (NetStart, NetEnd: marker; VAR CopyNetStart: marker);

{ ----------------------------- }

PROCEDURE SetCol(col: word);
PROCEDURE TextCol(col: word);


Implementation

(********************* Graphics Procedures and Functions *************)

procedure puff_draw(x1,y1,x2,y2,color : integer);
{*
	Line drawing routine.
	Only used by draw_ticks,
	Draw_Smith, and draw_to_port.
*}
begin
  SetCol(color);
  Line(x1,y1,x2,y2);
end; {* puff_draw *}


procedure Draw_Box(xs,ys,xm,ym,color : integer);
{*
	This procedure reduced using new graphics.
*}
begin
  SetCol(color);
  Rectangle(xs,ys,xm,ym);
end; {draw_box}



procedure fill_box(x1,y1,x2,y2,color : integer);
{*
	This procedure has been drastically reduced using
	Turbo Pascal graphics.
	 
	Used for erasing sections of the screen (color=brown)
	and for drawing	tlines (color=white).
*}
begin
  if(blackwhite) then SetFillStyle(SolidFill, white) else SetFillStyle(SolidFill,Color);
  Bar(x1,y1,x2,y2);
end; {fill_box}


procedure clear_window(x1, y1, x2, y2 : integer);
{*
	Clear region of screen. Text coordinates are the input.
	Erasing was done in textmode, now in graphics mode.
*}
begin
(*
  Window(x1,y1,x2,y2);   {specify area as window}
  TextCol(black);      {Here TextColor behaves as background}
  ClrScr;  		 {clear to background color}
*)
  Window(1,1,Max_Text_X,Max_Text_Y);     {return to default window}
  SetFillStyle(SolidFill,Black);
  Bar(8*(x1-1),14*(y1-1),8*x2,14*y2)
end; {clear_window}


procedure clear_window_gfx(x1, y1, x2, y2 : integer);
{*
	Clear region of screen. Graphics coordinates are the input.
	Erasing was done in textmode, now in graphics mode.
*}
begin
  Window(1,1,Max_Text_X,Max_Text_Y);     {return to default window}
  SetFillStyle(SolidFill,Black);
  Bar(x1,y1,x2,y2)
end; {clear_window_gfx}


procedure Make_Text_Border(x1,y1,x2,y2,colour: integer; single : boolean);
{*
	Creates text border pattern for start screen and other windows
*}
Const
  sing_vert=#179; doub_vert=#186;  {side bars}
  sing_horz=#196; doub_horz=#205;
  sing_UL=#213; doub_UL=#201;      {corner bars}
  sing_UR=#184; doub_UR=#187;
  sing_LL=#212; doub_LL=#200;
  sing_LR=#190; doub_LR=#188;

var
  vert,horz,UL,
  UR,LL,LR  	: char;
  i 		: integer;

Begin
  if single then begin
    vert:=sing_vert;
    horz:=doub_horz;
    UL:=sing_UL;
    UR:=sing_UR;
    LL:=sing_LL;
    LR:=sing_LR;
  end
  else begin
    vert:=doub_vert;
    horz:=doub_horz;
    UL:=doub_UL;
    UR:=doub_UR;
    LL:=doub_LL;
    LR:=doub_LR;
  end;
  clear_window(x1,y1,x2,y2);   {clear area}
  TextCol(colour);
  for i := y1 to y2 do begin     {* Draw Border for startup screen *}
     GotoXY(x1,i);Write(vert);
     GotoXY(x2,i);Write(vert);
  end;
  for i := x1 to x2 do begin
     GotoXY(i,y1);Write(horz);
     GotoXY(i,y2);Write(horz);
  end;
  GotoXY(x1,y1);Write(UL);
  GotoXY(x2,y1);Write(UR);
  GotoXY(x1,y2);Write(LL);
  GotoXY(x2,y2);Write(LR);
end; {* Make_Text_Border *}


procedure pattern(x1,y1,ij,pij : integer);
{*
	Draw marker pattern for s-parameter plots
	ij=1 box, ij=2 X, ij=3 diamond, ij=4 +
*}
begin
  SetCol(s_color[ij]);
  case ij of
    1 : Rectangle(x1-3,y1-3,x1+3,y1+3); {draw the box}
    2 : begin  {draw X}
            Line(x1-3,y1-3,x1+3,y1+3);
	    Line(x1-3,y1+3,x1+3,y1-3);
        end;
    3 : begin {draw diamond}
            Line(x1-4,y1,x1,y1+4);
	    Line(x1-3,y1-1,x1,y1-4);
	    Line(x1+4,y1,x1+1,y1+3);
	    Line(x1+3,y1-1,x1+1,y1-3);
        end;
    4 : begin {draw +}
            Line(x1-4,y1  ,x1+4,y1  );
	    Line(x1  ,y1+4,x1  ,y1-4);
        end;
  end;{case}
end; {pattern}


procedure box(x,y,ij : integer);
{*
	Draw small box to indicate where s-parameters are calculated.
*}
begin
  case ij of
     2 : begin
	     Dec(y);
	     Dec(x);
	 end;
     3 : Dec(x);
     4 : Dec(y);
  end; {case}
  PutPixel(x,y,s_color[ij]);
  PutPixel(x+1,y,s_color[ij]);
  PutPixel(x,y+1,s_color[ij]);
  PutPixel(x+1,y+1,s_color[ij]);
end; {box}


procedure write_compt(color : integer; tcompt : compt);
{*
	Display a component -- highlighted
*}
begin
  TextCol(color);
  with tcompt^ do begin
      gotoxy(xp,yp) ;
      write(descript);
  end;
end; {* write_compt *}


procedure write_comptm(m,color : integer; tcompt : compt);
{*
	Display the first m characters of a component.
*}
var
  i : integer;

begin
  TextCol(color);
  with tcompt^ do begin
	  gotoxy(xp,yp);
	  for i:=1 to m do write(descript[i]);
  end;
end; {* write_comptm *}


procedure beep;
{*
	Make the Puff tone.
*}
begin
  Sound(250);
  Delay(50);
  Nosound;
end;


procedure rcdelay(j : integer);
{*
	Interuptable delay for use in demo mode.
*}
var
 i : integer;

begin
  for i:=1 to j do begin
	  if keypressed then begin
	        chs := Readkey;
		if chs='S' then begin
		      beep;
		      textmode(co80);
		      halt(1);
		end
		else
		    delay(2000);
	   end
	   else
	       delay(10);  {if keypressed}
  end; {for i:= 1 to j}
end; {rcdelay}


procedure write_message;
{*
	Write message in center box.
*}
begin
  TextCol(message_color);
  Gotoxy((xmin[6]+xmax[6]-length(message[1])) div 2,ymin[6]);
  Write(message[1]);
  Gotoxy((xmin[6]+xmax[6]-length(message[2])) div 2,ymin[6]+1);
  Write(message[2]);
  Gotoxy((xmin[6]+xmax[6]-length(message[3])) div 2,ymin[6]+2);
  Write(message[3]);
  if (message[1]+message[2]+message[3] <> '') and read_kbd then beep;
  if demo_mode then rcdelay(50);
end; {write_message}


procedure Erase_message;
{*
	Erase message in center box.
*}
begin
  clear_window(xmin[6],ymin[6],xmax[6],ymax[6]); {set up window}
  Message[1]:='';
  Message[2]:='';
  Message[3]:='';
end; {Erase_message}


procedure write_error(const time : double);
{*
	Flash error message in message window.
*}
begin
  write_message;
  delay(Round(1000*time));
  erase_message;
end; {write_error}


function input_string(const mess1,mess2 : line_string) : file_string;
{*
	Prompt user to input string (filename).
	The escape key cannot be used to exit here.
*}
var
  answer : file_string;

begin
  Erase_message;
  Window(xmin[6],ymin[6],xmax[6],ymax[6]); {set up window for oversized text}
  TextCol(Yellow);
  WriteLn(mess1);
  WriteLn(mess2);
  Write('?');
  ReadLn(answer);
  input_string:=answer;
  Erase_message;
end; {input_string}


procedure dirn_xy;
{*
	Checks cursor direction.
	Maps dirn into x and y changes.
*}
begin
  xii:=0;
  yii:=0;
  case dirn of
    2 : xii:= 1; {East}
    4 : xii:=-1; {West}
    8 : yii:= 1; {South}
    1 : yii:=-1; {North}
  end;
end; {dirn_xy}


procedure increment_pos(i : integer);
{*
	Increment postion of cursor on circuit.
*}
begin
  dirn_xy;
  if odd(i) then begin
       if i=-1 then begin     {step 1/2 of compt}
	     xm:=xm+(compt1^.lngth*xii+yii*compt1^.con_space)/2.0;
	     ym:=ym+(compt1^.lngth*yii+xii*compt1^.con_space)/2.0;
       end
       else begin
	      if (compt1^.typ in ['i','d']) then begin
		   if compt1^.number_of_con <>1 then begin
		        xm:=xm+lengthxm*xii/(compt1^.number_of_con-1);
		        ym:=ym+lengthym*yii/(compt1^.number_of_con-1);
		    end;
	      end
	      else begin
		   xm:=xm+lengthxm*xii;
		   ym:=ym+lengthym*yii;
	      end;
	end;
  end {if odd i}
  else begin
      if i=0 then begin
	    xm:=cnet^.xr;
	    ym:=cnet^.yr;
      end
      else begin
	    if (compt1^.typ in ['i','d']) then begin
		  xm:=xm+lengthxm*xii/(compt1^.number_of_con-1);
		  ym:=ym+lengthym*yii/(compt1^.number_of_con-1);
	    end
	    else begin
		  xm:=xm+lengthxm*xii-compt1^.con_space*yii;
		  ym:=ym+lengthym*yii-compt1^.con_space*xii;
	    end;
      end; {if i else}
  end; {if odd else}
  xi:=Round(xm/csx);
  yi:=Round(ym/csy);
  if (not(compt1^.typ in ['i','d'])) or (i<=0)
     or (i=(compt1^.number_of_con-1)) then
  	case dirn of
		1 : dirn:=8;
		2 : dirn:=4;
		4 : dirn:=2;
		8 : dirn:=1;
	end; {case}
end; {increment pos}


procedure lengthxy(tnet : net);
{*
	Convert part lengths and widths to increments
	in the x and y directions.
*}
var
  lengths,widths : double;

begin
  dirn_xy;
  if tnet <> nil then begin
    	lengths:=tnet^.com^.lngth;
	widths:=tnet^.com^.width;
  end
  else
  	writeln(lst,'error');
  lengthxm:=lengths*abs(xii)+widths*abs(yii);
  lengthym:=lengths*abs(yii)+widths*abs(xii);
end; {lengthxy}


function betweenr(const x1,x2,x3,sigma : double) : boolean;
{*
	True if real x2 is between x1-sigma and x3+sigma.
*}
begin
  if x1 > x3 then begin
    if (x3-sigma<= x2 ) and (x2 <= x1+sigma) then
     	  betweenr:=true
      else
     	  betweenr:=false;
  end else begin
    if (x1-sigma<= x2 ) and (x2 <= x3+sigma) then
     	  betweenr:=true
      else
     	  betweenr:=false;
  end;
end;


function betweeni(x1,x2,x3 : integer) : boolean;
{*
	Check to see that x2 is between x1 and x3
*}
begin
  if (x1 <= x2 ) and (x2 <= x3) then
  	betweeni:=true
  else
     	betweeni:=false;
end;


function ext_port(tcon : conn) : boolean;
{*
	Check to see if a connector is joined to an external port.
*}
begin
  ext_port:=betweeni(1,tcon^.port_type,min_ports);
end;


{******************** Complex Number Utilities ***********************}

PROCEDURE prp(VAR vu: TComplex; CONST vX,vY: TComplex);
{*
	Complex product.
	Multiply two complex numbers.
*}
begin
  vu.r:=vX.r*vY.r-vX.i*vY.i;
  vu.i:=vX.r*vY.i+vX.i*vY.r;
end;


PROCEDURE supr(VAR vu: TComplex; CONST vX,vY: TComplex);
{*
	Complex sum and product.
	Multiply two complex numbers and add.
	vu = vu + vx*vy
*}
begin
  vu.r:=vu.r+vX.r*vY.r-vX.i*vY.i;
  vu.i:=vu.i+vX.r*vY.i+vX.i*vY.r;
end;


PROCEDURE diffpr(VAR vu: TComplex; CONST vX,vY: TComplex);
{*
	Complex difference and product.
	Multiply two complex numbers and subtract.
	vu = vu - vX*vY
*}
begin
  vu.r:=vu.r-vX.r*vY.r+vX.i*vY.i;
  vu.i:=vu.i-vX.r*vY.i-vX.i*vY.r;
end;


PROCEDURE co(VAR co: TComplex; CONST s,t : double);
{*
	Create a complex number type.
*}
begin
  co.r:=s;
  co.i:=t;
end; {co}


PROCEDURE di(VAR di: TComplex; CONST s,t: TComplex);
{*
	Calculate difference of two complex numbers (s - t).
*}
begin
  di.r:=s.r - t.r;
  di.i:=s.i - t.i;
end; {di}


PROCEDURE su(VAR su: TComplex; CONST s,t: TComplex);
{*
	Calculate sum of two complex numbers (s + t).
*}
begin
  su.r := s.r + t.r;
  su.i := s.i + t.i;
end; {s+t}


PROCEDURE rc(VAR rc: TComplex; CONST z: TComplex);
{*
	Calculate the reciprocal of a complex number (1/z).
*}
var
  mag : double;         {! was real, changed 10/15/90}

begin
  mag:=sqr(z.r)+sqr(z.i);
  {!* check for 1/0 added here *}
  if (mag=0.0) then begin
	rc.r := 0.0; {Although this is equivalent to saying 1/0 = 0}
	rc.i := 0.0; {it works properly for the few times it occurs}
  end
  else begin
        rc.r := z.r/mag;
	rc.i :=-z.i/mag ;
  end;
end; {* 1/z *}


PROCEDURE sm (VAR sm: TComplex; CONST s: double; CONST t: TComplex);
{*
	Scale magnitude of a complex number s*t.
*}
begin
  sm.r:=s * t.r;
  sm.i:=s * t.i;
end; {sm or s*t}


FUNCTION co_mag (CONST z: TComplex): double;
{*
	Compute magnitude of a complex number.
	Used for pivoting in matrix inversion routines.
*}
Begin
  co_mag:= sqrt (sqr(z.r) + sqr(z.i));
end; {* co_mag *}


PROCEDURE Equate_Zs (VAR z1: TComplex; CONST z2: Tcomplex);
{*
	sets z1 := z2;
*}
Begin
  z1.r:=z2.r;
  z1.i:=z2.i;
end;


{*********************** Parsing Utilities ***********************}

function Eng_Prefix(c : char) : double;
{*
	Find multiplication factor for engineering prefixes
*}
Begin
  case c of
    	'E' : Eng_Prefix:=1.0e+18;
	'P' : Eng_Prefix:=1.0e+15;
	'T' : Eng_Prefix:=1.0e+12;
	'G' : Eng_Prefix:=1.0e+09;
	'M' : Eng_Prefix:=1.0e+06;
	'k' : Eng_Prefix:=1.0e+03;
	'm' : Eng_Prefix:=1.0e-03;
	Mu  : Eng_Prefix:=1.0e-06;
	'n' : Eng_Prefix:=1.0e-09;
	'p' : Eng_Prefix:=1.0e-12;
	'f' : Eng_Prefix:=1.0e-15;
	'a' : Eng_Prefix:=1.0e-18;
     else
         Eng_Prefix:= 1.0;
  end; {case}
end; {* Eng_Prefix *}


function Manhattan(tcompt : compt) : boolean;
{*
	Determine if Manhattan layout has been selected.
	Looks for 'M' at the end of tcompt^.descript
	 or a '?' anywhere in the description.
*}
var
  c_string : line_string;
  long	   : integer;

Begin
  if Manhattan_Board then
    Manhattan:=true
  else begin
    c_string := tcompt^.descript;
    long:=length(c_string);
    while c_string[long]=' ' do Dec(long); {ignore end blanks}
    {* Select Manhattan if last character is an 'M' *}
    if c_string[long]='M' then Manhattan:=true
  	    		  else Manhattan:=false;
    {* Select Manhattan if a '?' is present in clines or tline *}
    while (long>0) do begin
      if (c_string[long]='?') and (tcompt^.typ in ['c','t'])
     	 then Manhattan:=true;
      Dec(long);
    end;
  end; {else}
end; {* Manhattan *}


function super_line(tcompt : compt) : boolean;
{*
	Determine if super line has been selected.
	Looks for '!' anywhere in tcompt^.descript.
*}
var
  c_string : line_string;
  long	   : integer;

Begin
  super_line:=false;
  c_string := tcompt^.descript;
  long:=length(c_string);
  {* super line if a '!' is present in clines or tline *}
  while (long>0) do begin
     if (c_string[long]='!') and (tcompt^.typ in ['c','t'])
    	 then super_line:=true;
     Dec(long);
  end;
end; {* super_line *}


function goto_numeral(n : integer; x : line_string) : integer;
{*
	Find location of nth number in x.
	Used by tlineO, clineO, get_real, get_param
	Will also return location of '?'.
*}
var
  long,i,j : integer;
  found    : boolean;

begin
  i:=0;
  found:=false;
  goto_numeral:=0;
  j:=1;
  long:=length(x);
  if long > 0 then
  Repeat
    if x[j]='(' then j:=Pos(')',x);
    if x[j] in ['?','+','-','.',',','0'..'9'] then begin
      Inc(i);
      if i=n then found:=true
	  else
	    repeat  {step over number to find next number}
		Inc(j);
	    until not(x[j] in ['?','-','.',',','0'..'9']) or (j=long+1);
    end
    else
    	Inc(j);
  until found or (j=long+1);
  if found then
       goto_numeral:=j
  else begin
       bad_compt:=true;
       message[2]:='Number is missing';
  end;
end; {* goto_numeral *}


function Get_Real(tcompt : compt; n : integer) : double;
{*
	Read nth number in tcompt.

	Called by get_coordsO, get_s_and_fO, Read_Net
*}
var
  c_string,s_value 	: line_string;
  j,code,long 		: integer;
  value       		: double;
  found       		: boolean;

begin
  c_string:=tcompt^.descript;
  j:=goto_numeral(n,c_string);
  if bad_compt then begin
     ccompt:=tcompt;
     exit;
  end;
  s_value:='';
  long:=length(c_string);
  found:=false;
  repeat
     if c_string[j] in [{'+',}'-','.',',','0'..'9'] then begin
        if c_string[j]=',' then s_value:=s_value+'.'
                   	   else s_value:=s_value+c_string[j];
        Inc(j);
     end
     else
     	found:=true;
  until (found or (j=long+1));
  Val(s_value,value,code);
  if (code<>0) or (length(s_value)=0) then begin
      ccompt:=tcompt;
      bad_compt:=true;
      message[2]:='Invalid number';
      exit;
  end;
  get_real:=value;
end; {* Get_Real *}


procedure Get_Param(tcompt : compt; n : integer; var value : double;
 var value_string: line_string; var u1,prefix: char; var alt_param: boolean);
{*
	Get nth parameter in tcompt.
	Used for parsing tlines, clines, qlines, BOARD, etc.
	Ignores '+' signs.

	Called by tlineO, clineO, Atten, Transformer,etc.
*}
const
  potential_units: set of char = [degree,Omega,'m','h','H',
  				  's','S','z','Z','y','Y'];

  potential_numbers: set of char = ['+','-','.',',','0'..'9'];

var
  c_string,s_value 	: line_string;
  i,j,code,long 	: integer;
  found_value 		: boolean;

begin
  alt_param:=false;
  c_string:=tcompt^.descript;
  j:=goto_numeral(n,c_string);
  if bad_compt then begin
     ccompt:=tcompt;
     exit;
  end;
  long:=length(c_string);
  while c_string[long]=' ' do Dec(long);  {ignore end spaces}
  if j > 0 then begin
    found_value:=false;
    s_value:='';
    repeat
     if c_string[j] in potential_numbers then begin
        if not(c_string[j]='+') then begin   {force a skip over '+' signs}
              if c_string[j]=',' then
	      		s_value:=s_value+'.'     {sub '.' for ','}
                    else
		    	s_value:=s_value+c_string[j];
        end; { '+' sign check }
        Inc(j);
     end
     else if c_string[j]='?' then begin    {Check here for variable}
     	alt_param:=true;
	Inc(j);
     end
     else
        found_value:=true;
    until (found_value or (j=long+1));
    Val(s_value,value,code);
    if (code<>0) or (length(s_value)=0) then begin
      if (alt_param=true) then begin
         value:=1.0;   {return these for uninitialized variables}
	 value_string:='1.0';
      end
      else begin
         ccompt:=tcompt;
	 bad_compt:=true;
	 message[2]:='Invalid number';
	 exit;
      end;
    end
    else
      value_string:=s_value;
  end;
  while (c_string[j] = ' ') and (j < long+1) do Inc(j);   {Skip spaces}
  prefix:=' '; {initialize prefix to blank}
  if (c_string[j] in Eng_Dec_Mux) and (j<=long) then begin
      if c_string[j]='m' then begin   {is 'm' a unit or prefix?}
	i:=j+1;
        while (c_string[i] = ' ') and (i < long+1) do Inc(i);
	{* Skip spaces to check for some unit *}
	if (c_string[i] in potential_units) then begin
	   {it's the prefix milli 'm' next to a unit}
	   prefix:='m';
	   value:=Eng_Prefix('m')*value;
	   j:=i; {make j point past the prefix, to the unit}
	end;
      end  {if 'm' is a unit do nothing}
      else begin  {if other than 'm' factor in prefix}
        prefix:=c_string[j];
        value:=Eng_Prefix(c_string[j])*value;
	Inc(j);  {advance from prefix toward unit}
      end;
  end;
  while (c_string[j] = ' ') and (j <= long) do Inc(j);   {Skip spaces}
  if j <=long then u1:=c_string[j]
  	      else u1:='?';
  if u1='m' then value:=1000*value; {return millimeters, not meters}
end; {* Get_Param *}


procedure Get_Lumped_Params(tcompt: compt; var v1,v2,v3,v4: double;
  var u,last_ID,last_prefix: char; var alt_param,parallel_cir : boolean);
{*
	Get paramters for a lumped element.

	example tcompt^.descript := 'a lumped 50-j10+j10'#139' 4mm'
					                 ohms
	Currently, only a single alt_parameter may be
	passed to LumpedO, (either v1,v2,v3, or v4)
	otherwise, an error will occur (in LumpedO).

*}
label
  exit_get_lumped;
var
  c_string,s_value   	: line_string;
  i,j,code,long,sign 	: integer;
  value,L_value,
  temp_val,C_value,
  omega0 		: double;
  found,par_error  	: boolean;
  ident,scale_char	: char;

  		{***************************************************}
		Procedure skip_space;
		{*
			Skip one or more spaces to advance to next
			legitimate data or unit value.
		*}
		begin
		  repeat
		    Inc(j);    {advance past spaces}
		  until (c_string[j] <> ' ') or (j=long+1);
		end;
		{****************************************************}


Begin   {* Get_lumped_params *}
  v1:=0; v2:=0; v3:=0; v4:=0; u:='?'; last_ID:=' '; last_prefix:=' ';
  L_value:=0; C_value:=0;
  par_error:=false; parallel_cir:=false; alt_param:=false;
  omega0:=2*Pi*design_freq*Eng_Prefix(freq_prefix);
  {convert design Freq to rad/sec times prefix}
  c_string:=tcompt^.descript;
  j:=2;  {look past id letter}
  if bad_compt then exit;
  long:=length(c_string);
  while c_string[long]=' ' do Dec(long); {ignore end blanks}
  if Pos(Parallel,c_string) > 0 then parallel_cir:=true;
  {* Look for character which represents a parallel circuit *}
  for i:=1 to 4 do begin
    s_value:='';
    scale_char:=' ';
    found:=false;
    if j > long then goto exit_get_lumped;
    while not(c_string[j] in ['?','+','-','.',',','0'..'9','j']) do begin
     	Inc(j);         {Advance characters until legitimate data found}
	if j > long then goto exit_get_lumped;
    end;
    if c_string[j]='+' then skip_space;
    if c_string[j]='-' then begin
        skip_space;
	sign:=-1;
    end
    else
    	sign:=1;
    if c_string[j]='j' then begin
    	skip_space;
	ident:='j'
    end
    else
    	ident:=' ';
    { Check for sweep variable }
    if c_string[j]='?' then
    if alt_param=false then begin
    	alt_param:=true;
	skip_space;
    end
    else begin
    	par_error:=true;
	goto exit_get_lumped;
    end;
    {* Load string with number characters *}
    repeat
     if c_string[j] in ['.',',','0'..'9'] then begin
        if c_string[j]=',' then s_value:=s_value+'.'
                           else s_value:=s_value+c_string[j];
        Inc(j);
     end
     else
     	found:=true;
    until (found or (j=long+1));
    if (c_string[j] = ' ') then skip_space;
    {* Look for engineering prefixes *}
    if (c_string[j] in Eng_Dec_Mux) and (j<long) then begin
        scale_char:=c_string[j]; {* ignore 'm' if last character *}
	skip_space;
    end;
    if (c_string[j] in ['j','m','H','F']) and (j<>long+1) then begin
        ident:=c_string[j];
        skip_space;
    end;
    if j<=long then
      if c_string[j] in ['y','Y','z','Z','s','S',Omega] then begin
	 u:=c_string[j];
         skip_space;
    end;
    Val(s_value,value,code);
    if (code<>0) or (length(s_value)=0) then begin
      if (alt_param=true) and (ident<>'m') then begin
         value:=1.0;   {return 1.0 for uninitialized variables}
      end
      else begin
      	 par_error:=true;
	 goto exit_get_lumped;
      end;
    end;
    value:=value*sign*Eng_Prefix(scale_char);
    case ident of
       'F'   : if C_value=0 then begin
       		  C_value:=value;
		  if C_value=0 then C_value:=1.0/infty;
		  {watch for zero capacitance}
	       end
	       else begin
		  par_error:=true;
		  goto exit_get_lumped;
	       end;
       'H'   : if L_value=0 then begin
       		  L_value:=value;
		  if L_value=0 then L_value:=1.0/infty;
		  {watch for zero inductance}
	       end
	       else begin
		  par_error:=true;
		  goto exit_get_lumped;
	       end;
       'j'   : if value > 0 then begin
     		   if v2=0 then v2:=value
		      else begin
			par_error:=true;
			goto exit_get_lumped;
		   end;
		end
		else begin
     		   if v3=0 then v3:=value
		      else begin
		        par_error:=true;
			goto exit_get_lumped;
		   end;
		end;
       'm'   :  v4:=1000*value; {convert from meters to mm}
       		{* return v4=0 if solo m i.e. Manhattan *}
      else
      	  if v1=0 then v1:=value
	  	 else begin
		        par_error:=true;
			goto exit_get_lumped;
	   end;
    end; {case}
    {Save part ID and prefix for alt_param}
    if not(ident in [' ','m']) then last_ID:=ident;
    if (scale_char<>' ') and (ident<>'m') then last_prefix:=scale_char;
  end; {for i}
exit_get_lumped:
  if not(par_error) then begin
    if (u in ['z','Z',Omega]) and (parallel_cir=true) then begin
      temp_val:=v2;    {* Swap values if parallel circuit is desired *}
      if v1<>0 then v1:=1.0/v1;
      if v3<>0 then v2:=-1.0/v3;
      if temp_val<>0 then v3:=-1.0/temp_val;
      if u=Omega then u:='S'    {*swap units too *}
         	 else u:='y';
    end; {if u in}
    {* Add in capacitor and inductor values *}
    if C_value <> 0 then
      case u of
        Omega   : v3:=v3 - 1.0/(omega0*C_value);
	'z','Z' : v3:=v3 - 1.0/(z0*omega0*C_value);
	'y','Y' : v2:=v2 + z0*omega0*C_value;
	's','S' : v2:=v2 + omega0*C_value;
	else {if 'F' the only unit}
         if parallel_cir then begin
	   u:='S';
	   if v1<>0 then v1:=1.0/v1; {assume ohms @ v1 if no units}
	   v2:=v2 + omega0*C_value;
	 end
	 else begin
	   u:=Omega;
	   v3:=v3 - 1.0/(omega0*C_value);
         end;
    end; {if..case}
    if L_value <> 0 then
      case u of
      	Omega   : v2:=v2 + omega0*L_value;
	'z','Z' : v2:=v2 + omega0*L_value/z0;
	'y','Y' : v3:=v3 - z0/(omega0*L_value);
	's','S' : v3:=v3 - 1.0/(omega0*L_value);
	else  {if 'H' the only unit}
          if parallel_cir then begin
	    u:='S';
	    if v1<>0 then v1:=1.0/v1; {assume ohms @ v1 if no units}
	    v3:=v3 - 1.0/(omega0*L_value);
	  end
	  else begin
	    u:=Omega;
	    v2:=v2 + omega0*L_value;
        end; {else}
    end; {if..case}
  end; {not par_error}
  if par_error or (u='?') then begin
    ccompt:=tcompt;
    bad_compt:=true;
    message[1]:='Error in';
    message[2]:='lumped element';
    message[3]:='description';
  end;
end; {* Get_Lumped_Params *}



{************************** Numerical Routines *************************}

function arctanh(const x:double) : double;

begin
  arctanh:=0.5*ln((1+x)/(1-x));
end;


function kkk(const x:double) : double;
{*
	Function used to calculate Cohn's "k" factor for stripline
	width formulas.  See equation 3.6, page 13 of the Puff Manual.
	Used by widthO, w_s_stripline_cline.
*}
var
  expx : double;

begin
  if x > 1 then begin
     expx:=exp(pi*x);
     kkk:=sqrt(1-sqr(sqr((expx-2)/(expx+2))));
  end
  else begin
     expx:=exp(pi/x);
     kkk:=sqr((expx-2)/(expx+2))
  end;
end; {kkk}


function widtht(const zed:double) : double; {width in mils}
{*
	Function for calculating width in mils of microstrip
	and stripline transmission lines.  See Puff manual
	pages 12-13 for details.

	Microstrip models are from Owens:
		Radio and Elect Eng, 46, pp 360-364, 1976.
	Stripline models are from  Cohn:
		MTT-3 pp19-126, March 1955.
	See also Gupta, Garg, Chadha:
		CAD of Microwave Circuits Artech House, 1981.
*}
const
 lnpi_2=0.451583;
 ln4_pi=0.241564;
var
  Hp,expH,de,x : double;

  	{******************************************}
	Procedure High_Z_Error;
	Begin
	  bad_compt:=true;
	  message[1]:='Impedance';
	  message[2]:='too large';
	  widtht:=0;
	end;
	{******************************************}

begin
  if stripline then begin
     x:=zed*sqrt(er)/(30*pi);
     if (pi*x > 87.0) then
     	High_Z_Error  {or else kkk(x) will explode}
     else
        widtht:= substrate_h*2*arctanh(kkk(x))/pi; {Use kkk for k factor}
  end
  else begin { if microstripline then }
     if zed > (44-2*er) then begin
	 Hp:= (zed/120)*sqrt(2*(er+1)) + (er-1)*(lnpi_2+ln4_pi/er)/(2*(er+1));
	 if Hp > 87.0 then begin  {e^87 = 6.0e37}
	 	High_Z_Error;
	  end
	  else begin
		expH:=exp(Hp);
		widtht:= substrate_h/(expH/8-1/(4*expH));
          end;
     end
     else begin  { if zed <= (44-2*er) }
	  de := 60*sqr(pi)/(zed*sqrt(er));
	  widtht:=substrate_h*(2/pi*((de-1)-ln(2*de-1))+
                  (er-1)*(ln(de-1)+0.293-0.517/er)/(pi*er));
     end; { if zed }
  end; {if stripline}
end; {widtht}


function sinh(const x : double) : double;
{*
	Hyperbolic sine used for s-parameter
	calculations in tlines and clines.

	Reals will explode with x > 300.
*}

var a:double;

begin
  a:=exp(x);
  sinh:=(a-1/a)/2;
end; {* sinh *}


function cosh(const x : double) : double;
{*
	Hyperbolic cosine used for tline and cline
	s-parameter calculation.

	Reals will explode with x > 300
*}
begin
  cosh:=(exp(x)+1/exp(x))/2;
end; {* cosh *}


function cl_cosh(const x : double) : double;
{*
	Hyperbolic cosine used for cline calculation.
*}
var
  exp1 : double;

begin
  if x > 300 then begin
	  exp1:=infty;
	  bad_compt:=true;
	  message[1]:='cline impedances';
	  message[2]:='can'+char(39)+'t be realized';
	  message[3]:='in microstrip';
  end
  else begin
	  exp1:=exp(x);
	  cl_cosh:=(exp1+1/exp1)/2;
  end;
end; {* cl_cosh *}


function arccosh(const x : double) : double;
{*
	Inverse cosh.
	Used for Procedures error() and w_s_microstip_cline.
*}
var
  sqx : double;

begin
  sqx:=sqr(x);
  if sqx <= 1 then begin
    arccosh:=0;
    bad_compt:=true;
    message[1]:='cline impedances';
    message[2]:='can'+char(39)+'t be realized';
    message[3]:='in microstrip';
  end
  else
    arccosh:=ln(x+sqrt(sqr(x)-1));
end; {arccosh}


procedure error(const g,wo,ceven : double; var fg,dfg : double);
{*
	This routine is used to calculate cline dimensions.
	When error=0 a consistent solution of the cline equations
	has been reached. See Edwards p139.
*}
var
 hh,sqm1,rsqm1,dcdg,
 acoshh,acoshg,u1,u2,
 du1dg,du2dg,dhdg,
 dcdu1,dcdu2,dcdh 		: double;

begin
  hh:=0.5*((g+1)*ceven+g-1);
  dhdg:=0.5*(ceven+1.0);
  acoshh:=arccosh(hh); if bad_compt then exit;
  acoshg:=arccosh(g);  if bad_compt then exit;

  sqm1:=sqr(hh)-1;
  rsqm1:=sqrt(sqm1);
  dcdh:=(rsqm1+hh)/(hh*rsqm1+sqm1);

  sqm1:=sqr(g)-1;
  rsqm1:=sqrt(sqm1);
  dcdg:=(rsqm1+g)/(g*rsqm1+sqm1);

  u1:=((g+1)*ceven-2)/(g-1);
  du1dg:=((g-1)*ceven-((g+1)*ceven-2))/sqr(g-1);
  u2:=acoshh/acoshg;
  du2dg:=(acoshg*dcdh*dhdg-acoshh*dcdg)/sqr(acoshg);

  sqm1:=sqr(u1)-1;
  rsqm1:=sqrt(sqm1);
  dcdu1:=(rsqm1+u1)/(u1*rsqm1+sqm1);

  sqm1:=sqr(u2)-1;
  rsqm1:=sqrt(sqm1);
  dcdu2:=(rsqm1+u2)/(u2*rsqm1+sqm1);

  if (er > 6) then begin
  	fg:=(2*arccosh(u1)+arccosh(u2))/pi-wo;
	if bad_compt then exit;
	dfg:=(2*dcdu1*du1dg+dcdu2*du2dg)/pi;
  end
  else begin
    	fg:=(2*arccosh(u1)+4*arccosh(u2)/(1.0+er/2.0))/pi-wo;
	if bad_compt then exit;
	dfg:=(2*dcdu1*du1dg+4*dcdu2*du2dg/(1.0+er/2.0))/pi;
  end;
end; {error}


procedure w_s_stripline_cline(const zede,zedo : double; var woh,soh : double);
{*
	Computes ratios W/b and S/b for stripline clines.
	See Puff Manual page 14 for details.

*}
var
  ke,ko : double;

begin
  ke:=kkk(zede*sqrt(er)/(30*pi));
  ko:=kkk(zedo*sqrt(er)/(30*pi));
  woh:=2*arctanh(sqrt(ke*ko))/pi;
  soh:=2*arctanh(sqrt(ke/ko)*(1-ko)/(1-ke))/pi;
end; {w_s_stripline_cline}


procedure w_s_microstrip_cline(const we,wo : double; var woh,soh : double);
{*
	This routine uses Netwon's method to find the cline width
	and spacing. Errors occur in the repeat (newton	algorithm)
	loop if the even and odd impedances are too close.
*}
const
  tol=0.0001;
var
  codd,ceven,g,fg,dfg,dg,g1 : double;
  i : integer;

begin
  ceven:=cl_cosh(pi*we/2);
  codd :=cl_cosh(pi*wo/2);
  soh:=2*arccosh((ceven+codd-2)/(codd-ceven))/pi;
  if bad_compt then exit;
  g:=cl_cosh(pi*soh/2); {starting guess}
  i:=0;
  repeat {newton algorithm}  {!* beware of divergence in this loop *}
    g1:=g;
    error(g,wo,ceven,fg,dfg);
    if bad_compt then exit;
    dg:=fg/dfg;
    g:=g1-dg;
    Inc(i);
    if g<= 1.0 then i:=101;
  until ((abs(dg)<abs(tol*g)) or (i > 100));
  if i> 100 then begin
    bad_compt:=true;
    message[1]:='cline impedances';
    message[2]:='can'+char(39)+'t be realized';
    message[3]:='in microstrip';
    exit;
  end;
  soh:=2.0*arccosh(g)/pi;
  woh:=arccosh(0.5*((g+1)*ceven+g-1))/pi-soh/2.0;
end; {w_s_microstrip_cline}


procedure shutdown;
{*
	Called when a disastrous error condition
	has been reached to stop Puff.
*}
begin
  CloseGraph;
  TextMode(OrigMode);
  message[1]:='FATAL ERROR:';
  write_message;
  Gotoxy(1,23);
  write('Press any key to quit');
  ReadKey;
  Halt(3);
end;


function Fileexists(note:boolean;var inf:textfile;fname:file_string): boolean;
{*
	Performs an Assign and Reset on textfile if the file exists.
	Note that Textfile is used here. Consider changing the
	buffer size using SetTextBuffer.

*}
begin
  fileexists:=False;
  if fname <> '' then begin
    Assign(inf,fname);
    {$I-} Reset(inf); {$I+}  {* Disable I/O check in case file not present *}
    if IOResult=0 then fileexists:=true    {* IOResult of 0 means success *}
     else begin
       if note then begin
         message[2]:='File not found';
         message[3]:=fname;
         write_message;
	 Delay(1000);
       end;
    end; {if IO}
  end; {if fname}
end; {* Fileexists *}


function setupexists(var fname : file_string) : boolean;
{*
	Look for setup.puf in current directory or
	in ~/.puff if user has set it up
	or in system wide at /usr/share/puff/config.
*}
var
  found : boolean;

begin
  found:=false;
  message[2]:=fname;
  if fname <> 'setup.puf' then begin
    fname:='setup.puf';
    found:=fileexists(false,net_file,fname);
  end;
  if not(found) then begin
    fname:=ExpandFileNameUTF8('~/.puff/setup.puf');
    found:=fileexists(false,net_file,fname);
  end;
  if not(found) then begin
    fname:=ExpandFileNameUTF8('/usr/share/puff/config/setup.puf');
    found:=fileexists(false,net_file,fname);
  end;
  if found then begin
    erase_message;
    message[1]:='Missing board#';
    message[2]:='Try';
    message[3]:=fname;
    write_error(2);
  end;
  setupexists:=found;
end; {setupexists}


function atan2(const x,y : double) : double;
{*
	Modified arctan to get phase in all quadrants
	and avoid blow ups when x=0.
*}
var
  atan2t : double;

begin
  if x=0 then begin
     if y > 0 then atan2t:=90.0
	      else atan2t:=-90.0;
  end
  else begin
     if x > 0 then atan2t:=180*arctan(y/x)/pi
	      else begin
		 if y > 0 then atan2t:=180*arctan(y/x)/pi+180
			  else atan2t:=180*arctan(y/x)/pi-180;
     end;
  end;
  if abs(atan2t) < 1.0e-25 then atan2:=0
			   else atan2:=atan2t;
end; {atan2}


function enough_space(defaultdrive : integer) : boolean;
{*
	Look for space on disk -- a: 0, b: 1 ..
*}

begin

{*
   On Linux, don't actually test whether there is enough disk space;
   that doesn't help much on a multitasking system anyway
*}

  enough_space:=true;
end; {* Enough_space *}


function node_number : integer;
{*
	Find number of node in linked list of nets.
*}
var
  nn   : integer;
  tnet : net;

begin
  tnet:=nil; nn:=0;
  if net_start <> nil then
    repeat
      if tnet=nil then tnet:=net_start
      		  else tnet:=tnet^.next_net;
      if tnet^.node then Inc(nn);
    until (tnet^.next_net=nil) or (cnet=tnet);
  if cnet=tnet then node_number:=nn
  	       else node_number:=0;
end; {node_number}


procedure update_key_list(nn : integer);
{*
	Update array which contains keystrokes used to layout circuit.
*}
begin
  if key_end=0 then key_end:=1 else Inc(key_end);
  if key_end=key_max then begin
    key_end:=key_max-1;
    message[1]:='Circuit is too';
    message[2]:='complex for';
    message[3]:='redraw';
    write_message;
  end;
  key_list[key_end].keyl:=key;
  key_list[key_end].noden:=nn;
end; {update_key_list}


Procedure Carriage_Return;
{*
     Carriage return operation used only in the
     Parts Window.
     Advances to next part, puts cursor on first character.
*}
Begin
   if ( (ccompt^.next_compt=nil)
   	or
	( not(Large_Parts) and
	(window_number=3) and (ccompt^.descript[1]='i') )
	or
	(Large_Parts and (window_number=3) and
	(ccompt^.descript[1]='j') and help_displayed )
	)
	   then begin
	      Case window_number of
	        3 : ccompt:=part_start;
		4 : ccompt:=board_start;
		else
		  beep;
	      end; {case}
	   end
	   else
	     ccompt:=ccompt^.next_compt;
   cx:=ccompt^.x_block;
end;


Procedure Move_Cursor(x1,y1 : integer);
{*
	Move character cursor. Used for Board, Parts, and Plot windows.
*}
var
  long,i 	: integer;
  has_spaces	: boolean;

begin
  has_spaces:=false;
  if x1 <> 0 then with ccompt^ do begin
    long:=length(descript);
    if cx+x1 <= long then begin
      cx:=cx+x1;
      if cx < x_block then cx:=x_block;
      if right and (cx+xp >= xorig) then begin
        if (window_number=2) then Inc(WindMax);
	{Increment WindMax to prevent scrolling in plot window}
        Dec(xp);
        write_compt(lightgray,ccompt);
	Write(' ');
        if (window_number=2) then Dec(WindMax);
	{Restore WindMax}
      end;
    end;
  end
  else begin { if x1=0 then... }
    Erase_message;
    if Pos(' ',ccompt^.descript) <> 0 then has_spaces:=true;
    if (window_number=2)
    	and ( (length(ccompt^.descript)<3) or (has_spaces) ) then
        for i:=1 to max_params do   {Delete invalid S-parameter designations}
          if s_param_table[i]=ccompt then begin
	  	Delete(ccompt^.descript,2,2);
	  	GotoXY(ccompt^.xp-2,ccompt^.yp);
		Write('     ');   {erase invalid s-parameter on screen}
    end;
    if y1 <> 0 then begin   {if y1=0 then skip the following}
      if y1=-1 then begin
        if ccompt^.prev_compt = nil then beep
	   			    else ccompt:=ccompt^.prev_compt;
      end
      else begin  {y1=1}
        if ( (ccompt^.next_compt=nil)
        or
	(not(Large_Parts) and (window_number=3) and (ord(ccompt^.descript[1])-ord('a') >= ymax[3]-ymin[3]) )
	or
	(Large_Parts and (window_number=3) and (ord(ccompt^.descript[1])-ord('a') >= ymax[3]-ymin[3]) and help_displayed )
	)
	   then beep
	   else ccompt:=ccompt^.next_compt;
      end; {y1=-1}
      if (window_number=2) and (length(ccompt^.descript)=1) then
         for i:=1 to max_params do
           if s_param_table[i]=ccompt then begin
	   	pattern(xmin[2]*charx-1,(ymin[2]+2+i)*chary-8,i,0);
		write_comptm(1,lightgray,ccompt); {write "S"}
      end;
      long:=length(ccompt^.descript);
      if cx > long then cx:=long;
      if window_number=2 then cx:=ccompt^.x_block;
      if cx < ccompt^.x_block then cx:=ccompt^.x_block;
    end; { if y1 <> 0}
  end; {else}
end; {move_cursor}


function tanh(const x : double) : double;
{*
	Calculate the hyperbolic tangent.
*}
var
  ex : double;

begin
  if (x < -30) then begin
  	tanh:=-1.0;
	exit;
  end;
  if (x > 30) then
  	tanh:= 1.0
      else begin
    	ex:=exp(x);
	tanh:=(ex-1/ex)/(ex+1/ex);
  end;
end;


function KoK(const k : double) : double;
{*
*}
var
  kp : double;

begin
  kp:=sqrt(1-sqr(k));
  if sqr(k) < 0.5 then
  		kok:=ln(2*(1+sqrt(kp))/(1-sqrt(kp)))/pi
         else
	 	kok:=pi/ln(2*(1+sqrt(k))/(1-sqrt(k)));
end;


procedure capac(const W_h,S_h,er : double; var ce,co : double);
{*
	Calculate capacitances of coupled microstrip.
*}
var
  cp,cf,cfp,cga,cgd,ere,zo,a : double;

begin
  ere:=(er+1)/2 + (er-1)/2/sqrt(1+10/W_h);
  if W_h <= 1.0 then
  		zo:=370.0*ln(8.0/W_h+0.25*W_h)/(2.0*pi*sqrt(ere))
            else
	  	zo:=370.0/((W_h+1.393+0.667*ln(W_h+1.44))*sqrt(ere));
  a:=exp(-0.1*exp(2.33-2.53*W_h));
  cp:=er*W_h;
  cf:=0.5*(sqrt(ere)/(zo/(120*pi))-cp);
  cfp:=cf*sqrt(er/ere)/(1+a*tanh(8*S_h)/S_h);
  cga:=KoK(S_h/(S_h+2*W_h));
  cgd:=er*ln(1/tanh(pi*S_h/4))/pi+0.65*cf*(0.02*sqrt(er)/S_h+1-1/sqr(er));
  ce:=cp+cf+cfp;
  co:=cp+cf+cga+cgd;
end; {capac}


procedure ere_even_odd(const W_h,S_h:double;var ee,eo:double);
{*
	Compute effective relative dielectric constants for cline
	even and odd impedances.
*}
var
  ce1,co1,cee,coe:double;

begin
  capac(W_h,S_h,1,ce1,co1);
  capac(W_h,S_h,er,cee,coe);
  ee:=cee/ce1;
  eo:=coe/co1;
end; {ere_even_odd}


Procedure LU_Decomp(VAR a: s_conv_matrix;
	                n: integer;
     	         VAR indx: s_conv_index;
                    VAR d: double);
{*
	L-U Decomposition routine inspired by Numerical Recipes.
   	The following types are used here:

	s_conv_matrix = array [1..conv_size,1..conv_size] of TComplex;
	s_conv_vector = array [1..conv_size] of TComplex;
	s_conv_index  = array [1..conv_size] of integer;
	s_real_vector = array [1..conv_size] of double;


*}
const
   tiny = 1.0e-20;

type
   s_real_vector = array [1..conv_size] of double;

var
   k,j,imax,i  : integer;
   sum,dum_z,
   z_dum       : TComplex;
   big,dum_r   : double;
   vv          : s_real_vector;

Begin
{   new(vv); }
   d := 1.0;
   {* Loop over rows to get implicit scaling information *}
   for i := 1 to n do begin
      big := 0.0;
      for j := 1 to n do
         if (co_mag(a[i,j]) > big) then big := co_mag(a[i,j]);
      if big = 0.0 then begin      {if zeros all along the column...}
         Message[1]:='Warning!';
	 Message[2]:='indef part has';
	 Message[3]:='singular matrix';
	 Write_Message;
	 big:=tiny;  {! This will not cause recovery *}
      end;
      vv[i] := 1.0/big;  {save the scaling for future reference}
   end;
   for j := 1 to n do begin
      for i := 1 to j-1 do begin
         Equate_Zs(sum,a[i,j]);
         for k := 1 to i-1 do
            Diffpr(sum,a[i,k],a[k,j]); {* sum=sum-a[i,k]*a[k,j] *}
	 Equate_Zs(a[i,j],sum);
      end;
      big := 0.0;
      for i := j to n do begin
         Equate_Zs(sum,a[i,j]);
         for k := 1 to j-1 do
            Diffpr(sum,a[i,k],a[k,j]);  {* sum=sum-a[i,k]*a[k,j] *}
	 Equate_Zs(a[i,j],sum);
	 {* Check here for a better figure of merit for the pivot *}
         dum_r := vv[i]*co_mag(sum);
         if dum_r >= big then begin  {*if better, exchange and save index*}
            big := dum_r;
            imax := i
         end;
      end;
      if j <> imax then begin  {* Interchange rows if needed *}
         for k := 1 to n do begin
	    Equate_Zs(dum_z,a[imax,k]);
            Equate_Zs(a[imax,k],a[j,k]);
            Equate_Zs(a[j,k],dum_z);
         end;
         d := -d;
         vv[imax] := vv[j];  {* Interchange the scale factor *}
      end;
      indx[j] := imax;
      if co_mag(a[j,j]) = 0.0 then a[j,j].r := tiny;
      if j <> n then begin
         Rc (z_dum, a[j,j]);  {complex reciprocal-creates pointer z_dum}
         for i := j+1 to n do begin
	    prp (dum_z, a[i,j], z_dum); {! is this legal?}
	    Equate_Zs (a[i,j], dum_z); {*a[i,j] := a[i,j]*z_dum *}
         end;
      end;
   end;
end;  {* LU_Decomp *}


Procedure LU_Sub(VAR a : s_conv_matrix;
                     n : integer;
              VAR indx : s_conv_index;
                 VAR b : s_conv_vector);
{*
	Routine for L-U forward and backward substitution,
	needed to solve for linear systems and do matrix inversions.

	The following types are used here:

	s_conv_matrix = array [1..conv_size,1..conv_size] of complex;
	s_conv_vector = array [1..conv_size] of complex;
	s_conv_index  = array [1..conv_size] of integer;
*}
var
   j,ip,ii,i   : integer;
   sum,dum_z   : TComplex;

Begin
   ii := 0;
   for i := 1 to n do begin
      ip := indx[i];
      Equate_Zs(sum,b[ip]);  { sum := b[ip]  }
      Equate_Zs(b[ip],b[i]); { b[ip] := b[i] }
      if ii <> 0 then
         for j := ii to i-1 do
            Diffpr(sum,a[i,j],b[j])  { sum := sum-a[i,j]*b[j] }
      else if (co_mag(sum) <> 0.0) then
         ii := i;
      Equate_Zs(b[i],sum);
   end;
   for i := n downto 1 do begin
      Equate_Zs(sum,b[i]);
      for j := i+1 to n do
         Diffpr(sum,a[i,j],b[j]);   { sum := sum-a[i,j]*b[j] }
      Rc (dum_z, a[i,i]);  { complex reciprocal - new pointer }
      Prp(b[i],sum,dum_z);  {! is this legal?}
   end;
end; {* Lub_Sub *}


Procedure Matrix_Inversion(VAR a : s_conv_matrix; n : integer);
{*
  	Uses the LU decomposition and substitution
	routines to invert the matrix "a" of size n x n.

	The original matrix "a" is destroyed and replaced
	with its inverse.

	Inversion is performed column by column.
*}
Var
   i,j       : integer;
   d         : double;
   co_0,co_1 : TComplex;
   indx      : s_conv_index;
   col       : s_conv_vector;
   y	     : s_conv_matrix;

Begin
  Co(co_0,0.0,0.0); {complex zero}
  Co(co_1,1.0,0.0); {complex one}
  LU_Decomp(a,n,indx,d);    {* LU decomposition of matrix a *}
  for j:= 1 to n do begin
    for i := 1 to n do Equate_Zs(col[i],co_0); {fill column with zeros}
    Equate_Zs(col[j],co_1);  {Put 1+j0 in the proper position}
    LU_Sub(a,n,indx,col);
    for i:= 1 to n do Equate_Zs(y[i,j],col[i]);
  end;
  {* Fill Matrix "a" with data in "y" *}
  for j:= 1 to n do
    for i:=1 to n do Equate_Zs(a[i,j],y[i,j]);
end; {* Matrix_Inversion *}


Procedure Matrix_Mux(VAR a,b,c : s_conv_matrix;
			     n : integer);
{*
	Performs the matrix multiplication:
		a = b * c
	  where a,b,c are matrices of complex numbers
	  each of dimension n x n.
	Matrices b and c are unaffected.
	It is assumed that all matrices are initialized.
*}
Var
  i,k,j       : integer;
  sum,co_0    : TComplex;

Begin
  co(co_0,0.0,0.0);
  for j:=1 to n do begin
    for i:=1 to n do begin
      Equate_Zs(sum,co_0);  {initialize sum to zero}
      for k:=1 to n do Supr(sum,b[i,k],c[k,j]);
      	{* sum:= sum + b[i,k]*c[k,j] *}
      Equate_Zs(a[i,j],sum); {fill matrix "a"}
    end;
  end;
end;  {* Matrix_Mux *}


Procedure Matrix_Conv(Var a: s_conv_matrix; n : integer);
{*
	Performs the calculation:

	   A := (I - A)(I + A)^(-1)

	Used to convert between S and Y matrices

	Defined are B = (I - A) and C = (I + A)

	When converting from a two port to a three port
	the s-parameters are switched such that  2 <-> 3
	for each of the port numbers.  This causes the
	(indefinite) ground to be created at port 2,
	and is easier to use in the layout window.
*}
Var
   i,j       : integer;
   b,c       : s_conv_matrix;
   co_0,co_1 : TComplex;

Begin
  co(co_0,0.0,0.0);
  co(co_1,1.0,0.0);
  {initialize pointers for c[i,j] b[i,j] and make copy of a[i,j]}
  for j:=1 to n do
      for i:=1 to n do begin
	if i=j then begin
	   di(b[i,j],co_1,a[i,j]); {di is complex difference}
	   su(c[i,j],co_1,a[i,j]); {su is complex sum}
        end
	else begin
	   di(b[i,j],co_0,a[i,j]); {di is complex difference}
	   Equate_Zs(c[i,j],a[i,j]); {su is complex sum}
        end;
  end;
  {* Now B = (I - A) and C = (I + A)  *}
  Matrix_Inversion(c,n);
  {* Now B = (I - A) and C = (I + A)^(-1)  *}
  Matrix_Mux(a,b,c,n);
  {* Now A = (I - A)(I + A)^(-1)  *}
end;  {* Matrix_Conv *}


Procedure Indef_Matrix(Var S : s_conv_matrix; n : integer);
{*
	Procedure for converting n port S matrix
	to n+1 port S matrix.
	Warning! The "S" pointers must be initialized to n+1 size!


	Steps:  1. S(n port) -> Y(n port)
		2. Y(n port) -> Y(n+1 port)
		3. Y(n+1 port) -> S(n+1 port)
*}
Var
  i,j         : integer;
  co_0,sum    : TComplex;

	{******************************************}
	Procedure Sign_Change(VAR z : TComplex);
	{*
		Change sign of complex number
	*}
	Begin
	  z.r:=-z.r;
	  z.i:=-z.i;
	end;
	{******************************************}
	Procedure Sum_Up(VAR z1,z2: TComplex);
	{*
		z1 = z1 +z2
	*}
	Begin
	  z1.r:=z1.r+z2.r;
	  z1.i:=z1.i+z2.i;
 	end;
	{*******************************************}
	Procedure Swap_2_and_3(VAR T : s_conv_matrix);
	{*
		Swap s-parameters between ports 2 and 3.
		To be called only for the 2 port device.
	*}
	Var
	  temp_z  : TComplex;
	Begin
	  {* S12 <-> S13 *}
	  Equate_Zs(temp_z,T[1,3]);
	  Equate_Zs(T[1,3],T[1,2]);
	  Equate_Zs(T[1,2],temp_z);
	  {* S21 <-> S31 *}
	  Equate_Zs(temp_z,T[3,1]);
	  Equate_Zs(T[3,1],T[2,1]);
	  Equate_Zs(T[2,1],temp_z);
	  {* S23 <-> S32 *}
	  Equate_Zs(temp_z,T[2,3]);
	  Equate_Zs(T[2,3],T[3,2]);
	  Equate_Zs(T[3,2],temp_z);
	  {* S22 <-> S33 *}
	  Equate_Zs(temp_z,T[3,3]);
	  Equate_Zs(T[3,3],T[2,2]);
	  Equate_Zs(T[2,2],temp_z);
	end;
	{********************************************}

Begin
  Matrix_Conv(S,n);  {Changes S to a normalized admittance matrix}
  {* Y n-port to Y n+1 port routine: *}
  Co(co_0,0.0,0.0);
  for j:=1 to n do begin
    Equate_Zs(sum,co_0); {initialize sum to complex zero}
    for i:=1 to n do begin
      Sum_Up(sum,S[i,j]);
    end;
    Sign_Change(sum);
    Equate_Zs(S[n+1,j],sum); {new value for Y[n+1,j] }
  end;
  for i:=1 to n do begin
    Equate_Zs(sum,co_0); {initialize sum to complex zero}
    for j:=1 to n do begin
      Sum_Up(sum,S[i,j]);
    end;
    Sign_Change(sum);
    Equate_Zs(S[i,n+1],sum); { new value for Y[i,n+1] }
  end;
  Equate_Zs(sum,co_0); {initialize sum to complex zero}
  for i:=1 to n do
    for j:=1 to n do Sum_Up(sum,S[i,j]);
  Equate_Zs(S[n+1,n+1],sum); { new value for Y[n+1,n+1] }
  Matrix_Conv(S,n+1);  {Change from Y to indef S matrix}
  if (n=2) then Swap_2_and_3(S);
  {* Exchange ports 2 and 3 for the 3 port indef *}
end; {* Indef_Matrix *}



function HeapFunc(Size: word) : integer;
{*
	A call is made to this function whenever a call to
	New or GetMem cannot be completed i.e. when no room
	remains on the heap. The net result of setting
	HeapFunc:=1 is that New and GetMem will then return
	a nil pointer and the program will not be aborted
	with a 203 error.

	In TP 6.0 a quick exit is required for Size=0
*}
begin
  if (Size > 0) then begin
    if message[3] <> ' Exhausted ' then begin
        erase_message;
	message[1]:='  DANGER!  ';
	message[2]:='  Memory   ';
	message[3]:=' Exhausted ';
	if window_number=2 {plot window} then begin
		write_message;
		delay(1500);
	end
	else
		shutdown;
    end;
    HeapFunc := 1;
  end; {if Size }
end; {* HeapFunc *}





{************* METHODS FOR THE SWEEP OBJECT ******************}

Procedure Sweep.Init_Use;
{*
	Reset sweep object.
*}
Begin
  element:=nil;
  used:=false;
  Alt_Sweep:=false;  {this is a global variable}
  unit_label:='';
  index:=0;
end;  {* Init_Use *}


Procedure Sweep.Init_Element(tcompt: compt; in_id,in_prefix,in_unit : char);
{*
	Initialize the sweep object element if it hasn't been
	previously initialized. Called by lumped,clines,tline,etc.

*}
const
  potential_units: set of char = [degree,Omega,'m','h',
  				  's','S','z','Z','y','Y','Q'];

Begin
  if not(used) then begin
     used:=true;
     element:=tcompt;  {element points to compt}
     id:=in_id;
     prefix:=in_prefix;
     omega0:=2*Pi*design_freq*Eng_Prefix(freq_prefix);
     {convert design Freq to rad/sec times prefix}
     units:=in_unit;
     alt_sweep:=true;  {this is a global flag}
     tcompt^.sweep_compt:=true;  {tell tcompt that its the sweep}
     part_label:='Part '+ tcompt^.descript[1];
     if prefix in Eng_Dec_Mux then unit_label:=prefix
     			      else unit_label:='';
     if (id='j') then unit_label:='j'+ unit_label;
     if (id in ['F','H']) then
    	unit_label:=unit_label+id
     else if (id='a') then
    	unit_label:=unit_label+'dB'
     else if (id='t') then     {transformer is n:1}
    	unit_label:=unit_label+'n:1'
     else if (units in potential_units) then
    	unit_label:=unit_label+units;
  end
  else begin
     element^.changed:=True; {Force re-parsing of last ?}
     Init_Use;   {clear current alt_param}
     tcompt^.sweep_compt:=false;
     bad_compt:=true;
     message[1]:='Parts list has';
     message[2]:='multiple sweep';
     message[3]:='parameters';
  end;
end; {* Init_Element *}


Procedure Sweep.Check_Reset(tcompt : compt);
{*
	See if a previous sweep_compt part has been changed.
	Called by Pars_Compt_List;
*}
Begin
  if (element=tcompt) and tcompt^.changed then begin
  	Init_Use;
	tcompt^.sweep_compt:=false;
  end;
end; {* Check_Reset *}


Procedure Sweep.Label_Axis;
{*
	Label x axis of x-y plot and Smith plot.
*}
var
  label_string : line_string;
  label_lngth : integer;

Begin
    label_string:=part_label+' : '+unit_label;
    label_lngth:=Length(label_string);
    GotoXY(x_y_plot_text[5,1]+2-label_lngth div 2,x_y_plot_text[5,2]);
    Write(label_string);
end; {* Label_Axis *}


Procedure Sweep.Label_Plot_Box;
{*
	Label data in plot window from frequency to alt_param.
*}
Var
  i : integer;
Begin
    GotoXY(xmin[2],ymin[2]+2);
    Write(part_label); {write part label over 'f'}
    GotoXY(xmin[2]+17,ymin[2]+2);
    Write(unit_label);
    if (Length(unit_label)<=2) then
    	for i:=0 to (2-Length(unit_label)) do Write(' ');
end; {* Label_Plot_Box *}


Procedure Sweep.Load_Prop_Const(const prop_consta,prop_constb : double);
{*
   Load in proportionality constants to be used in sweep calculations.
*}
Begin
  prop_const1:=prop_consta;
  prop_const2:=prop_constb;
end;


Procedure Sweep.Load_Index(i : integer);
{*
   Read index for lumped element and clines sweep_compt.
      LUMPED
   	i=1 : resistance
	i=2 : + reactance or susceptance
	i=3 : - reactance or susceptance
      CLINES
   	i=1 : even mode impedance only
	i=2 : odd mode impedance only
	i=3 : even and odd mode impedances given, even is the variable
	i=4 : even and odd mode impedances given, odd is the variable
*}
Begin
  index:=i;
  if (id='j') and (index=3) then unit_label:='-'+unit_label;
  {identify negative X's and B's}
end; {* Load_Index *}


Procedure Sweep.Load_Data(CONST sweep_data : double);
{*
	Read data during alternate parameter sweep.

	Parse data and place in appropriate element
	location.
*}
Begin
  new_value:=sweep_data*Eng_Prefix(prefix);
  if (new_value=0.0) then new_value:=1.0/infty;  {make 1e-35}
  Case element^.typ of
   'x','a'  : element^.zed:=new_value;
   'q','t'  : begin
      		Case units of
		   omega   :  element^.zed:=new_value;
		   's','S' :  element^.zed:=1.0/new_value;
		   'z','Z' :  element^.zed:=z0*new_value;
		   'y','Y' :  element^.zed:=z0/new_value;
		   degree  :  element^.wavelength:=new_value/360.0;
		   'm'   :  element^.wavelength:=1000.0*new_value*prop_const1;
		   		{must put in mm}
		   'h','H' : element^.wavelength:=new_value*prop_const1;
		       'Q' : begin
		   		element^.alpha_c:=(Pi*element^.wavelength)/
					(new_value*element^.lngth0);
				element^.alpha_d:=0.0;
			     end;
		   end;
      	     end;
      'c'  : begin  {Coupled lines}
      		Case units of  {fix impedances later using index}
		   {omega  :  new_value:=new_value;}
		   's','S' :  new_value:=1.0/new_value;
		   'z','Z' :  new_value:=z0*new_value;
		   'y','Y' :  new_value:=z0/new_value;
		   degree  :  begin
		   	  element^.wavelength:=new_value*prop_const1/360.0;
		   	  element^.wavelengtho:=new_value*prop_const2/360.0;
			      end;
		   'm'   :  begin
		          element^.wavelength:=1000.0*new_value*prop_const1;
		          element^.wavelengtho:=1000.0*new_value*prop_const2;
			    end;
		      {Use factor of 1000 to put in mm}
		   'h','H' : begin
		   	  element^.wavelength:=new_value*prop_const1; {even}
		   	  element^.wavelengtho:=new_value*prop_const2; {odd}
			     end;
		      {for 'h' substrate_h has been factored in prop_const1}
		end; {case units}
		Case index of {if an impedance, fix it up}
		   1 : begin
		   	  element^.zed:=new_value;
			  if (new_value>1.0e-17) then
			       element^.zedo:=sqr(z0)/new_value
			     else
			       element^.zedo:=sqrt(infty);
		       end;
		   2 : begin
		   	  element^.zedo:=new_value;
			  if (new_value>1.0e-17) then
			       element^.zed:=sqr(z0)/new_value
			     else
			       element^.zed:=sqrt(infty);
		       end;
		   3 : element^.zed:=new_value; {both given, even var}
		   4 : element^.zedo:=new_value; {both given, odd var}
		end; {case index}
      	     end;
      'l'  : begin {use index to find what lumped value is to be changed}
      		if (id in ['F','H']) then
		  if index=2 then
		  	new_value:=Omega0*new_value
		  else if index=3 then
		  	new_value:=1.0/(Omega0*new_value);
		Case units of
		    omega   :  new_value:=new_value/z0;
		    { 'z','Z','y','Y' :  new_value:=new_value; }
		    's','S' :  new_value:=new_value*z0;
		end; {case units}
		Case index of
		  1 : element^.zed:=new_value;
		  	{resistance or conductance}
		  2 : element^.zedo:=new_value;
		  	{+ reactance or susceptance}
		  3 : element^.wavelength:=-new_value;
		  	{- reactance or susceptance}
			{need minus sign to work for j's}
		end; {Case index}
      	     end; {Case 'l'}
  end; {case}
end; {* Load_Data *}


(************* Memory Management ********************)




Const memsize=2*1024*1024;
Var membase : Pointer;
    memused : Longint;

PROCEDURE Init_Mem;
BEGIN
    getmem(membase,memsize);
    if (membase=NIL) then begin
       WriteLn ('Memory allocation error!!');
       Halt;
    end;
    memused:=0;
END;

FUNCTION Mem_Left: LONGINT;
BEGIN
  Mem_Left:= memsize-memused;
END;

procedure mygetmem(var p: pointer; size: longint);
begin
  p := membase+memused;
  memused := memused+size;
end;

PROCEDURE New_c (VAR P: PMemComplex);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE New_s (VAR P: s_param);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE New_plot (VAR P: plot_param);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE New_spline (VAR P: spline_param);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE New_n (VAR P: net);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE New_conn (VAR P: conn);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE New_compt (VAR P: compt);
BEGIN
  myGetMem (P, SizeOf (P^));
END;

PROCEDURE Mark_Mem (VAR P: marker);
BEGIN
  P.used := memused;
END;

PROCEDURE Release_Mem (VAR P: marker);
BEGIN
  if (P.used>=0) then memused := P.used;
END;

PROCEDURE Init_Marker (VAR P: marker);
BEGIN
  P.used := -1;
END;

FUNCTION Marked (VAR P: marker): BOOLEAN;
BEGIN
  Marked:= (P.used >=0 );
END;


PROCEDURE Copy_Networks (NetStart, NetEnd: marker; VAR CopyNetStart: marker);
{*
	Make a copy of the circuit for 'destructive' analysis.
*}
VAR
  Size: LONGINT;
  SrcOfs, DestOfs: LONGINT;

  FUNCTION Min (a, b, c: LONGINT): LONGINT;
  BEGIN
    IF (a < b) THEN BEGIN
      IF (a < c) THEN Min:= a ELSE Min:= c;
    END ELSE BEGIN
      IF (b < c) THEN Min:= b ELSE Min:= c;
    END;
  END;

BEGIN
  Size := NetEnd.used - NetStart.used;
  IF (NOT Marked(CopyNetStart)) THEN BEGIN
    IF (memused + Size + 1024 >= MemSize) THEN Exit;
    CopyNetStart.Used:= memused;
    memused:= memused + Size;
    DestOfs:= CopyNetStart.used;
    SrcOfs:= NetStart.used;
  END ELSE BEGIN
    SrcOfs:= CopyNetStart.used;
    DestOfs:= NetStart.used;
  END;
  Move ( (membase+SrcOfs)^, (membase+DestOfs)^, Size);

END;


function No_mem_left : boolean;
{*
	Check to see that there is at least a 16 byte
	block of memory remaining on the heap.
*}
begin
   if Mem_Left < 1024 then No_mem_left := true
   		      else No_mem_left := false;
end;


PROCEDURE SetCol(col: word);
BEGIN
  IF (blackwhite) THEN
    CASE col OF
      0    : SetColor(0);
{      1..7 : SetColor(lightgray); }
      8    : SetColor(0);
      ELSE SetColor(white);
    END
  ELSE
    SetColor(col);
END;

PROCEDURE TextCol(col: word);
BEGIN
  IF ((blackwhite) AND (col <> black)) THEN
    TextColor(white)
  ELSE
    TextColor(col);
END;




END.
