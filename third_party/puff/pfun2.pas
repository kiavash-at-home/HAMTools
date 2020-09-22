{$R-}    {Range checking}
{$S-}    {Stack checking on}
{$B-}    {Boolean complete evaluation or short circuit}
{$I+}    {I/O checking on}


Unit pfun2;

(*****************************************************************

	Unit PFUN2

        This code is now licenced under GPLv3.

	Copyright (C) 1991, S.W. Wedge, R.C. Compton, D.B. Rutledge.
        Copyright (C) 1997,1998, A. Gerstlauer.

	Code cleanup for Linux only build 2009 Leland C. Scott.

	Original code released under GPLv3, 2010, Dave Rutledge.

	Contains routines for:
	  * drawing and analyzing parts

******************************************************************)

Interface

Uses
  Dos, 		{Units found in the Free Pascal's RTL's}
  Printer, 	{Unit found in TURBO.TPL}
  xgraph,	{Custom replacement unit for TUBO's "Crt" and "Graph" units}
  pfun1;	{Add other puff units}

procedure snapO;
{*
  Advanced tline and clines routines:
  Function Disperse_f(er1,er2,F_eo : double) : double;
  Procedure ms_dispersion(tcompt : compt);
  Procedure ms_cl_dispersion(tcompt : compt);
  function ms_alpha_c(W_in,Z_0_in,er_e : double) : double;
  function Hammerstad_Z(u : double) : double;
  function ms_alpha_d(ere_in : double) : double;
  procedure super_microstrip(tcompt : compt);
  procedure super_stripline(tcompt : compt);
  procedure super_cl_stripline(tcompt : compt; widthc, spacec : double);
  procedure super_cl_microstrip(tcompt : compt; widthc, spacec : double);
*}
procedure tlineO(tcompt : compt);
procedure qline(tcompt : compt);
procedure clinesO(tcompt : compt);
procedure lumpedO(tcompt : compt);
procedure Transformer(tcompt : compt);
procedure Attenuator(tcompt : compt);
procedure Device_S(tcompt : compt; indef : boolean);
procedure dx_dyO;
function get_lead_charO(tcompt : compt) : char;
procedure Draw_tline(tnet : net; linex,seperate : boolean);
procedure Draw_xformer(tnet : net);
procedure Draw_device(tnet : net);
(* local procedure
 Add_coord(x1,xb,xl,y1 : integer;just : boolean;tdes : line_string);  *)
procedure Set_Up_KeyO;
procedure Update_KeyO_locations;
procedure Set_Up_Board;
procedure Fresh_Dimensions;
procedure draw_groundO(xr,yr : double);
function look_backO : boolean;

{********************************************************************}

Implementation

procedure snapO;
{*
	Move cursor X to nearest node.
*}
var
  distance,distancet : double;
  tnet,pnet 	     : net;
  found     	     : boolean;
  i         	     : integer;

begin
  tnet:=nil;
  found:=false;
  if net_start <> nil then
      if read_kbd then begin
	  distance:=1.0e10;
	  repeat
	    if tnet = nil then tnet:=net_start 
	    		  else tnet:=tnet^.next_net;
	    if tnet^.node then begin
		distancet:=sqrt(sqr(tnet^.xr-xm)+sqr(tnet^.yr-ym));
		if betweenr(0,distancet,distance,-resln/2.0) then begin
			distance:=distancet;
			found:=true;
			pnet:=tnet;
		end;
	    end;
	  until tnet^.next_net=nil;
     end 
     else begin
	  i:=0;
	  repeat
	    if tnet = nil then tnet:=net_start 
	    		  else tnet:=tnet^.next_net;
	    if tnet^.node then begin
		i:=i+1;
		if i=key_list[key_i].noden then begin
			found:=true;
			pnet:=tnet;
		end;
	    end;
	  until (tnet^.next_net=nil) or found;
     end; {else if read_kbd}
  if found then	begin
	cnet:=pnet;
	increment_pos(0);
  end;
end; {snapO}


Function Rough_alpha(alpha_in : double) : double;
{*
	Scale conductor loss alpha to include surface roughness. 
	Surface_roughness is given in micrometers.
*}
Var
   skin_depth,
   angle_arg  : double;

Begin
  if (freq>0.0) and (surface_roughness>0.0) then begin
    skin_depth:=1.0e6/sqrt(Pi*freq*Eng_prefix(freq_prefix)*Mu_0*conductivity);
    angle_arg:=1.4*sqr(surface_roughness/skin_depth);
    Rough_alpha:=alpha_in*(1.0 + 2*arctan(angle_arg)/Pi);
  end
  else
    Rough_alpha:=alpha_in;
end;



Function Disperse_f(er1,er2,F_eo : double) : double;
{*
	Formula used in all dispersion calculations
*}
Begin
  Disperse_f:=er1 - (er1 - er2)/(1.0 + F_eo);
end;


Procedure ms_dispersion(tcompt : compt);
{*
	Calculate effective dielectric constant and Z 
	as a function of frequency for microstrip.

	Makes changes to:
		tcompt^.zed,
		tcompt^.wavelength
	for frequency sweeps.	

	Input values from super_microstrip are:
		tcompt^.zed_e0   := advanced model for zed at f=0
		tcompt^.e_eff_e0 := new ere at f=0
		tcompt^.lngth0   := lngth in mm

	Requires W/h from static calculation, epsilon(0)
	from supermicrostrip calculation, and
	frequency normalized to board thickness.

	Uses M. Kirschning and R.H. Jansen ere model
	from Electronics Letters, vol. 18, pp. 272-273,
	March, 1982. See also H. Atwater and York
	and Compton papers.
	
	Uses Hammerstad and Jensen formula for frequency
	dependence of Z0.

	If freq=0 then make sure values are initialized,
	in case values were changed from a previous sweep.
*}
Var
  u_in,P,P1,P2,
  P3,P4,F4,
  ere0,ere_f	: double;

Begin
  {F4 = f*h in units of GHz-cm (freq normalized to board thickness}
  F4:=substrate_h*freq*Eng_Prefix(freq_prefix)/1.0e+10;

  if (F4 > 25) then begin
    {! Unstable, substitute asymptotic values}
    with tcompt^ do begin   
      zed:=zed_S_e0;
      wavelength:=lngth0*sqrt(er)/lambda_fd; 
    end;
  end
  else if (F4 > 0.0) then begin
    u_in:=tcompt^.width/substrate_h;
    ere0:=tcompt^.e_eff_e0;   {from advanced model super_microstrip}

    P1:=0.27488 + (0.6315+0.525/exp(20*Ln(1.0+0.157*F4)))*u_in
  	      - 0.065683*exp(-8.7513*u_in);
    P2:=0.33622*(1.0 - exp(-0.03442*er));
    P3:=0.0363*exp(-4.6*u_in)*(1.0 - exp(-1.0*exp(4.97*Ln(F4/3.87))));
    P4:=1.0+2.751*(1.0 - exp(-1.0*exp(8*Ln(er/15.916))));
    P:=P1*P2*exp(1.5763*Ln((0.1844+P3*P4)*10*F4));
    ere_f:=Disperse_f(er,ere0,P);
    with tcompt^ do begin   
      zed:=Disperse_f(zed_S_e0,zed_e0,P);
      wavelength:=lngth0*sqrt(ere_f)/lambda_fd; 
    end;
  end
  else begin   {F4=0}
    with tcompt^ do begin   
      zed:=zed_e0;  {reset dc values if a re-sweep w/o parsing}
      wavelength:=lngth0*sqrt(e_eff_e0)/lambda_fd; 
    end;
  end;
 end; {* ms_dispersion *}


Procedure ms_cl_dispersion(tcompt : compt);
{*
	Calculate effective dielectric constant and Z 
	as a function of frequency for microstrip.

	Makes changes to:
		tcompt^.zed,
		tcompt^.zedo,
		tcompt^.wavelength,
		tcompt^.wavelengtho
	for frequency sweeps.	

	Input values from super_cl_microstrip are:
		tcompt^.zed_e0,  (even mode, f=0)
		tcompt^.zed_o0,  (odd mode, f=0)
		tcompt^.zed_S_e0, (eq. stripline value)
		tcompt^.zed_S_o0, (eq. stripline value)
		tcompt^.e_eff_e0, (even mode, f=0)
		tcompt^.e_eff_o0, (odd mode, f=0)
		tcompt^.u_even, (We/h factor)
		tcompt^.u_odd,  (Wo/h factor)
		tcompt^.g_fac  (S/h factor)

	Uses frequency normalized to board thickness.

	Uses M. Kirschning and R.H. Jansen e_eff model
	from MTT-32, Jan. 1984
	
	Uses Bianco formula for frequency dependence of Z0,
	but with the Kirschning and Jansen F factor substituted.

*}
Var
  u,g,P1,P2,P3,P4,
  P5,P6,P7,P8,P9,
  P10,P11,P12,P13,
  P14,P15,f_n,
  F_o_f,F_e_f,
  ere_e_f,ere_o_f		: double;


Begin
  { f_n = f*h in units of GHz-mm (freq normalized to board thickness) }
  f_n:=substrate_h*freq*Eng_Prefix(freq_prefix)/1.0e+9;

  if (f_n > 225) then begin 
    {! Unstable, must substitute asymptotic values for large f_n}
    with tcompt^ do begin   
      zed:=zed_S_e0;
      zedo:=zed_S_o0;
      {lngth0 = lngth in mm}
      wavelength:=lngth0*sqrt(er)/lambda_fd; 
      wavelengtho:=wavelength;
    end;
  end
  else if (f_n > 0.005) then begin      
    {! Numerically unstable and no affect at small f_n}

    {even mode calculation}
    u:=tcompt^.u_even;
    g:=tcompt^.g_fac;
    P1:=0.27488 + (0.6315+0.525/exp(20*Ln(1.0+0.0157*f_n)))*u
  	      - 0.065683*exp(-8.7513*u);
    P2:=0.33622*(1.0 - exp(-0.03442*er));
    P3:=0.0363*exp(-4.6*u)*(1.0 - exp(-1.0*exp(4.97*Ln(f_n/38.7))));
    P4:=1.0+2.751*(1.0 - exp(-1.0*exp(8*Ln(er/15.916))));
    P5:=0.334*exp(-3.3*exp(3*Ln(er/15))) + 0.746;
    P6:=P5*exp(-1.0*exp(0.368*Ln(f_n/18)));
    P7:=1.0 + 4.069*P6*exp(0.479*Ln(g))*
    	exp( -1.347*exp(0.595*Ln(g)) - 0.17*exp(2.5*Ln(g)) );
    F_e_f:=P1*P2*exp(1.5763*Ln(( P3*P4 + 0.1844*P7)*f_n));
    ere_e_f:=Disperse_f(er,tcompt^.e_eff_e0,F_e_f);

    {odd mode calculation - uses P1,P2,P3,P4}
    {P1 and P3 must be recalculated with new u, P2,P4 are OK}
    u:=tcompt^.u_odd;
    P1:=0.27488 + (0.6315+0.525/exp(20*Ln(1.0+0.0157*f_n)))*u
  	      - 0.065683*exp(-8.7513*u);
    P3:=0.0363*exp(-4.6*u)*(1.0 - exp(-1.0*exp(4.97*Ln(f_n/38.7))));
    P8:=0.7168*(1.0+1.076/(1.0+0.0576*(er-1.0)));
    P9:=P8 - 0.7913*(1.0-exp(-1.0*exp(1.424*Ln(f_n/20))))
    	 * arctan(2.481*exp(0.946*Ln(er/8)));
    P10:=0.242*exp(0.55*Ln(er-1.0));
    P11:=0.6366*(exp(-0.3401*f_n)-1.0)*arctan(1.263*exp(1.629*Ln(u/3)));
    P12:=P9 + (1.0-P9)/(1.0 + 1.183*exp(1.376*Ln(u)));
    P13:=1.695*P10/(0.414 + 1.605*P10);
    P14:=0.8928 + 0.1072*(1.0 - exp(-0.42*exp(3.215*Ln(f_n/20))));
    P15:=Abs( 1.0 - 0.8928*(1.0+P11)*P12*exp(-P13*exp(1.092*Ln(g)))/P14 );
    F_o_f:=P1*P2*exp(1.5763*Ln(( P3*P4 + 0.1844)*f_n*P15));
    ere_o_f:=Disperse_f(er,tcompt^.e_eff_o0,F_o_f);

    with tcompt^ do begin   
      zed:=Disperse_f(zed_S_e0,zed_e0,F_e_f);
      zedo:=Disperse_f(zed_S_o0,zed_o0,F_o_f);
      {lngth0 = lngth in mm}
      wavelength:=lngth0*sqrt(ere_e_f)/lambda_fd; 
      wavelengtho:=lngth0*sqrt(ere_o_f)/lambda_fd;
    end;

  end  {f_n > 0.005}
  else begin  {reset dc values in case changed by previous sweep} 
    with tcompt^ do begin   
      zed:=zed_e0;
      zedo:=zed_o0;
      {lngth0 = lngth in mm}
      wavelength:=lngth0*sqrt(e_eff_e0)/lambda_fd; 
      wavelengtho:=lngth0*sqrt(e_eff_o0)/lambda_fd;
    end;
  end; 
end; {* ms_cl_dispersion *}


Function ms_alpha_c(W_in,Z_0_in,er_e : double) : double;
{*
	Computes microstrip alpha due to conductor loss.
	Uses effective width calculations.
	See Gupta, Garg, and Bahl pp 91-92.
	Requires W_in, Z_0_in, er_e.

	W_in is uncorrected (actual) width, Z_0_in is
	previously calculated Z.
	Tested on 2/19/91.
*}
var
  W_over_h,
  We_over_h,
  A_fac,B_fac,
  W_h_ratio	: double;

Begin
  if (metal_thickness > 0.0) then begin
    W_over_h:=W_in/substrate_h;
    {* is W/h < 1/2pi ?*}
    if (W_over_h < 0.1592) then begin
  	B_fac:=2*Pi*W_in;
	We_over_h:=W_over_h+1.25*metal_thickness*
	    (1.0+Ln(4*Pi*W_in/metal_thickness))/(Pi*substrate_h);
    end
    else begin
  	B_fac:=substrate_h;
	We_over_h:=W_over_h+1.25*metal_thickness*
	    (1.0+Ln(2*substrate_h/metal_thickness))/(Pi*substrate_h);
    end;
    A_fac:=1.0+ (1.0 + 1.25*Ln(2*B_fac/metal_thickness)/Pi)/We_over_h;
    if (W_over_h < 1.0) then begin
  	W_h_ratio:=(32.0 - sqr(We_over_h))/(32.0 + sqr(We_over_h));
	W_h_ratio:=W_h_ratio/(2*Pi*Z_0_in);
    end
    else begin
  	W_h_ratio:=0.667*We_over_h/(We_over_h + 1.444) + We_over_h;
	W_h_ratio:=W_h_ratio*Z_0_in*er_e/sqr(120*Pi);
    end; 
    ms_alpha_c:=A_fac*W_h_ratio*Rs_at_fd/substrate_h; {nepers per mm} 
  end
  else 
    ms_alpha_c:=0.0;
end; {* ms_alpha_c *}


function Hammerstad_Z(u : double) : double;
{*
	Calculates Z_o of microstrip using 
	Hammerstad and Jensen model.
	Used by super_microstrip and super_cl_microstrip
	This value must be divided by sqrt(ere) before use.
*}
var
  f : double;
Begin
  f:=6.0 + (2*Pi-6.0)*exp(-1.0*exp(0.7528*Ln(30.666/u)));	
  Hammerstad_Z:=60*Ln( f/u + sqrt(1.0+sqr(2/u)));
end;


Function ms_alpha_d(ere_in : double) : double;
{*
	Used to computer dielectric losses for 
	microstip tlines and clines. 
*}
Var
  er_int : double;

Begin
  if (er <> 1.0) then begin
     er_int:=Pi*er*(ere_in-1.0)/(sqrt(ere_in)*(er-1.0));
     ms_alpha_d:=er_int*loss_tangent*
  	design_freq*Eng_prefix(freq_prefix)/c_in_mm;
  end
  else begin
    ms_alpha_d:=Pi*sqrt(er)*loss_tangent/lambda_fd;   {nepers/mm}
  end;
end; {* ms_alpha_d *}	


procedure super_microstrip(tcompt : compt);
{*
	Re-analyze microstrip parameters using the W/h 
	derived from static calculation.
	Uses Hammerstad and Jensen (1980 MTT-S) models
	for Z0 and e_eff (see Itoh's IEEE book).

	Affects:  tcompt^.zed,  (new value from W/h)
		  tcompt^.e_eff_e0   (e_eff value at f=0)
		  tcompt^.alpha_c,  (value at fd)
		  tcompt^.alpha_d   (value at fd)
		  tcompt^.zed_e0,   (new f=0 value from W/h)
		  tcompt^.wavelength  (new value from lngth0)

*}
Var
  u_in,b,t_n,delta_ul,
  delta_ur,Z_0,e_eff,
  A_fac,b_t_W,ul,ur,Z_0_t	:  double;

	{*********************************}
	function a(u : double) : double;
	Var 
	  a_int : double;
	Begin
	  a_int:=1.0+Ln((exp(4*Ln(u))+sqr(u/52))/(exp(4*Ln(u))+0.432))/49; 
	  a:=a_int+ Ln(1.0+exp(3*Ln(u/18.1)))/18.7;
	end;
	{*********************************}
	function e_e(u : double) : double;
	Begin
	  e_e:=(er+1.0)/2 +((er-1.0)/2)*exp(-1.0*a(u)*b*Ln(1.0+10/u));
	end;
	{*********************************}

Begin
  u_in:=tcompt^.width/substrate_h;
  b:=0.564*exp(0.053*Ln((er-0.9)/(er+3.0)));
  t_n:=metal_thickness/substrate_h;
  if (t_n > 0.0) then begin
  	delta_ul:=(t_n/Pi)*Ln(1.0+ (4*exp(1.0))/
		(t_n*sqr(cosh(sqrt(6.517*u_in))/sinh(sqrt(6.517*u_in))))); 
	delta_ur:=0.5*(1.0+1.0/(cosh(sqrt(er-1.0))))*delta_ul;
 	ul:=u_in+delta_ul;
	ur:=u_in+delta_ur;
  end
  else begin
  	ul:=u_in;
	ur:=u_in;
  end;
  Z_0:=Hammerstad_Z(ur)/sqrt(e_e(ur));
  e_eff:=e_e(ur)*sqr(Hammerstad_Z(ul)/Hammerstad_Z(ur));

  {* For ms_dispersion, compute value for zed_S_e0 from
     equivalent zero thickness stripline with b=2h. 
     Double the value obtained from the formulas with b=2h. 
     Use super_stripline formulas with t=0, b=2*h *}
  b_t_W:=2/u_in;
  A_fac:=Ln(1.0+(4*b_t_W/Pi)*((8*b_t_w/Pi)+sqrt(sqr(8*b_t_w/Pi)+6.27)));
  Z_0_t:=60*A_fac/sqrt(er);

  with tcompt^ do begin
    alpha_c:=ms_alpha_c(tcompt^.width,Z_0,e_eff);   {nepers/mm}
    alpha_d:=ms_alpha_d(e_eff);		  {nepers/mm}
    zed:=Z_0; {replace with new zed}
    zed_e0:=Z_0; {save f=0 value for ms_dispersion}
    zed_S_e0:=Z_0_t;  {save value here for ms_dispersion}
    e_eff_e0:=e_eff; {save for tline and ms_dispersion use}  
    wavelength:=lngth0*sqrt(e_eff)/lambda_fd;  {new length}
    super:=true;
  end;
end; {* super_microstrip *}


procedure super_stripline(tcompt : compt);
{*
	Re-analyze stripline parameters using W/h 
	from static calculation, adding in the effects
	of finite strip thickness. Re-calculates Z0.
	Computes stripline alpha due to conductor loss.
	See Gupta, Garg, and Chadha pp 59-60.

	Affects:  tcompt^.zed,
		  tcompt^.alpha_c,
		  tcompt^.alpha_d

*}
Var
  W,b,x,m,W_prime,
  b_t_W,W_over_b_t,
  delta_W_b_t,A_fac,
  Z_0_t,Q_fac,
  partial_Z_w,log_term		: double;
  
Begin
  if (metal_thickness > 0.0) then begin 
    W:=tcompt^.width;
    b:=substrate_h;
    x:=metal_thickness/b;
    {* Calculation of Z_0 with finite thickness metal *}
    m:=2/(1.0 + 2*x/(3*(1.0-x)));
    delta_W_b_t:=x*(1.0-0.5*Ln( sqr(x/(2.0-x)) + 
  		  exp(m*Ln(0.0796*x/((W/b)+1.1*x))) ) )/(Pi*(1.0-x));
    W_over_b_t:= (W/(b-metal_thickness)) + delta_W_b_t;
    W_prime:=(b-metal_thickness)*W_over_b_t;
    b_t_W:=1/W_over_b_t;
    A_fac:=Ln(1.0+(4*b_t_W/Pi)*((8*b_t_w/Pi)+sqrt(sqr(8*b_t_w/Pi)+6.27)))/Pi;
    Z_0_t:=30*Pi*A_fac/sqrt(er);
 
    {* Calculation of alpha_c *}
    Q_fac:=sqrt( 1.0 + 6.27*sqr(Pi*W_over_b_t/8) );
    partial_Z_w:=30.0*(3.135/Q_fac - (1+Q_fac-0.303/Q_fac)*
    	sqr(8.0/(Pi*W_over_b_t)) )/ (exp(Pi*A_fac)*W_prime) ;  
	{W_prime defines units}
    {! beware of sign errors here!}
    log_term:=1.0+2*W_over_b_t - (3*x/(2.0-x) + Ln(x/(2.0-x)))/Pi;
    with tcompt^ do begin
	alpha_c:=-Rs_at_fd*partial_Z_w*log_term/(120*Pi*Z_0_t);  {nepers/mm}
	zed:=Z_0_t;
    end;
  end; {if t>0}
   
  {Add dielectric losses, despite metal thickness}

  with tcompt^ do begin
    super:=true;
    alpha_d:=Pi*sqrt(er)*loss_tangent/lambda_fd;   {nepers/mm}
  end;

end; {* super_stripline *}


procedure super_cl_stripline(tcompt : compt; widthc, spacec : double);
{*
	Re-analyze coupled stripline parameters using W/h
	and S/h from static calculation, adding in the effects
	of finite strip thickness. Re-calculates Ze and Zo.
	Computes even and odd mode stripline alphas due to 
	conductor and dielectric losses.
	See Gupta, Garg, and Chadha pp 74-75.

	Affects:  tcompt^.zed,
		  tcompt^.zedo,
		  tcompt^.alpha_c,
		  tcompt^.alpha_co,
		  tcompt^.alpha_d,
		  tcompt^.alpha_do,
		  
*}
Var
  W,S,b,t,
  theta_fac,C_f,A_e,A_o,
  Z_oe,Z_oo,C_ff,A_eo,
  Rs_prop,A_c_int,A_co_int	 	: double;
  
Begin
  if (metal_thickness>0.0) then begin
     W:=widthc*substrate_h;  
     S:=spacec*substrate_h;
     b:=substrate_h;
     t:=metal_thickness;
     theta_fac:=Pi*S/(2*b);

     {* Z calculations -- do not function for t=0 *}
     C_f:=2*Ln((2*b-t)/(b-t)) - (t/b)*Ln(t*(2*b-t)/sqr(b-t));
     A_e:=1.0 + Ln(1.0 + sinh(theta_fac)/cosh(theta_fac))/Ln(2);
     A_o:=1.0 + Ln(1.0 + cosh(theta_fac)/sinh(theta_fac))/Ln(2);
     Z_oe:=30*Pi*(b-t)/( sqrt(er)*(W + b*C_f*A_e/(2*Pi)) );
     Z_oo:=30*Pi*(b-t)/( sqrt(er)*(W + b*C_f*A_o/(2*Pi)) );

     {* alpha calculations  :  units are nepers/mm  *}

     C_ff:=Ln((2*b-t)/(b-t)) + 0.5*Ln(t*(2*b-t)/sqr(b-t));
     A_eo:= C_f*(-1.0 + S/b)/(4*Ln(2)*(sinh(theta_fac)+cosh(theta_fac))); 
     Rs_prop:=Rs_at_fd*sqrt(er)/( 3600*sqr(Pi)*(b-t) );
     {break this up to prevent stack overflow}
     A_c_int:=1.0 - (A_e*C_ff/Pi) + (A_eo/cosh(theta_fac)); 
     A_co_int:=1.0 - (A_o*C_ff/Pi) - (A_eo/sinh(theta_fac)); 

     with tcompt^ do begin
     	zed:=Z_oe;
	zedo:=Z_oo;
	alpha_c:=Rs_prop*(60*Pi + Z_oe*sqrt(er)*A_c_int);
	alpha_co:=Rs_prop*(60*Pi + Z_oo*sqrt(er)*A_co_int);
    end; {with}

  end;  {metal_thickness>0}

 {Add dielectric losses, despite metal thickness}
  
  with tcompt^ do begin
     super:=true;
     alpha_d:=Pi*sqrt(er)*loss_tangent/lambda_fd;
     alpha_do:=alpha_d;
  end;

end; {* super_cl_stripline *}


procedure super_cl_microstrip(tcompt : compt; widthc, spacec : double);
{*
	Re-analyze coupled microstrip parameters using W/h
	and S/h from static calculation, adding in the effects
	of finite strip thickness. Re-calculates Ze and Zo.
	Computes even and odd mode stripline alphas due to 
	conductor and dielectric losses.
	
	Equations are found in Kirschning and Jansen (Jan 1984 MTT-32)
	``Accurate wide-range design equations for...coupled microstrip''
	Gupta, Garg, and Bahl pp 337-344, Jansen (Feb 1978 MTT-26),
	Hammerstad and Jensen (1980 MTT-S)

	Affects:  tcompt^.zed,
		  tcompt^.zedo,
		  tcompt^.alpha_c,
		  tcompt^.alpha_co,
		  tcompt^.alpha_d,
		  tcompt^.alpha_do,
		  tcompt^.con_space:=(widthc+spacec)*substrate_h;
		  
*}
Var
  W,S,g,W_over_h,
  B_fac,delta_W,delta_t,
  e_eff0,
  u,a,b,v,
  b_o,c_o,d_o,
  e_effe0,e_effo0,
  Z_L_0,Q1,Q2,Q3,Q4,
  Q5,Q6,Q7,Q8,Q9,Q10,
  Z_Le_0,Z_Lo_0,
  theta_fac,C_f,A_o,A_e,
  Z_oo,Z_oe,K_loss	 	: double;

Begin
  W_over_h:=widthc;   {widthc comes normalized}
  g:=spacec;          {spacec comes normalized}
  S:=spacec*substrate_h;
  W:=widthc*substrate_h;

  {Effective width calculations, Jansen}

  if (metal_thickness>0.0) then begin
    if (W_over_h < 0.1592) then B_fac:=2*Pi*W
  	  		   else B_fac:=substrate_h;
    delta_W:=metal_thickness*(1.0+Ln(2*B_fac/metal_thickness))/Pi;
    delta_t:=metal_thickness/(er*g);
    with tcompt^ do begin
      u_even:=(W+delta_W*(1.0-0.5*exp(-0.69*delta_W/delta_t)))/substrate_h;
      u_odd:=u_even+delta_t/substrate_h;
      g_fac:=g;
    end;
  end
  else begin   {zero thickness}
    with tcompt^ do begin
      u_even:=W_over_h;
      u_odd:=u_even;
      g_fac:=g;
    end;
  end;

  {e_eff0: single microstrip of width W}
  u:=W_over_h;
  a:=1.0+Ln((exp(4*Ln(u))+sqr(u/52))/(exp(4*Ln(u))+0.432))/49; 
  a:=a+Ln(1.0+exp(3*Ln(u/18.1)))/18.7;
  b:=0.564*exp(0.053*Ln((er-0.9)/(er+3.0)));
  e_eff0:=(er+1.0)/2 +((er-1.0)/2)*exp(-a*b*Ln(1.0+10/u));
  
  {e_effe0: even mode f=0, b is still good}
  u:=tcompt^.u_even;
  v:=u*(20.0+sqr(g))/(10.0+sqr(g)) + g*exp(-g);
  a:=1.0 + (Ln((exp(4*Ln(v))+sqr(v/52))/(exp(4*Ln(v))+0.432))/49); 
  a:=a + (Ln(1.0+exp(3*Ln(v/18.1)))/18.7);
  e_effe0:=0.5*(er+1.0) + 0.5*(er-1.0)*exp(-a*b*Ln(1.0+10/v));
  
  {e_effo0: odd mode f=0}
  u:=tcompt^.u_odd;
  d_o:=0.593+0.694*exp(-0.562*u);
  b_o:=0.747*er/(0.15+er);
  c_o:=b_o-(b_o-0.207)*exp(-0.414*u);
  a:=0.7287*(e_eff0-0.5*(er+1.0))*(1.0 - exp(-0.179*u));
  e_effo0:=(0.5*(er+1.0)+a-e_eff0)*exp(-c_o*exp(d_o*Ln(g)))+e_eff0;

  {Z_Le_0: even mode impedance at f=0}
  u:=tcompt^.u_even;
  Z_L_0:=Hammerstad_Z(u)/sqrt(e_eff0);  
  Q1:=0.8695*exp(0.194*Ln(u));
  Q2:=1.0 + (0.7519*g) + (0.189*exp(2.31*Ln(g))) ;
  Q3:=0.1975 + exp(-0.387*Ln(16.6 + exp(6*Ln(8.4/g))));
  Q3:=Q3 + ( Ln( exp(10*Ln(g))/(1.0+exp(10*Ln(g/3.4))))/241 );
  Q4:=(2*Q1/Q2)*1/( exp(-g)*exp(Q3*Ln(u)) + (2.0-exp(-g))*exp(-Q3*Ln(u)));
  Z_Le_0:=Z_L_0*sqrt(e_eff0/e_effe0)/(1.0-(Z_L_0/(120*Pi))*sqrt(e_eff0)*Q4);

  {Z_Lo_0: odd mode impedance at f=0}
  u:=tcompt^.u_odd;
  Z_L_0:=Hammerstad_Z(u)/sqrt(e_eff0);  
  Q5:=1.794+1.14*Ln(1.0 + 0.638/(g + 0.517*exp(2.43*Ln(g))));
  Q6:=0.2305 + Ln(exp(10*Ln(g))/(1.0 + exp(10*Ln(g/5.8))))/281.3
  	     + Ln(1.0 + 0.598*exp(1.154*Ln(g)))/5.1;
  Q7:=(10.0 + 190*sqr(g))/(1.0 + 82.3*exp(3*Ln(g)));
  Q8:=-6.5 - 0.95*Ln(g) - exp(5*Ln(g/0.15));
  if (Q8<-50) then Q8:=0
  	      else Q8:=exp(Q8);
  Q9:=Ln(Q7)*(Q8 + 1/16.5);
  Q10:=(Q2*Q4 - Q5*exp( Ln(u)*Q6*exp(-Q9*Ln(u))))/Q2;
  Z_Lo_0:=Z_L_0*sqrt(e_eff0/e_effo0)/(1.0-(Z_L_0/(120*Pi))*sqrt(e_eff0)*Q10);

  {* Compute values for zed_S_e0 and zed_S_o0 from
     equivalent zero thickness stripline with b=2h. 
     Double the values obtained from the formulas with b=2h. 
     Use super_cl_stripline formulas with t=0, b=2*h *}
  b:=2*substrate_h;
  theta_fac:=Pi*S/(2*b);
  C_f:=2*Ln(2);
  A_e:=1.0 + Ln(1.0 + sinh(theta_fac)/cosh(theta_fac))/Ln(2);
  A_o:=1.0 + Ln(1.0 + cosh(theta_fac)/sinh(theta_fac))/Ln(2);
  Z_oe:=60*Pi*b/( sqrt(er)*(W + b*C_f*A_e/(2*Pi)) );
  Z_oo:=60*Pi*b/( sqrt(er)*(W + b*C_f*A_o/(2*Pi)) );

  {Conductor loss from simple Hammerstad and Jensen formulas}
  {Dielectric loss from Ramo Rao and Gupta)}
  K_loss:=exp(-1.2*exp(0.7*Ln(
  	( Z_Lo_0 + Z_Le_0 )/(240*Pi))));

  with tcompt^ do begin
    alpha_c:=Rs_at_fd*K_loss/(Z_Le_0*u_even*substrate_h);
    alpha_co:=Rs_at_fd*K_loss/(Z_Lo_0*u_odd*substrate_h);
    alpha_d:=ms_alpha_d(e_effe0);
    alpha_do:=ms_alpha_d(e_effo0);
    zed:=Z_Le_0;
    zed_e0:=Z_Le_0;
    zedo:=Z_Lo_0;
    zed_o0:=Z_Lo_0;
    zed_S_e0:=Z_oe;
    zed_S_o0:=Z_oo;
    e_eff_e0:=e_effe0;
    e_eff_o0:=e_effo0;
    super:=true;
  end;
end; {* super_cl_microstrip *}


procedure tlineO(tcompt : compt);
{*
	If action is true then get tline parameters.
	If action is false calculate tline s-parameters.

	Example tcompt^.descript := 'a tline 50'#139' 90'#140
					       ohms   degrees
*}
var
  i,j   	: integer;
  c_ss  	: array[1..2] of array[1..2] of PMemComplex;
  rds           : TComplex;
  unit1,prefix  : char;
  Manhat_on,alt_param	  : boolean;
  zd,ere,value,
  alpha_tl,beta_l,
  elength,gamma {,sh,ch}     : double;   {were extended intermediate results}
  value_str 		  : line_string;
  sh,ch		: Tcomplex;

begin
 if action then begin
  with tcompt^ do begin
    alpha_c:=0.0;
    alpha_d:=0.0;
    alpha_co:=0.0;
    alpha_do:=0.0; {default attenuation factors nepers/mm}
    super:=false;  {initialize}
    Manhat_on:=Manhattan(tcompt);  {* an 'M' at the end of ^.descript? *}
    if (Pos('?',descript)>0) and super_line(tcompt) then begin
         bad_compt:=true;
         message[1]:='Combined';
         message[2]:='? and !';
         message[3]:='disallowed';
         exit;
    end;
    Get_Param(tcompt,1,value,value_str,unit1,prefix,alt_param);
    {value_str not used here}
    if bad_compt then exit;
    if alt_param then x_sweep.init_element(tcompt,'z',prefix,unit1);
    if bad_compt then exit;
    case unit1 of
      Omega   : zed:=value;
      's','S' : zed:=1.0/value;
      'z','Z' : zed:=z0*value;
      'y','Y' : zed:=z0/value;
       else begin
         bad_compt:=true;
         message[1]:='Invalid tline';
         message[2]:='impedance unit';
         message[3]:='Use y, z, S or '+Omega;
         exit;
       end; {else}
    end;{case}
    if not(Manhat_on) and (zed<=0.0) then begin {OK if alt_param}
         bad_compt:=true;
         message[1]:='Negative';
	 message[2]:='or zero tline';
         message[2]:='impedance';
         exit;
    end;
    {Get_Param will return 1.0 for zed if alt_param and no number given}
    if (alt_param and (value_str='1.0')) or (zed<=0.0) then
    		width:=widthZ0
    	   else
	   	width:=widtht(zed);
    {width is always needed for ere calculation}
    if bad_compt then exit;
    if not(Manhat_on) then begin
      if width < resln then begin
      	bad_compt:=true;
	message[1]:='Impedance too big';
	message[2]:='tline too narrow';
	message[3]:='(<'+sresln+')';
	exit;
      end;
      if width > bmax then begin
      	bad_compt:=true;
	message[1]:='Impedance is';
	message[2]:='too small:';
	message[3]:='tline too wide';
	exit;
      end;
    end; {not Manhat_on}
    if super_line(tcompt) and ((width/substrate_h)<0.0001) then begin
      	bad_compt:=true;
	message[1]:='Impedance out of';
	message[2]:=' range for';
	message[3]:='tline! model';
	exit;
    end;
    if stripline then   {ere calculation is a function of width!}
    	   ere:=er
	else
	   ere:=(er+1)/2 + (er-1)/2/sqrt(1+10*substrate_h/width);
    Get_Param(tcompt,2,value,value_str,unit1,prefix,alt_param);
    {value_str not used here}
    if bad_compt then exit;
    if alt_param then x_sweep.init_element(tcompt,'l',prefix,unit1);
    if bad_compt then exit;
    case unit1 of
      degree : begin
                 wavelength:=value/360.0;
                 lngth:=lambda_fd*wavelength/sqrt(ere);
               end;
      'm'    : begin
                 lngth:=value; {mmlong}
                 wavelength:=lngth*sqrt(ere)/lambda_fd;
		 if alt_param then
		     x_sweep.Load_Prop_Const(sqrt(ere)/lambda_fd,0.0);
               end;
      'h','H': begin
                 lngth:=value*substrate_h;
                 wavelength:=lngth*sqrt(ere)/lambda_fd;
		 if alt_param then
		 x_sweep.Load_Prop_Const(substrate_h*sqrt(ere)/lambda_fd,0.0);
               end;
        else begin
          bad_compt:=true;
          message[1]:='Invalid tline';
          message[2]:='length unit';
          message[3]:='Use mm, h or '+Degree;
          exit;
        end;
      end;{case}
      lngth0:=lngth;   {save lngth factor in mm}
      {* Enable lossy and dispersive line (super_line) here *}
      if super_line(tcompt) then begin
	if stripline then
	  super_stripline(tcompt)
	else begin
	  super_microstrip(tcompt);
	end;
      end;
      if Manhat_on then begin
      	 width:=Manh_width;
	 lngth:=Manh_length;
      end  {Artwork correction and Manh_width after ere calculation}
      else
      	 width:=width+artwork_cor;
      {* Check here for artwork length corrections *}
      j:=goto_numeral(3,tcompt^.descript);
      if bad_compt then erase_message; {ignore lack of correction}
      bad_compt:=false;
      if (j > 0) and not(Manhat_on) then begin
        Get_Param(tcompt,3,value,value_str,unit1,prefix,alt_param);
	{value_str and prefix not used here}
	if alt_param then bad_compt:=true;
	if bad_compt then exit;
        case unit1 of  { Add or subtract line for artwork }
          Degree : lngth:=lngth+lambda_fd*(value/360.0)/sqrt(ere);
          'h','H': lngth:=lngth+value*substrate_h;
          'm'    : lngth:=lngth+value;
	    else begin
		bad_compt:=true;
		message[1]:='Improper units';
		message[2]:='used in length';
		message[3]:=' correction   ';
		exit;
		end;
        end; {case unit1}
      end; {if j > 0}
      if lngth > bmax then begin
        bad_compt:=true;
        message[1]:='tline is longer';
        message[2]:='than board size';
        exit;
      end;
      if lngth < resln then begin
        bad_compt:=true;
        message[1]:='tline too short';
        message[2]:='Length must be';
        message[3]:='>'+sresln;
        exit;
      end;
      con_space:=0.0;
      number_of_con:=2;
    end; {with tcompt^ do}
  end        {if action}
  else begin {if no action}

    { Calculate scattering parameters }

    {Normalized frequency}
    gamma:=freq/design_freq;

    {Re-compute Zo and wavelength when dispersive microstrip}
    if tcompt^.super and not(stripline) then ms_dispersion(tcompt);

    elength:=2*pi*tcompt^.wavelength;

    {! Beware of problems here with trig operations}
(*******Real gamma routines
    sh := Sin(elength*gamma);   {! was Sin_asm }
    ch := Cos(elength*gamma);   {! was Cos_asm }
    zd:=tcompt^.zed/z0;
    rds := rc(co(2*zd*ch,(sqr(zd)+1.0)*sh));
    new(u);
    c_ss[1,1]:=prp(u,co(0.0,(sqr(zd)-1.0)*sh),rds);
    c_ss[2,2]:=co(c_ss[1,1]^.r,c_ss[1,1]^.i);
    c_ss[1,2]:=sm(2*zd,rds);
    c_ss[2,1]:=co(c_ss[1,2]^.r,c_ss[1,2]^.i);
******)

(*******Complex gamma routines**************)
    alpha_tl:=( tcompt^.alpha_d*gamma +
    	       Rough_alpha(tcompt^.alpha_c)*sqrt(gamma) )*tcompt^.lngth0;
    beta_l:=elength*gamma;
    sh.r := sinh(alpha_tl)*cos(beta_l);
    sh.i := cosh(alpha_tl)*sin(beta_l);
    ch.r := cosh(alpha_tl)*cos(beta_l);
    ch.i := sinh(alpha_tl)*sin(beta_l);
    zd:=tcompt^.zed/z0;
    for j:= 1 to 2 do
      for i:= 1 to 2 do
        New_c (c_ss[i,j]);

    co(c_ss[2,1]^.c,2*zd*ch.r+(sqr(zd)+1.0)*sh.r,
    	            2*zd*ch.i+(sqr(zd)+1.0)*sh.i);
    rc(rds,c_ss[2,1]^.c);
    co(c_ss[2,1]^.c,(sqr(zd)-1.0)*sh.r,(sqr(zd)-1.0)*sh.i);
    prp(c_ss[1,1]^.c,c_ss[2,1]^.c,rds);
    co(c_ss[2,2]^.c,c_ss[1,1]^.c.r,c_ss[1,1]^.c.i);
    sm(c_ss[1,2]^.c,2*zd,rds);
    co(c_ss[2,1]^.c,c_ss[1,2]^.c.r,c_ss[1,2]^.c.i);
(************************************************)
    c_s:=nil;
    for j:=1 to 2 do
    for i:=1 to 2 do begin
      if c_s=nil then begin
        new_s(tcompt^.s_begin);
        c_s:=tcompt^.s_begin;
      end
      else begin
        new_s(c_s^.next_s);
        c_s:=c_s^.next_s;
      end;
      c_s^.next_s:=nil;
      c_s^.z:=c_ss[i,j];
   end; {i}
  end; {action}
end; {* tlineO *}


procedure qline(tcompt : compt);
{*
	If action is true then get qline parameters.
	If action is false calculate qline s-parameters.

	Example tcompt^.descript := 'a qline 50'#139' 90'#140' 100Qc'
					       ohms   degrees  Qfactor
*}
var
  i,j,des_lngth : integer;
  rds   	: Tcomplex;
  c_ss    	: array[1..2] of array[1..2] of PMemComplex;
  unit1,prefix 		  : char;
  Manhat_on,alt_param	  : boolean;
  zd,ere,value,
  alpha_tl,beta_l,
  elength,gamma {,sh,ch}     : double;   {were extended intermediate results}
  value_str 		  : line_string;
  sh,ch		: Tcomplex;

begin
 if action then begin
  with tcompt^ do begin
    alpha_c:=0.0;
    alpha_d:=0.0;
    alpha_co:=0.0;
    alpha_do:=0.0; {default attenuation factors nepers/mm}
    super:=false;  {initialize}
    Manhat_on:=Manhattan(tcompt);  {* an 'M' at the end of ^.descript? *}
    if (Pos('!',descript)>0) then begin
         bad_compt:=true;
         message[1]:='qline! is';
         message[2]:='an invalid';
         message[3]:='part';
         exit;
    end;
    Get_Param(tcompt,1,value,value_str,unit1,prefix,alt_param);
    {value_str not used here}
    if bad_compt then exit;
    if alt_param then x_sweep.init_element(tcompt,'z',prefix,unit1);
    if bad_compt then exit;
    case unit1 of
      Omega   : zed:=value;
      's','S' : zed:=1.0/value;
      'z','Z' : zed:=z0*value;
      'y','Y' : zed:=z0/value;
       else begin
         bad_compt:=true;
         message[1]:='Invalid qline';
         message[2]:='impedance unit';
         message[3]:='Use y, z, S or '+Omega;
         exit;
       end; {else}
    end;{case}
    if not(Manhat_on) and (zed<=0.0) then begin {OK if alt_param}
         bad_compt:=true;
         message[1]:='Negative';
	 message[2]:='or zero qline';
         message[2]:='impedance';
         exit;
    end;
    {Get_Param will return 1.0 for zed if alt_param and no number given}
    if (alt_param and (value_str='1.0')) or (zed<=0.0) then 
    		width:=widthZ0
    	   else 
	   	width:=widtht(zed);
    {width is always needed for ere calculation}
    if bad_compt then exit;
    if not(Manhat_on) then begin
      if width < resln then begin
      	bad_compt:=true;
	message[1]:='Impedance too big';
	message[2]:='qline too narrow';
	message[3]:='(<'+sresln+')';
	exit;
      end;
      if width > bmax then begin
      	bad_compt:=true;
	message[1]:='Impedance is';
	message[2]:='too small:';
	message[3]:='qline too wide';
	exit;
      end;
    end; {not Manhat_on}
    if stripline then   {ere calculation is a function of width!}
    	   ere:=er
	else
	   ere:=(er+1)/2 + (er-1)/2/sqrt(1+10*substrate_h/width);
    Get_Param(tcompt,2,value,value_str,unit1,prefix,alt_param);
    {value_str not used here}
    if bad_compt then exit;
    if alt_param then x_sweep.init_element(tcompt,'l',prefix,unit1);
    if bad_compt then exit;
    case unit1 of
      degree : begin
                 wavelength:=value/360.0;
                 lngth:=lambda_fd*wavelength/sqrt(ere);
               end;
      'm'    : begin
                 lngth:=value; {mmlong}
                 wavelength:=lngth*sqrt(ere)/lambda_fd;
		 if alt_param then 
		     x_sweep.Load_Prop_Const(sqrt(ere)/lambda_fd,0.0);
               end;
      'h','H': begin
                 lngth:=value*substrate_h;
                 wavelength:=lngth*sqrt(ere)/lambda_fd;
		 if alt_param then
		 x_sweep.Load_Prop_Const(substrate_h*sqrt(ere)/lambda_fd,0.0);
               end;
        else begin
          bad_compt:=true;
          message[1]:='Invalid qline';
          message[2]:='length unit';
          message[3]:='Use mm, h or '+Degree;
          exit;
        end;
      end; {case}
      lngth0:=lngth;   {save lngth factor in mm}
      if Manhat_on then begin
      	 width:=Manh_width;
	 lngth:=Manh_length;
      end  {Artwork correction and Manh_width after ere calculation} 
      else   
      	 width:=width+artwork_cor;	   
    {* Check for Q factor *}
    j:=goto_numeral(3,tcompt^.descript);
    if bad_compt then erase_message;  {ignore lack of Q}
    bad_compt:=false;
    if (j > 0) then begin  {get Q value}
        Get_Param(tcompt,3,value,value_str,unit1,prefix,alt_param);
	{value_str, prefix not used here, unit1 should be 'Q'}
	if alt_param then x_sweep.init_element(tcompt,'Q',prefix,'Q');
	if bad_compt then exit;
	if (unit1 in [degree,'m','h','H']) then begin
          bad_compt:=true;
          message[1]:='Corrections';
          message[2]:='not allowed for';
	  message[3]:='qline length';
          exit;
	end;
	if (value=0.0) or not(unit1 in ['q','Q']) then begin
          bad_compt:=true;
          message[1]:='Invalid or zero';
          message[2]:='Q factor';
          exit;
	end;
	des_lngth:=length(descript);
	Repeat 
	      Inc(j)   {Find location of 'Q'}
	Until (descript[j]=unit1) or (j>des_lngth);
	Repeat        {Skip spaces to}
	     Inc(j);  {find 'd' or 'c' after Q}
	Until (descript[j]<>' ') or (j>des_lngth);
	if (lngth0<>0.0) then begin
	  alpha_co:=(Pi*wavelength)/(value*lngth0);
	  if (j<=des_lngth) and (descript[j] in ['C','c']) then 
	  	 alpha_c:=alpha_co
	     else   	{default to dielectric loss}
		 alpha_d:=alpha_co;
	  alpha_co:=0.0; {reset to 0}
        end;	 
     end;  {if j > 0}
     con_space:=0.0;
     number_of_con:=2;
   end; {with tcompt^ do}
  end   
  else begin {if no action}

    { Calculate scattering parameters }
    {Normalized frequency}
    gamma:=freq/design_freq;
    elength:=2*pi*tcompt^.wavelength;


    alpha_tl:=( tcompt^.alpha_d*gamma +
    	        tcompt^.alpha_c*sqrt(gamma) )*tcompt^.lngth0;
    {! Warning, these alphas get huge for small Q's}
    if (alpha_tl > 80.0) then alpha_tl:=80;
    beta_l:=elength*gamma;
    sh.r := sinh(alpha_tl)*cos(beta_l);
    sh.i := cosh(alpha_tl)*sin(beta_l);
    ch.r := cosh(alpha_tl)*cos(beta_l);
    ch.i := sinh(alpha_tl)*sin(beta_l);
    zd:=tcompt^.zed/z0;
    for i:= 1 to 2 do
      for j:= 1 to 2 do
        New_c (c_ss[i,j]);

    co(c_ss[1,1]^.c,2*zd*ch.r+(sqr(zd)+1.0)*sh.r,
    	         2*zd*ch.i+(sqr(zd)+1.0)*sh.i);
    rc(rds,c_ss[1,1]^.c);
    co(c_ss[2,1]^.c,(sqr(zd)-1.0)*sh.r,(sqr(zd)-1.0)*sh.i);
    prp(c_ss[1,1]^.c,c_ss[2,1]^.c,rds);
    co(c_ss[2,2]^.c,c_ss[1,1]^.c.r,c_ss[1,1]^.c.i);
    sm(c_ss[1,2]^.c,2*zd,rds);
    co(c_ss[2,1]^.c,c_ss[1,2]^.c.r,c_ss[1,2]^.c.i);
    c_s:=nil;
    for j:=1 to 2 do
    for i:=1 to 2 do begin
      if c_s=nil then begin
        new_s(tcompt^.s_begin);
        c_s:=tcompt^.s_begin;
      end
      else begin
        new_s(c_s^.next_s);
        c_s:=c_s^.next_s;
      end;
      c_s^.next_s:=nil;
      c_s^.z:=c_ss[i,j];
   end; {i}
  end; {action}
end; {* qline *}


Procedure clinesO(tcompt : compt);
{*
	Cline equivalent of tline.

	example tcompt^.descript := 'f clines 60'#139' 40'#139' 90'#140
					         ohms     ohms	  degrees
*}
var
  i,j,mi,mj,z_index 	: integer;
  rds     		: Tcomplex;
  c_s       		: s_param;
  unit1,prefix 		: char;
  seo       	: array[1..2] of array[1..2] of array[1..2] of TComplex;
  wide,wido,zd,elength,
  gamma,widthc,spacec,
  alpha_tl,beta_l, {sh,ch,}
  value,zt,ere,eree,ereo	: double;
  sh,ch				: Tcomplex;
  check_correction_three,
  Manhat_on,alt_param		: boolean;
  value_str			: line_string;

begin
  if action then begin
    with tcompt^ do begin
      Manhat_on:=Manhattan(tcompt);  {* an 'M' at the end of ^.descript? *}
      if bad_compt then exit;
      if (Pos('?',descript)>0) and super_line(tcompt) then begin
         bad_compt:=true;
         message[1]:='Combined';
         message[2]:='? and !';
         message[3]:='disallowed';
         exit;
      end;
      alpha_c:=0.0; 
      alpha_d:=0.0;
      alpha_co:=0.0; 
      alpha_do:=0.0; {default attenuation factors nepers/mm}
      super:=false;
      number_of_con:=4;   
      z_index:=0;
      zed:=0; 
      zedo:=0; 
      wavelength:=0; 
      lngth:=0;
      check_correction_three:=false;
      for i:=1 to 3 do
        if (lngth=0) and (wavelength=0) then begin
         j:=goto_numeral(i,tcompt^.descript);
	 bad_compt:=false;
         if (j > 0) or (i < 3) then begin           
           Get_Param(tcompt,i,value,value_str,unit1,prefix,alt_param);
	   {value_str and prefix not used here}
	   if bad_compt then exit;
	   if alt_param then begin {init sweep object}
	      if unit1 in [omega,'s','S','z','Z','y','Y'] then begin
	         if zed=0 then begin
	   	    x_sweep.init_element(tcompt,'z',prefix,unit1);
		    z_index:=1;	{variable is the 1st z}
		 end	
		 else begin 
	   	    x_sweep.init_element(tcompt,'z',prefix,unit1);
		    z_index:=2;	{variable is the 2nd z} 
		 end;	
	      end
	      else if (unit1 in [degree,'m','h','H']) then begin
	      	 {if length units}
 	         x_sweep.init_element(tcompt,'l',prefix,unit1);
		 z_index:=5;	{variable is length}
	      end;	 	
	   end; {if alt_param}
           if bad_compt then exit;
	   {Read in first impedance as zed, second as zedo}
           case unit1 of
            omega   : if zed=0 then zed:=value 
	    		       else zedo:=value;
            's','S' : if zed=0 then zed:=1.0/value 
	    		       else zedo:=1.0/value;
            'z','Z' : if zed=0 then zed:=z0*value 
	    		       else zedo:=z0*value;
            'y','Y' : if zed=0 then zed:=z0/value 
	    		       else zedo:=z0/value;
             degree : wavelength:=value/360.0;
            'm'     : begin
	    		lngth:=value; {mmlong}
			if z_index=5 then z_index:=6; {var in meters}
		      end;
            'h','H' : begin
	    		lngth:=value*substrate_h; {mmlong}
			if z_index=5 then z_index:=7; {var in h}
		      end;	
             else begin
               bad_compt:=true;
               message[1]:='Missing clines';
               message[2]:='unit. Use y, z';
               message[3]:='S, '+Omega+', mm, h or '+Degree;
               exit;
             end;
          end; {case}
        end; {(j > 0) or (i < 3)}
        if (i=2) and ((wavelength <> 0) or (lngth <> 0)) then
      		check_correction_three:=true;
                {* Set flag if 3rd term (i=3) in tcompt^.descript
      		is a possible length correction *}
      end; {for i=1 to 3}
      if not(check_correction_three) then i:=4; 
      if (zed = 0) and (zedo = 0) then begin
        bad_compt:=true;
        message[1]:='Both cline even';
        message[2]:='& odd impedances';
        message[3]:='not found or zero';
        exit;
      end
      else begin
        { if zed=0 then zed:=sqr(Z0)/zedo; }
        if zedo=0 then zedo:=sqr(Z0)/zed  {calculate zedo if blank}
	  else if (z_index=1) then z_index:=3  {both given, even is var}
	  else if (z_index=2) then z_index:=4; {both given, odd is var}
      end;
      if zed < zedo then begin {swap even and odd impedances}
      	zt:=zed; 
	zed:=zedo; 
	zedo:=zt; 
        Case z_index of 
	  1 : z_index:=2; {single given, odd mode is variable} 
	  2 : z_index:=1; {single given, even mode is variable}
	  3 : z_index:=4; {both given, odd mode is variable}
	  4 : z_index:=3; {both given, even mode is variable} 
	end; {case}
      end;
      if (zed <= 0) or (zedo <= 0) then begin
        bad_compt:=true;
        message[1]:='cline';
        message[2]:='impedances must';
        message[3]:='be positive';
        exit;
      end;
      {Load index's 1..4 for alt parameter sweep}
      if ((z_index<>0) and (z_index<5)) then x_sweep.Load_Index(z_index);
      {* All dimensions must be calculated, even for Manhattan,
         to guarantee that electrical lengths are the same be it
	 regular or Manhattan *}
      if zed*0.97 < zedo then begin  {!* this factor was 0.98 in 1.0 *}
        bad_compt:=true;     {!* changed to avoid w_s_micro errors*}
	message[1]:='cline even & odd';
	message[2]:='impedances are';
	message[3]:='too close';
	exit;
      end;
      if not(bad_compt) then begin
          if stripline then 
	    	w_s_stripline_cline(zed,zedo,widthc,spacec)
             else begin
	     	wide:=widtht(zed /2.0)/substrate_h;
		wido:=widtht(zedo/2.0)/substrate_h;
		if bad_compt then exit;
		w_s_microstrip_cline(wide,wido,widthc,spacec);
	  end;
          if not(bad_compt) then begin
          	width:=widthc*substrate_h + artwork_cor;
		{! * Artwork correction added here ^ *}
		con_space:=(widthc+spacec)*substrate_h;
		if (con_space < resln) and not(Manhat_on) then begin
			bad_compt:=true;
			message[1]:='clines spacing is';
			message[2]:='<'+sresln;
			message[3]:=Omega+'e/'+Omega+'o is too big';
			exit;
		end;
		if (width < resln) and not(Manhat_on) then begin
			bad_compt:=true;
			message[1]:='Even impedance is';
			message[2]:='too large. Width';
			message[3]:='<'+sresln;
			exit;
		end;
		if stripline then begin
                  	ereo:=er;  
			eree:=er;  
			ere:=er;
		end 
                else begin
		     	ere_even_odd(widthc,spacec,eree,ereo);
			ere:=4*eree*ereo/sqr(sqrt(eree)+sqrt(ereo));
		end;
		if (lngth=0) and (wavelength=0) then begin
		    bad_compt:=true;
		    message[1]:='Missing cline';
		    message[2]:='length. Supply';
		    message[3]:='length in mm or '+Degree;
		    exit;
		end
	        else begin
		    if lngth=0 then lngth:=lambda_fd*wavelength/sqrt(ere);
		    wavelength :=lngth*sqrt(eree)/lambda_fd;
		    wavelengtho:=lngth*sqrt(ereo)/lambda_fd;
		    lngth0:=lngth; {used in cl_dispersion}
		    Case z_index of
		    	5 : x_sweep.Load_Prop_Const(sqrt(eree)/sqrt(ere),
						    sqrt(ereo)/sqrt(ere));
			6 : x_sweep.Load_Prop_Const(sqrt(eree)/lambda_fd,
						    sqrt(ereo)/lambda_fd);
			7 : x_sweep.Load_Prop_Const(
			        substrate_h*sqrt(eree)/lambda_fd,
			   	substrate_h*sqrt(ereo)/lambda_fd);
		    end; {case}
		    j:=goto_numeral(i,tcompt^.descript);
		    if bad_compt then erase_message; {ignore corrections}
		    bad_compt:=false;
		    {* Invoke advanced models *}
		    if super_line(tcompt) then
		            if stripline then
			    	super_cl_stripline(tcompt,widthc,spacec)
			    else
			    	super_cl_microstrip(tcompt,widthc,spacec);
		    {* Check for and if needed add length corrections *}
		    if j > 0 then begin           
			Get_Param(tcompt,i,value,value_str,
			    		unit1,prefix,alt_param);
			    {value_str and prefix not used here}
			if bad_compt then exit;
			case unit1 of
			    Degree : lngth:=lngth+lambda_fd*
			    	(value/360.0)/sqrt(ere);
			    'h','H': lngth:=lngth+value*substrate_h;
			    'm'    : lngth:=lngth+value;
			    else begin
				bad_compt:=true;
				message[1]:='Improper units';
				message[2]:='used in length';
				message[3]:=' correction   ';
				exit;
			    end;
			 end;{case}
		    end; {if j > 0} 
		end; {else lngth=wavelength=0}
		if (lngth<0) and not(Manhat_on) then begin
		    bad_compt:=true;
		    message[1]:='Negative';
		    message[2]:='cline length';
		    exit;
		end; 
             end; {if not_bad}
        end; {if not_bad}
	if bad_compt and (z_index>0) then begin 
	  message[1]:='Add or alter';
	  message[2]:='best-guess';
	  message[3]:='values';
	end;
	if Manhat_on then begin   {* if Manhatton then fix dimensions *}
	  width:=Manh_width;
	  con_space:=Manh_length;
	  lngth:=Manh_length;
	end;  {* if Manhatton *}
      end; {with}
    end {if action true}
 else begin { if no action then compute s-parameters}
    gamma:=freq/design_freq; {normalized}
    {Re-compute Zo and wavelength when dispersive microstrip} 
    if tcompt^.super and not(stripline) then ms_cl_dispersion(tcompt); 
    for i:=1 to 2 do begin
      if i=1 then begin
         zd:=tcompt^.zed/z0; 
         elength:=2*pi*tcompt^.wavelength;
	 alpha_tl:=(tcompt^.alpha_d*gamma + 
	 	Rough_alpha(tcompt^.alpha_c)*sqrt(gamma) )*tcompt^.lngth0;
      end
      else begin
         zd:=tcompt^.zedo/z0;
         elength:=2*pi*tcompt^.wavelengtho;
	 alpha_tl:=(tcompt^.alpha_do*gamma +
	 	Rough_alpha(tcompt^.alpha_co)*sqrt(gamma) )*tcompt^.lngth0;
      end;

      beta_l:=elength*gamma;
      sh.r := sinh(alpha_tl)*cos(beta_l);
      sh.i := cosh(alpha_tl)*sin(beta_l);
      ch.r := cosh(alpha_tl)*cos(beta_l);
      ch.i := sinh(alpha_tl)*sin(beta_l);

      co(seo[i,1,1],2*zd*ch.r+(sqr(zd)+1.0)*sh.r,
    	            2*zd*ch.i+(sqr(zd)+1.0)*sh.i);
      rc(rds,seo[i,1,1]);
      co(seo[i,1,2],0.5*(sqr(zd)-1.0)*sh.r,
      			   0.5*(sqr(zd)-1.0)*sh.i);
      prp(seo[i,1,1],seo[i,1,2],rds);
      sm(seo[i,1,2],zd,rds);
      seo[i,2,2]:=seo[i,1,1];
      seo[i,2,1]:=seo[i,1,2];
    end;{for i}
    c_s:=nil;
    for j:=1 to 4 do begin
    	if j>2 then mj:=j-2
	       else mj:=j;
        for i:=1 to 4 do begin
          if c_s=nil then begin
             new_s(tcompt^.s_begin);
             c_s:=tcompt^.s_begin;
          end
	  else begin
	     new_s(c_s^.next_s);
             c_s:=c_s^.next_s;
          end;
          c_s^.next_s:=nil;
          New_c (c_s^.z);
          if i>2 then mi:=i-2 else mi:=i;
          if (i>2) xor (j>2) then di(c_s^.z^.c,seo[1,mi,mj],seo[2,mi,mj])
                             else su(c_s^.z^.c,seo[1,mi,mj],seo[2,mi,mj]);
      end; {i}
    end; {j}
  end; {action}
end; {clinesO}


procedure lumpedO(tcompt : compt);
{*
	Lumped equivalent of tline.
*}
var
  value					: array [1..4] of double;
  ff,zi 				: double;
  zo2,yb2,s11,s21 			: Tcomplex;
  i,j   				: integer;
  unit1,ident,prefix			: char;
  alt_param,parallel_cir		: boolean;

begin
  if action then begin
    with tcompt^ do begin
      number_of_con:=2;
      con_space:=0.0;
      Get_Lumped_Params(tcompt,value[1],value[2],value[3],value[4],
      			unit1,ident,prefix,alt_param,parallel_cir);
      if bad_compt then exit;
      if alt_param then begin 
        {* Find the alt param -- allow only one *}
	j:=0; {number of non-zero values}
	for i:=1 to 3 do if (value[i]<>0) then Inc(j);
	if (j<>1) then begin
           bad_compt:=true;
           message[1]:='One parameter';
           message[2]:='only for';
           message[3]:='swept lumped';
	end
	else if parallel_cir then begin
           bad_compt:=true;
           message[1]:='Parallel circuit';
           message[2]:='not allowed for';
           message[3]:='swept lumped';
	end
	else begin {j=1, value[1..3]}
      	   i:=0; {index of non-zero value}
	   repeat Inc(i); 
	   until (value[i]<>0);
	   {* value[i] is now the alt_parm *}
	   if (i in [1..3]) then 
	      x_sweep.init_element(tcompt,ident,prefix,unit1);
	   x_sweep.Load_Index(i);
	end;   
      end; {if alt_param}
      if bad_compt then exit;
      if Manhattan(tcompt) or (value[4]=0) then begin
        width:=Manh_width;
        lngth:=2.0*Manh_width;  {* Select Manhattan layout *}
      end
      else begin
      	lngth:=value[4];
	width:=0;
      end;
      case unit1 of
        omega : begin
                  zed:=value[1]/z0;
                  zedo:=value[2]/z0;
                  wavelength:=value[3]/z0;
                  spec_freq:=1;
                end;
       'z','Z': begin
                  zed:=value[1];
                  zedo:=value[2];
                  wavelength:=value[3];
                  spec_freq:=1;
                 end;
       's','S': begin
                  zed:=value[1]*z0;
                  zedo:=value[2]*z0;
                  wavelength:=value[3]*z0;
                  spec_freq:=-1;
                end;
       'y','Y': begin
                  zed:=value[1];
                  zedo:=value[2];
                  wavelength:=value[3];
                  spec_freq:=-1;
                end;
       end;{case}
      if zed < 0 then zed:=zed*one;
      if lngth<=resln then begin
         bad_compt:=true;
         message[1]:='lumped length';
         message[2]:='must be in m';
         message[3]:='>'+sresln;
      end;
    end; {with}
  end 
  else begin
    ff:=freq/design_freq;  {normalized}
    with tcompt^ do
    if spec_freq > 0 then begin  {z ,zedo=Ind wavlength=Cap}
      if freq= 0 then begin
        if wavelength=0 then co(s21,1/(1+zed/2),0)
			else co(s21,0.0,0.0);
      end
      else begin
        zi:=(zedo*ff+wavelength/ff)/2;
        co(zo2,1+zed/2,zi);
        rc(s21,zo2);
      end;
      s11.r:=1-s21.r;
      s11.i:=-s21.i;
    end
    else begin              {y}
      if freq= 0 then begin
        if wavelength=0 then co(s11,1/(1+zed*2),0)
			else co(s11,0.0,0.0);
      end
      else begin
        zi:=2*(zedo*ff+wavelength/ff);
        co(yb2,1+2*zed,zi);
        rc(s11,yb2);
      end;
      s21.r:=1-s11.r;
      s21.i:=-s11.i;
    end;
    c_s:=nil;
    for j:=1 to 2 do
    for i:=1 to 2 do begin
      if c_s=nil then begin
        new_s(tcompt^.s_begin);
        c_s:=tcompt^.s_begin;
      end
      else begin
        new_s(c_s^.next_s);
        c_s:=c_s^.next_s;
      end;
      c_s^.next_s:=nil;
      New_c (c_s^.z);
      if i=j then co(c_s^.z^.c,s11.r,s11.i)
      	     else co(c_s^.z^.c,s21.r,s21.i);
   end; {i}
  end; {action}
end; {lumpedO}


procedure Transformer(tcompt : compt);
{*
	Procedure for drawing transformer and
	computing its s-parameters.

	tcompt^.zed = n = turns ratio
	S11 = (n^2 - 1)/(n^2 + 1)
	S12 = 2n/(n^2 + 1) = S21
	S21 = 2n/(n^2 + 1)
	S22 = (1 - n^2)/(n^2 + 1) = - S11
	where n is the turns ratio. Each is double.
*}
var
  denom,turns_ratio,
  S11,S21 		: double;
  i	   		: integer;
  unit1,prefix 		: char;
  value_string		: line_string;
  alt_param		: boolean;

begin
  if action then begin
    with tcompt^ do begin
      number_of_con:=2;
      con_space:=0.0;
      Get_Param(tcompt,1,turns_ratio,value_string,unit1,prefix,alt_param);
	{! t_ratio has prefixes factored in - must catch as an error}
	{if ':' present it will return as unit1 }
      if bad_compt then exit;
      if (prefix<>' ') then begin  
      	{! no prefixes for unitless numbers}
        bad_compt:=true;	      	
	message[1]:='No prefixes';
	message[2]:='allowed for';
        message[3]:='transformer';
	exit;
      end;	
      if alt_param then x_sweep.init_element(tcompt,'t',prefix,unit1);
      if bad_compt then exit;
      width:=Manh_length;  
      lngth:=Manh_length;  {* Use Manhattan dimensions    *}
      (****Negative values OK, just imply a 180 phase shift***
      if turns_ratio < 0 then turns_ratio:=Abs(turns_ratio); 
      	{take absolute value if negative}
	*****)
      zed:=turns_ratio;  {Pass turns ratio to tcompt^.zed}
    end; {with}
  end {action}
  else begin
    {* Fill frequency independent scattering parameters *}
    {* Turns ratio given in tcompt^.zed *}
    denom:=sqr(tcompt^.zed)+1.0; {denominator}
    S11:=(denom-2.0)/denom;      {S11=-S22}
    S21:=2.0*tcompt^.zed/denom;  {S12= S21}
    new_s(tcompt^.s_begin);
    c_s:=tcompt^.s_begin;
    New_c (c_s^.z);
    co(c_s^.z^.c,S11,0);   {S11}
    for i:=2 to 4 do begin
      new_s(c_s^.next_s);
      c_s:=c_s^.next_s;
      New_c (c_s^.z);
      if i=4 then co(c_s^.z^.c,-S11,0)        {S22=-S11}
      	     else co(c_s^.z^.c,S21,0);        {S12=S21}
    end; {for i}
    c_s^.next_s:=nil;
  end;
end; {* Transformer *}


procedure Attenuator(tcompt : compt);
{*
	Procedure for drawing transformer and
	computing its s-parameters.

	S11 = S22 = 0
	S12 = S21 = tcompt^.zed
*}
var
  value			: double;
  i	   		: integer;
  unit1,prefix 		: char;
  value_string		: line_string;
  alt_param		: boolean;

begin
  if action then begin
    with tcompt^ do begin
      number_of_con:=2;
      con_space:=0.0;
      Get_Param(tcompt,1,value,value_string,unit1,prefix,alt_param);
      	{* value_string, prefix are ignored}
	{value has prefixes factored in at this point}
	{if entered in dB then unit1 returns 'd' or 'D'}
	{if no unit then unit1 = '?'}
      if bad_compt then exit;
      if (prefix<>' ') then begin
        bad_compt:=true;
	message[1]:='No prefixes';
	message[2]:='allowed for';
        message[3]:='attenuator';
	exit;
      end;	
      if not(unit1 in ['d','D','?']) then begin
        bad_compt:=true;
	message[1]:='Enter';
        message[2]:='attenuation';
	message[3]:='in dB';
	exit;
      end;	
      if (Abs(value) > 99) then begin
        bad_compt:=true;
        message[1]:='Attenuation';
	message[2]:='out of range';
	exit;
      end;	
      if alt_param then x_sweep.init_element(tcompt,'a',prefix,unit1);
      if bad_compt then exit;
      width:=2.0*Manh_width;  {* Draw as a square box using *}
      lngth:=width;           {* Manhattan dimensions  *}
      zed:=value;  {zed is dB value of S12,S21}
    end; {with}
  end {action}
  else begin
    {* Fill frequency independent scattering parameters *}
    value:=Exp(-ln10*tcompt^.zed/20);  {convert from dB for S12, S21}
    new_s(tcompt^.s_begin);
    c_s:=tcompt^.s_begin;
    New_c (c_s^.z);
    co(c_s^.z^.c,0.0,0.0);   {S11}
    for i:=2 to 4 do begin
      new_s (c_s^.next_s);
      c_s:=c_s^.next_s;
      New_c (c_s^.z);
      if i=4 then co(c_s^.z^.c,0.0,0.0)  {S22}
      	     else co(c_s^.z^.c,value,0); {S12=S21}
    end; {for i}
    c_s^.next_s:=nil;
  end;
end; {* Attenuator *}


Procedure Device_S(tcompt : compt; indef : boolean);
{*
	See PFMSC.PAS for Device_Read(): reads file data.

	Called only if action is false,
	to calculate interpolated device s-parameters.

	Indef specifies whether or not to enable the generation
	of indefinite scattering parameters (extra port).

	type compt has the following s_param records:
		tcompt^.s_begin,
		tcompt^.s_file,
		tcompt^.s_ifile,
		tcompt^.f_file
*}
{label
  read_finish;}

var
  c_ss,c_f,c_is			: s_param;
  s1,s2        			: array[1..10,1..10] of PMemComplex;
  found			     	: boolean;
  i,j,k,txpt,tnpts		: integer;

  f1,f2,tfreq,tfmin,ffac 	: double;


Begin  {* Device_S *}
    if Alt_Sweep then tnpts:=1		{load twice for alt_sweep}
    		 else tnpts:=npts;
    if xpt=0 then begin
      with tcompt^ do begin
        if f_file<>nil then tfmin:=f_file^.z^.c.r;   {first frequency}
        s_ifile:=nil;
        for txpt:=0 to tnpts do begin
          if f_file <> nil then begin
	    if (txpt=tnpts) then tfreq:=sxmax
	    		    else tfreq:=fmin+txpt*finc;
	    if Alt_Sweep then tfreq:=design_freq;
            found:=false;
            if tfmin <= tfreq then begin
              c_f:=nil;
	      c_ss:=nil;
              repeat
                if c_f=nil then c_f:=f_file
		     	   else c_f:=c_f^.next_s;
                for j:= 1 to number_of_con do
                   for i:= 1 to number_of_con do begin
                  	if c_ss=nil then c_ss:=s_file
			     	   else c_ss:=c_ss^.next_s;
			s1[i,j]:=c_ss^.z;
		end; {i j}
                if c_f^.next_s^.z^.c.r >= tfreq then found:=true;
              until found or (c_f^.next_s^.next_s=nil);
	      {Get endpoints for interpolation}
              IF (found) THEN BEGIN
                f1:=c_f^.z^.c.r;
	        f2:=c_f^.next_s^.z^.c.r;
                FOR j:= 1 to number_of_con DO
              	  FOR i:= 1 to number_of_con DO BEGIN
                    c_ss:=c_ss^.next_s;
		    s2[i,j]:=c_ss^.z
                  END; {for i,j}
              END;
            end; {if tfmin < tfreq}
          end
	  else begin    {if f_file=nil}
            if txpt=0 then begin
              	c_ss:=nil;
		found:=true;
		for j:= 1 to number_of_con do
		   for i:= 1 to number_of_con do begin
		   	if c_ss=nil then c_ss:=s_file
			           else c_ss:=c_ss^.next_s;
			s1[i,j]:=c_ss^.z;
			s2[i,j]:=s1[i,j];
		end; {for i,j}
            end; {if txpt=0}
          end; {if f_file}
          for j:= 1 to number_of_con do
          for i:= 1 to number_of_con do begin
            if s_ifile=nil then begin
              	new_s(s_ifile);
		c_is:=s_ifile;
            end
	    else begin
              	new_s(c_is^.next_s);
		c_is:=c_is^.next_s;
            end;
            c_is^.next_s:=nil;
            if found then begin	 {*device s-parameter interpolation routine*}
                New_c (c_is^.z);
              	if f_file=nil then ffac:=0
		     	      else ffac:=(tfreq-f1)/(f2-f1);
		c_is^.z^.c.r:=s1[i,j]^.c.r+ffac*(s2[i,j]^.c.r-s1[i,j]^.c.r);
		c_is^.z^.c.i:=s1[i,j]^.c.i+ffac*(s2[i,j]^.c.i-s1[i,j]^.c.i);
            end else begin {found = true}
              c_is^.z:= NIL;
            end;
          end; {for i,j to number_of_con}
        end; {for txpt}
      end; {with}
    end; {if xpt:=0}

    if Alt_Sweep then txpt:=1	{only one freq}
    		 else txpt:=xpt;

    with tcompt^ do begin
      	s_begin:=s_ifile;
	for k:=0 to txpt-1 do 		{advance to next freq}
	  for j:=1 to number_of_con do
	    for i:=1 to number_of_con do begin
	    	s_begin:=s_begin^.next_s;
			if s_begin=nil then begin
			    message[2]:='s out of range';
			    shutdown;
			end;
        end; {for i,j,k}
        if (s_begin^.z = NIL) then begin
        	bad_compt:=true;
		erase_message;
		message[1]:='Frequency out of';
		message[2]:='   range given   ';
		message[3]:='in device file';
        end;
    end; {with}
End; {* Device_S *}


procedure dx_dyO;
{*
	Display change in x an y in mm when cursor X moves.
*}
const
   pos_prefix : string = 'EPTGMk m'+Mu+'npfa';

var
  i,j         : integer;	
  dx,dy       : double;
  dx_prefix,
  dy_prefix   : char;

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


begin
  dx:=(xm-xrold);   {Initial numbers are in mm}  
  dy:=(ym-yrold);
  xrold:=xm;       
  yrold:=ym;
  i:=8;  {start index is 'm' in mm}
  {Check for large or small values of dx,dy}
  if (dx<>0.0) then begin
    Big_Check(dx,i);
    Small_Check(dx,i);
  end;
  dx_prefix:=pos_prefix[i]; 
  j:=8;  {start index is 'm' in mm}  
  if (dy<>0.0) then begin
    Big_Check(dy,j);
    Small_Check(dy,j);
  end;
  dy_prefix:=pos_prefix[j]; 
  if read_kbd then begin
     TextCol(lightgray);
     GotoXY(xmin[6]+2,ymin[6]+1);
     if abs(dx) > resln then begin
        Write(delta,'x ', dx:7:3,dx_prefix,'m');
        GotoXY(xmin[6]+2,ymin[6]);
     end 
     else 
        GotoXY(xmin[6]+2,ymin[6]+1);
     if abs(dy) > resln then Write(delta,'y ',-dy:7:3,dy_prefix,'m');
  end;
end; {* dx_dyO *}


function get_lead_charO(tcompt : compt) : char;
{*
	Get lead character to determine if part is 
	tline, clines, device, lumped, etc.
*}
label
  exit_label;
var
  xstr  : line_string;
  char1 : char;

begin
  xstr:=tcompt^.descript;
  Delete(xstr,1,1);
  char1:=xstr[1];
  repeat
    if xstr[1]=' ' then Delete(xstr,1,1);
    if (length(xstr)=0) then goto exit_label;
    char1:=xstr[1];
  until (xstr[1] <> ' ');
  exit_label:
  if char1 in ['A'..'Z'] then char1:=char(ord(char1)+32);
  get_lead_charO:=char1;
end; {get_lead_charO}


Procedure Draw_tline(tnet : net; linex,seperate : boolean);
{*
	Draw a transmission line and lumped element on the circuit board.
*}
var
  x1,x2,y1,y2,x3,y3,
  x1e,y1e,x2e,y2e,i,j    : integer;
  x1r,y1r,x2r,y2r        : double;

begin
  x1r:=tnet^.xr-lengthxm*yii/2.0;
  x2r:=x1r+lengthxm*(xii+yii);
  y1r:=tnet^.yr-lengthym*xii/2.0;
  y2r:=y1r+lengthym*(yii+xii);
  x1:=Round(x1r/csx+xmin[1]);
  x2:=Round(x2r/csx+xmin[1]);
  x3:=Round((x1r+x2r)/(2.0*csx)+xmin[1]);
  y1:=Round(y1r/csy+ymin[1]);
  y2:=Round(y2r/csy+ymin[1]);
  y3:=Round((y1r+y2r)/(2.0*csy)+ymin[1]);
  x1e:=Round(tnet^.xr/csx)+xmin[1];
  y1e:=Round(tnet^.yr/csy)+ymin[1];
  x2e:=Round((tnet^.xr+lengthxm*xii)/csx)+xmin[1];
  y2e:=Round((tnet^.yr+lengthym*yii)/csy)+ymin[1];
  if linex then 
	fill_box(x1,y1,x2,y2,brown) 
  else begin
    	if x1=x2 then begin   { make 50 Ohms wide if width=0 }
		x1:=Round(x1-widthZ0/(2.0*csx));
		x2:=Round(x2+widthZ0/(2.0*csx));
	end 
	else if y1=y2 then begin  { make 50 Ohms wide if width=0 }
		y1:=Round(y1-widthZ0/(2.0*csy));
		y2:=Round(y2+widthZ0/(2.0*csy));
	end;  { if width<>0 i.e. Manhattan, just draw it }
	draw_box(x1,y1,x2,y2,lightblue);
	IF (tnet^.com^.typ='a') THEN BEGIN
	    {* Make small boxes for atten terminals *}
	    box(x1e,y1e,1);
	    box(x2e,y2e,1);
	END;
  end;
  if seperate then begin
    x1r:=(tnet^.xr+tnet^.com^.con_space*yii/2.0)/csx+xmin[1];
    y1r:=(tnet^.yr+tnet^.com^.con_space*xii/2.0)/csy+ymin[1];
    if not((x1=x2) or (y1=y2)) then
    BEGIN
      SetCol(black);
      Line(Round(x1r),Round(y1r),Round(x1r+lengthxm*xii/csx),
           Round(y1r+lengthym*yii/csy));
    END;
  end;
  {* Write graphics character to identify part *}
  SetTextJustify(CenterText,CenterText);
  PutPixel(x3,y3,Black);  {make sure center dot is black}
  SetCol(Black);
  for i:=-1 to 1 do
    for j:=-1 to 1 do
       OutTextXY(x3+i,y3+j,tnet^.com^.descript[1]); {shadow}
  SetCol(LightRed);
  OutTextXY(x3,y3,tnet^.com^.descript[1]);      {letter}
end; {* Draw_tline *}


Procedure Draw_xformer(tnet : net);
{*
	Draw a transformer on the circuit board.
*}
var
  x1,x2,y1,y2,x3,y3,xt,yt   : integer;

begin
  x1:=Round(tnet^.xr/csx)+xmin[1];
  y1:=Round(tnet^.yr/csy)+ymin[1];
  x2:=Round((tnet^.xr+lengthxm*xii)/csx)+xmin[1];
  y2:=Round((tnet^.yr+lengthym*yii)/csy)+ymin[1];
  xt:=Round(yii*lengthym/(2.0*csx));
  yt:=Round(xii*lengthxm/(2.0*csy));
  x3:=Round((x1+x2)/2.0);
  y3:=Round((y1+y2)/2.0);
  SetTextJustify(CenterText,CenterText);  {center text for OutText}
  SetCol(lightblue);
  Line(x1-xt,y1-yt,x1+xt,y1+yt);
  Line(x1+xt,y1+yt,x2+(xt div 2),y2+(yt div 2));
  Line(x2+(xt div 2),y2+(yt div 2),x2-(xt div 2),y2-(yt div 2));
  Line(x2-(xt div 2),y2-(yt div 2),x1-xt,y1-yt);
  SetCol(LightRed);
  OutTextXY(x3,y3,tnet^.com^.descript[1]);
  {* Make small boxes for xformer terminals *}
  box(x1,y1,1);
  box(x2,y2,1);
end; {* Draw_xformer *}


Procedure Draw_device(tnet : net);
{*
	Draw a triangle to represent a device.
*}
var
  sx1,sy1 			: double;
  x1,x2,y1,y2,x3,y3,xt,yt,i 	: integer;

begin
  x1:=Round(tnet^.xr/csx)+xmin[1];
  y1:=Round(tnet^.yr/csy)+ymin[1];
  x2:=Round((tnet^.xr+lengthxm*xii)/csx)+xmin[1];
  y2:=Round((tnet^.yr+lengthym*yii)/csy)+ymin[1];
  xt:=Round(yii*lengthym/(2.0*csx));  
  yt:=Round(xii*lengthxm/(2.0*csy));
  x3:=Round((2*x1+x2)/3.0);
  y3:=Round((2*y1+y2)/3.0);
  SetTextJustify(CenterText,CenterText);  {center text for OutText}
  SetCol(lightblue);
  Line(x1-xt,y1-yt,x1+xt,y1+yt);
  Line(x1+xt,y1+yt,x2,y2);
  Line(x2,y2,x1-xt,y1-yt);
  SetCol(LightRed);
  OutTextXY(x3,y3,tnet^.com^.descript[1]);
  {* Make small boxes for device terminals *}
  with tnet^ do
    if number_of_con =1 then begin
      box(x1,y1,1);
    end 
    else begin
      sx1:=(x2-x1)/(number_of_con-1);
      sy1:=(y2-y1)/(number_of_con-1);
      for i:=0 to number_of_con-1 do 
      	box(x1+Round(i*sx1),y1+Round(i*sy1),1);     	
      if (tnet^.com^.typ='i') then begin
         if number_of_con=3 then
	     box(x1+Round(sx1),y1+Round(sy1),4) {Yellow box at port 2}
    	 else 
	     box(x1+Round((number_of_con-1)*sx1),
	         y1+Round((number_of_con-1)*sy1),4); 
	     {Yellow box at last port}
      end;
    end;
end; {* Draw_device *}


procedure Add_Coord(x1,xb,xl,y1: integer;just,brd: boolean;tdes: line_string);
{*
	Add a record to the list of paramters used 
	in the plot window or the board window.
	Used below in Set_Up_KeyO and Set_Up_Board
*}
begin
  if ccompt=nil then begin
  	if brd then ccompt:=board_start
	       else ccompt:=coord_start;
  end
  else 
        ccompt:=ccompt^.next_compt;
  with ccompt^ do begin
     xp:=x1; 		{x-position}
     xorig:=x1; 
     xmaxl:=xl; 	{length of number}
     x_block:=xb; 	{amount of text}
     yp:=y1;	 	{y-position}
     right:=just;
     descript:=tdes;
  end;
end; {add_coord}


procedure Set_Up_KeyO;
{*
	Set up parameters for Plot window.
	Called by Puff_Start to initialize to blank parameters,
	and by Read_Net() after reading file key. 
	Uses Add_Coord;
*}
begin
  ccompt:=nil;
  add_coord(x_y_plot_text[1,1],0, 5, x_y_plot_text[1,2], 
  		true,false,s_key[1]);  {dBmax} 
  dBmax_ptr:=ccompt; {save this position for swapping, also coord_start}
  add_coord(x_y_plot_text[3,1],0, 5, x_y_plot_text[3,2], 
  		true,false,s_key[2]);  {dBmin}
  add_coord(x_y_plot_text[4,1],0, 7, x_y_plot_text[4,2],
  		false,false,s_key[3]);  {fmin}
  fmin_ptr:=ccompt;
  add_coord(x_y_plot_text[6,1],0, 7, x_y_plot_text[6,2],
  		true,false,s_key[4]);   {fmax}
  add_coord(xmin[2],7,12,ymin[2],false,false,'Points '+s_key[5]);
  Points_compt:=ccompt;
  add_coord(xmin[2],13,17,ymin[2]+1,false,false,'Smith radius '+s_key[6]);
  rho_fac_compt:=ccompt;
  add_coord(xmin[2]+2,1, 3,ymin[2]+3,false,false,'S'+s_key[7]);   
  s_param_table[1]:=ccompt;
  add_coord(xmin[2]+2,1, 3,ymin[2]+4,false,false,'S'+s_key[8]);  
  s_param_table[2]:=ccompt;
  add_coord(xmin[2]+2,1, 3,ymin[2]+5,false,false,'S'+s_key[9]);  
  s_param_table[3]:=ccompt;
  add_coord(xmin[2]+2,1, 3,ymin[2]+6,false,false,'S'+s_key[10]); 
  s_param_table[4]:=ccompt;
end; {*Set_Up_KeyO*}


procedure Update_KeyO_locations;
{*
	Update the locations of the KeyO parameters after a screen resize
*}
var c : compt;
begin
  c:=coord_start;
  c^.xp:=x_y_plot_text[1,1]; c^.xorig:=c^.xp; c^.yp:=x_y_plot_text[1,2];  c:=c^.next_compt;
  c^.xp:=x_y_plot_text[3,1]; c^.xorig:=c^.xp; c^.yp:=x_y_plot_text[3,2];  c:=c^.next_compt;
  c^.xp:=x_y_plot_text[4,1]; c^.xorig:=c^.xp; c^.yp:=x_y_plot_text[4,2];  c:=c^.next_compt;
  c^.xp:=x_y_plot_text[6,1]; c^.xorig:=c^.xp; c^.yp:=x_y_plot_text[6,2];  c:=c^.next_compt;
  c^.xp:=xmin[2];            c^.xorig:=c^.xp; c^.yp:=ymin[2];             c:=c^.next_compt;
  c^.xp:=xmin[2];            c^.xorig:=c^.xp; c^.yp:=ymin[2]+1;           c:=c^.next_compt;
  c^.xp:=xmin[2]+2;          c^.xorig:=c^.xp; c^.yp:=ymin[2]+3;           c:=c^.next_compt;
  c^.xp:=xmin[2]+2;          c^.xorig:=c^.xp; c^.yp:=ymin[2]+4;           c:=c^.next_compt;
  c^.xp:=xmin[2]+2;          c^.xorig:=c^.xp; c^.yp:=ymin[2]+5;           c:=c^.next_compt;
  c^.xp:=xmin[2]+2;          c^.xorig:=c^.xp; c^.yp:=ymin[2]+6;           c:=c^.next_compt;
end; {*Set_Up_KeyO*}


procedure Set_Up_Board;
{*
	Set up parameters for BOARD window.
	Called by Puff_Start to initialize blank parameters,
	and by Read_Net() after Read_Board. 
	Uses Add_Coord;
*}
begin
  ccompt:=nil;
  add_coord(xmin[4],4,16,ymin[4],false,true,'zd  '+s_board[1,1]+
  	' '+s_board[1,2]+Omega); {zd norm impedance}
  add_coord(xmin[4],4,16,ymin[4]+1,false,true,'fd  '+s_board[2,1]+
  	' '+s_board[2,2]+'Hz'); {fd design_freq}
  add_coord(xmin[4],4,16,ymin[4]+2,false,true,'er  '+s_board[3,1]); 
  {er dielectric const}
  add_coord(xmin[4],4,16,ymin[4]+3,false,true,'h   '+s_board[4,1]+
  	' '+s_board[4,2]+'m'); {h substrate thick}
  add_coord(xmin[4],4,16,ymin[4]+4,false,true,'s   '+s_board[5,1]+
  	' '+s_board[5,2]+'m'); {s board size}  
  add_coord(xmin[4],4,16,ymin[4]+5,false,true,'c   '+s_board[6,1]+
  	' '+s_board[6,2]+'m'); {c conn separation}
end; {*Set_Up_Board*}


Procedure Fresh_Dimensions;
{*
     Determine screen and artwork layout variables.
     Called in Read_Board().
     Uses only global variables.
     Must be called after any change to bmax (s),z0 (zd).
     Sets all parts to ^.changed=true, forcing parsing
       therefore, call after changes to fd,er,h
*}
var
  tcompt      	: compt;

Begin
  csy:=bmax/(ymax[1]-ymin[1]);
  csx:=csy*yf;
  Manh_length:=0.1*bmax;
  Manh_width:=0.05*bmax;

  if abs(con_sep) > bmax then con_sep:=bmax;
  if Manhattan_Board then widthZ0:=Manh_width
  		     else widthZ0:=widtht(z0) + artwork_cor;
  {* Artwork correction added ^ *}
  pwidthxZ02:=Round(widthZ0*0.5/psx);  {artwork dimen}
  pwidthyZ02:=Round(widthZ0*0.5/psy);
  cwidthxZ02:=Round(widthZ0*0.5/csx);  {screen dimen}
  cwidthyZ02:=Round(widthZ0*0.5/csy);

  {* (Global Var) Sheet resistance of metal at design_freq *} 
  Rs_at_fd:=sqrt(Pi*design_freq*Eng_prefix(freq_prefix)*Mu_0/conductivity);

  {* (Global Var) Wavelength in mm at design freq. *}
  Lambda_fd:=c_in_mm/(design_freq*Eng_Prefix(freq_prefix));

  tcompt:=nil;
  repeat    {* Force parsing of each part *}
    if tcompt=nil then tcompt:=part_start 
	          else tcompt:=tcompt^.next_compt;
    tcompt^.changed:=true;
  until tcompt^.next_compt=nil;
end; {* Fresh_Dimensions *}


procedure draw_groundO(xr,yr : double);
{*
	Draw ground on circuit.
*}
var
  x1,y1   : integer;

begin
  if read_kbd or demo_mode then begin
	x1:=Round(xr/csx)+xmin[1];
	y1:=Round(yr/csy)+ymin[1];
	SetCol(yellow);
	Line(x1-4,y1  ,x1+4,y1);
	Line(x1-2,y1+2,x1+2,y1+2);
	Line(x1-1,y1+4,x1+1,y1+4);
   end; {read_kbd}
end; {draw_groundO}


function Look_BackO : boolean;
(*
	Look back at network to see how cline connection should be made.
	Called by Add_Net, puff.pas
	mate_node is a global array[1..4] of net;
	
	Mate_Node is set up for possible use in Add_Net.
	look_back is called as follows:

		special_coupler:=Look_Back;
		for i:=1 to compt1^.number_of_con do begin
		    if special_coupler and (i in[1,3]) then begin
		    	cnet:=mate_node[i];
			cnet^.number_of_con:=cnet^.number_of_con+1;
		    end;	
		    etc...
		end; 

*)
var
  tcon,scon,mtcon,mscon : conn;
  x1,x2,y1,y2,cs,cm   	: double;
  coupler_found 	: boolean;
  tnet  		: net;
  d2    		: integer;

begin
  look_backO:=false;
  coupler_found:=false;
  if cnet <> nil then 
  if compt1^.typ = 'c' then begin  {if a cline then}
    tcon:=nil;
    repeat
      if tcon=nil then tcon:=cnet^.con_start 
      		  else tcon:=tcon^.next_con;
      if tcon^.mate <> nil then
      if tcon^.mate^.net^.com^.typ='c' then begin   {if cline to cline}
         cs:=(tcon^.mate^.net^.com^.con_space+compt1^.con_space)/2.0;
         cm:=(tcon^.mate^.net^.com^.con_space-compt1^.con_space)/2.0;
	 {find averages of connector separation between old and new}
         d2:=tcon^.dir;
         mtcon:=tcon^.mate;
         case tcon^.mate^.conn_no of  {look at conns old clines}
           1,2 :  mscon:=mtcon^.next_con^.next_con; {advance 2 connectors}
           3   :  mscon:=mtcon^.net^.con_start;	    {con 3 -> con 1}
           4   :  mscon:=mtcon^.net^.con_start^.next_con; {con 4 -> con 2}
         end; {case}
         scon:=mscon^.mate;	{change to ccon form}
         Mate_Node[1]:=cnet;
	 x1:=Mate_Node[1]^.xr;  {note current marker positions}
	 y1:=Mate_Node[1]^.yr;
         Mate_Node[3]:=scon^.net;  
	 x2:=Mate_Node[3]^.xr;  {note old clines position}
	 y2:=Mate_Node[3]^.yr;
         coupler_found:=true;
      end; {if cline to cline}
    until tcon^.next_con=nil;
    if coupler_found then     {if coupler to coupler connection}
    if abs(x1-x2) < resln then begin   {if both in same x position}
     if y1 > y2 then begin	{if cursor above old clines}
       case dirn of
         2 : begin
               ym:=ym-cs;
               tnet:=Mate_Node[1];
               Mate_Node[1]:=Mate_Node[3];
               Mate_Node[3]:=tnet;
               look_backO:=true;
             end;
         4 : begin
               ym:=ym-cm;
               look_backO:=true;
             end;
         8 : if d2 =2 then begin
               dirn:=4;
               ym:=ym+compt1^.con_space;
             end 
	     else 
	       dirn:=2;
        end; {case}
      end {y1>y2}
      else begin
        case dirn of
         4 : begin
               ym:=ym+cs;
               tnet:=Mate_Node[1];
               Mate_Node[1]:=Mate_Node[3];
               Mate_Node[3]:=tnet;
               look_backO:=true;
             end;
         2 : begin
               ym:=ym+cm;
               look_backO:=true;
             end;
         1 : if d2=4 then begin
               dirn:=2;
               ym:=ym-compt1^.con_space;
             end 
	     else 
	       dirn:=4;
        end; {case}
      end; {y1 > y2}
    end {abs}
    else begin
     if x1 > x2 then begin
        case dirn of
         8 : begin
               xm:=xm-cs;
               tnet:=Mate_Node[1];
               Mate_Node[1]:=Mate_Node[3];
               Mate_Node[3]:=tnet;
               look_backO:=true;
             end;
         1 : begin
               xm:=xm-cm;
               look_backO:=true;
             end;
         2 : if d2=8 then begin
               dirn:=1;
               xm:=xm+compt1^.con_space;
             end 
	     else 
	       dirn:=8;
        end; {case}
     end {x1 >x2}
     else begin
       case dirn of
         1 : begin
               xm:=xm+cs;
               tnet:=Mate_Node[1];
               Mate_Node[1]:=Mate_Node[3];
               Mate_Node[3]:=tnet;
               look_backO:=true;
             end;
         8 : begin
               xm:=xm+cm;
               look_backO:=true;
             end;
         4 : if d2=1 then begin
               dirn:=8;
               xm:=xm-compt1^.con_space;
             end 
	     else  {i.e. d2=8} 
	       dirn:=1;
        end; {case}
      end; {x1 > x2}
    end; {if abs}
  end; {if compt1}
end; {look_backO}


End.
