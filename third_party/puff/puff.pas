{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


{**********************************************************************

Puff

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer.

	Last Modifications made by Andreas Gerstlauer, 10/98
	Last compiled with Borland Turbo Pascal 7.01

        Modifications for Linux compilation 2000-2007 Pieter-Tjerk de Boer.

	Code cleanup for Linux only build 2009 Leland C. Scott.
 
	Original code released under GPLv3, 2010, Dave Rutledge.


	NOTES:

	Code now in external units:
	* Artwork routines
	* Puff initialization
	* Puff FFT routines
	* Smith Chart code
	* Disk I/O

        PUFF.PAS Main program unit contains:
	* Main analysis routines
 	* Main circuit drawing functions
	* Main flow of control

************************************************************************}

program PUFF;

Uses
  dos,
  xgraph,	{Custom replacement for TUBO's "Crt" and "Graphics" units}
  initc,
  pfun1,
  pfun2,
  pfun3,
  pfart, 	{artwork code}
  pfrw,  	{puff file read/write code}
  pfst,  	{puff start code}
  pfmsc, 	{Smith chart, help, and device file reading}
  pffft; 	{puff FFT code}

procedure Pick_Smith(smith_type : boolean);
{*
	Pick which Smith chart to draw.
	When smith_type is true then admittance chart selected.
	Both Smith chart routines are in PFST.PAS
*}
begin
  clear_window_gfx(xmin[10],ymin[10],xmax[10],ymax[10]);
  	{Erase Smith Chart region}
  Draw_EGA_Smith(not(smith_type));
  if Large_Smith then Write_BigSmith_Coordinates;
end; {*Pick_Smith *}


Procedure Change_Bk_Color;
{*
	Used to toggle background color.
	if next_color true then change to next color.
	if next_color false then change to last color.
*}
var
    color_var : word;
(*    Last_Palette : PaletteType; *)

Begin
    color_var:=GetBkColor;
    if color_var=Black then SetBkColor(Blue)
     		       else SetBkColor(Black);
end; {* Change_Bk_Color *}


{************* Main Circuit Drawing Functions *****************}

function port_or_node_found : boolean;
{*
	 Calls node_look to look for a node then
	 looks for a port at current cursor postion.
*}
var
  i : integer;

begin
  node_look;
  if cnet <> nil then 
    port_or_node_found:=true 
  else begin
    port_or_node_found:=false;
    for i:=1 to min_ports do
    if (abs(portnet[i]^.xr-xm)< resln) and not(portnet[i]^.node) and
       (abs(portnet[i]^.yr-ym)< resln) then begin
         port_or_node_found:=true;
         join_port(i,1);
         exit
    end;
  end; {if cnet}
end; {port_or_node_found}


function Coupler_Jump(cur_dir : integer) : boolean;
{*
	Check for drawing direction across the 
	ends of a clines part. 

	cur_dir returns 1:up, 2:right, 4:left, 8:down

	Called by Move_Net(dirnt,ivt : integer);
*}
var
  tcon		: conn; 

  port,d2	: integer;
  coupler_skip  : boolean;

begin 
  coupler_jump:=false;
  coupler_skip:=false;
  if cnet <> nil then begin
     {see if a cline is at this connection} 
     tcon:=nil;
     repeat  
      if tcon=nil then tcon:=cnet^.con_start 
      		  else tcon:=tcon^.next_con;
      if tcon^.mate <> nil then
      if tcon^.mate^.net^.com^.typ='c' then begin   {found cline}
         d2:=tcon^.dir;
         port:= tcon^.mate^.conn_no;
         case d2 of     {* check conditions for jumping over ends *}
           1 : if ( (port=1)and(cur_dir=4) or (port=3)and(cur_dir=2)
	   	  or (port=2)and(cur_dir=2) or (port=4)and(cur_dir=4) )
		   then coupler_skip:=true;
	   2 : if ( (port=1)and(cur_dir=8) or (port=3)and(cur_dir=1)
	   	  or (port=2)and(cur_dir=1) or (port=4)and(cur_dir=8) )
		   then coupler_skip:=true;
           4 : if ( (port=1)and(cur_dir=1) or (port=3)and(cur_dir=8)
	   	  or (port=2)and(cur_dir=8) or (port=4)and(cur_dir=1) )
		   then coupler_skip:=true;
           8 : if ( (port=1)and(cur_dir=2) or (port=3)and(cur_dir=4)
	   	  or (port=2)and(cur_dir=4) or (port=4)and(cur_dir=2) )
		   then coupler_skip:=true;
         end; {case}
      end; {if found cline}
    until (tcon^.next_con=nil) or (coupler_skip);
  end; {if cnet <> nil}
  if coupler_skip then begin   {move ports: 1->3, 2->4, 3->1, 4->2}
        case port of
          1,2 : cnet:=tcon^.mate^.next_con^.next_con^.mate^.net;
          3   : cnet:=tcon^.mate^.net^.con_start^.mate^.net;
          4   : cnet:=tcon^.mate^.net^.con_start^.next_con^.mate^.net;
        end; {case}
        increment_pos(0);
	coupler_jump:=true;
        iv:=0; {! This is for dx_dy }
  end;
end; {* Coupler_Jump *}


procedure Add_Net;
{*
	Connect up a new network to circuit.

	For the clines it must check for proper directions.
*}
var
  i    			: integer;
  vcon 			: conn;
  vnet 			: net;
  special_coupler 	: boolean;


  	{************************************************************}
  	function occupied_portO : boolean;
	{*
		Don't allow cursor to step over path to external port.
	*}
	var
	   i : integer;

	begin
	  occupied_portO:=false;
	  for i:=1 to min_ports do
	   with portnet[i]^ do begin
	     if (abs(xr-xm)<resln) and (abs(yr-ym)<resln) and node then begin
		occupied_portO:=true;
		snapO;  {jump back to circuit from port}
	     end;
          end; {for-with}
        end; {occupied_portO}
	{****************************************************************}

begin
  special_coupler:=look_backO;
  if not(off_boardO(1.0) or occupied_portO) then begin
    {Set flag if part from extra list has been used}
    if (compt1^.descript[1] in ['j'..'r']) then 
    	Extra_Parts_Used:=True;
    compt1^.used:=compt1^.used+1;
    vnet:=new_net(compt1^.number_of_con,false);
    Draw_Net(vnet);
    for i:=1 to compt1^.number_of_con do begin
      if special_coupler and (i in [1,3]) then begin
         cnet:=Mate_Node[i];
         cnet^.number_of_con:=cnet^.number_of_con+1
      end
      else begin
        if port_or_node_found then
		cnet^.number_of_con:=cnet^.number_of_con+1 {advance count}
             else
	        cnet:=new_net(1,true);  {or make new node}
      end;
      vcon:=new_con(vnet,dirn);
      vcon^.conn_no:=i;
      ccon:=new_con(cnet,dirn);
      if (vnet^.com^.typ in ['i','d']) and (i<>1)
      	and (i<>compt1^.number_of_con) then begin
           case dirn of
	     2,4 : begin
                     vcon^.dir:=6;
		     ccon^.dir:=6;
                   end;
	     1,8 : begin
                     vcon^.dir:=9;
                     ccon^.dir:=9;
                   end;
           end; {case}
      end; {if}
      ccon^.mate:=vcon;
      vcon^.mate:=ccon;
      if i <> compt1^.number_of_con then increment_pos(i);
    end; {for i}
  end; {if not off_boardO}
end; {* Add_Net *}


procedure rem_net;
{*
	Remove a network from the circuit.
*}
var
  i,sdirn : integer;
  mnode,snet,onet : net;

begin
  if not(port_dirn_used) then begin
    snet:=nil;
    cnet^.com^.used:=cnet^.com^.used-1;
    for i:=1 to cnet^.number_of_con do begin
      if i=1 then ccon:=cnet^.con_start
      	     else ccon:=ccon^.next_con;
      mnode:=ccon^.mate^.net;
      dispose_con(ccon^.mate);
      with mnode^ do if number_of_con=1 then begin
         onet:=cnet;
	 cnet:=mnode;
	 sdirn:=dirn;
         if ext_port(con_start) then join_port(con_start^.port_type,0);
         cnet:=onet;
	 dirn:=sdirn;
      end;
      if mnode^.number_of_con > 0 then snet:=mnode;
    end; {for i}
    lengthxy(cnet);
    increment_pos(1);
    dispose_net(cnet);
    node_look;
    if cnet=nil then begin
       cnet:=snet;
       if cnet <> nil then increment_pos(0);
    end;
    if read_kbd then draw_circuit;
  end; {if not port}
end; {rem_net}


procedure step_line;
{*
	Step a distance = 1/2 part size,
	on exit cnet points to node if found.
*}
begin
  if not(port_dirn_used or off_boardO(0.5)) then begin
    compt1^.step:=true;
    increment_pos(-1);
    node_look;
  end; {if not port}
end; {step_line} 


procedure step_over_line;
{*
	Step over a line, on exit cnet points to node.
         Enter:cnet=network that you are stepping over. 
         Exit:cnet=node
*}
var
  tcon : conn;

  i,j  : integer;

begin
  if not(port_dirn_used) then begin
    iv:=0; {! This is for dx_dy }
    tcon:=ccon^.mate;
    if cnet^.number_of_con=1 then begin
      message[1]:='Cannot step';
      message[2]:='over 1 port';
      update_key:=false;
      cnet:=cnet^.con_start^.mate^.net;
    end 
    else begin
      if (cnet^.com^.typ in ['i','d']) then begin
        if dirn=cnet^.con_start^.dir then 
	    cnet:=tcon^.next_con^.mate^.net
        else begin
            j:=tcon^.conn_no-1;
	    tcon:=cnet^.con_start;
	    for i:=2 to j do tcon:=tcon^.next_con;
	    cnet:=tcon^.mate^.net;
        end;
      end
      else begin {if not a device}
        case tcon^.conn_no of
          1,3 : cnet:=tcon^.next_con^.mate^.net;
          2   : cnet:=cnet^.con_start^.mate^.net;
          4   : cnet:=cnet^.con_start^.next_con^.next_con^.mate^.net;
        end; {case}
      end;
      increment_pos(0);
    end;
  end; {if not port}
end; {step_over_line}


procedure Move_Net(dirnt,ivt:integer);
{*
	Procedure for calling either
		rem_net :  delete part from the circuit
		step_over_line : jump to opposite end of current part 
		step_line : move half the distance of current part
		add_net : add part (net) to circuit
		if coupler_jump() then jump across clines ends
*}
begin
  if compt1^.parsed and not(missing_part) then begin
    dirn:=dirnt;
    iv:=ivt;
    if con_found then
    	if iv=0 then rem_net
		else step_over_line
    else
	if iv=0 then step_line
		else if not(coupler_jump(dirnt)) then add_net;
  end
  else begin
    erase_message;
    if not(read_kbd) then begin      {if problem during circuit read}
      key:=F3;
      read_kbd:=true;
      compt3:=ccompt;
      cx3:=compt3^.x_block;
      message[1]:='Part used in';
      message[2]:='layout has been';
      message[3]:='deleted';
      GotoXY(checking_position[1],checking_position[2]);
      Write('                  ');  {delete 'checking circuit'}
    end
    else
       message[2]:='Invalid part';
    update_key:=false;
  end; {if parsed}
end; {* Move_Net *}


Procedure Pars_Compt_List;
{*
	Pars the component list.
	If action=true then find part dimensions 
		       else find s-parameters.

	Careful here on memory management!
*}
var
  pars,reload_all_devices  : boolean;
  tcompt    : compt;

begin
  if action then begin   {Check for alt_sweep and device file changes}
     tcompt:=nil;
     reload_all_devices:=false;
     Repeat   {step through and Reset if a sweep_compt was changed}
       if tcompt=nil then tcompt:=part_start
    	 	     else tcompt:=tcompt^.next_compt;
       x_sweep.Check_Reset(tcompt);
       if tcompt^.changed
       		and (get_lead_charO(tcompt) in ['i','d']) then begin
	 if (Marked (dev_beg)) then Release_Mem(dev_beg);      {Release Device}
	 Mark_Mem(dev_beg);  {re-mark block}	       {memory block}
	 Init_Marker (net_beg);  {net memory sits above device memory}
	 circuit_changed:=true;  {force Redraw_circuit to reset net_beg}
	 reload_all_devices:=true; {forces all device files to be reloaded}
       end;
     Until (tcompt^.next_compt=nil);
     if reload_all_devices then begin   {Check for unchanged devic files}
       tcompt:=nil;
       Repeat   {force all device files to be reloaded at marker dev_beg}
         if tcompt=nil then tcompt:=part_start
    	 	       else tcompt:=tcompt^.next_compt;
         if (get_lead_charO(tcompt) in ['i','d']) then
	 	tcompt^.changed:=True;
       Until (tcompt^.next_compt=nil);
     end;
  end;
  tcompt:=nil;
  bad_compt:=false;
  repeat
    if tcompt=nil then tcompt:=part_start
    		  else tcompt:=tcompt^.next_compt;
    with tcompt^ do begin
      if changed and ((used > 0) or step) then circuit_changed:=true;
      if action then pars:=changed
      		else pars:=used > 0;
      if pars then begin
         parsed:=true;
         if action then begin
	     typ:=get_lead_charO(tcompt);
	     sweep_compt:=false;  {init to check for alt_sweep-needed?}
	 end;
         case typ of
          't'  : tlineO(tcompt);
	  'q'  : qline(tcompt);
          'c'  : clinesO(tcompt);
          'd',
	  'i'  : if action then Device_Read(tcompt,(typ='i'))
	  		   else Device_S(tcompt,(typ='i'));
          'l'  : lumpedO(tcompt);
	  'x'  : transformer(tcompt);
	  'a'  : attenuator(tcompt);
          ' '  : parsed:=false;
          else begin
            parsed:=false;
            bad_compt:=true;
            message[1]:=typ+' is an';
            message[2]:='unknown part';
          end;
        end; {case}
      end; {if pars}
      if not(bad_compt) then changed:=false
      			else if window_number=3 then ccompt:=tcompt;
    end; {with}
  until ((tcompt^.next_compt=nil) or bad_compt);
  if bad_compt then write_message;
end; {* Pars_Compt_List *}


Procedure Pars_Single_Part(tcompt : compt);
{*
   Pressing the "=" sign will cause a tline or clines
   to be parsed, and the values of the computations
   to be displayed.  This only works with 
   tlines, qlines, and clines.
*}
const
   pos_prefix : string = 'EPTGMk m'+Mu+'npfa';

Var
  i 	      : integer;
  d_s,avg_ere : double;

  	{*****************************************************}
	Procedure Big_Check(var dt : double; var i_in : integer);
	Begin
	  while (abs(dt)>1000.0) do begin
	     dt:=dt/1000;
	     Dec(i_in);   {set-up prefix change}
	  end;
        end;
  	{*****************************************************}
	Procedure Small_Check(var dt : double; var i_in : integer);
	Begin
	  while (abs(dt)<0.01) do begin
	     dt:=dt*1000;
	     Inc(i_in);   {set-up prefix change}
	  end;   
        end;
	{*****************************************************}
 
Begin
  erase_message;
  action:=true;
  bad_compt:=false;
  with tcompt^ do begin
     changed:=true;   {force future re-parsing and check reset}
     x_sweep.Check_Reset(tcompt);  {init x_sweep for later re-parsing}
     typ:=get_lead_charO(tcompt);
     case typ of
          't'  : tlineO(tcompt);
	  'q'  : qline(tcompt);
          'c'  : clinesO(tcompt);
        else beep;
     end; {case}
     if bad_compt then begin
     	write_message;
     end
     else if (typ in['t','q','c']) then begin
       if super then begin
         TextCol(lightgray);
	 GotoXY(xmin[6]+2,ymin[6]);
         if (typ in ['t','q']) then Write('Z : ',zed:7:3,Omega);
	 if (typ='c') then begin
           Write('Ze: ',zed:7:3,Omega);
           GotoXY(xmin[6]+2,ymin[6]+1);      
           Write('Zo: ',zedo:7:3,Omega);
	   if stripline then
	      avg_ere:=er
            else
	      avg_ere:=4*e_eff_e0*e_eff_o0/sqr(sqrt(e_eff_e0)+sqrt(e_eff_o0));
	   GotoXY(xmin[6]+2,ymin[6]+2);      
	   Write('l : ',(lngth0*sqrt(avg_ere)*360/lambda_fd):7:3,Degree);
         end 
	 else begin
          GotoXY(xmin[6]+2,ymin[6]+1);      
          Write('l : ',(wavelength*360):7:3,Degree);
	 end;  
       end {if super}
       else begin
         TextCol(lightgray);
	 i:=8;  {specify prefix for mm}
	 d_s:=lngth;
	 {Check for large or small values of d_s}
	 if (d_s<>0.0) then begin
	 	Big_Check(d_s,i);
		Small_Check(d_s,i);
	 end;
	 GotoXY(xmin[6]+2,ymin[6]);
         Write('l: ',d_s:7:3,pos_prefix[i],'m');
	 i:=8;  {specify prefix for mm}
	 d_s:=width;
	 {Check for large or small values of d_s}
	 if (d_s<>0.0) then begin
	 	Big_Check(d_s,i);
		Small_Check(d_s,i);
	 end;
         GotoXY(xmin[6]+2,ymin[6]+1);      
         Write('w: ',d_s:7:3,pos_prefix[i],'m');
	 if typ='c' then begin
	   i:=8;  {specify prefix for mm}
	   d_s:=con_space-width;
	   {Check for large or small values of d_s}
	   if (d_s<>0.0) then begin
	 	Big_Check(d_s,i);
		Small_Check(d_s,i);
	   end;
           GotoXY(xmin[6]+2,ymin[6]+2);      
           Write('s: ',d_s:7:3,pos_prefix[i],'m');
         end;
       end;
     end;  {typ in}
  end; {with}
end; {* Pars_Single_Part *}


procedure Board_Parser; 
{*
	Parse the entries in the board parameter list.
*}
var
  tcompt 		: compt;
  value  		: double;
  unit_type,prefix 	: char;
  value_str        	: line_string;
  alt_param		: boolean;

begin
  tcompt:=nil;
  bad_compt:=false;
  repeat
    if tcompt=nil then tcompt:=board_start 
    		  else tcompt:=tcompt^.next_compt;
    with tcompt^ do begin
      if changed then begin
         Board_Changed:=true;
         parsed:=true;
	 typ:=descript[1]; {first letter gives parameter}
	 Get_Param(tcompt,1,value,value_str,unit_type,prefix,alt_param);
	   {! if unit is 'm' then value is returned in mm}
	   {Otherwise prefix is factored in}
	 if not(bad_compt) then begin
          case typ of
          'z'  : if (value > 0) and (unit_type=Omega) then begin
	  		z0:=value;
			s_board[1,1]:=value_str;
			s_board[1,2]:=prefix;
		 end
	  	 else begin
			Message[3]:='in zd';
		 	bad_compt:=true;
		 end;
          'f'  : if (value > 0) and (unit_type='H') then begin
	  		design_freq:=value/Eng_prefix(prefix);
			{!normalize-take out the prefix}
			s_board[2,1]:=value_str;
			s_board[2,2]:=prefix;
			freq_prefix:=prefix;
		 end
		 else begin
			Message[3]:='in fd';
		 	bad_compt:=true;
		 end;
          'e'  : if (value > 0) and (unit_type='?') then begin
	  		er:=value;
			s_board[3,1]:=value_str;
			s_board[3,2]:=prefix;
		 end
		 else begin
			Message[3]:='in er';
		 	bad_compt:=true;
		 end;
          'h'  : if (value > 0) and (unit_type='m') then begin
	  		substrate_h:=value;
			s_board[4,1]:=value_str;
			s_board[4,2]:=prefix;
		 end
		 else begin
			Message[3]:='in h';
		 	bad_compt:=true;
		 end;
          's'  : if (value > 0) and (unit_type='m') then begin
	  		bmax:=value;
			s_board[5,1]:=value_str;
			s_board[5,2]:=prefix;
			{Ensure con_sep re-calculation}
			{since it's effected by bmax}
			tcompt^.next_compt^.changed:=true;
		 end
		 else begin 
			Message[3]:='in s';
		 	bad_compt:=true;
		 end;
          'c'  : if (value >= 0) and (unit_type='m') then begin
	  		con_sep:=value;
			s_board[6,1]:=value_str;
			s_board[6,2]:=prefix;
		 end
		 else begin 
			Message[3]:='in c';
		 	bad_compt:=true;
		 end;
          end; {case}
	  if bad_compt then Message[2]:='Bad value or unit';
        end; {if not(bad_unit)}
      end; {if changed}
      if not(bad_compt) then changed:=false
                        else if window_number=4 then ccompt:=tcompt;
    end; {with}
  until ((tcompt^.next_compt=nil) or bad_compt);
  if bad_compt then write_message;
end; {* Board_Parser *}


procedure Get_Coords;
{*
	Get values of coordintes in Plot window.
	symin and symax are used by other plotting
	routines.
*}
var
  tcoord : compt;

begin
  bad_compt:=false;  
  tcoord:=dBmax_ptr;        { point to dBmax value }
  symax:=get_real(tcoord,1);
  if bad_compt then exit;
  tcoord:=tcoord^.next_compt; { point to dBmin value }
  symin:=get_real(tcoord,1);
  if bad_compt then exit;
  if symin >= symax then begin
      bad_compt:=true; 
      message[1]:='Must have';
      message[2]:='dB(max) > dB(min)';
      ccompt:=tcoord;  
      exit;
  end;
  tcoord:=tcoord^.next_compt;  { point to fmin }
  sxmin:=get_real(tcoord,1);
  if bad_compt then exit;
  if (sxmin < 0) and not(Alt_Sweep) then begin
      bad_compt:=true; 
      message[1]:='Must have';
      message[2]:='frequency >= 0';
      ccompt:=tcoord;  
      exit;
  end;
  tcoord:=tcoord^.next_compt;  { point to fmax }
  sxmax:=get_real(tcoord,1);
  if bad_compt then exit;
  if (sxmax < 0) and not(Alt_Sweep) then begin
      bad_compt:=true; 
      message[1]:='Must have';
      message[2]:='frequency >= 0';
      ccompt:=tcoord;  
      exit;
  end;
  if sxmin >= sxmax then begin
      bad_compt:=true;
      message[1]:='Plot must have';
      message[2]:='x_max > x_min';
      ccompt:=tcoord;  
      exit;
  end;
  sfx1:=(xmax[8]-xmin[8])/(sxmax-sxmin);
  sfy1:=(ymax[8]-ymin[8])/(symax-symin);
  sigma:=(symax-symin)/100.0;
  rho_fac:=get_real(rho_fac_compt,1);
  if (rho_fac<=0.0) or bad_compt then begin
      bad_compt:=true;
      message[1]:='The Smith chart';
      message[2]:='radius must be >0';
      ccompt:=rho_fac_compt;
  end;
end; {* Get_coords *}


procedure Fill_Sa (out: BOOLEAN);
{*
	 Fill array sa with s-parameters and then load
	 into linked list of plot parameters ready for spline.
*}
var
  i,j,ij,sfreq 	: integer;
  tcon,scon    	: conn;
  s 		: s_param;
  sa            : array[1..max_params,1..max_params] of ^TComplex; {s-params array}

begin
  cnet:= net_start;
  FillChar (sa, SizeOf (sa), 0);
  IF (NOT bad_compt) THEN
    REPEAT
      tcon:= cnet^.con_start;
      IF (tcon <> NIL) THEN
        REPEAT
          j:=tcon^.port_type;
          s   := tcon^.s_start;
          scon:= cnet^.con_start;
          REPEAT
            i:=scon^.port_type;

            IF (s <> NIL) THEN BEGIN
              IF ((i*j > 0) AND (s^.z <> NIL)) THEN BEGIN
                sa[i,j]:= @(s^.z^.c);
              END;
              s   := s^.next_s;
            END;

            scon:= scon^.next_con;

          UNTIL (scon = NIL);

          tcon:= tcon^.next_con;

        UNTIL (tcon = NIL);

        cnet:= cnet^.next_net;

    UNTIL (cnet = NIL);

  sfreq:=xmin[8]+Round((freq-sxmin)*sfx1);
  for ij:=1 to max_params do begin
    IF (out) THEN Write_FreqO;  {re-calculates freq}
    if s_param_table[ij]^.calc then begin
      if xpt=0 then begin
         c_plot[ij]:=plot_start[ij];
         plot_des[ij]:=nil;
      end
      else
      	 c_plot[ij]:=c_plot[ij]^.next_p;
      plot_end[ij]:=c_plot[ij];
      if xpt=Round((design_freq-fmin)/finc) then plot_des[ij]:=c_plot[ij];
      {xpt is the point where the design freq. is located}
      c_plot[ij]^.filled:=false;
      case s_param_table[ij]^.descript[1] of
      's','S' : begin
                  i:=si[ij];
		  j:=sj[ij];
                  if sa[i,j] <> nil then begin
                    c_plot[ij]^.x:=sa[i,j]^.r;
		    c_plot[ij]^.y:=sa[i,j]^.i;
                  end
		  else begin
                    c_plot[ij]^.x:=0;
		    c_plot[ij]^.y:=0;
                  end;
                  c_plot[ij]^.filled:=true;
                end;
      end; {case}
      IF ((NOT (bad_compt)) AND (out)) THEN BEGIN
        write_sO(ij);
        calc_posO(c_plot[ij]^.x,c_plot[ij]^.y,0,1,sfreq,false);
        if spline_in_smith then box(spx,spy,ij);
	if not(Large_Smith) and spline_in_rect then box(sfreq,spp,ij);
      end;
    end; {if s_param}
  end; {for ij}
end; {* Fill_Sa *}


function get_s_and_remove(index : integer; var start : s_param):s_param;
{*
	Get an s-parameter from a linked list and remove it.
*}
var
  i : integer;
  s : s_param;

begin
  if index=1 then begin
    get_s_and_remove:=start;
    start:=start^.next_s;
  end
  else begin
    for i:=1 to index-1 do begin
      if i=1 then s:=start else s:=s^.next_s;
      if s=nil then begin
        message[2]:='get_s_and_remove';
        shutdown;
      end;
    end; {For i}
    get_s_and_remove:=s^.next_s;
    s^.next_s:=s^.next_s^.next_s;
  end; {if index}
end; {get_c_con_and_remove}


function get_c_and_remove(index : integer; var start : conn) : conn;
{*
	Get a connector from a linked list and remove it.
*}
var
  i : integer;
  s : conn;

begin
   if index=1 then begin
      get_c_and_remove:=start;
      start:=start^.next_con;
   end
   else begin
     for i:=1 to index-1 do begin
       if i=1 then s:=start
       	      else s:=s^.next_con;
       if s=nil then begin
         message[2]:='get_c_and_remove';
         shutdown;
       end;
     end; {For i}
     get_c_and_remove:=s^.next_con;
     s^.next_con:=s^.next_con^.next_con;
  end; {if index}
end; {get_c_con_and_remove}


function get_kL_from_con(tnet : net;tcon : conn) : integer;
{*
	Find k given tnet and tcon.
*}
var
  kL    : integer;
  found : boolean;
  vcon  : conn;

begin
  found:=false;
  kL:=0;
  vcon:=nil;
  repeat
    if vcon=nil then vcon:=tnet^.con_start
  	        else vcon:=vcon^.next_con;
    kL:=kL+1;
    if vcon=tcon then found:=true;
  until ((vcon^.next_con=nil) or (found));
  if not(found) then begin
    message[2]:='get_kL_from_con';
    shutdown;
  end;
  get_kL_from_con:=kL;
end; {get_kL_from_con}


function internal_joint_remaining : boolean;
{*
	Look for next joint to make connection.
	If no joint found then internal_joint_remaining:=false.
*}
var
  csize,size 	: integer;
  cNmate 	: net;

begin
  Conk:=nil;
  cnet:= net_start;
  csize:=1000;
  REPEAT
    ccon:= cnet^.con_start;
    IF (ccon <> NIL) THEN
      REPEAT
        if ccon^.port_type <=0 then begin
          cNmate:=ccon^.mate^.net;
          if cNmate=cnet then
		    size:=cnet^.number_of_con-2
		  else
		    size:=cnet^.number_of_con+cNmate^.number_of_con-2;
          if betweeni(1,size,csize) then begin
          	  csize:=size-1;
		  Conk:=ccon;
	  end; {if size - found simpler net to remove}
        end;{if ccon^.mate}

        ccon:= ccon^.next_con;

      UNTIL (ccon = NIL);

    cnet:= cnet^.next_net;

  UNTIL (cnet = NIL);

  if Conk <> nil then begin
    netK:=Conk^.net;
    netL:=Conk^.mate^.net;
    internal_joint_remaining:=true;
  end
  else
    internal_joint_remaining:=false;
  if No_mem_left then internal_joint_remaining := false;
  	{ exit analysis if out of memory }
end; {internal_joint_remaining}


function calc_con(Conj : conn) : boolean;
{*
	Does connector belong to set for which 
	s-parameters need to be calculated.
*}
begin
  if ext_port(Conj) then calc_con:=inp[Conj^.port_type]
            	    else calc_con:=true;
end; {* calc_con *}


procedure Join_Net;
{*
	Join connectors from different networks.
*}
var
  biL,bLL,akj,akk,aij,aik,start	:s_param;
  sizea,sizeb,i,j,k,L 		: integer;
  num1,num2,num3,num  		: Tcomplex;
  ConL,Conj           		: conn;

begin
  k:=get_kL_from_con(netK,ConK);
  L:=get_kL_from_con(netL,Conk^.mate);
  Conk:= get_c_and_remove(k,netK^.con_start);
  ConL:= get_c_and_remove(L,netL^.con_start);
  akk := get_s_and_remove(k,Conk^.s_start);
  bLL := get_s_and_remove(L,ConL^.s_start);
  prp(num,akk^.z^.c,bLL^.z^.c);
  co (num3,1.0,0.0);
  di(num1,num3,num);
  rc(num2,num1);{rc}
  sizea:=netK^.number_of_con-1;
  sizeb:=netL^.number_of_con-1;
  prp(num1,bLL^.z^.c,num2);
  for j:=1 to sizea do begin
    if j=1 then Conj:=netK^.con_start
    	   else Conj:=Conj^.next_con;
    if calc_con(Conj) then begin
      akj:=get_s_and_remove(k,Conj^.s_start);
      prp(num,num1,akj^.z^.c);
      prp(num3,num2,akj^.z^.c);

      aij:=Conj^.s_start;
      aik:=Conk^.s_start;
      if (aij^.z <> NIL) then supr(aij^.z^.c,aik^.z^.c,num);
      for i:=2 to sizea do begin
         aij:=aij^.next_s;
         aik:=aik^.next_s;
         if (aij^.z <> NIL) then supr(aij^.z^.c,aik^.z^.c,num);
      end;{ for i}

      for i:=1 to sizeb do begin
         if i=1 then biL:=ConL^.s_start
	        else biL:=biL^.next_s;
         new_s (aij^.next_s);
         aij:=aij^.next_s;
         if (biL^.z <> NIL) then begin
            New_c (aij^.z);
            prp(aij^.z^.c,biL^.z^.c,num3)
         end
	 else
	    aij^.z:= NIL;
      end;{ for i}
      aij^.next_s:=nil;
    end; {if calc conj}
  end; {end j}
  if sizea= 0 then netK^.con_start:=netL^.con_start
              else Conj^.next_con:=netL^.con_start;
  prp(num1,akk^.z^.c,num2);
  for j:=1 to sizeb do begin
      if j=1 then Conj:=netL^.con_start
      	     else Conj:=Conj^.next_con;
      if calc_con(Conj) then begin
      	Conj^.net:=netK;
	akj:=get_s_and_remove(L,Conj^.s_start);
	prp(num,num1,akj^.z^.c);
	prp(num3,num2,akj^.z^.c);

	aij:=Conj^.s_start;
	aik:=ConL^.s_start;
	if (aij^.z <> NIL) then supr(aij^.z^.c,aik^.z^.c,num);
	for i:=2 to sizeb do begin
           aij:=aij^.next_s;
	   aik:=aik^.next_s;
	   if (aij^.z <> NIL) then supr(aij^.z^.c,aik^.z^.c,num);
        end; {for i}

        for i:=1 to sizea do begin
          if i=1 then begin
          	biL:=Conk^.s_start;
		new_s (start);
		aij:=start;
          end
	  else begin
          	biL:=biL^.next_s;
		new_s (aij^.next_s);
		aij:=aij^.next_s;
          end;
	  aij^.next_s:=Conj^.s_start;
	  if (biL^.z <> NIL) then begin
                New_c (aij^.z);
		prp(aij^.z^.c,biL^.z^.c,num3)
          end
	  else
	    	aij^.z:= NIL;
       end; {for i}
       if sizea > 0 then Conj^.s_start:=start;
    end; {if conj}
  end; {for j}
  dispose_net(netL);
  netK^.number_of_con:=sizea+sizeb;
end; {join_net}


procedure Reduce_Net;
{*
	Join connectors from the same networks.
*}
var
  akj,akk,aij,aik,aLL,aiL,akL,aLk,aLj 	: s_param;
  num1,num2,num3,num4 			: TComplex;
  ConL,Conj 				: conn;
  i,k,L     				: integer;

begin
  k:=get_kL_from_con(netK,Conk);
  L:=get_kL_from_con(netK,Conk^.mate);
  if k < L then begin
  	i:=k;
	k:=L;
	L:=i;
  end;
  Conk := get_c_and_remove(k,netK^.con_start);
  ConL := get_c_and_remove(L,netK^.con_start);
  akk  := get_s_and_remove(k,Conk^.s_start);
  aLk  := get_s_and_remove(L,Conk^.s_start);
  akL  := get_s_and_remove(k,ConL^.s_start);
  aLL  := get_s_and_remove(L,ConL^.s_start);
  di(num3,co1,akL^.z^.c);
  di(num4,co1,aLK^.z^.c);
  prp(num2,num3,num4);
  prp(num3,aLL^.z^.c,akk^.z^.c);
  di(num4,num2,num3);
  rc(num1,num4);
  Conj:=netK^.con_start;
  while Conj <> nil do begin
    if calc_con(Conj) then begin
      akj := get_s_and_remove(k,Conj^.s_start);
      aLj := get_s_and_remove(L,Conj^.s_start);
      num4.r:= 0.0;
      num4.i:= 0.0;
      di (num3,co1,aLK^.z^.c);
      supr(num4,akj^.z^.c,num3);
      supr(num4,aLj^.z^.c,akk^.z^.c);
      prp(num2,num1,num4);
      num4.r:= 0.0;
      num4.i:= 0.0;
      di (num3,co1,akL^.z^.c);
      supr(num4,aLj^.z^.c,num3);
      supr(num4,akj^.z^.c,aLL^.z^.c);
      prp (num3,num1,num4);

      aij:=Conj^.s_start;
      aiL:=ConL^.s_start;
      aik:=Conk^.s_start;
      if aij^.z<>nil then begin
        supr(aij^.z^.c,aiL^.z^.c,num2);
        supr(aij^.z^.c,aik^.z^.c,num3);
      end;
      while (aij^.next_s <> nil) do begin
        aij:=aij^.next_s;
        aiL:=aiL^.next_s;
        aik:=aik^.next_s;
        if aij^.z<>nil then begin
           supr(aij^.z^.c,aiL^.z^.c,num2);
           supr(aij^.z^.c,aik^.z^.c,num3);
        end;
      end; {while aij}
    end; {if calc_con conj}
    Conj:=Conj^.next_con;
  end;{Conj}
  netK^.number_of_con:=netK^.number_of_con-2;
end; {reduce net}


procedure rem_node(tnet : net);
{*
	Remove nodes in network with 2 ports.
	These require no connecting tee's or crosses
	for reduction. Makes connectors from one net
	mate up with the other.
*}
var
  tcon : conn;
  i,j  : integer;

begin
  ccon:=tnet^.con_start;

  {!* Dead code? tnet^.ports_connected=2 is not permitted by the call!}

  if tnet^.ports_connected =2 then begin {2 port node connect to two ports}
    for j:=1 to 2 do begin
      if j=1 then ccon:=tnet^.con_start
      	     else ccon:=ccon^.next_con;
      for i:=1 to 2 do begin
        if i=1 then begin
           new_s(ccon^.s_start);
           c_s:=ccon^.s_start;
        end
	else begin
           new_s(c_s^.next_s);
           c_s:=c_s^.next_s;
        end;
        new_c(c_s^.z);
        if i<>j then c_s^.z^.c.r:=-1.0
		else c_s^.z^.c.r:= 0.0;
        c_s^.z^.c.i:=0.0;
      end; {for i}
      c_s^.next_s:=nil;
    end; {j}
  end
  else begin
    if tnet^.ports_connected > 0 then begin {if node is connected to port}
      if ext_port(ccon) then begin
        tcon:=ccon^.next_con^.mate;
        tcon^.port_type:=ccon^.port_type
      end
      else begin
        tcon:=ccon^.mate;
        tcon^.port_type:=ccon^.next_con^.port_type;
      end;
      tcon^.mate:=nil;
      tcon^.net^.ports_connected:=tnet^.ports_connected;
    end
    else begin
      ccon^.mate^.mate:=ccon^.next_con^.mate;
      ccon^.next_con^.mate^.mate:=ccon^.mate;
    end;
    dispose_net(tnet);
  end;
end; {* rem_node *}


procedure Set_Up_Element(ports : integer);
{*
	Set up frequency independent s-parameters for each network.
	Does opens, shorts, tee's, and crosses.
*}
var
  i,j,jj 		: integer;
  pta    		: array[1..max_net_size] of integer;
  onlyinp,onlyout 	: array[1..max_net_size] of boolean;

begin
  if ports=1 then begin 	{open or short}
    new_s(cnet^.con_start^.s_start);
    c_s:=cnet^.con_start^.s_start;
    c_s^.next_s:=nil;
    New_c (c_s^.z);
    if cnet^.grounded then co(c_s^.z^.c,-one,0.0)   { short }
	      	      else co(c_s^.z^.c, one,0.0);  { open  }
  end
  else begin
    jj:=1;
    for j:=1 to ports do begin {check to see if input or output port}
      if j=1 then ccon:=cnet^.con_start
      	     else ccon:=ccon^.next_con;
      if ext_port(ccon) then begin
        pta[jj]:=ccon^.port_type;
        onlyout[jj]:=out[pta[jj]] and not(inp[pta[jj]]);
        onlyinp[jj]:=inp[pta[jj]] and not(out[pta[jj]]);
        if not(out[pta[jj]] or inp[pta[jj]]) then begin
           ccon:=get_c_and_remove(jj,cnet^.con_start);
           Dec(cnet^.number_of_con);
           Dec(jj);
        end; {if not(out..)}
      end
      else begin
        onlyout[jj]:=false;
        onlyinp[jj]:=false;
      end; {if ext}
      Inc(jj);
    end; {j}
    for j:=1 to cnet^.number_of_con do begin
      if j=1 then ccon:=cnet^.con_start
      	     else ccon:=ccon^.next_con;
      for i:=1 to cnet^.number_of_con do begin
        if i=1 then begin
          new_s(ccon^.s_start);
          c_s:=ccon^.s_start;
        end
	else begin
          new_s(c_s^.next_s);
          c_s:=c_s^.next_s;
        end;
        if onlyinp[i] or onlyout[j] then begin
          c_s^.z:=nil;
        end
	else begin
          new_c (c_s^.z);
          if cnet^.node then begin
            c_s^.z^.c.i:=0.0;
            if cnet^.grounded then begin {if grounded}
              if i=j then c_s^.z^.c.r:=-one
	      	     else c_s^.z^.c.r:= 0.0;
            end
	    else begin    {Tee or Cross}
              if i=j then c_s^.z^.c.r:=one*((2/ports)-1)
                     else c_s^.z^.c.r:=one*(2/ports);
            end; {if grounded}
          end;
        end; {if onlyinp}
      end; {i}
      c_s^.next_s:=nil;
    end; {j}
  end; {if 1 port}
end; {* set_up_element *}


procedure Fill_Compts;
{*
	Transfer s-parameters from parts to networks.
*}
var
  i,j,ii,jj : integer;
  v_s       : s_param;
  coni,conj : conn;

begin
  action:=false;
  {Load s-param data into memory, at xpt=0 fill device s_ifile}
  Pars_Compt_List;
  cnet:= net_start;
  IF (NOT (bad_compt)) THEN
    REPEAT
      if not(cnet^.node) and (cnet^.number_of_con > 0) then begin
        coni:= cnet^.con_start;
        REPEAT
          ii:=coni^.conn_no;
          conj:= cnet^.con_start;
          c_s := coni^.s_start;
          REPEAT
            jj:=conj^.conn_no;
            v_s:=nil;
            if c_s^.z <> nil then begin
              for i:=1 to cnet^.com^.number_of_con do
              for j:=1 to cnet^.com^.number_of_con do begin
                if v_s=nil then v_s:=cnet^.com^.s_begin
	      		   else v_s:=v_s^.next_s;
                if (ii=i) and (jj=j) then begin
                  c_s^.z^.c.r:=v_s^.z^.c.r;
                  c_s^.z^.c.i:=v_s^.z^.c.i;
                end; {if ii}
              end; {for j}
            end; {if c_s}

            conj:= conj^.next_con;
            c_s := c_s^.next_s;

          UNTIL ((conj = NIL) OR (c_s = NIL));

          coni:= coni^.next_con;

        UNTIL (coni = NIL);
      end;{if not(cnet^.node)};

      cnet:= cnet^.next_net;

    UNTIL (cnet = NIL);
end; {* Fill_Compts *}


procedure set_up_net;
{*
	Procedure for setting up nets
*}
var
  i : integer;

begin
    for i:=1 to 2 do begin {set_up_nets}
      cnet:=nil;
      repeat    {Loop through network, setting up connections}
        if cnet=nil then cnet:=net_start
		    else cnet:=cnet^.next_net;
        with cnet^ do if i=1 then begin
           if ((number_of_con=2) and node
		and not(grounded)
			and (ports_connected <> 2))
                              then rem_node(cnet);
        end
	else
	  Set_Up_Element(number_of_con);
      until cnet^.next_net=nil;
    end;	{set_up_nets and do freq indept stuff}
end; {* set_up_net *}


procedure Get_s_and_f(do_time : boolean);
{*
	Find parameter in plot box, i.e. which s to calc at fd/df

	For do_time it is necessary to prompt for fd/df.
	Otherwise the number of Points are used.
*}
var
  pt_end,pt_start,ij,i,j,code1,code2 : integer;
  real_npts      : double;
  q_fac_string   : file_string;

begin  
  ccompt:=Points_compt;
  cx:=ccompt^.x_block; 
  bad_compt:=false;
  if do_time then begin    {* Use fd/df for time sweep *}
    q_fac_string:=input_string('  Integer fd/df', '     <10>');
    if (q_fac_string='') then
    	q_fac:=10
    else begin
    	 Val(q_fac_string,q_fac,code1);  {fd/df}
	 if (code1<>0) then bad_compt:=true;
    end;
    if bad_compt then begin
	message[2]:='Invalid fd/df';
	exit;
    end;
    bad_compt:=true;
    if q_fac < 1 then begin
	message[1]:='fd/df too small';
	message[2]:='or negative';
	exit;
    end;
    finc:=design_freq/q_fac;   {normalized}
    if (sxmin/finc < 10000) and (sxmax/finc < 10000) then begin
	if abs(sxmin/finc-Round(sxmin/finc)) < 0.001
		then pt_start:=Round(sxmin/finc)
		else pt_start:=Trunc(sxmin/finc)+1;
	fmin:=finc*pt_start;
	pt_end:=Trunc(sxmax/finc);
    end
    else begin
	message[2]:='fd/df too large';
	exit;
    end;
    npts:=pt_end-pt_start;
    if npts < 0 then begin
	message[2]:='fd/df too small';
	exit;
    end;
    if npts > ptmax then begin
	message[2]:='fd/df too large';
	exit;
    end;
  end   {if do_time}
  else begin    {* Use Points for frequency or other sweep}
    real_npts:=Get_Real(Points_compt,1);
    if (Trunc(real_npts)>ptmax) then
    	bad_compt:=true
      else
        npts:=Trunc(real_npts) - 1;   {number of points}
    if bad_compt or (npts < 0) then begin
        bad_compt:=true;
	message[1]:='Invalid number';
	message[2]:='of points';
	exit;
    end;
    fmin:=sxmin;  {if npts=0 then plot a point at fmin}
    if (npts<>0) then finc:=(sxmax-sxmin)/npts;
    {This to allow plotting of 1 point i.e. npts=0}
  end;  {if do_time}
  for ij:=1 to min_ports do begin
	inp[ij]:=false;
	out[ij]:=false;
  end;
  for ij:=1 to max_params do
     with s_param_table[ij]^ do begin
	calc:=false;
	if length(descript)>=3 then begin
	   Val(descript[2],i,code1);
	   Val(descript[3],j,code2);
	   if (code1=0) and (code2=0) then
		if betweeni(1,i,min_ports) 
		  and betweeni(1,j,min_ports) then begin
		  	si[ij]:=i;
			sj[ij]:=j;
			if portnet[i]^.node
			  and portnet[j]^.node then begin
				inp[j]:=true;  
				out[i]:=true;
				calc:=true; 
				bad_compt:=false;
			end;{if port}
		end;{if code and between}
	end; {if length}
  end; {for ij and with}
  if bad_compt then begin
	ccompt:=rho_fac_compt;
	move_cursor( 0, 1);
	message[1]:='No pair of Sij';
	message[2]:='correspond to';
	message[3]:='connected ports';
	exit;
  end;
end; {* Get_s_and_f *}


Procedure Analysis(do_time, out: boolean);
{*
	Main procedure for directing the analysis.
	Pass do_time on to get_s_and_f in order to
	return FFT parameters based on q_fac.
*}
label
  exit_analysis;

var

  old_net       : net;
  old_net_start : net;
  net_end_ptr1  : marker;
  net_end_ptr2  : marker;
  ptrall        : marker;
  ptrvar        : marker;
  ptranalysis   : marker;
{  netmem        : LONGINT; }
  MemError      : BOOLEAN;

begin
  filled_OK:=false;
  MemError:= FALSE;
  if net_start = nil then begin
    message[1]:='No circuit';
    message[2]:='to analyze';
    write_message;
  end
  else begin
    Get_s_and_f(do_time);
    if bad_compt then begin
        write_message;
        cx:=ccompt^.x_block;
    end
    else begin
      filled_OK:=true;
      TextCol(lightgray);
      GotoXY(xmin[6],ymin[6]+1);
      Write(' Press h to halt ');
      TextCol(white);
      GotoXY(xmin[6]+7,ymin[6]+1);
      Write('h');

      { Save initial Markers}
      old_net:=cnet;
      old_net_start:= net_start;

      { Mark original memory setting }
      Mark_Mem (ptrall);
{      netmem:= MemAvail; }

      { Copy original network }
      Init_Marker (net_end_ptr1);
      copy_networks (net_beg, ptrall, net_end_ptr1);

      IF NOT Marked (net_end_ptr1) THEN BEGIN
        MemError:= TRUE;
        GOTO exit_analysis;
      END;

      { set up nets for analysis }
      set_up_net;
(*
      IF (MemAvail < (netmem - MemAvail + npts * 256)) THEN
      BEGIN
        MemError:= TRUE;
        GOTO Exit_Analysis;
      END;
*)
      { Initialize markers for copy of new network }
      Init_Marker (net_end_ptr2);
      Mark_Mem (ptranalysis);

      { main analysis loop }
      for xpt:=0 to npts do begin
        if Alt_Sweep then begin
	  freq:=design_freq;   {Force parts to use fd}
	  x_sweep.Load_Data(fmin+xpt*finc);
	  {use freq data for alt parameter}
	end
	else begin
	  if (xpt=npts) and (npts<>0) then freq:=sxmax
	  	    		      else freq:=fmin+xpt*finc;
          {These are normalized to the window}
	end;
	{* For alternate sweep freq:=design_freq and finc=0 *}

        { make copy of network for analysis }
        copy_networks (net_beg, ptranalysis, net_end_ptr2);
        IF (NOT Marked (net_end_ptr2)) THEN BEGIN
          MemError:= TRUE;
          GOTO Exit_Analysis;
        END;

        { parts calculation and at xpt=0 fills device file s_ifile interpolation data }
        Fill_compts;

	IF (No_mem_left) THEN GOTO exit_analysis; { check for 16 bytes }

        IF (bad_compt) THEN BEGIN
	  filled_OK:= FALSE;
          GOTO Exit_Analysis;
	END ELSE BEGIN
		while internal_joint_remaining do 	{loop over joints}
		if netK=netL then
			reduce_net 	{join connectors on same net}
                    else
		    	join_net;  	{join two nets}
        END; {if bad_compt }

        if Alt_Sweep then freq:=fmin+xpt*finc;
	{Restore freq for use in linked lists}

        Fill_Sa (out);     { uses freq, calls write_freqO }

        { free memory used for analysis }
        { -> not for xpt = 0; keep device file's interpolation data }
        IF (xpt <> 0) THEN
          Release_Mem (ptrvar)
        ELSE
          Mark_Mem (ptrvar);

        { check for abort }
        if keypressed then begin
          chs := ReadKey;
          if chs in ['h','H'] then begin
            filled_OK:=false;
            erase_message;
            message[2]:='      HALT       ';
            write_message;
            goto exit_analysis;
          end;
          beep;
        end; {if keypreseed}
      end; {for xpt:= 0 to npts }
  exit_analysis:
      if (No_mem_left OR MemError) then begin
      	 filled_OK := false;
	 erase_message;
	 message[1] := ' Circuit is too  ';
	 message[2] := ' large for Puff  ';
	 message[3] := '   to analyze    ';
	 write_message
      end;

      { Restore network }
      copy_networks (net_beg, ptrall, net_end_ptr1);

      { Release all network copies }
      Release_Mem (ptrall);

      {Restore initial markers}
      cnet     :=old_net;
      net_start:= old_net_start;
    end; {if bad_compt}
  end; {if cnet}
end; {* Analysis *}


procedure move_marker(xi : integer);
{*
	Move marker on Smith chart and rectangular plot.

	Move_marker(+/- 1) is invoked from Plot2
		by Page-Up and Page-Down keys.

	Move_marker(0) is called by plot_manager.
*}
var
  i,ij,k,kk,nb,sfreq : integer;

begin
  if marker_OK then begin
    for ij:=1 to max_params do
    if s_param_table[ij]^.calc then
    case xi of
    	0 : begin
          	if plot_des[ij]=nil then xpt:=0
		  else begin
		  	c_plot[ij]:=plot_des[ij];
			xpt:=Round((design_freq-fmin)/finc);
			{point for cursor placement}
			if not(betweeni(0,xpt,npts)) then xpt:=0;
		end;
		if xpt=0 then c_plot[ij]:=plot_start[ij];
            end; { 0: }
	1 : if c_plot[ij]=plot_end[ij] then 
    			c_plot[ij]:=plot_start[ij]
		else 
	      		c_plot[ij]:=c_plot[ij]^.next_p;
       -1 : if c_plot[ij]=plot_start[ij] then
   			c_plot[ij]:=plot_end[ij]
                else 
			c_plot[ij]:=c_plot[ij]^.prev_p;
    end; {case xi}
    if xi = 0 then for i:=1 to 2*max_params do box_filled[i]:=false
              else xpt:=xpt+xi;
    if xpt > npts then xpt:=0;
    if xpt < 0    then xpt:=npts;
    IF (xi <> 0) THEN Erase_Message;
    Write_FreqO;
    sfreq:=xmin[8]+Round((freq-sxmin)*sfx1);
    for k:=1 to 3 do
    for ij:=1 to max_params do
    if s_param_table[ij]^.calc then
    case k of
     1 : restore_boxO(ij);
     2 : begin
           box_filled[ij]:=false;
           box_filled[ij+max_params]:=false;
           if c_plot[ij]^.filled then begin
             calc_posO(c_plot[ij]^.x,c_plot[ij]^.y,0,1,sfreq,false);
             if spline_in_smith then move_boxO(spx ,spy,ij);
             if not(Large_Smith) then
	        if spline_in_rect then move_boxO(sfreq,spp,ij+max_params);
           end;
         end; {2:}
     3 : begin
           for kk:=0 to 1 do begin
            nb:=ij+kk*max_params;
            if box_filled[nb] then pattern(box_dot[1,nb],box_dot[2,nb],ij,128)
           end;{kk}
           if c_plot[ij]^.filled then write_sO(ij);
         end; {3 :}
    end; {case}
  end; {if do time}
end; {move_marker}


procedure show_real;
var
  ij: integer;
  d,r,i: double;
  u: char;

begin
  if (marker_ok) then
  begin
    for ij:= 1 to max_params do
    begin
      if (s_param_table[ij] = ccompt) then
      begin
        if ((ccompt^.calc) AND (c_plot[ij]^.filled) AND
           ((ccompt^.descript = 'S11') OR (ccompt^.descript = 'S22') OR
            (ccompt^.descript = 'S33') OR (ccompt^.descript = 'S44'))) THEN
          with c_plot[ij]^ do
          begin
            GotoXY (xmin[6]+2, ymin[6]);
            if (admit_chart) then
            begin
              d:= sqr (1 + x) + sqr (y);
              r:= (1 - sqr (x) - sqr (y));
              IF (r = 0.0) THEN
              BEGIN
                Write ('Rp:');
              END ELSE
              BEGIN
                r:= (d * z0 / r);
                IF (abs (r) <= 1e+9) THEN
                  Write ('Rp:', r:10:3, ' ', Omega)
                ELSE
                  Write ('Rp:         ', infin, ity);
              END;
              i:= 2 * y;
              GotoXY (xmin[6]+2,ymin[6]+1);
              IF (i = 0.0) THEN
              BEGIN
                Write ('Xp:');
              END ELSE
              BEGIN
                i:= (d * z0 / i);
                IF (abs (i) <= 1e+9) THEN
                  Write ('Xp:', i:10:3, ' ', Omega)
                ELSE
                  Write ('Xp:         ', infin, ity);
              END;
            end else
            begin
              d:= sqr(1 - x) + sqr(y);
              IF (d = 0.0) THEN d:= 5e-324;
              r:= ((1 - sqr(x) - sqr(y)) * z0 / d);
              i:= (2 * y * z0 / d);
              IF (abs (r) <= 1e+9) THEN BEGIN
                IF (abs (i) <= 1e+9) THEN BEGIN
                  Write ('Rs:', r:10:3, ' ', Omega);
                  GotoXY (xmin[6]+2, ymin[6]+1);
                  Write ('Xs:', i:10:3, ' ', Omega);
                END ELSE BEGIN
                  Write ('Rs:');
                  GotoXY (xmin[6]+2, ymin[6]+1);
                  Write ('Xs:         ', infin, ity);
                END;
              END ELSE BEGIN
                IF (abs (i) <= 1e+9) THEN BEGIN
                  Write ('Rs:         ', infin, ity);
                  GotoXY (xmin[6]+2, ymin[6]+1);
                  Write ('Xs:');
                END ELSE BEGIN
                  Write ('Rs:         ', infin, ity);
                  GotoXY (xmin[6]+2, ymin[6]+1);
                  Write ('Xs:         ', infin, ity);
                END;
              END;
            end;
            d:= fmin+xpt*finc;
            CASE freq_prefix OF
              'G': d:= d * 1000000000.0;
              'M': d:= d * 1000000.0;
              'k': d:= d * 1000.0;
              ELSE RunError (0);
            END;
            GotoXY (xmin[6]+2,ymin[6]+2);
            IF (i <> 0.0) THEN
            BEGIN
              IF (i > 0) THEN BEGIN
                Write ('L :');
                d:= (i / (2*pi*d));
                u:= 'H';
              END ELSE BEGIN
                Write ('C :');
                d:= (-1 / (2*pi*d*i));
                u:= 'F';
              END;
              GotoXY (xmin[6]+5,ymin[6]+2);
              IF (d > 1e+9) THEN
                Write ('        ', infin, ity)
              ELSE IF (d >= 1.0) THEN
                Write (d:10:3, ' ', u)
              ELSE IF (d >= 0.001) THEN
                Write (d*1000.0:10:3, ' m', u)
              ELSE IF (d >= 0.000001) THEN
                Write (d*1000000.0:10:3, ' æ', u)
              ELSE IF (d >= 0.000000001) THEN
                Write (d*1000000000.0:10:3, ' n', u)
              ELSE
                Write (d*1000000000000.0:10:3, ' p', u);
            END;
          end else { if .. then .. with }
            beep;
      end; { if s_param... }
    end; { for ... }
  end else { if marker_ok }
    beep;
end;


Procedure Plot_Manager(do_analysis, clear_plot, do_time, boxes, out: boolean);
{*
	Main procedure for directing anlaysis followed by plotting.

*}
var
  ticko: integer;
begin
  ticko:=GetTimerTicks;
  erase_message;
  move_cursor(0,0);    { used to erase any residual S's }
  Get_Coords;
  if bad_compt then begin
      	write_message;
	cx:=ccompt^.x_block;
	filled_OK:=false;
  end
  else begin
  	Pick_Smith(admit_chart);
	if not(Large_Smith) then
		Draw_Graph(xmin[8],ymin[8],xmax[8],ymax[8],false);
	cx:=ccompt^.x_block;
	if not(clear_plot) and filled_OK then begin
            Smith_and_Magplot(true,true,true);
	    move_marker(0);
        end;
	if do_analysis then Analysis(do_time, out);	{ Start Analysis }
	if filled_OK then begin
           marker_OK:=true;
	   Smith_and_Magplot(false,false,boxes);
	      {plot spline points after analysis}
           ticko:=GetTimerTicks-ticko;
	   if ( do_analysis and not(key in['h','H']) ) then begin
	   	erase_message;
		TextCol(lightgray); {center text in message box}
		Gotoxy((xmin[6]+xmax[6]-16) div 2,ymin[6]+1);
		Write('Time ',ticko/18.2:6:1,' secs');  {was ticko/18.2:8:1 }
		beep;
	   end;
	   move_marker(0);
	   if demo_mode then rcdelay(300);
        end
        else
      	   marker_OK:=false;
  end; {if bad_compt} 
end; {* Plot_Manager}


Procedure Erase_Circuit;
{*
	Erase circuit board. Redraw if read_kbd=false.
	Check to see if device files need to be re-copied into memory.

	Very significant memory management control here
	involving the net_beg pointer.

	Called by:
		Redraw_Circuit,
		Read_Net (after or if not board_read),
		Lpayout1 (if Ctrl_e),
		Parts3 (if Ctrl_e)

*}


begin
  erase_message;
  if compt1 <> nil then write_compt(lightgray,compt1);
  compt1:=part_start;

  if (Marked (net_beg)) then Release_Mem(net_beg); {release networks memory}
  Mark_Mem(net_beg);
  key_i:=0; {set_up for redraw}
  if read_kbd then begin
    filled_OK:=false;  
    circuit_changed:=false;
    Board_Changed:=false;
    marker_OK:=false;
    key_end:=0; 	{erase key_list}
    Extra_Parts_Used:=false;
  end;
  net_start:=nil;  
  cnet:=nil;
  Draw_Circuit;
end; {Erase_Circuit}


procedure Toggle_Smith_and_Plot;
{*
	Activated by the <Tab> key, this allows
	re-plotting for under a new smith chart.
*}
begin
  admit_chart:=not(admit_chart); {Toggle Smith type}
  Erase_message;
  move_cursor(0,0);    { used to erase any residual S's }
  Get_Coords;
  if bad_compt then begin
      	write_message;
	cx:=ccompt^.x_block;
	filled_OK:=false;
  end 
  else begin
      	Pick_Smith(admit_chart);
	if not(Large_Smith) then
		Draw_Graph(xmin[8],ymin[8],xmax[8],ymax[8],false);
	cx:=ccompt^.x_block;
	if filled_OK then begin
            Smith_and_Magplot(false,true,true);
	    move_marker(0);
        end;
  end;
end; {* Toggle_Smith_and_Plot *}


procedure Redraw_Circuit;
{*
	Set up for circuit redraw.
*}
begin
  read_kbd:=false;  
  Erase_Circuit;
  key_o:=key; 
  key:=F1;
  GotoXY(checking_position[1],checking_position[2]);
  TextCol(lightred);
  if not(demo_mode) then write('Checking Circuit.');
end; {* Redraw_Circuit *}


Procedure Large_Smith_Coords;
{*
	Change linked list of coordinates to that required for
	Large Smith chart. 
*}
Begin
  {Advance coord_start pointer to fmin position}
  coord_start:=fmin_ptr;
  {Change wrap-around point}
  fmin_ptr^.prev_compt:=s_param_table[4];
  s_param_table[4]^.next_compt:=fmin_ptr;
end; {* Large_Smith_Coords *}


Procedure Small_Smith_Coords;
{*
	Change linked list of coordinates to that required for
	small Smith chart.
*}
Begin
  {return coord_start pointer to dBmax}
  coord_start:=dBmax_ptr;
  {Change wrap-around point}
  fmin_ptr^.prev_compt:=dBmax_ptr^.next_compt;
  s_param_table[4]^.next_compt:=dBmax_ptr;
end; {* Small_Smith_Coords *}


Procedure Toggle_Large_Smith(return_key : char);
{*
	Change parameters to enlarge/shrink Smith chart.

*}
Begin
     Large_Smith:=not(Large_Smith);
     if not(Large_Smith) then begin  {make small Smith}
        Small_Smith_Coords;
	clear_window_gfx(xmin[10],ymin[10],xmax[10],ymax[10]); {Erase Large Smith region}
        Screen_Plan;
	Draw_Graph(xmin[8],ymin[8],xmax[8],ymax[8],false);
	key:=return_key;
	Redraw_Circuit; {Setup circuit re-draw and return to F2}
	Write_File_Name(puff_file);
     end
     else begin {Make large Smith}
        Large_Smith_Coords;
        Screen_Plan;
	{Move if invalid cursor position}
	if (ccompt=dBmax_ptr) or (ccompt=dBmax_ptr^.next_compt) then begin
	   ccompt:=Points_compt;
	   cx:=ccompt^.x_block;
	end;   
     end;
     Pick_Smith(admit_chart);  
     if Large_Smith then Write_BigSmith_Coordinates;
     if filled_OK then begin
        Smith_and_Magplot(false,true,true);
	move_marker(0);
     end;
end; {* Toggle_Large_Smith *}


Procedure Read_Net(var fname : file_string; init_graphics : boolean);
{* 
	Read in xxx.puf file. 
*}
var
  char1,char2 	: char;
  file_read,
  bad_file	: boolean;


begin
  file_read:=false;  
  marker_OK:=false;
  filled_OK:=false;
  bad_file:=false;
  if (pos('.',fname)=0) and (fname<>'') then fname:=fname+'.puf';
  if fileexists(true,net_file,fname) then begin
    read(net_file,char1);
    repeat
      if char1=#13 then read(net_file,char2)	{Don't skip 2 lines on CR's}
      		   else readln(net_file,char2);
      if char1='\' then begin
        case char2 of
          'b','B' : begin {board parameters}
	  	      Read_Board(init_graphics);
                      if board_read then begin
                            if init_graphics then begin
			    	Screen_Init;
                                Init_Mem;
				Fresh_Dimensions;
			    end; {!} 	
			    Erase_Circuit;
			    Set_Up_Board;
                      end;
                    end;
          'k','K' : begin {read in 'key' = plot parameters}
                      Read_KeyO;
		      Set_Up_KeyO;
                      bad_compt:=false; 
		      rho_fac:=get_real(rho_fac_compt,1);
                      if bad_compt or (rho_fac<=0.0) then begin
                             rho_fac:=1;
                             rho_fac_compt^.descript:='Smith radius 1.0';
                      end;
                    end;
          'p','P' : read_partsO;    {read parts list}
          's','S' : Read_S_Params; {read in calculated s-parameters}
          'c','C' : read_circuitO;  {read circuit}
          else begin
	    {* readln(net_file); *} {else advance a line}
            {* read(net_file,char1); *}
	    {! Should have character after backslash}
	    Message[1]:='Improper';
	    Message[2]:='Puff file';
	    Write_Message;
	    bad_file:=true;
	    board_read:=false;
	    if not(init_graphics) then begin
	    	Close(net_file);
		exit;
	    end;
          end;
        end; {case}
      end 
      else 
          Read(net_file,char1); { look for '\' on this line }
    Until bad_file or EOF(net_file) ;
    Close(net_file);
    file_read:=true;
  end; {if fileexists}
  if not(board_read) then begin  {if couldn't Read_Board data}
    	read_setup(fname);	 {then read setup.puf board data}
	if not(board_read) then bad_board;
	if init_graphics then begin
		Screen_Init;
		Fresh_Dimensions;
	end;
	Erase_Circuit;
	file_read:=true;
  end;
  if file_read then begin
  	puff_file:=fname;	{Change current file name}
    	write_file_name(fname);

    (*	ccompt:=Points_compt;   {previous location of plot_manager}
	if filled_OK then Plot_Manager(false,true,false,true);   *)

(*	New(net_beg);  *)

	ccompt:=part_start;  
	cx:=ccompt^.x_block;
	compt3:=ccompt; 
	cx3:=cx;
	action:=true;
	x_sweep.Init_Use; {Initialize alt_sweep object}
	Pars_Compt_List;  {Parse before plotting to check for alt_sweep}
	if Large_Parts then Write_Expanded_Parts
	  else begin 
	  	Write_Parts_ListO;
	        Write_Board_Parameters;
	end;
	if filled_OK then Plot_Manager(false,true,false,true,true)
	   else begin
		Draw_Graph(xmin[8],ymin[8],xmax[8],ymax[8],false);
		Pick_Smith(admit_chart);  
	end;
	key:=F3;
  end; {if file_read}
end; {* Read_Net *}


procedure Save_Net;
{*
	Routine for saving .puf file.
*}
var
  fname : file_string;
  drive : integer;

begin
  Move_Cursor( 0, 0); {erase residual s-parameters}
  ccompt:=Points_compt;
  cx:=ccompt^.x_block; 
  fname:=input_string('File to save:','<'+puff_file+'>');
  if fname='' then fname:=puff_file;  
  {Default: save under current file name}
  if Pos(':',fname)=2 then drive:=ord(fname[1])-ord('a')+1
                      else drive:=-1;
  if enough_space(drive) then begin
    if pos('.',fname)=0 then fname:=fname+'.puf';
    Assign(net_file,fname);  
    {$I-} Rewrite(net_file); {$I+}
    if IOresult=0 then begin
      puff_file:=fname;
      if not(Large_Smith) then Write_File_Name(fname);
      save_boardO;
      save_keyO;
      save_partsO;
      save_s_paramsO;
      save_circuitO;
      close(net_file);
      erase_message
    end 
    else begin
      message[1]:='Invalid filename';
      write_message
    end; {if IOresult}
  end; {if enough}
end; {* Save_Net *}


procedure check_esc;
{*
	Check that on exit Esc key was not accidently pressed.
*}
var
  tcompt : compt;

begin
  message[1]:='Exit? Type Esc to';
  message[2]:='confirm, or other';
  message[3]:='  key to resume  ';
  write_message;
  tcompt:=ccompt;
  ccompt:=nil;		{so cursor doesn't blink}
  repeat get_key until key<>screenresize;
  if key <> Esc then key:=not_esc;
  ccompt:=tcompt;
  erase_message;
end; {check_esc}


Procedure Toggle_Help_Window;
{*
	Toggle help window in appropriate area of screen.
	help_displayed is a global variable.
*}
Begin
  if help_displayed then begin 
  	if (window_number=4) then begin  
	     if Large_Parts then begin
	        {Write Large parts list under board window}
	        Write_Expanded_Parts;
		Write_Board_Parameters;
		Highlight_Window;
	     end
	     else
	       Write_Parts_ListO;  {help window was over parts}
	end
	else if Large_Parts then begin
	     Write_Expanded_Parts;
	end
	else begin
	     Write_Board_Parameters; {help window was over board}
	end;
  end
  else begin
  	if (window_number=4) then begin  
		Board_Help_Window  {Different area then write_commands}
	end	
	else if (window_number=3) then begin
		if ((Ord(ccompt^.descript[1])>106) )
		    then begin
			ccompt:=part_start;   {goto top if part>'i'}
			cx:=ccompt^.x_block;
		end;	
	  	Write_Commands;  {write commands over Board window}
	end	
	else
	  	Write_Commands;  {write commands over Board window}
  end;
  help_displayed:=not(help_displayed);
end;


Procedure Toggle_Parts_Lists;
{*
	Toggle between small and large Parts Lists.
*}
Begin
  if Extra_Parts_Used then begin
     erase_message;
     Message[1]:='Cannot Toggle.';
     Message[2]:='Extra parts used';
     Message[3]:='in Layout.';
     Write_Message;
  end
  else begin 
     if Large_Parts then begin  
       {Clear area}
       clear_window(xmin[3]-1,ymin[3]-1,xmax[5]+1,ymax[5]+1);
       {Write Board and small Parts windows}
       Write_Board_Parameters;
       Write_Parts_ListO;
       Highlight_Window;
       {return pointer to first part}
       ccompt:=part_start;  
       cx:=part_start^.x_block;
     end
     else 
       Write_Expanded_Parts;
     Large_Parts:=not(Large_Parts);
  end; {extra parts}
end; {* Toggle_Parts_Lists *}


Procedure Time_Domain_Manager;
{*
	Procedure for directing time domain functions
	called from the Plot2 window.
*}
Begin
  Erase_Message;
  if Alt_Sweep then begin
     Message[1]:='Frequency';
     Message[2]:='sweep needed';
     Message[3]:='for time plot';
     Write_Message;
  end
  else if Large_Smith then begin
     Message[1]:='Unavailable';
     Message[2]:='with large';
     Message[3]:='Smith chart';
     Write_Message;
  end
  else begin
     step_fn:= key in ['s','S'];
     Plot_Manager(true,true,true,false,true); {time-analyze}
     if (filled_OK and not(key in['h','H'])) then 
	       	     Time_Response;  {do inverse FFT and time plot}
  end;
end; {* Time_Domain_Manager *}


Procedure Screen_Resize;
{*
	Process resizing of the "screen" (i.e., the X11 window under Linux)
*}
var
   tmp: compt;
begin
   Small_Smith_Coords;
   Screen_Plan;
   clear_window_gfx(xmin[12],ymin[12],xmax[12],ymax[12]);
   tmp:=ccompt;
   Set_Up_Board;       { update some stored coordinates in the F4 window }
   Update_KeyO_locations;        { update some stored coordinates in the F2 window }
   ccompt:=tmp;
   Fresh_Dimensions;   { need to call this to update the board size in other variables than the x/ymin/max arrays }
   Get_Coords;         { need to call this to update the magnitude plot vertical scale factor }
   if (not Large_Smith) then begin
      Draw_Circuit;
      Write_File_Name(puff_file);
   end;
   Write_Board_Parameters;
   Write_Parts_ListO;
   Write_Message;
   Make_Text_Border(xmin[6]-1,ymin[6]-1,xmax[6]+1,ymax[6]+1,LightRed,true);
   Make_Text_Border(xmin[2]-1,ymin[2]-1,xmax[2]+1,ymax[2]+1,Green,true);
   write_compt(col_window[2],window_f[2]);
   if (Large_Smith) then Large_Smith_Coords;
   Plot_Manager(false,true,false,true,true);
end; {* Screen_Resize *}



procedure Layout1;
{*
	Procedure for directing circuit drawing functions in
	the circuit window.
*}
begin
  missing_part:=false;
  write_compt(white,compt1);
  repeat
    Get_Key;
    if (key <> F3) and read_kbd then erase_message;
    case key of   {these do not effect the keylist}
      Ctrl_e      : begin
      		      Erase_Circuit; 
		      write_compt(white,compt1);
		    end;
      Esc         : check_esc;
      F5	  : Change_Bk_Color;
      F10         : Toggle_Help_Window;
      screenresize: Screen_Resize;
     else begin {HKMP bad}
        update_key:=read_kbd;
        case key of
          right_arrow : move_net(2,1);
          left_arrow  : move_net(4,1);
          down_arrow  : move_net(8,1);
          up_arrow    : move_net(1,1);
          sh_right    : move_net(2,0);
          sh_left     : move_net(4,0);
          sh_down,Mu  : move_net(8,0);
          sh_up       : move_net(1,0);
          sh_1        : join_port(1,0);
          sh_2        : join_port(2,0);
          sh_3        : join_port(3,0);
          sh_4        : join_port(4,0);
          'a'..'r',
          'A'..'R'    : choose_part(key);
          '1'..'4'    : join_port(ord(key)-ord('1')  +1,1);
          '='         : ground_node;
          '+'         : unground;
          Ctrl_n      : snapO;
          else begin
             update_key:=false;
             if not(key in [F1..F4,screenresize]) then beep;
          end;
        end; {case key}
        if update_key then update_key_list(node_number);
       end;
    end;  {case key}
    dx_dyO;
    write_message;
  until key in [F2..F4,Esc];
  write_compt(lightgray,compt1);
  if help_displayed then Write_Board_Parameters; 
end; {* Layout1 *}


procedure Plot2;
{*
	Procedure for directing plotting routines in the Plot window.
*}
begin
  ccompt:=Points_compt;
  cx:=ccompt^.x_block;
  previous_key:=' ';
  repeat
    Get_Key;
    case key of
      '0'..'9','.',' ','-','+'
                   : add_char(ccompt);
       Del         : del_char(ccompt);
       backspace   : back_char(ccompt);
       Ins         : insert_key:=not(insert_key);
       Up_Arrow    : move_cursor( 0,-1);
       Down_arrow  : move_cursor( 0, 1);
       Left_arrow  : move_cursor(-1, 0);
       Right_arrow : move_cursor( 1, 0);
       PgDn        : move_marker(-1);
       PgUp        : move_marker(+1);
       '='         : show_real;
       'i','I',
       's','S'     : Time_Domain_Manager;
       Ctrl_s      : begin
			if Large_Smith then Small_Smith_Coords;
       			Save_Net;
			if Large_Smith then Large_Smith_Coords;
		     end;
       Ctrl_a      : if Art_Form=2 then Make_HPGL_file
       				   else Printer_Artwork;
       Ctrl_p      : Plot_manager (true,false,false,true,true); {replot}
       'p','P'     : Plot_manager (true, true,false,false,true); {analyze}
       'q','Q'     : Plot_Manager (true, true, false, false, false);
       Ctrl_q      : Plot_Manager (true, false, false, true, false);
       Tab         : Toggle_Smith_and_Plot;
       Mu {Alt_s}  : Toggle_Large_Smith(F2);
       screenresize: Screen_Resize;
       F5	   : Change_Bk_Color;
       F10         : Toggle_Help_Window;
       Esc         : check_esc;
       else if not(key in [F1..F4]) then beep;
    end; {case}
    previous_key:=key;
  until key in [F1,F3,F4,Esc];
  IF (key <> ESC) THEN Erase_Message;
  if Large_Smith then Toggle_Large_Smith(key);
  if help_displayed then Write_Board_Parameters; 
end; {* Plot2 *}


procedure Parts3;
{*
	Procedure for directing editing actions in the parts window.
*}
label
  component_start;

Var 
  tmp_file_name : string;

begin
  ccompt:=compt3;  
  cx:=cx3;
component_start:
  repeat
    if read_kbd then get_key;
    case key of
       C_R           : Carriage_Return;
       right_arrow   : move_cursor( 1, 0);
       left_arrow    : move_cursor(-1, 0);
       Ins           : insert_key:=not(insert_key);
       'a'..'z','A'..'Z','0'..'9','+','-','.',',',' ',
       '(',')',':','\','?','!',Omega,Degree,Parallel,Mu
       		     : add_char(ccompt);
       del           : del_char(ccompt);
       backspace     : back_char(ccompt);
       down_arrow    : move_cursor( 0, 1);
       up_arrow      : move_cursor( 0,-1);
       '='           : Pars_Single_Part(ccompt);
       Ctrl_r        : begin
       			 tmp_file_name:=input_string('File to read:',' ');
			 if (tmp_file_name<>'') then begin
			    puff_file:=tmp_file_name;
                            Read_Net(puff_file,false);
			 end;   
                       end;
       Ctrl_e        : Erase_Circuit;
       F5	     : Change_Bk_Color;
       F10           : Toggle_Help_Window;
       Tab	     : Toggle_Parts_Lists;
       Esc           : check_esc;
       screenresize  : Screen_Resize;
        else if not(key in [F1..F4]) then beep;
     end; {case}
  until key in [F1..F4,Esc];
  compt3:=ccompt;  
  cx3:=cx;
  if (key <> Esc) and (key<>not_esc) then begin
    erase_message;
    action:=true;  
    Pars_Compt_List;
    if bad_compt then begin
      read_kbd:=true;
      cx:=ccompt^.x_block;
      Goto component_start;
    end;
  end;
  if not(board_changed and (key=F4)) then 
   if circuit_changed and (key <>Esc) then Redraw_Circuit;
  {Delay redraw if F4 and board_changed, in case of error}
  if help_displayed then begin 
     if Large_Parts then Write_Expanded_Parts
     		    else Write_Board_Parameters;
     help_displayed:=false; 
  end;
end; {* Parts3 *}


procedure Board4;
{*
	Procedure for directing editing in the Board window.
*}
Label
  Start_Board_Label;

Begin
  Write_Board_Parameters; {in case a previous help window displayed}
  HighLight_Window;
  ccompt:=board_start;  
  cx:=ccompt^.x_block; 
Start_Board_Label:
  repeat
    Get_Key;
    case key of
      '0'..'9','.',' ','E','P','T','G','M','k','m',
      Mu,'n','p','f','a',Omega,'h','H','z','Z'	  
                   : add_char(ccompt);
       Del         : del_char(ccompt);
       backspace   : back_char(ccompt);
       Ins         : insert_key:=not(insert_key);
       Up_Arrow    : move_cursor( 0,-1);
       Down_arrow  : move_cursor( 0, 1);
       Left_arrow  : move_cursor(-1, 0);
       Right_arrow : move_cursor( 1, 0);
       C_R         : Carriage_Return;
       Tab         : Toggle_Circuit_Type; {sets board_changed}
       F10         : Toggle_Help_Window;
       F5	   : Change_Bk_Color;
       Esc         : check_esc;
       screenresize: Screen_Resize;
       else 
       	  if not(key in [F1..F4]) then beep;
    end; {case}
  until key in [F1..F3,Esc];
  if (key <> Esc) then begin
    erase_message;
    action:=true;
    Board_Parser;     {compute new board parameters}
    if bad_compt then begin
      read_kbd:=true;
      cx:=ccompt^.x_block;
      Goto Start_Board_Label;
    end;
    if board_changed then begin
    	Fresh_Dimensions;          {load in new board parameters}
	Write_Plot_Prefix(false);  {write new prefix for x-coord}
	Pars_Compt_List;       {compute new component parameters}
	if bad_compt then begin
	   read_kbd:=true;                    {If error occurs, }
	   cx:=ccompt^.x_block;            {point to last change}
	   Goto Start_Board_Label;
        end;
        Redraw_Circuit;
    end;
  end;
  if Large_Parts then Write_Expanded_Parts
     else if help_displayed then Write_Parts_ListO; 
end; {* Board4 *}


(***************************************************************
			Main Program
****************************************************************)

BEGIN
  Puff_Start;
  Init_Marker (dev_beg);   {Init device file memory block}
  Init_Marker (net_beg);   {Init network memory block}
  Read_Net(puff_file,true);
  read_kbd:=not(circuit_changed);
  repeat
    window_number:=Ord(key)-Ord(F1)+1;
    help_displayed:=false;
    HighLight_Window;
    case window_number of
      1 : Layout1;
      2 : Plot2;
      3 : Parts3;
      4 : Board4;
    end;
    if not( (window_number=4) and Large_Parts) then
    	write_comptm(3,col_window[window_number],window_f[window_number]);
  until key= Esc;
  CloseGraph;
  TextMode(OrigMode);
  ClrScr;
END.
