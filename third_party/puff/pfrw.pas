{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pfrw;

(*******************************************************************

	Unit PFRW;

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.


	Potentially hazardous code is denoted by {!xxx} comments

	Contains code for reading and writing .puf files.

********************************************************************)

Interface

Uses
  Dos, 		{Unit found in Free Pascal RTL's}
  xgraph,	{Custom replacement unit for TUBO's "Crt" and "Graph" units}
  pfun1,	{Add other puff units}
  pfun2;


procedure Read_Board(read_graphics : boolean);
procedure read_keyO;
procedure read_partsO;
procedure read_circuitO;
Procedure Read_S_Params;
procedure save_boardO;
procedure save_keyO;
procedure save_partsO;
procedure save_circuitO;
procedure save_s_paramsO;
procedure bad_board;
procedure read_setup(var fname2 : file_string);


Implementation


procedure Read_Board(read_graphics : boolean);
{*
	Read board parameters from .puf file.
*}
Const
  {* Artwork Reduction Ratios in mm/dot *}
  red_psx=0.2117; { 25.4 mm/in  /(120 dots) in x dirn for matrix artwork}
  red_psy=0.1764; { 25.4 mm/in  /(144 dots) in y dirn for matrix artwork}
  red_lasr=0.169333; { LaserJet reduction ratio = 25.4 mm/in * 1/150dpi }

Var
  i    		: integer;
  value		: double;
  unit_prf      : string[80];  {unit-prefix string}
  char1,char2,
  char3,prefix 	: char;


  	{*****************************************************}
	function file_prefix(id_string : string) : char;
	{*
		Look for prefixes when reading board parameters.
		If no prefix and no unit then return 'x' to
		designate that default prefixes are to be used.
	*}
var
  pot_prefix : char;

Begin
  while id_string[1]=' ' do Delete(id_string,1,1); {delete leading blanks}
  if id_string[1] in Eng_Dec_Mux then begin
      pot_prefix:=id_string[1];
      if (id_string[1]='m') and (not(id_string[2] in ['H','O','m']))
          then pot_prefix:=' ';
       {if its just meters, then no prefix}
  end
  else if id_string[1]='U' then begin   {U = micro}
     pot_prefix:=Mu;  {convert U to Mu}
  end
  else if (id_string[1] in ['H','O']) then begin {Hz or Ohms?}
     pot_prefix:=' ';  {if units but no prefix}
  end
  else  {if no prefix or units return 'x'}
     pot_prefix:='x';
  file_prefix:=pot_prefix;
end;

	{*******************************************************}
Procedure Attach_Prefix(b_num : integer; def_prefix : char;
	 var board_param : double; zero_OK : boolean);
{*

*}
Begin
 ReadLn(net_file,value,unit_prf);
 prefix:=file_prefix(unit_prf);
 if def_prefix='G' then begin   {Do not attach prefix for xHz}
 	board_param:=value;
	if prefix='x' then begin
	   s_board[b_num,2]:='G';
	   freq_prefix:='G'; {use default prefix}
	end
	else begin
	   s_board[b_num,2]:=prefix;
	   freq_prefix:=prefix;
        end; 
 end
 else if prefix='x' then begin
 	board_param:=value;
	s_board[b_num,2]:=def_prefix; {use default prefix}
 end	
 else begin {if prefix is given}
	board_param:=value*Eng_Prefix(prefix)/Eng_Prefix(def_prefix);
	{return value in default units }
	s_board[b_num,2]:=prefix;
 end;
 if (board_param > 0.0) or ((board_param=0.0) and zero_OK) then begin
        board[b_num]:=true;
	Str(value:7:3,s_board[b_num,1]);
	if ((value < 1.0e-3) or (value > 1.0e+3)) and not(value=0.0) then 
		Str(value:8,s_board[b_num,1]);
		{Write in exponential notation for small/large numbers}
 end;
end;
	{****************************************************}

Begin  {* Read_Board *}
  {* Default parameters for old .puf files without new parameters *} 
  for i:=9 to 12 do board[i]:=true;  {Make these parameters optional}
  Art_Form:=0;   
  Laser_Art:=False;
  {initialize new parameters for old puff files}
  metal_thickness:=0.0; s_board[9,1]:='  0.000'; s_board[9,2]:='m';
  surface_roughness:=0.0; s_board[10,1]:='  0.000' ;s_board[10,2]:=Mu;
  loss_tangent:=0.0; s_board[11,1]:='  0.000'; s_board[11,2]:=' ';
  conductivity:=5.80e+7;s_board[12,1]:='  5.8E+7';s_board[12,2]:=' ';
  repeat
    if SeekEoln(net_file) then begin {ignore blank lines}
	readln(net_file); {advance to beginning of next line}
	char1:=' ';
    end 
    else begin
	repeat 
	     read(net_file,char1); 
	until char1 <> ' ';
	if char1 <> '\' then begin
	     Read(net_file,char2);
	     if (char2<>' ') then 
	        repeat 
		  read(net_file,char3)
	        until char3=' ';
	     case char1 of
          'z','Z' : Attach_Prefix(1,' ',z0,false);
          'f','F' : Attach_Prefix(2,'G',design_freq,false); 
	  		{prefix not attached here}
          'e','E' : begin
                      ReadLn(net_file,er); {no units here}
                      if er > 0 then begin
		         board[3]:=true;
			 Str(er:7:3,s_board[3,1]);
			 s_board[3,2]:=' '; {no units}
		      end;
                    end;
          'h','H' : Attach_Prefix(4,'m',substrate_h,false);	
          's','S' : if (char2 in ['r','R']) then begin
	  		Board[10]:=false; {init-optional value}
			Attach_Prefix(10,Mu,surface_roughness,true);
		    end
		    else begin
	  	      Attach_Prefix(5,'m',bmax,false);	
                    end;
          'c','C' : if (char2 in ['d','D']) then begin
	  		board[12]:=false; {init-optional}
			ReadLn(net_file,conductivity); {no units here}
                        if (conductivity > 0) then begin
		           board[12]:=true;
			   Str(conductivity:8,s_board[12,1]);
			   s_board[12,2]:=' '; {no units}
		        end;
	            end
		    else
		    	Attach_Prefix(6,'m',con_sep,true);
          'r','R' : begin
	  	      Attach_Prefix(7,'m',resln,false);
		      sresln:=s_board[7,1]+s_board[7,2]+'m';
                    end;
          'a','A' : Attach_Prefix(8,'m',artwork_cor,true);
          'm','M' : if (char2 in ['t','T']) then begin
	  		Board[9]:=false; {init-optional value}
			Attach_Prefix(9,'m',metal_thickness,true);
		    end
		    else begin
                      Readln(net_file,miter_fraction);
                      if (0 <= miter_fraction) and (miter_fraction < 1)
                          then board[16]:=true;
                    end;
	  'l','L' : begin   {Loss Tangent}
	  	      Board[11]:=false; {init-optional}	 
                      ReadLn(net_file,loss_tangent); {no units here}
                      if loss_tangent >= 0 then begin
		         board[11]:=true;
			 Str(loss_tangent:8,s_board[11,1]);
			 s_board[11,2]:=' '; {no units}
		      end;
	            end;
          'p','P' : begin
                      ReadLn(net_file,reduction);
                      if reduction > 0 then 
		      	 if Laser_Art then begin  {setup 150 DPI}
                        	psx:=red_lasr/reduction;
				psy:=red_lasr/reduction;
				board[13]:=true;
			 end 
			 else begin  {setup 144 x 120 DPI}
                        	psx:=red_psx/reduction;
				psy:=red_psy/reduction;
				board[13]:=true;
		      end; {if reduction and/or Laser_art}
                    end;
       	'd','D' : if read_graphics then begin
			readln(net_file,value);
			display:=Round(value);
			board[14]:=true;
			{ ignore the VGA/EGA setting on Linux }
                        imin:=1;
                    end
                    else begin
		    	ReadLn(net_file,value);
			board[14]:=true;
		    end;
          'o','O' : begin   {* New entry for artwork output *}
                      readln(net_file,value);
                      Art_Form:= Round(value);
		      if Art_Form = 1 then Laser_Art:=True;
                    end;
          't','T' : begin
                      ReadLn(net_file,value);
		      if (Round(value)=2) then begin
		      	Manhattan_Board:=true;
			stripline:=true; {makes calculations easier}
		      end
		      else begin
		        Manhattan_Board:=false;
                        stripline:= Round(value) <> 0; 
		      end;	
                      if (Round(value) in [0..2]) then board[15]:=true;
                    end;
             else begin
                message[2]:='Unknown board';
                message[3]:='parameter in .puf';
                shutdown;
             end;
        end;{case char1}
      end; {if char1}
    end; {if SeekEoln}
  until (char1='\') or EOF(net_file);
  board_read:=board[1];
  for i:=2 to 12 do 
  	board_read:=board_read and board[i];
  if board_read and not(read_graphics) then Fresh_Dimensions;
end; {* Read_Board *}


procedure Read_KeyO;
{*
	Read key from .puf file.
*}
var
 len,j,i 	: integer;
 des     	: line_string;
 c1,c2,c3,char1 : char;

begin
  for i:=1 to 6  do s_key[i]:=' ';
  for i:=7 to 10 do s_key[i]:='';
  repeat
    if Eoln(net_file) then begin  {ignore blank lines}
	readln(net_file);
	char1:=' ';
    end 
    else begin
	read(net_file,char1);  
	des:='';
	if char1 <> '\' then begin
	     des:=char1;
	     repeat
	        read(net_file,char1);
	        des:=des+char1;
	     until (char1=lbrack) or Eoln(net_file);
	     readln(net_file);
	     c1:=des[1];
	     c2:=des[2];
	     c3:=des[3];
	     while not(des[1]in ['+','-','.',',','0'..'9','e','E']) 
                 do Delete(des,1,1);
	     len:=length(des);
	     while not(des[len]in ['+','-','.',',','0'..'9','e','E']) 
	     		and (len > 0) do begin
		Delete(des,len,1);
		len:=length(des);
	     end;
	     case c1 of
	     	'd','D' : if c2 in ['u','U'] then s_key[1]:=des 
					     else s_key[2]:=des;
                'f','F' : case c2 of
                    		'l','L': s_key[3]:=des;
				'u','U': s_key[4]:=des;
				'd','D': if c3='/' then s_key[5]:=des
			  end; {case}
		'p','P' : s_key[5]:=des; {pts=number of points}	   
                's','S' : if c2 in ['r','R'] then begin
			     s_key[6]:=des;
			  end 
			  else begin
			     j:=6;
			     repeat
			        j:=j+1;
			     until (length(s_key[j])=0) or (j>9);
			     s_key[j]:=des;
			  end;
	      end; {case}
      end; {if char1 ..}
    end; {if Eoln}
  until (char1='\') or EOF(net_file);
end; {* Read_Key *}


procedure read_partsO;
{*
	Read parts from .puf file. 
	Called by Read_Net() in pfmain1a.pas.
	Upon a call to read_partsO the read index has already 
	advanced to the point where a '\p' has been read.
*}
var
  char1  : char;
  i,j    : integer;
  des    : line_string;
  tcompt : compt;

begin
  Large_Parts:=False;
  {* Clear previous parts list *}
  for i:=1 to 18 do begin 	
    	if i=1 then tcompt:=part_start 
	       else tcompt:=tcompt^.next_compt;
	with tcompt^ do begin
		descript:=char(ord('a')+i-1)+' ';
		used:=0; 
		changed:=false; 
		parsed:=false;
		f_file:=nil;
		s_file:=nil;
		s_ifile:=nil;
	end; {with}
  end; {for i:=1 to 18}
  j:=0;
  repeat
    if Eoln(net_file) then begin {if at end_of_line..}
      	readln(net_file);        {do carriage return}
	char1:=' '; 		 {initialize char1}
    end
    else begin
        read(net_file,char1);
	if char1 <> '\' then begin {dont read first line with '\p'}
        	readln(net_file,des); {read string}
                insert(char1, des, 1);
		Inc(j);
		if j <= 18 then begin
			i:=Pos(lbrack,des);
			if i> 0 then Delete(des,i,length(des));
			for i:=1 to length(des) do
				case des[i] of
				    'O' :  des[i]:=Omega;
				    'D' :  des[i]:=Degree;
				    'U' :  des[i]:=Mu;
				    '|' :  des[i]:=Parallel;
				end; {case}
			while des[length(des)]=' ' do
					delete(des,length(des),1);
					{delete extra blanks}
                        if j=1 then tcompt:=part_start
			       else tcompt:=tcompt^.next_compt;
			with tcompt^ do
			    if (length(des) = 0) then
			    	   changed:=true
				   {descript:=descript}
				   {leave part blank}
				else begin
				   descript:=descript+des;
				   changed:=true;
				   if (j>9) then Large_Parts:=True;
			end; {if and with}
		end; {if j <= 18}
       end; {if char1<>'\'}
    end; {else Eoln}
  until (char1='\') or EOF(net_file);
end; {read_partsO}


procedure read_circuitO;
{*
	Read in circuit from .puf file.
*}
var
  key_i,nn : integer;
  char1    : char;

begin
  circuit_changed:=true; 
  key_end:=0;
  repeat
    if not(Eof(net_file)) then  {read circuit}
    if Eoln(net_file) then begin  {ignore blank lines}
      readln(net_file);
      char1:=' ';
    end 
    else begin
      read(net_file,char1);
      if char1 <> '\' then begin
        readln(net_file,key_i,nn);
        key:= char(key_i);
        update_key_list(nn);
      end;{if char1}
    end;{if Eoln}
  until (char1='\') or EOF(net_file);
  key_i:=0; {set_up for redraw}
end; {read_circuitO}



Procedure Read_S_Params;
{*
	Read s-parameters from .puf file.
	Uses procedure Read_Number.
*}
var
  ij          : integer;
  freq,mag,ph : double;
  char1       : char;

	{********************************************************}
Procedure Read_Number(var s : double);
{*
	Read s-parameter values from files.
*}
Const
  potential_numbers=['+','-','.','0'..'9','e','E'];

Var
  ss	: string[128];
  code	: integer;
  found	: boolean;

Begin
  ss:='';
  if char1 in potential_numbers then
  	ss:=char1  {char1 is the first freq character}
  else begin  {Search for first valid numeric character}
    	found:=false;
	if char1 in [lbrack,'#','!'] then ReadLn(net_file);
	{skip potential comment lines}
	Repeat 
    	   Read(net_file,char1); 	{read another character}
	   if char1 in [lbrack,'#','!'] then ReadLn(net_file);
	   	 {skip potential comment lines}
	   if char1 in potential_numbers then begin
	      ss:=char1;
	      found:=true;
	   end;
        Until found or (char1='\');
  end;
  found:=false;
  if not(char1='\') then
     Repeat {Add to string ss}
     	Read(net_file,char1);
	if char1 in potential_numbers then 
		ss:=ss+char1 
             else 
	        found:=true;
     Until found or Eoln(net_file);
  if (ss<>'') then begin
  	Val(ss,s,code);
	if (code<>0) then s:=0.0;
  end
  else 
  	s:=0.0;
  { turn string ss into double number }
end; {read_number}
	{********************************************************}

Begin   {* Read_S_Params *}
  filled_OK:=true;
  npts:=-1;
  ReadLn(net_file); {Advance through \s comment line}
  for ij:=1 to max_params do begin
	s_param_table[ij]^.calc:=false;
	c_plot[ij]:=nil;
	plot_des[ij]:=nil;
  end;
  Repeat
    if Eoln(net_file) then begin {ignore blank lines}
	ReadLn(net_file);
	char1:=' ';
    end 
    else begin
	Read(net_file,char1);
	if (char1<>'\') and (npts+1 < ptmax) then begin
		Read_Number(freq); 
		Inc(npts); 
		if npts=0 then fmin:=freq;
		ij:=0;
		repeat
		   Inc(ij);
		   if c_plot[ij]=nil then c_plot[ij]:=plot_start[ij]
                                     else c_plot[ij]:=c_plot[ij]^.next_p;
		   if abs(freq-design_freq)=0 then  
		   	plot_des[ij]:=c_plot[ij];
			{restore markers to fd}
		   s_param_table[ij]^.calc:=true;
		   c_plot[ij]^.filled:=true;
		   read(net_file,mag,ph);
		   c_plot[ij]^.x:=mag*cos(ph*pi/180);
		   c_plot[ij]^.y:=mag*sin(ph*pi/180);
		until Eoln(net_file) or (ij=max_params);
		Readln(net_file);
	end; {if char}
    end; {if Eoln else}
  until (char1='\') or EOF(net_file);
  if npts<=1 then filled_OK:=false;
  for ij:=1 to max_params do plot_end[ij]:=c_plot[ij];
  finc:=(freq-fmin)/npts;
end; {* Read_S_Params *}



procedure Save_BoardO;
{*
	Save board parameters to .puf file.
*}
var
 sl,i :integer;

begin
  for i:=1 to 12 do begin        {* Convert Mu's to U's *}
  	if s_board[i,2]=Mu then s_board[i,2]:='U';
  end;
  writeln(net_file,'\b',lbrack,'oard',rbrack,' ',
                        lbrack,'.puf file for PUFF, version 2.1d',rbrack);
  writeln(net_file,'d ',display:6,'     ',lbrack,
  'display: 0 VGA or PUFF chooses, 1 EGA',rbrack);
  writeln(net_file,'o ',Art_Form:6,'     ',lbrack,
  'artwork output format: 0 dot-matrix, 1 LaserJet, 2 HPGL file',rbrack);
  if Manhattan_Board then sl:=2
    else if stripline then sl:=1 else sl:=0;
  writeln(net_file,'t ',sl:6,'     ',lbrack,
  'type: 0 for microstrip, 1 for stripline, 2 for Manhattan',rbrack);
  writeln(net_file,'zd  ',s_board[1,1]+' '+s_board[1,2]+'Ohms ',lbrack,
  'normalizing impedance. 0<zd',rbrack);
  writeln(net_file,'fd  ',s_board[2,1]+' '+s_board[2,2]+'Hz   ',lbrack,
  'design frequency. 0<fd',rbrack);
  writeln(net_file,'er  ',s_board[3,1]+'       ',lbrack,
  'dielectric constant. er>0',rbrack);
  writeln(net_file,'h   ',s_board[4,1]+' '+s_board[4,2]+'m    ',lbrack,
  'dielectric thickness. h>0',rbrack);
  writeln(net_file,'s   ',s_board[5,1]+' '+s_board[5,2]+'m    ',lbrack,
  'circuit-board side length. s>0',rbrack);
  writeln(net_file,'c   ',s_board[6,1]+' '+s_board[6,2]+'m    ',lbrack,
  'connector separation. c>=0',rbrack);
  writeln(net_file,'r   ',s_board[7,1]+' '+s_board[7,2]+'m    ',lbrack,
  'circuit resolution, r>0, use Um for micrometers', rbrack);
  writeln(net_file,'a   ',s_board[8,1]+' '+s_board[8,2]+'m    ',lbrack,
  'artwork width correction.',rbrack);
  writeln(net_file,'mt  ',s_board[9,1]+' '+s_board[9,2]+'m    ',lbrack,
  'metal thickness, use Um for micrometers.',rbrack);
  writeln(net_file,'sr  ',s_board[10,1]+' '+s_board[10,2]+'m    ',lbrack,
  'metal surface roughness, use Um for micrometers.',rbrack);
  writeln(net_file,'lt   ',s_board[11,1]+'   ',lbrack,
  'dielectric loss tangent.',rbrack);
  writeln(net_file,'cd   ',s_board[12,1]+'   ',lbrack,
  'conductivity of metal in mhos/meter.',rbrack);
  writeln(net_file,'p   ',reduction:7:3,'       ',lbrack,
  'photographic reduction ratio. p<=203.2mm/s',rbrack);
  writeln(net_file,'m   ',miter_fraction:7:3,'       ',lbrack,
  'mitering fraction.  0<=m<1',rbrack);
  for i:=1 to 12 do begin        {* Convert U's back to Mu's *}
  	if s_board[i,2]='U' then s_board[i,2]:=Mu;
  end;
end; {save_boardO}


procedure save_keyO;
{*
	Save Plot window parameters to .puf file.
*}
var
  tcompt : compt;
  i      : integer;
  temp   : line_string;

begin
  writeln(net_file,'\k',lbrack,'ey for plot window',rbrack);
  for i:=1 to 10 do begin
    if i=1 then tcompt:=coord_start else tcompt:=tcompt^.next_compt;
    with tcompt^ do
    case i of
      1   :  writeln(net_file,'du  '+descript,
                     '   ',lbrack,'upper dB-axis limit',rbrack);
      2   :  writeln(net_file,'dl  '+descript,
                     '   ',lbrack,'lower dB-axis limit',rbrack);
      3   :  writeln(net_file,'fl  '+descript,
                     '   ',lbrack,'lower frequency limit. fl>=0',rbrack);
      4   :  writeln(net_file,'fu  '+descript,
                     '   ',lbrack,'upper frequency limit. fu>fl',rbrack);
      5   :  begin
               temp:=descript;
               delete(temp,1,6); {delete "Points"}
               writeln(net_file,'pts'+temp,
            '   ',lbrack,'number of points, positive integer',rbrack);
             end;
      6   :  begin
               temp:=descript;
               delete(temp,1,12);
               writeln(net_file,'sr'+temp,
                '   ',lbrack,'Smith-chart radius. sr>0',rbrack);
             end;
     7..10:  begin
               temp:=descript;
               delete(temp,1,1);
               if length(temp) > 0 then begin
                 write(net_file,'S   '+temp);
                 if i=7 then writeln(net_file,
                       '   ',lbrack,'subscripts must be 1, 2, 3, or 4',rbrack)
                        else writeln(net_file);
                 end;
             end;
    end; {case}
  end; {i}
end; {save_keyO}


procedure Save_PartsO;
{*
	Save list of parts to .puf file.
*}
var
  tcompt : compt;
  des    : line_string;
  i      : integer;

begin
  tcompt:=nil;
  writeln(net_file,'\p',lbrack,'arts window',rbrack,' ',
        lbrack,'O = Ohms, D = degrees, U = micro, |=parallel',rbrack);
  repeat {write component list}
    if tcompt=nil then 
    		tcompt:=part_start  {find starting pointer}
	      else 
	    	tcompt:=tcompt^.next_compt; { or find next }
    des:=tcompt^.descript;
    if length(des) > 2 then begin  {if descript more than just a letter}
      	Delete(des,1,2); {delete part letter designation}
	for i:=1 to length(des) do
      	     case des[i] of  	{change to O's, D's, U's, and |'s}
        	Omega  : des[i]:='O';
		Degree : des[i]:='D';
		Mu     : des[i]:='U';
		Parallel : des[i]:='|';
	     end; {case}
	writeln(net_file,des); 
     end    {if length(des) > 2}
     else   {write blank message }
        writeln(net_file,lbrack,'Blank at Part ',des,rbrack); 
  until tcompt^.next_compt=nil;
end; {* Save_PartsO *}


procedure save_circuitO;
{*
	Save circuit to .puf file.
*}
begin
  for key_i:=1 to key_end do begin
    if key_i=1 then writeln(net_file,'\c',lbrack,'ircuit',rbrack);
    write(net_file,ord(key_list[key_i].keyl):4,key_list[key_i].noden:4);
    case key_list[key_i].keyl of
        right_arrow : writeln(net_file,'  right');
        left_arrow  : writeln(net_file,'  left');
        down_arrow  : writeln(net_file,'  down');
        up_arrow    : writeln(net_file,'  up');
        sh_right    : writeln(net_file,'  shift-right');
        sh_left     : writeln(net_file,'  shift-left');
        sh_down     : writeln(net_file,'  shift-down');
        sh_up       : writeln(net_file,'  shift-up');
        sh_1        : writeln(net_file,'  shift-1');
        sh_2        : writeln(net_file,'  shift-2');
        sh_3        : writeln(net_file,'  shift-3');
        sh_4        : writeln(net_file,'  shift-4');
        '+'         : writeln(net_file,'  shift-=');
        Ctrl_n      : writeln(net_file,'  Ctrl-n');
          else        writeln(net_file,'  ',key_list[key_i].keyl);
      end; {case}
  end; {for key_i}
end; {save_circuitO}


Procedure save_s_paramsO;
{*
	Save s-parameters to .puf file.
*}
var
  number_of_parameters,ij,txpt  : integer;
  first_line 			: string[120];
  mag,deg    			: double;
  last_plot_ptr			: array [1..max_params] of plot_param;

begin
  if filled_OK then begin
    writeln(net_file,'\s',lbrack,'parameters',rbrack);
    number_of_parameters:=0;
    first_line:='';
    for ij:=1 to max_params do
      if s_param_table[ij]^.calc then begin
        last_plot_ptr[ij]:=c_plot[ij];  {save last plot position}
	c_plot[ij]:=nil;
	if first_line='' then 
	   first_line:='   f              '+s_param_table[ij]^.descript
         else 
	  first_line:=first_line+'              '+s_param_table[ij]^.descript;
        number_of_parameters:=number_of_parameters+1;
    end; {for ij;if s_param_table}
    writeln(net_file,first_line);
    for txpt:=0 to npts do begin
	  freq:=fmin+finc*txpt;
	  write(net_file,freq:9:5);
	  for ij:=1 to max_params do
	      if s_param_table[ij]^.calc then begin
		   if c_plot[ij]=nil then c_plot[ij]:=plot_start[ij]
                     		     else c_plot[ij]:=c_plot[ij]^.next_p;
		   mag:=sqrt(sqr(c_plot[ij]^.x)+sqr(c_plot[ij]^.y));
		   deg:=atan2(c_plot[ij]^.x,c_plot[ij]^.y);
		   if betweenr(0.1,mag,99.0,0.0) then 
		   		write(net_file,mag:10:5,' ',deg:6:1)
                         else 
			 	write(net_file,' ',mag:9,' ',deg:6:1)
	   end; {for ij ; if s_param_table}
           writeln(net_file);
    end; {for txpt:=0 to npts}
    for ij:=1 to max_params do
      if s_param_table[ij]^.calc then 
        c_plot[ij]:=last_plot_ptr[ij];  {restore last plot position}
  end;{if filled_OK}
end; {save_s_paramsO}


procedure bad_board;
{*
   Give error message when bad board element is present.
*}
var
  i :integer;
begin
  erase_message;
  message[2]:='Bad or invalid';
  i:=0;
  repeat
    i:=i+1;
    if not(board[i]) then begin
      case i of
         1 : message[3]:='zd';
         2 : message[3]:='fd';
         3 : message[3]:='er';
         4 : message[3]:='h';
         5 : message[3]:='s';
         6 : message[3]:='c';
         7 : message[3]:='r';
         8 : message[3]:='a';
         9 : message[3]:='mt';
        10 : message[3]:='sr';
        11 : message[3]:='lt';
        12 : message[3]:='cd';
        13 : message[3]:='p';
        14 : message[3]:='d';
        15 : message[3]:='t';
        16 : message[3]:='m';
      end;{case}
      message[3]:=message[3]+' in .puf file'
    end;
  until not(board[i]);
  shutdown;
end; {* bad_board *}


procedure read_setup(var fname2 : file_string);
{*
	Read board parameters in setup.puf.
*}
var
  char1,char2 : char;

begin
  if setupexists(fname2) then begin
      Repeat
         ReadLn(net_file,char1,char2);
      until ((char1='\') and (char2 in ['b','B'])) or Eof(net_file);
      if not(EOF(net_file)) then Read_Board(true);
      Close(net_file);
  end;
end; {* read_setup *}



End.
