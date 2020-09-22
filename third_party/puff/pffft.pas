{$R-}    {Range checking}
{$S-}    {Stack checking}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pffft;

(*******************************************************************

	Unit PFFFT;

	PUFF FFT CODE

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.

	Contains code for FFT analysis.

********************************************************************)

Interface

Uses
  xgraph,	{Custom replacement unit for TUBO's "Crt" and "Graph" units}
  pfun1,	{Use other puff unit}
  pfun3;

(* Local code:
   Procedure Fill_Data_4_FFT(ij,istart,ifinish : integer; nf : double);
   Procedure Four1(ij,nn,isign : integer);
   Procedure Real_FFT(ij,n,isign : integer);
*)
Procedure Time_Response;



Implementation

Type
 farray  = array[1..514,1..max_params] of double; {2*256+2 nft max= 256}

Var
  Data  : farray;   {data array for FFT}


Procedure Fill_Data_4_FFT(ij,istart,ifinish : integer; nf : double);
{*
	Fill array data for FFT and apply weighting.
	Global variable filled is `Data' of type farray
	where farray = array[1..514,1..max_params] of double.
	514=2*nft+2   nft= 256, max_params=4
	ij: scattering parameter index.
	nf: normalization factor.

	wf:   Weighting factor applied for either the impulse
	      or step function.
	cplt: Used to step through the linked list of frequency
              data. cplt^.x =real part, cplt^.y=imag.

	The weighting function used for the impulse response is 
	a raised cosine function. It is purely real.
	The weighting function used for the step response is
        1/omega, band limited by a raised cosine. It is
	purely imaginary. And, is an odd function.
	
	Since the routines included in PUFF are only used
	to generate a real time function from the complex
	frequency function, it is only necessary to use
	positive frequency components. Therefore, the
	size of Data is half of that anticipated.
*}

var
  wf   : double;
  i    : integer;
  cplt : plot_param;

begin
  for i:= 1 to (nft+1) do
    if betweeni(istart,i-1,ifinish) then begin
	if (i-1)=istart then cplt:=plot_start[ij] 
               		else cplt:=cplt^.next_p;
	if step_fn then	begin  {Apply weighting for step function}
	    if not(odd(i)) then begin  
	    	{1/i weighting, band limited by raised cosine}
		wf:=nf*(1.0+cos(pi*(i-1)/(ifinish+1)))/(i-1);
		{wf is supposed to be -imaginary, so swap x and y}
		data[2*i-1,ij] := wf*cplt^.y;
		data[2*i,ij]   :=-wf*cplt^.x;
	    end 
	    else begin {force function to be odd in (i-1)}
		data[2*i-1,ij] :=0;
		data[2*i,ij]   :=0;
	    end;  
	end 
	else begin
	    {Apply raised cosine band limiting for the impulse response}
	    wf:=nf*(1.0+cos(pi*(i-1)/(ifinish+1)));
	    data[2*i-1,ij] :=wf*cplt^.x;
	    data[2*i,ij]   :=wf*cplt^.y;
	end; {else if step_fn}
    end 
    else begin   {fill with zeros outside of frequency range}
	data[2*i-1,ij] :=0;
	data[2*i,ij]   :=0;
    end; {else if between}
    data[2,ij]:=data[2*nft+1,ij];
end; {* Fill_Data_4_FFT *}


Procedure Four1(ij,nn,isign : integer);
{*
	FFT as per Press et. al. Numerical Recipes p 394, p 754.
	Uses global array Data[1..514,1..4].

	if isign=1 then FFT, else inverse FFT (without scaling).
	However, in Puff since an inverse FFT is performed
	going from complex frequency data to real time data,
	use isign=1 when calling from Real_FFT.
	
*}
{label
  one,two;}

var
    ii,jj,n,i,m,j,mmax,istep 	: integer;
    wr,wi,wpr,wpi,wtemp,theta 	: double;
    tempr,tempi 		: double;

begin
  n:=2*nn;
  j:=1;
  for ii:=1 to nn do begin
     i:=2*ii-1;
     if (j > i) then begin
	Tempr:=Data[j,ij];
	Tempi:=Data[j+1,ij];
	Data[j,ij]:=Data[i,ij];
	Data[j+1,ij]:=Data[i+1,ij];
	Data[i,ij]:=Tempr;
	Data[i+1,ij]:=Tempi;
     end;
     m:= n div 2;
     while (m >=2) and (j > m) do begin
	j:=j-m;
	m:=m div 2;
     end;
     j:=j+m;
  end; {for ii}
  mmax:=2;
  while (n > mmax) do begin
    istep:=2*mmax;
    theta:=2*pi/(isign*mmax);
    wpr:=-2.0*sqr(sin(theta/2.0));
    wpi:=sin(theta);
    wr:=1.0;
    wi:=0.0;
    for ii:=1 to (mmax div 2) do begin
       m:=2*ii-1;
       for jj:=0 to ((n-m) div istep) do begin
          i:=m+jj*istep;
          j:=i+mmax;
	  tempr:=wr*data[j,ij]-wi*data[j+1,ij];
	  tempi:=wr*data[j+1,ij]+wi*data[j,ij];
	  data[j,ij]:=data[i,ij]-tempr;
	  data[j+1,ij]:=data[i+1,ij]-tempi;
	  data[i,ij]:=data[i,ij]+tempr;
	  data[i+1,ij]:=data[i+1,ij]+tempi;
       end; {for jj}	
       wtemp:=wr; 
       wr:=wr*wpr-wi*wpi+wr;
       wi:=wi*wpr+wtemp*wpi+wi;
   end; {for ii}
   mmax:=istep;
  end; {while n>}
end; {* Four1 *}


Procedure Real_FFT(ij,n,isign : integer);
{*
	Perform real FFT as per Press et. al. Numerical Recipes p 400.
	(a.k.a. "realft")

	Uses global array Data[1..514,1..4].

	Called only by Time_Response.
	In puff isign=-1 so that the inverse FFT is always performed.
	Call is made to Four1 to execute FFT.
	
	Although not used here, if isign=+1 then FFT done.
*}
var
  i,i1,i2,i3,i4 		: integer;
  c1,c2,h1r,h1i,h2i,h2r		: double;
  wr,wi,wpr,wpi,wtemp,theta 	: double;

begin
  theta:=2*pi/(2.0*n);
  wr:=1.0;
  wi:=0.0;
  c1:=0.5;
  if (isign=1) then begin
   	c2:=-0.5;
	theta:=-theta;
	Four1(ij,n,1);
	data[2*n+1,ij]:=data[1,ij];
	data[2*n+2,ij]:=data[2,ij];
  end 
  else begin
	c2:= 0.5;
	data[2*n+1,ij]:=data[2,ij];
	data[2*n+2,ij]:=0.0;
	data[2,ij]:=0.0;
  end;
  wpr:=-2.0*sqr(sin(theta/2.0));
  wpi:=sin(theta);
  for i:=1 to (n div 2)+1 do begin
	i1:=2*i-1;
	i2:=i1+1;
	i3:=2*n+3-i2;
	i4:=i3+1;
	h1r:= c1*(data[i1,ij]+data[i3,ij]);
	h1i:= c1*(data[i2,ij]-data[i4,ij]);
	h2r:=-c2*(data[i2,ij]+data[i4,ij]);
	h2i:= c2*(data[i1,ij]-data[i3,ij]);
	data[i1,ij]:= h1r+wr*h2r-wi*h2i;
	data[i2,ij]:= h1i+wr*h2i+wi*h2r;
	data[i3,ij]:= h1r-wr*h2r+wi*h2i;
	data[i4,ij]:=-h1i+wr*h2i+wi*h2r;
	wtemp:=wr;
	wr:=wr*wpr - wi*wpi + wr;
	wi:=wi*wpr+wtemp*wpi+wi;
  end; {for i}
  if (isign=1) then data[2,ij]:=data[2*n+1,ij] 
	       else Four1(ij,n,1);
end; {* Real_FFT *}


Procedure Time_Response;
{*
	Main procedure for FFT to get time response.
*}
var
  nf,delt,time,hir_temp	: double;
  istart,ifinish,
  x1,y1,i,ij,col 	: integer;

begin
  hir_temp:=1.0;
  Erase_Message;
  istart:=Round(fmin/finc);
  ifinish:=istart+npts;
  if ifinish > nft then begin
    message[2]:='fmax/df too large';
    Write_Message;
    exit;
  end;
  nf:=0;
  for i:= 1 to (nft+1) do
   if betweeni(istart,i-1,ifinish) then
    if step_fn then begin
     if not(odd(i)) then begin
      if odd(i div 2) then nf:=nf+(1.0+cos(pi*(i-1)/(ifinish+1)))/(i-1)
                      else nf:=nf-(1.0+cos(pi*(i-1)/(ifinish+1)))/(i-1);
     end;
  end 
  else begin
      if (i-1) > 0 then nf:=nf+(1.0+cos(pi*(i-1)/(ifinish+1)))
                   else nf:=nf+1.0;
  end;
  nf:=1.0/nf;
  marker_OK:=false;
  delt:=1.0/(2.0*nft*finc);
  sxmin:= -q_fac/(8*design_freq);  
  sxmax:=3*q_fac/(8*design_freq);
  symax:= rho_fac;                 
  symin:=-rho_fac;
  Draw_Graph(xmin[8],ymin[8],xmax[8],ymax[8],true);
  sfx1:=(xmax[8]-xmin[8])/(sxmax-sxmin);
  sfy1:=(ymax[8]-ymin[8])/(symax-symin);
  for ij:=1 to max_params do
   if s_param_table[ij]^.calc then begin
    col:=s_color[ij];
    Fill_Data_4_FFT(ij,istart,ifinish,nf); {fill Data[1..514,1..4]}
    Real_FFT(ij,nft,-1); {convert complex data to real time function}
    for i:= 1 to 2*nft do begin
      time:=(i-1)*delt;
      if time > sxmax then time := time-2*nft*delt;
      x1:=xmin[8]+Round((time-sxmin)*sfx1);
      if betweenr(symin,data[i,ij],symax,1/sfy1) then begin
        y1:=ymax[8]-Round((data[i,ij]-symin)*sfy1);
        if betweeni(xmin[8],x1,xmax[8]) then 
		PutPixel(x1,Round(hir_temp*y1),col);
      end;
    end; {i}
  end; {ij}
  message[1]:='Type any key';
  message[2]:='to return to the'; 
  message[3]:='frequency domain';
  Write_Message;
  chs := ReadKey;
  if keypressed then chs := ReadKey;
  Erase_Message;
  Draw_Graph(xmin[8],ymin[8],xmax[8],ymax[8],false);
end; {* Time_Response *}


End. 
{Unit implementation}
