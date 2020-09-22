{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pfart;

(*******************************************************************

        Unit PFART;

        This code is now licenced under GPLv3.

        Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer

        Modifications for Linux compilation 2000-2007 Pieter-Tjerk de Boer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.


        Contains code for creating dot-matrix, LaserJet,
        and HPGL artwork.

********************************************************************)

Interface

Uses

  xgraph,
  Dos,          {Unit found in Free Pascal RTL's}
  Printer,
  pfun1,     {Add other puff units}
  pfun2;

  {* Internals: 
  procedure get_widthxyO(tnet : net; var widthx,widthy : double);
  procedure init_chamferO(tnet : net; widthx,widthy : double);
  procedure init_lineO(tnet : net);
  procedure fill_shape(tnet : net; corner : boolean);
  procedure fill_port(tNt : net);
  procedure net_loop;
  function printer_offline : boolean;
  procedure reset_printer;
  *}

Procedure Make_HPGL_File;
Procedure Printer_Artwork;

Implementation

{**** Artwork variables ****}
Var
  bita                  : array[0..1200] of byte;    {Bit map for artwork}
  dot_step,ydot,mb,
  rowl,xdot_max         : integer;


procedure get_widthxyO(tnet : net; var widthx,widthy : double);
{*
        Given node tnet, find out the width in the 
        x and y direction of connecting parts for chamfer.
*}
var
 direction : integer;
 width     : double;
 tcon      : conn;

begin
  widthx:=0; 
  widthy:=0;
  tnet^.nodet:=0;
  tcon:=nil;
  repeat
    if tcon=nil then tcon:=tnet^.con_start 
                else tcon:=tcon^.next_con;
    direction:=tcon^.dir;
    if tcon^.mate=nil then width:=widthZ0
                      else width:=tcon^.mate^.net^.com^.width;
    if width <> 0 then begin
        tnet^.nodet:=tnet^.nodet+direction;
        case direction of
                1,8 : widthx:=width;
                2,4 : widthy:=width;
        end; {case}
    end;
  until tcon^.next_con=nil;
end; {get_widthxyO}


procedure init_chamferO(tnet : net; widthx,widthy : double);
{*
        Calculate corners of white triangle for chamfer.
        Returns different values of nx2,ny2 than init_line. 
        Right-triangle coordinates returned are:
          (nx1,ny1) (90 degree corner), (nx1,yend) and (xend,ny1)
          where xend=nx1+nx2, yend=ny1+ny2
          xend and yend are computed and used in fill_shape.

*}
var
   hwidthx,hwidthy      : integer;


begin
  with tnet^ do begin
   if (widthx*widthy=0) or (number_of_con<>2) then chamfer:=false 
                                              else chamfer:=true;
   hwidthx:= Round(widthx*0.5/psx);
   hwidthy:= Round(widthy*0.5/psy);
   if chamfer then case nodet of
    10:begin
        nx1:= Round(xr/psx) - hwidthx;
        ny1:= Round(yr/psy) - hwidthy;
        nx2:= Round((miter_fraction*2.0)*widthx/psx);
        ny2:= Round((miter_fraction*2.0)*widthy/psy);
       end;
    12:begin
        nx1:= Round(xr/psx) + hwidthx;
        ny1:= Round(yr/psy) - hwidthy;
        nx2:=-Round((miter_fraction*2.0)*widthx/psx);
        ny2:= Round((miter_fraction*2.0)*widthy/psy);
       end;
     5:begin
        nx1:= Round(xr/psx) + hwidthx;
        ny1:= Round(yr/psy) + hwidthy;
        nx2:=-Round((miter_fraction*2.0)*widthx/psx);
        ny2:=-Round((miter_fraction*2.0)*widthy/psy);
       end;
     3:begin
        nx1:= Round(xr/psx) - hwidthx;
        ny1:= Round(yr/psy) + hwidthy;
        nx2:= Round((miter_fraction*2.0)*widthx/psx);
        ny2:=-Round((miter_fraction*2.0)*widthy/psy);
       end;
     else 
       chamfer:=false;
    end; {case}
  end; {with tnet}
end; {init_chamferO}


procedure init_lineO(tnet : net);
{*
        Calculate dot positons of line tnet for artwork.
*}
var
  xt : integer;

begin
  lengthxy(tnet);
  with tnet^ do begin
        nx1:=Round((xr-yii*lengthxm/2.0)/psx);
        ny1:=Round((yr-xii*lengthym/2.0)/psy);
        nx2:=nx1+Round(lengthxm*(xii+yii)/psx);
        ny2:=ny1+Round(lengthym*(yii+xii)/psy);
        if nx1 > nx2 then begin 
            xt:=nx1;
            nx1:=nx2;
            nx2:=xt;
        end;
        if ny1 > ny2 then begin 
            xt:=ny1;
            ny1:=ny2;
            ny2:=xt;
        end;
  end; {with tnet}
end; {init_lineO}


procedure fill_shape(tnet : net; corner : boolean);
{*
        Updated to function for LaserJet and Dot matrix data.
        Fills array bita[1..xdot_max] that will be sent to printer.
        For Dot matrix, bita[] is up to 960 dot columns (8").
        For LaserJet, bita[] is 8 rows of up to 150 dot rows
                connected end to end, causing the maximum
                size of bita to be 1200 bytes.
        Toggle between dot matrix and Laserjet routines is
                accomplished by examining boolean variable Laser_Art.
        Called by Net_Loop.
*} 
var
  yval,xbeg,xend,ybeg,yend,
  ix,i,left,right,
  in_right,in_left,
  right_byte,left_byte          : integer;
  dot_skip                      : shortint;
  slope                         : double;
  temp                          : byte;

        {**************************************************}
        Procedure white_out(i,ix : integer);
        {* 
                Used to white out a single pixel for chamfers.
        *}
        var
           mask : byte;

        Begin
          if Laser_Art then begin {if LaserJet}
             left := ix div 8;   
             in_right:= ix mod 8;
             mask := 128 shr in_right;
             bita[left+150*i] := bita[left+150*i] and not(mask);
          end 
          else {if Dot matrix}
            bita[ix]:=bita[ix] and not(temp);
        end;

        {**************************************************}
        Procedure black_out(i : integer);
        {*   
                Use for filling array for the Laserjet Printer. 
                Fills pixels (bita[] bytes) from nx1 to nx2.
        *}
        var
                ix:integer;

        Begin
         with tnet^ do begin
          left := nx1 div 8;   in_right:= nx1 mod 8;
          right := nx2 div 8;  in_left:= 7 - nx2 mod 8;
          left_byte:= 255 shr in_right; { use shr and shl to form }
          right_byte:= (255 shl in_left) and 255; { bytes not full of pixels }
          if (left = right) then 
            bita[left+150*i]:= bita[left+150*i] or (left_byte and right_byte)
          else begin   {for right > left fill partial pixel bytes}
            bita[left+150*i]:= bita[left+150*i] or left_byte;
            bita[right+150*i]:= bita[right+150*i] or right_byte;
          end;
          if (right > left + 1) then
               for ix := left+1 to right-1 do bita[ix+150*i]:= 255;
         end; {with}
        End;       
        {***************************************************}


Begin
  if Laser_Art then dot_skip:=1  {Laserjet has true 150 dpi}
               else dot_skip:=2; {Skip dot matrix dots to produce 2*72 dpi}
  with tnet^ do
  if corner then begin {chamfer corner}
        ybeg:=ny1;
        if ny2 < 0 then ybeg:=ybeg+ny2;
        yend:=ybeg+abs(ny2);
        if yend +10 > ydot then remain:=true;
        xbeg:=nx1;
        if nx2 < 0 then xbeg:=xbeg+nx2;
        xend:=xbeg+abs(nx2);
        if xbeg < 0 then xbeg:=0; 
        if xbeg > xdot_max then xbeg:=xdot_max;
        if xend < 0 then xend:=0; 
        if xend > xdot_max then xend:=xdot_max;
        if xbeg=xend then slope:=1 
                     else slope:=(yend-ybeg)/(xend-xbeg);
        temp:=128;
        for i:=0 to 7 do begin
          yval:=ydot+dot_skip*i;
          if i <> 0 then temp:=temp shr 1;
          if (ybeg <= yval) and (yval <= yend) then begin
            if xend > rowl then rowl:=xend;
              for ix:=xbeg to xend do begin     
                case nodet of
                 10: if yval < (yend-Round((ix-xbeg)*slope)) then
                        white_out(i,ix);
                 12: if yval < (ybeg+Round((ix-xbeg)*slope)) then
                        white_out(i,ix);
                  5: if yval > (yend-Round((ix-xbeg)*slope)) then
                        white_out(i,ix);
                  3: if yval > (ybeg+Round((ix-xbeg)*slope)) then
                        white_out(i,ix);
                end; {case}
              end; {for ix}
          end; { if ybeg<= yval }
        end; {for i=0 to 7}
     end
     else begin  {if not corner fill in shape}
        if ny2+10  > ydot then remain:=true;
        temp:=0;
        for i:=0 to 7 do begin
          temp:=temp shl 1;
          if (ny1 <= ydot+dot_skip*i) and (ydot+dot_skip*i <= ny2) then begin
                temp:= (temp + 1);
                if nx2 > rowl then rowl:=nx2;
          end; {if y1}
        end; {for i}  
        if nx1 < 0 then nx1:=0;   {* Clip corners *}
        if nx1 > xdot_max then nx1:=xdot_max;
        if nx2 < 0 then nx2:=0; 
        if nx2 > xdot_max then nx2:=xdot_max;
        if temp>0 then 
          if Laser_Art then begin
             for i:=7 downto 0 do begin
                if (temp and 1) = 1 then black_out(i);
                temp:= temp shr 1;
             end; {for i}       
          end
          else begin
             for ix:=nx1 to nx2 do bita[ix]:=bita[ix] or temp;
        end; {if temp and/or Laser_Art}
  end; {if not corner}
end; {fill_shape}


procedure fill_port(tNt : net);
{*
        Perform artwork connections to external ports.
*}
var
  tptyr,tptxr           : double;
  tport,tpt             : net;
  tcon                  : conn;
  nodet1,x1,y1,x2,y2    : integer;

begin
  tcon:=nil;
  repeat
    if tcon=nil then tcon:=tNt^.con_start 
                else tcon:=tcon^.next_con;
    if ext_port(tcon) then begin
      tport:=portnet[tcon^.port_type];
      y1:=Round(tNt^.yr/psy);
      y2:=Round(tport^.yr/psy);
      if ydot=0 then begin
        tpt:=tport;
        x1:=Round(tNt^.xr/psx);
        x2:=Round(tpt^.xr/psx);
        tptxr:=tpt^.xr;
        tptyr:=tpt^.yr;
        New_n(tpt^.other_net);
        tpt:=tpt^.other_net;
        tpt^.ny1:=y2-pwidthyZ02; 
        tpt^.ny2:=y2+pwidthyZ02;
        if x1 < x2 then begin  
            tpt^.nx1:=x1;  
            tpt^.nx2:=x2
        end 
        else begin  
            tpt^.nx1:=x2;  
            tpt^.nx2:=x1  
        end;
        New_n(tpt^.other_net);
        tpt:=tpt^.other_net;
        tpt^.nx1:=x1-pwidthxZ02; 
        tpt^.nx2:=x1+pwidthxZ02;
        if y1 < y2 then begin  
            tpt^.ny1:=y1;  
            tpt^.ny2:=y2
        end 
        else begin  
            tpt^.ny1:=y2;  
            tpt^.ny2:=y1  
        end;
        if tNt^.yr > tptyr then begin
           if tNt^.xr > tptxr then nodet1:=12 
                              else nodet1:=10;
        end 
        else begin
          if tNt^.xr > tptxr then nodet1:=5  
                             else nodet1:= 3;
        end;
        New_n(tpt^.other_net);
        tpt:=tpt^.other_net; {chamfers}
        tpt^.xr:=tNt^.xr; 
        tpt^.yr:=tptyr;
        tpt^.nodet:=nodet1;
        tpt^.number_of_con:=2;
        init_chamferO(tpt,widthZ0,widthZ0);
      end;
      tport:=tport^.other_net;  
      fill_shape(tport,false);  {horiz line}
      if abs(y2-y1) > pwidthyZ02 then begin
        tport:=tport^.other_net; 
        fill_shape(tport,false);{vert. line}
        tport:=tport^.other_net;
        fill_shape(tport,true);  {do chamfer}
      end;
    end;{if tcon}
  until tcon^.next_con=nil;
end; {fill_port}


procedure net_loop;
{*
        Loop over parts for artwork mask.
*}
var
  tnet : net;
  widthx,widthy : double;

begin
  remain:=false;
  ydot:=ydot+dot_step;
  tnet:=nil ;
  repeat
    if tnet=nil then tnet:=net_start 
                else tnet:=tnet^.next_net;
    if ydot=0 then begin
       if tnet^.node then begin
          get_widthxyO(tnet,widthx,widthy);
          init_chamferO(tnet,widthx,widthy)
       end 
       else begin
          dirn:=tnet^.con_start^.dir;
          init_lineO(tnet);
          if tnet^.com^.typ='c' then init_lineO(tnet^.other_net);
       end; {if tnet^.node}
    end; {if ydot}
    if not(tnet^.node) then begin
       if tnet^.com^.typ in ['q','t','c'] then fill_shape(tnet,false);
       if tnet^.com^.typ in ['c'] then fill_shape(tnet^.other_net,false);
    end;
  until tnet^.next_net=nil;
  tnet:=nil ;
  repeat
    if tnet=nil then tnet:=net_start 
                else tnet:=tnet^.next_net;
    if tnet^.node then begin
       if tnet^.ports_connected > 0 then fill_port(tnet);
       if tnet^.chamfer then fill_shape(tnet,true);  {fill chamfer}
    end;
  until tnet^.next_net=nil;
end; {* net_loop *}


Procedure Make_HPGL_File;
{*
        Used to generate HPGL files.
        Called in Plot via Ctrl-a when enabled in .puf file 

        Code here is tricky! X and Y coordinates 
        must be swapped for compatibility between printer
        coordinate systems and the plotter coordinate system. 
        Units in millimeters must be changed to plotter units
        with conversion factor of 40 plu/mm.
*}
Var
  tport,tpt,tnet                : net;
  tcon                          : conn;
  nodet1,drive,plu_size,
  xoffset,yoffset,
  lx,ly,x2,y2, 
  max_x_plu,max_y_plu           : integer;
  fname,pap_size                : file_string;
  widthx,widthy,sf              : double;
  pap_char                      : char;         

        {*****************************************************}
        procedure HPGL_chamfer(tnet:net; widthx,widthy,sf:double);
        {*
                Calculate corners of white triangle for chamfer.
                Parameter units used are millimeters.   
        *}
        var
                rx1,ry1,rx2,ry2 : double;

        begin
          with tnet^ do begin
            if (widthx*widthy=0) or (number_of_con<>2) 
                then chamfer:=false
                else chamfer:=true;
            if chamfer then
                case nodet of
                   10:  begin
                          rx1:= (xr-widthx/2.0);
                          rx2:=+(miter_fraction*2.0)*widthx;
                          ry1:= (yr-widthy/2.0);
                          ry2:=+(miter_fraction*2.0)*widthy;
                        end;
                   12:  begin
                          rx1:= (xr+widthx/2.0);
                          rx2:=-(miter_fraction*2.0)*widthx;
                          ry1:= (yr-widthy/2.0);
                          ry2:=+(miter_fraction*2.0)*widthy;
                        end;
                    5:  begin
                          rx1:= (xr+widthx/2.0);
                          rx2:=-(miter_fraction*2.0)*widthx;
                          ry1:= (yr+widthy/2.0);
                          ry2:=-(miter_fraction*2.0)*widthy;
                        end;
                    3:  begin
                          rx1:= (xr-widthx/2.0);
                          rx2:=+(miter_fraction*2.0)*widthx;
                          ry1:= (yr+widthy/2.0);
                          ry2:=-(miter_fraction*2.0)*widthy;
                        end;
                else 
                        chamfer:=false;
             end; {if chamfer, case}
           if chamfer then 
                WriteLn(net_file,'PUPA',xoffset+Round(sf*ry1),
                  ',',yoffset+Round(sf*(rx1+rx2)),
                  ';PDPA',xoffset+Round(sf*(ry1+ry2)),
                  ',',yoffset+Round(sf*(rx1)),';PU;');
         end; {with tnet}
        end; {HPGL_chamfer}
        {********************************************************}

Begin   {* Make_HPGL_File *}
  if net_start=nil then begin
    message[1]:='No circuit';
    message[2]:='to do HPGL file';
    write_message;
  end 
  else begin
    fname:=input_string('HP-GL file name:', '     (*.HPG)');
    if fname='' then exit;
    if Pos(':',fname)=2 then drive:=ord(fname[1])-ord('a')+1
                        else drive:=-1;
    if enough_space(drive) then begin
      if pos('.',fname)=0 then fname:=fname+'.HPG';
      Assign(net_file,fname);  
      {$I-} Rewrite(net_file); {$I+}
      if IOresult=0 then begin
        sf:=40*reduction;  {red* 40 plotter units per mm (plu/mm)}
        plu_size:=Round(bmax*sf); {board size in plu's}
        pap_size:=input_string('Select Paper Size',' A,B,A4,A3: (A)');
        if pap_size='' then pap_char:='A'
                       else pap_char:=pap_size[1];
        Case pap_char of  {determine maximum plotter unit}
              'a','A'   : begin
                            if pap_size[2]='3' then begin   {A3 size}
                              max_x_plu:=16158;
                              max_y_plu:=11040;
                            end
                            else if pap_size[2]='4' then begin  {A4 size}
                              max_x_plu:=11040;
                              max_y_plu:=7721;
                            end
                            else begin   {A size}
                              max_x_plu:=10365;
                              max_y_plu:=7962;
                            end;
                          end;  
              'b','B'   : begin  {B size}
                            max_x_plu:=16640;
                            max_y_plu:=10365;
                          end;  
                 else begin {default to A}
                    max_x_plu:=10365;
                    max_y_plu:=7962;
                 end;  
        end; {case}
        if (plu_size > max_x_plu)
           or (plu_size > max_y_plu) then begin
          message[1]:='Reduction ratio';
          message[2]:='too large';
          message[3]:='Edit .puf file';
          write_message;
          Close(net_file);
        end 
        else begin
          xoffset:=(max_x_plu - plu_size) div 2;  {use to page center}
          yoffset:=(max_y_plu - plu_size) div 2;
          tnet:=nil;
                {* Initialize and select pen 1 *}
                {* Place paper size selection in file *}
          Write(net_file,'IN;SP1;'); 
          if max_x_plu > 16000 then WriteLn(net_file,'PS0;')
                              else WriteLn(net_file,'PS4;');
          repeat 
            if tnet=nil then tnet:=net_start 
                        else tnet:=tnet^.next_net;
            if tnet^.node then begin
                get_widthxyO(tnet,widthx,widthy);
                HPGL_chamfer(tnet,widthx,widthy,sf);
                with tnet^ do
                 if ports_connected > 0 then begin
                    tcon:=nil;
                    repeat
                      if tcon = nil then tcon:=tnet^.con_start
                                    else tcon:=tcon^.next_con;
                      if ext_port(tcon) then begin
                        {* Draw horizontal connection to port *}
                        tport:=portnet[tcon^.port_type];
                        lx:=Round(sf*(tport^.yr - widthZ0/2.0)); {y-start} 
                        ly:=Round(sf*(tport^.xr)); {x-start}
                          {goto corner,  X and Y swapped}
                        WriteLn(net_file,'PUPA',xoffset+lx,',',
                                yoffset+ly,';PD;');
                        x2:=Round(sf*widthZ0);         {delta-y}
                        y2:=Round(sf*(xr-tport^.xr));  {delta-x}
                          {Edge rectangle relative}
                        WriteLn(net_file,'ER',x2,',',y2,';PU;');
                        if abs(tnet^.yr - tport^.yr) > widthz0/2.0 then begin
                          {* Draw vertical connection to port *}
                          ly:=Round(sf*(xr - widthZ0/2.0)); {x-start}
                          lx:=Round(sf*(tport^.yr));  {y-start}
                            {goto corner,  X and Y swapped}
                          WriteLn(net_file,'PUPA',xoffset+lx,',',
                                yoffset+ly,';PD;');
                          y2:=Round(sf*widthZ0);        {delta-x}
                          x2:=Round(sf*(yr-tport^.yr)); {delta-y}
                            {Edge rectangle relative}
                          WriteLn(net_file,'ER',x2,',',y2,';PU;');
                          if yr > tport^.yr then begin
                            if xr > tport^.xr then nodet1:=12 
                                              else nodet1:=10;
                          end 
                          else begin
                            if xr > tport^.xr then nodet1:=5  
                                              else nodet1:= 3;
                          end;
                          New_n(tpt);
                          tpt^.xr:=xr; 
                          tpt^.yr:=tport^.yr;
                          tpt^.nodet:=nodet1;
                          tpt^.number_of_con:=2;
                          HPGL_chamfer(tpt,widthZ0,widthZ0,sf);
                        end; {if abs(tnet..}
                      end; {if ext_port}
                   until tcon^.next_con=nil;
                end; {with tnet^ do, if tnet^.ports_connected }
            end {if tnet^.node}   
            else if (tnet^.com^.typ in ['q','t','c']) then begin
                 {* Draw tlines, qlines, and clines *}
               dirn:=tnet^.con_start^.dir;
               lengthxy(tnet);
               with tnet^ do begin
                  lx:=Round(sf*(yr - abs(xii)*lengthym/2.0));
                  ly:=Round(sf*(xr - abs(yii)*lengthxm/2.0));
                  if yii=0 then x2:=Round(sf*lengthym)
                           else x2:=Round(sf*yii*lengthym);
                  if xii=0 then y2:=Round(sf*lengthxm)
                           else y2:=Round(sf*xii*lengthxm);
                  WriteLn(net_file,'PUPA',xoffset+lx,
                           ',',yoffset+ly,';PD;');
                   {* Edge rectangle relative *}
                  WriteLn(net_file,'ER',x2,',',y2,';PU;');
               end; {with tnet}
               if tnet^.com^.typ='c' then
                  with tnet^.other_net^ do begin
                     lx:=Round(sf*(yr - abs(xii)*lengthym/2.0));
                     ly:=Round(sf*(xr - abs(yii)*lengthxm/2.0));
                     WriteLn(net_file,'PUPA',xoffset+lx,',',
                                yoffset+ly,';PD;');
                          {* Edge rectangle relative *}
                     WriteLn(net_file,'ER',x2,',',y2,';PU;');
               end; {if tnet^ = c, with tnet}
            end; {if not tnet^.node};
        until tnet^.next_net=nil;
                {* Present paper and put pen away *}
        WriteLn(net_file,'IP;PA0,',max_y_plu,';SP0;');  
        Close(net_file);
        message[1]:='HP-GL data';
        message[2]:='written to file';
        message[3]:=fname;
        write_message;
     end;  {if reduction too small}
    end; {if IOResult=0}
   end; {if enoughspace}
  end; {if not net_start= nil}
End; {*Make_HPGL_File*}
     

Procedure Printer_Artwork;
{*
        Revised Procedure for directing artwork to dot-matrix
        or LaserJet printers.

*}
label
  exit_artwork;

var
  ix            : integer;
  lpt_label     : string;
  lst           : text;   { local printer file; hides the global variable of the same name }

        {***************************************************}
        function top_labels : boolean;
        {*
                Prompt user for labels to on the top of artwork mask.
        *}
        begin
          top_labels := false;
          top_labels := true;
          name:=input_string(lpt_label,' Enter label #1');
          network_name:=input_string(lpt_label,' Enter label #2');
        end; {top_labels}
        {***************************************************}
        procedure Matrix_labels;
        {*
                Print labels on the top of artwork mask.
        *}
        begin
          write(lst,#27'E',#27'G'); {switch on  emphasised, double strike}
          writeln(lst,name:26    + length(name) div 2);
          writeln(lst,network_name:26 + length(network_name) div 2);
          write(lst,#27'F',#27'H'); {switch off emphasised, double strike}
          p_labels := false;
        end; {print_labelsO}
        {***************************************************}
        procedure Laser_labels;
        {*
                Initialize laser printer and put labels 
                on the top of artwork mask.
        *}
        var
          xpos, ypos    : integer;

        begin
          write(lst,#27,'E'); {Reset Printer}
          write(lst,#27,'&l0O',#27,'&l2A',#27,'(0U',#27,
                '(s0p10h12v0s3b3T'); 
                {Put in landscape mode, 8 1/2 x 11 
                page size, ASCII symbol set, fixed spacing,
                10cpi, 12pt, upright, courier bold font}
          xpos:= 1200 - 30 * length(name) div 2;        
          ypos:= 1450-xdot_max;
          write(lst,#27,'*p',xpos,'x',ypos,'Y'); {position cursor for text}
          write(lst,name);
          xpos:= 1200 - 30 * length(network_name) div 2;        
          ypos:= 1500 - xdot_max; {move down 70 dots}
          write(lst,#27,'*p',xpos,'x',ypos,'Y'); {position cursor for text}
          write(lst,network_name);
          write(lst,#13); {add carriage return}
          write(lst,#27,'(s0B'); {turn off bold font}
          xpos:=1200-xdot_max;
          ypos:=1600-xdot_max;
          write(lst,#27,'*p',xpos,'x',ypos,'Y'); {center artwork}
          write(lst,#27,'*t150R'); {Put in raster graphics 150 dpi mode}
          write(lst,#27,'*r1A'); {start graphics at current cursor position }
          p_labels := false;
        end; {Laser_labels}
        {***************************************************}
        Procedure Send_Matrix_Data;
        {*
        *}
        var
          ix    : integer;

        Begin
          if not(p_labels) then begin
            if rowl > xdot_max then rowl:=xdot_max;
            write(lst,#27'L', chr((rowl+1) mod 256), chr((rowl+1) div 256));
                {* Put printer in dual-density bit-image
                   graphics mode (half-speed) and specify
                   total number of bit image bytes
                   to be n=n1+(n2*256)   *}
            for ix := 0 to rowl do write(lst,chr(bita[ix]));
                {* Write row of dot-columns *}
            write(lst,#13);
                {* Carriage return of given spacing *}
            if odd(mb) then write(lst,#27'J',#13)   {* 13/216" spacing *}
                       else write(lst,#27'J',#11);  {* 11/216" spacing *}
          end; {if not(p_labels)}
          if odd(mb) then dot_step:=9  {* Alternate dot steps for *}
                     else dot_step:=7; {* different spacings *}
        end; {Send_Matrix_Data}
        {***************************************************}
        Procedure Send_Laser_Data;
        {*
        *}
        var
          ix,iy,byte_total      : integer;

        Begin
          if not(p_labels) then begin
            if rowl > xdot_max then rowl:=xdot_max;
            byte_total:= rowl div 8 + 1;
            if (rowl mod 8) > 0 then byte_total:= byte_total+1;
            for iy:=0 to 7 do begin  {* loop for 8 rows *}
               write(lst,#27,'*b',byte_total,'W');
                  {* prepare to send data bytes *}
               for ix:=0 to (byte_total-1) do
                  write(lst,chr(bita[ix+150*iy]));
                  {* send data *}
            end; {for iy}   
          end; {if not(p_labels)}
          dot_step:=8  {* 8 rows of data *}
        end; {Send_Laser_Data}
        {***************************************************}


Begin   {* Printer_Artwork *}
  if net_start=nil then begin
    message[1]:='No circuit';
    message[2]:='to do artwork';
    write_message;
  end 
  else begin
    if reduction*bmax > 8*25.4 then begin
      message[1]:='Reduction ratio'; 
      message[2]:='too large'; 
      message[3]:='Edit .puf file';
      write_message;
    end 
    else begin

  {*-------------------------------------------------------------------
			<Linux Printer Options>

     The following lines determine where printer-data will be sent.
     You should uncomment (and possibly change) the option that suits
     your system.
     The first option just sends it to /dev/null, i.e., the data will be
     ignored:
  *}
      assignlst(lst, '/dev/null|');

  {* If you have a suitable printer, you can simply send the data to the
     printer, through the /usr/bin/lpr program. Note that the data contains
     all kind of control sequences, so it should not be interpreted by any
     printer filters. In this example, we assume that on your system a
     printer called 'raw' is defined for this purpose:
  *}
     { assignlst(lst, '|/usr/bin/lpr -Praw'); }

  {* You may also want to send the data to a simple file, and send it to
     the printer by hand. This is e.g. useful if the printer is not
     directly reachable from this machine. As an example, we send the
     data to a file named 'puff.lst':
  *}
     { assignlst(lst, '/tmp/puff.lst|'); }

  {* Note the '|' at the end of the filename. If you remove it, the file
     will also be sent to the printer using the 'lpr' program, and deleted
     afterwards.
     See the documentation of the free pascal compiler for more information
     on printing.
  ------------------------------------------------------------------------*}
      rewrite(lst);
      ydot:=0;      {* These initial values activate *}
      dot_step:=0;  {* chamfer routines in net_loop  *}
      remain:=true;  
      if Laser_Art then begin  {maximum number of dots at 150 dpi}
         xdot_max:=Round(reduction*bmax*150/25.4);
         if xdot_max > 1200 then xdot_max:=1200;
         lpt_label:='  LaserJet Art';
      end
      else begin    {maximum number of dots at 120 dpi}
         xdot_max:=Round(reduction*bmax*120/25.4);
         if xdot_max > 960 then xdot_max:=960;
         lpt_label:=' Dot-Matrix Art';
      end;
      mb:=-1;
      p_labels:=top_labels;
      if p_labels then begin
        message[2]:='Press h to halt';
        write_message;
        while remain do begin
          if keypressed then begin
            chs := ReadKey;
            if chs in ['h','H'] then begin
               message[2]:='      HALT       ';
               write_message;
               goto exit_artwork;
            end; {if key}
            beep; 
          end; {if keypressed}
          rowl:=0;
          for ix:=0 to 1200 do bita[ix]:=0; {Initialize data}
          Inc(mb);
          Net_Loop;
          if (rowl > 0) and p_labels then 
              if Laser_Art then Laser_labels
                           else Matrix_labels;
          if Laser_Art then Send_Laser_Data
                       else Send_Matrix_Data;
        end; {while remain}
        message[2]:='Artwork completed';
        write_message;
        if Laser_Art then write(lst,#27,'E'); {reset LaserJet, eject page}
      end; {if p_labels}
      exit_artwork:
      close(lst);
    end;
  end;
End; {* Printer_Artwork *}

End.
