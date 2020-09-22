/*-----------------------------------------------------------------------

This file contains several functions used for emulating the 'crt' and
'graph' units from Turbo Pascal, as well as a few other functions.
This has been written in order to compile and use the PUFF microwave
circuit analysis and design software under Linux with the X11 window
system. 

The implementations here and in xgraph.pas are not complete: they are limited
to what is needed for compiling and using the PUFF software. As such, they
may or may not be useful for compiling other graphical Turbo Pascal
applications under Linux, depending on the requirements of such applications.

Copyright (c) 2000-2001,2006,2007,2010 by Pieter-Tjerk de Boer, pa3fwm@amsat.org.
This software is distributed under the conditions of version 3 of the GNU
General Public License from the Free Software Foundation.

-----------------------------------------------------------------------*/




#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/Xutil.h>
#include <assert.h>
#include <sys/time.h>
#include <sys/types.h>
#include <X11/XKBlib.h>


#define GROK 0
#define LeftText 0
#define CenterText 1
#define RightText 2
#define BottomText 0
#define TopText 2

#define SolidFill 0

struct ViewPortType {
  int x1;
  int y1;
  int x2;
  int y2;
  char clip;
};

Display *dpy=NULL;
XWindowAttributes wa;
int scr;
Window w;
GC gc,gcfill,gcclear,gctext,gcpixel;
Pixmap pm;
Pixmap boxes[16];
int fontyoffs=0;
int Ox=0, Oy=0;
int textjustX=RightText;
int textjustY=CenterText;

int ScreenHeight;
int ScreenWidth;

int drawcounter=0;
int bkcolor=0;

struct ViewPortType vp={0,0,639,479,1};

unsigned long pascalcolours[16];

int width, height;


void InitGraph (short int *GraphDriver, short int *GraphModus, char *PathToDriver)
{
}



void CloseGraph(void)  
{
}

void SetColor (int Color) 
{
   XSetForeground(dpy,gc,pascalcolours[Color]);
}

void SetBkColor (int Color) 
{
   bkcolor=Color;
   XSetForeground(dpy,gcclear,pascalcolours[Color]);
}

void SetFillStyle (int Pattern,int Color) 
{
   assert(Pattern==SolidFill);
   XSetForeground(dpy,gcfill,pascalcolours[Color]);
}

void SetLineStyle (int LineStyle,int Pattern,int Width) 
{
   /* note: LineStyle is not fully implemented; Pattern is ignored */
   XSetLineAttributes(dpy, gc, Width, LineStyle==0 ? LineSolid : LineOnOffDash, CapRound, JoinRound);
}

void Line (int X1,int Y1,int X2,int Y2) 
{
   XDrawLine(dpy, pm, gc, Ox+X1,Oy+Y1,Ox+X2,Oy+Y2);
   drawcounter++;
}

void PutPixel (int X,int Y, int Color) 
{
   XSetForeground(dpy,gcpixel,pascalcolours[Color]);
   XDrawPoint(dpy, pm, gcpixel, Ox+X,Oy+Y);
}

void Bar (int X1,int Y1,int X2,int Y2) 
{
   int h;

   if (!dpy) return;    /* why is this test needed??? */
   if (X2<X1) { h=X1; X1=X2; X2=h; }
   if (Y2<Y1) { h=Y1; Y1=Y2; Y2=h; }
   XFillRectangle(dpy, pm, gcfill, Ox+X1,Oy+Y1,X2-X1+1,Y2-Y1+1);
   drawcounter++;
}

void Rectangle (int X1,int Y1,int X2,int Y2) 
{
   int h;

   if (X2<X1) { h=X1; X1=X2; X2=h; }
   if (Y2<Y1) { h=Y1; Y1=Y2; Y2=h; }
   XDrawRectangle(dpy, pm, gc, Ox+X1,Oy+Y1,X2-X1,Y2-Y1);
   drawcounter++;
}

void Arc (int X,int Y,int start,int stop, int radius) 
{
   XDrawArc(dpy, pm, gc, Ox+X-radius,Oy+Y-radius,radius*2,radius*2,start*64,stop*64);
   drawcounter++;
}

void FillEllipse (int X,int Y, int Xradius,int Yradius) 
{

   XFillArc(dpy, pm, gcfill, Ox+X-Xradius,Oy+Y-Yradius,Xradius*2,Yradius*2,0,64*360);
   XDrawArc(dpy, pm, gc,     Ox+X-Xradius,Oy+Y-Yradius,Xradius*2,Yradius*2,0,64*360);
   drawcounter++;
}

void Circle (int X,int Y, int radius) 
{

   XDrawArc(dpy, pm, gc, Ox+X-radius,Oy+Y-radius,radius*2,radius*2,0,64*360);
   drawcounter++;
}

void FloodFill (int X,int Y, int BorderColor) 
{
   /* a real floodfill would be rather non-trivial and inefficient on X11;
      since puff only seems to use it to clean up the regio around the Smith
      chart, we can get away with a much simpler function:
      we just draw a _very thick_ circle in the background colour around
      the Smith chart, but clipped by the square viewport around the circle.
   */
   
   if (X==0 || Y==0) return;  // FloodFill is called 4 times by the original pascal code, this check only leaves the last one

   XDrawArc(dpy, pm, gcfill, Ox-500,Oy-500,X+1000,Y+1000,0,64*360);
   XDrawArc(dpy, pm, gc, Ox,Oy,X,Y,0,64*360);

   drawcounter++;
}




void SetTextJustify (int Horizontal,int Vertical) 
{
   textjustX=Horizontal;
   textjustY=Vertical;
}

void C_OutTextXY (int X,int Y, unsigned char *TextString)
{
   int x,y;
   char s[40];
   int l;

   l=TextString[0];
   if (l>32) l=32;
   memcpy(s,TextString+1,l);
   s[l]=0;

   x=Ox+X;
   y=Oy+Y;
   if (textjustX==CenterText) x-=4*TextString[0];
   if (textjustX==RightText) x-=8*TextString[0];
   if (textjustY==CenterText) y-=7;
   if (textjustY==TopText) y-=14;

   XDrawString(dpy,pm,gc, x, y+fontyoffs, TextString+1,TextString[0]);
   drawcounter++;
}

void SetViewPort (int X1,int Y1,int X2,int Y2, int Clip) 
{
   Ox = X1;
   Oy = Y1;
   vp.x1=X1;
   vp.y1=Y1;
   vp.x2=X2;
   vp.y2=Y2;
   vp.clip=Clip;

   if (Clip) {
      XRectangle xr;
      xr.x=X1;
      xr.y=Y1;
      xr.width=X2-X1+1;
      xr.height=Y2-Y1+1;
      XSetClipRectangles(dpy, gc, 0, 0, &xr, 1, Unsorted);
      XSetClipRectangles(dpy, gcfill, 0, 0, &xr, 1, Unsorted);
      XSetClipRectangles(dpy, gcpixel, 0, 0, &xr, 1, Unsorted);
   } else {
      XSetClipMask(dpy, gc, None);
      XSetClipMask(dpy, gcfill, None);
      XSetClipMask(dpy, gcpixel, None);
   }
}


int GetBkColor(void) 
{
   return bkcolor;
}


char *GraphErrorMsg (int ErrorCode)
{
   return "Test!";
}

int GraphResult()
{
   return GROK;
}





int crtX=1,crtY=1;
int crtXmin=1, crtXmax=80, crtYmin=1, crtYmax=34;

void crtWindow (int X1,int Y1,int X2,int Y2)
{
   crtXmin=X1;
   crtYmin=Y1;
   crtXmax=X2;
   crtYmax=Y2;
   crtX=crtXmin; crtY=crtYmin;
}

void GotoXY (int X,int  Y)
{
   crtX=X+crtXmin-1; crtY=Y+crtYmin-1;
}

void Sound (int hz)
{
}

int key=-1;
int prevdrawcounter=0;


void process_event(XEvent *xe)
{
   KeySym keysym;
   char keystring[4];

   switch (xe->type) {
      case KeyPress:
	 keysym = XkbKeycodeToKeysym(dpy,xe->xkey.keycode,0,0);
         /* first, consider the raw keysyms, to catch a few combinations of keys with shift/alt */
         switch (keysym) {
            case XK_1: if (xe->xkey.state & ShiftMask) { key='!'; return; }
            case XK_2: if (xe->xkey.state & ShiftMask) { key='@'; return; }
            case XK_3: if (xe->xkey.state & ShiftMask) { key='#'; return; }
            case XK_4: if (xe->xkey.state & ShiftMask) { key='$'; return; }
            case XK_d: case XK_D: if (xe->xkey.state & Mod1Mask) { key=160; return; }
            case XK_m: case XK_M: if (xe->xkey.state & Mod1Mask) { key=178; return; }
            case XK_o: case XK_O: if (xe->xkey.state & Mod1Mask) { key=152; return; }
            case XK_p: case XK_P: if (xe->xkey.state & Mod1Mask) { key=153; return; }
            case XK_s: case XK_S: if (xe->xkey.state & Mod1Mask) { key=159; return; }
         }
         /* for the rest, first process the keysym further, in which things like shift, ctrl and numlock are taken into account */
         if (XLookupString((XKeyEvent*)xe, keystring, 4, &keysym, NULL)!=0) {
            /* normal ASCII characters, and ctrl-codes, go here: */
            key=keystring[0];
            return;
         }
         /* remaining keys (cursor, function, etc.) go here: */
         switch (keysym) {
            case XK_KP_Up:
            case XK_Up: key= (xe->xkey.state & ShiftMask) ? 184 : 200; return;
            case XK_KP_Down:
            case XK_Down: key= (xe->xkey.state & ShiftMask) ? 178 : 208; return;
            case XK_KP_Left:
            case XK_Left: key= (xe->xkey.state & ShiftMask) ? 180 : 203; return;
            case XK_KP_Right:
            case XK_Right: key= (xe->xkey.state & ShiftMask) ? 182 : 205; return;
            case XK_KP_Page_Up:
            case XK_Prior: key= 201;  /* page up ? */ return;
            case XK_KP_Page_Down:
            case XK_Next: key= 209;  /* page down ? */ return;
            case XK_F1: key= 187; return;
            case XK_F2: key= 188; return;
            case XK_F3: key= 189; return;
            case XK_F4: key= 190; return;
            case XK_F5: key= (xe->xkey.state & ShiftMask) ? 216 : 191; return;
            case XK_F6: key= 192; return;
            case XK_F10: key= 196; return;
            case XK_KP_Insert:
            case XK_Insert: key= 210; return;
            case XK_KP_Delete:
            case XK_Delete: key= 211; return;
         }
         break;

      case ConfigureNotify: 
         {
            int ww,hh;
            ww=ScreenWidth;
            hh=ScreenHeight;
            int cnt=0;
            do {
               XConfigureEvent *xrre=(XConfigureEvent*)xe;
               ScreenWidth=xrre->width;
               ScreenHeight=xrre->height;
            } while (XCheckMaskEvent(dpy,StructureNotifyMask,xe));
            if (ww>ScreenWidth) ww=ScreenWidth;
            if (hh>ScreenHeight) hh=ScreenHeight;
            // we notify the pascal code about the resize by sending a "virtual" keypress
            key=255;  // this constant is screenresize in the pascal code
            // need to update the background pixmap
            Pixmap oldpm=pm;
            pm=XCreatePixmap(dpy, RootWindow(dpy,scr),ScreenWidth,ScreenHeight,wa.depth);
            XFillRectangle(dpy, pm, gcfill, 0,0,ScreenWidth,ScreenHeight);
            XCopyArea(dpy, oldpm, pm, gc, 0, 0, ww, hh, 0, 0);
            XFreePixmap(dpy, oldpm);
            XSetWindowBackgroundPixmap(dpy,w,pm);
            return;
         }
   }
}


void Delay (int DTime)
{
   fd_set f;
   struct timeval timeout;
   int cn;
   XEvent xe;

   if (key>=0) return;
   if (XCheckMaskEvent(dpy,KeyPressMask,&xe)) {
      process_event(&xe);
      if (key>=0) return;
   }

   if (drawcounter>0) {
      XClearWindow(dpy,w);
      XFlush(dpy);
      drawcounter=0;
   }

   timeout.tv_sec=DTime/1000;
   timeout.tv_usec=1000*(DTime%1000);
   FD_ZERO(&f);
   cn=ConnectionNumber(dpy);
   FD_SET(cn, &f);
   select(cn+1, &f, 0, 0, &timeout);
   
   /* note: the above implements a delay that is interrupted as
      soon as an X event occurs, a keypress/release in all practical
      cases. Interrupting the waiting upon keypress/release gives
      much smoother behaviour with puff.
   */
}

void NoSound(void)
{
}


int KeyPressed(void)
{
   XEvent xe;
   if (drawcounter>0 && drawcounter==prevdrawcounter) {
      XClearWindow(dpy,w);
      XFlush(dpy);
      drawcounter=0;
   }
   prevdrawcounter=drawcounter;
   if (key>=0) return 1;
   if (XCheckMaskEvent(dpy,KeyPressMask|KeyReleaseMask|StructureNotifyMask,&xe)) {
      process_event(&xe);
      if (key>=0) return 1;
   }
   return 0;
}

int ReadKey(void)
{
   XEvent xe;
   int i;

   XClearWindow(dpy,w);
   XFlush(dpy);
   while (key<0) {
      XNextEvent(dpy, &xe);
      process_event(&xe);
   }
   i=key;
   key=-1;
   return i;
}

void TextMode(int Mode)
{
}

void TextColor (int CL)
{
   if (!dpy) return;
   XSetForeground(dpy,gctext,pascalcolours[CL]);
}

void TextBackground (int CL)
{
   if (!dpy) return;
   XSetForeground(dpy,gcclear,pascalcolours[CL]);
}

void ClrScr(void)
{
   int y;
   if (!dpy) return;
   y=14*(crtYmax-crtYmin+1);
   if (y==476) y=480;
   XFillRectangle(dpy, pm, gcclear, 8*(crtXmin-1),14*(crtYmin-1),8*(crtXmax-crtXmin+1),y);
   XClearWindow(dpy,w);
   XFlush(dpy);
}


void write_other(int x,int y,int c)
{
   switch (c) {
      case 24:     /* up arrow */
         XDrawLine(dpy, pm, gctext, x+3,y+10,x+3,y+2);
         XDrawLine(dpy, pm, gctext, x+3,y+2,x+1,y+4);
         XDrawLine(dpy, pm, gctext, x+3,y+2,x+5,y+4);
         break;
      case 25:     /* down arrow */
         XDrawLine(dpy, pm, gctext, x+3,y+2,x+3,y+10);
         XDrawLine(dpy, pm, gctext, x+3,y+10,x+1,y+8);
         XDrawLine(dpy, pm, gctext, x+3,y+10,x+5,y+8);
         break;
      case 26:     /* right arrow */
         XDrawLine(dpy, pm, gctext, x+1,y+6,x+6,y+6);
         XDrawLine(dpy, pm, gctext, x+4,y+4,x+6,y+6);
         XDrawLine(dpy, pm, gctext, x+4,y+8,x+6,y+6);
         break;
      case 27:     /* left arrow */
         XDrawLine(dpy, pm, gctext, x+1,y+6,x+6,y+6);
         XDrawLine(dpy, pm, gctext, x+3,y+4,x+1,y+6);
         XDrawLine(dpy, pm, gctext, x+3,y+8,x+1,y+6);
         break;
      case 132:    /* ground; although the definition has been commented out in pfun1_21.pas, it is still used in pfmsc_21.pas (and displayed incorrectly under DOS, it seems) */
         y+=6; x+=3;
         XDrawLine(dpy, pm, gctext, x-3,y,x+3,y);
         y+=2; XDrawLine(dpy, pm, gctext, x-2,y,x+2,y);
         y+=2; XDrawLine(dpy, pm, gctext, x-1,y,x+1,y);
         break;
      case 179:    /* single vertical bar */
         XDrawLine(dpy, pm, gctext, x+3,y,x+3,y+13);
         break;
      case 184:    /* =, */
         XDrawLine(dpy, pm, gctext, x+3,y+5,x+3,y+13);
         XDrawLine(dpy, pm, gctext, x,y+7,x+3,y+7);
         XDrawLine(dpy, pm, gctext, x,y+5,x+3,y+5);
         break;
      case 186:    /* double vertical bar */
         XDrawLine(dpy, pm, gctext, x+2,y,x+2,y+13);
         XDrawLine(dpy, pm, gctext, x+4,y,x+4,y+13);
         break;
      case 187:    /* =,, */
         XDrawLine(dpy, pm, gctext, x+4,y+5,x+4,y+13);
         XDrawLine(dpy, pm, gctext, x+2,y+7,x+2,y+13);
         XDrawLine(dpy, pm, gctext, x,y+7,x+2,y+7);
         XDrawLine(dpy, pm, gctext, x,y+5,x+4,y+5);
         break;
      case 188:    /* ='' */
         XDrawLine(dpy, pm, gctext, x+2,y+5,x+2,y);
         XDrawLine(dpy, pm, gctext, x+4,y+7,x+4,y);
         XDrawLine(dpy, pm, gctext, x,y+7,x+4,y+7);
         XDrawLine(dpy, pm, gctext, x,y+5,x+2,y+5);
         break;
      case 190:    /* =' */
         XDrawLine(dpy, pm, gctext, x+3,y+7,x+3,y);
         XDrawLine(dpy, pm, gctext, x,y+7,x+3,y+7);
         XDrawLine(dpy, pm, gctext, x,y+5,x+3,y+5);
         break;
      case 200:    /* ``= */
         XDrawLine(dpy, pm, gctext, x+2,y+7,x+2,y);
         XDrawLine(dpy, pm, gctext, x+4,y+5,x+4,y);
         XDrawLine(dpy, pm, gctext, x+7,y+7,x+2,y+7);
         XDrawLine(dpy, pm, gctext, x+7,y+5,x+4,y+5);
         break;
      case 201:    /* ,,= */
         XDrawLine(dpy, pm, gctext, x+2,y+5,x+2,y+13);
         XDrawLine(dpy, pm, gctext, x+4,y+7,x+4,y+13);
         XDrawLine(dpy, pm, gctext, x+7,y+7,x+4,y+7);
         XDrawLine(dpy, pm, gctext, x+7,y+5,x+2,y+5);
         break;
      case 205:    /* double horizontal bar */
         XDrawLine(dpy, pm, gctext, x,y+5,x+7,y+5);
         XDrawLine(dpy, pm, gctext, x,y+7,x+7,y+7);
         break;
      case 212:    /* `= */
         XDrawLine(dpy, pm, gctext, x+3,y+7,x+3,y);
         XDrawLine(dpy, pm, gctext, x+7,y+7,x+3,y+7);
         XDrawLine(dpy, pm, gctext, x+7,y+5,x+3,y+5);
         break;
      case 213:    /* ,= */
         XDrawLine(dpy, pm, gctext, x+3,y+5,x+3,y+13);
         XDrawLine(dpy, pm, gctext, x+7,y+7,x+3,y+7);
         XDrawLine(dpy, pm, gctext, x+7,y+5,x+3,y+5);
         break;
      case 234:    /* Omega */
         x++; y+=10; XDrawPoint(dpy, pm, gctext, x,y);
         x++; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         x--; y--; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y--; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y--; XDrawPoint(dpy, pm, gctext, x,y);
         x++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y++; XDrawPoint(dpy, pm, gctext, x,y);
         y++; XDrawPoint(dpy, pm, gctext, x,y);
         y++; XDrawPoint(dpy, pm, gctext, x,y);
         x--; y++; XDrawPoint(dpy, pm, gctext, x,y);
         y++; XDrawPoint(dpy, pm, gctext, x,y);
         y++; XDrawPoint(dpy, pm, gctext, x,y);
         y++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; XDrawPoint(dpy, pm, gctext, x,y);
         break;
      case 235:    /* delta */
         y+=5; x+=3;
         XDrawPoint(dpy, pm, gctext, x,y);
         y++; XDrawPoint(dpy, pm, gctext, x+1,y); XDrawPoint(dpy, pm, gctext, x-1,y);
         y++; XDrawPoint(dpy, pm, gctext, x+2,y); XDrawPoint(dpy, pm, gctext, x-2,y);
         y++; XDrawPoint(dpy, pm, gctext, x+3,y); XDrawPoint(dpy, pm, gctext, x-3,y);
         y++; XDrawLine(dpy, pm, gctext, x-3,y,x+3,y);
         break;
      case 236:   /* infinity */
         y+=8; x+=3; 
         XDrawPoint(dpy, pm, gctext, x,y);
         x--; y++; XDrawPoint(dpy, pm, gctext, x,y);
         x--; XDrawPoint(dpy, pm, gctext, x,y);
         x--; y--; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y--; XDrawPoint(dpy, pm, gctext, x,y);
         x++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; XDrawPoint(dpy, pm, gctext, x,y);
         x++; y--; XDrawPoint(dpy, pm, gctext, x,y);
         y--; XDrawPoint(dpy, pm, gctext, x,y);
         x--; y--; XDrawPoint(dpy, pm, gctext, x,y);
         x--; XDrawPoint(dpy, pm, gctext, x,y);
         x--; y++; XDrawPoint(dpy, pm, gctext, x,y);
         break;
      default:
         fprintf(stderr,"NOT IMPLEMENTED: write_other(%i,%i,%i)\n",c,x,y);
   }
}

void DoWrite(unsigned char *s)
{
   int x,y;
   unsigned char *p;
   int newline=0;

   x=(crtX-1)*8;
   y=(crtY-1)*14;

   if (memcmp(s,"\x03\x08 \x08",4)==0) {
      XFillRectangle(dpy, pm, gcclear, x-8,y,8,14);
      crtX--;
      return;
   }

   XFillRectangle(dpy, pm, gcclear, x,y,8*s[0],14);

   p=s+1;
   while (p<=s+s[0]) {
      switch (*p) {
         case 10:
             newline=1;
             if (p!=s+s[0]) fprintf(stderr,"NOT IMPLEMENTED: newline in middle of string");
             s[0]--;
             break;
         case 248: *p=176; break; /* degree */
         case 230: *p=181; break; /* mu */
         default: if (*p<32 || *p>127) { write_other(x+8*(p-s-1), y, *p); *p=' '; }
      }
      p++;
   }

   XDrawString(dpy,pm,gctext,x,y+fontyoffs,s+1,s[0]);
   crtX+=s[0];
   if (newline) { crtX=crtXmin; crtY++; }

   drawcounter++;
}

void DoWriteEnd(void)
{
}





void getpascalcolours()
{
   XColor xc;
   Colormap cm;
   int i,on;

   cm=DefaultColormap(dpy,scr);
   for (i=0;i<16;i++) {
      if (i>=8) on=65535; 
      else if (i==7) on=49052;  // exception to make the much-used grey colour a bit brighter
      else on=32768;
      xc.blue = (i&1)?on:0;
      xc.green = (i&2)?on:0;
      xc.red = (i&4)?on:0;
      XAllocColor(dpy,cm,&xc);
      pascalcolours[i]=xc.pixel;
   }
}


void init_x(void)
{
   XGCValues xgcv;
   XFontStruct *fontinfo;
   int i;

   dpy=XOpenDisplay(NULL);
   if (dpy==NULL) {
      fprintf(stderr,"Could not open display; is the DISPLAY variable set correctly?\n");
      exit(1);
   }
   scr=DefaultScreen(dpy);

   width=900; height=600;
   ScreenWidth=width;
   ScreenHeight=height;
   vp.x2=width-1;
   vp.y2=height-1;

   // create our window
   w=XCreateWindow(dpy,RootWindow(dpy,scr),-1,-1, width, height, 0, CopyFromParent, InputOutput, CopyFromParent, 0, NULL);
   XMapWindow(dpy,w);
   XStoreName(dpy,w,"puff");

   // create a background pixmap, that we're actually going to use for everything, because then the xserver takes care of redrawing the window when it is uncovered
   XGetWindowAttributes(dpy,w,&wa);
   pm=XCreatePixmap(dpy, RootWindow(dpy,scr),wa.width,wa.height,wa.depth);
   XSetWindowBackgroundPixmap(dpy,w,pm);

   // tell the window manager that we don't want to be resized to less than 640x480 (the old VGA resolution)
   XSizeHints* win_size_hints = XAllocSizeHints();
   win_size_hints->flags = PMinSize;
   win_size_hints->min_width = 640;
   win_size_hints->min_height = 480;
   XSetWMNormalHints(dpy, w, win_size_hints);
   XFree(win_size_hints);

   // allocate 16 memory places to temporarily store pieces of the drawing
   for (i=0;i<16;i++) boxes[i]=XCreatePixmap(dpy, RootWindow(dpy,scr),32,32,wa.depth);

   // create several graphics contexts
   xgcv.foreground=WhitePixel(dpy,scr);
   xgcv.background=BlackPixel(dpy,scr);
   xgcv.function=GXcopy;
   gc = XCreateGC(dpy, w, GCForeground|GCBackground|GCFunction, &xgcv);
   XSetLineAttributes(dpy, gc, 1, LineSolid, CapRound, JoinRound);

   xgcv.foreground=BlackPixel(dpy,scr);
   xgcv.background=WhitePixel(dpy,scr);
   xgcv.function=GXcopy;
   gcclear = XCreateGC(dpy, w, GCForeground|GCBackground|GCFunction, &xgcv);

   gcpixel = XCreateGC(dpy, w, 0, &xgcv);

   xgcv.foreground=WhitePixel(dpy,scr);
   xgcv.background=BlackPixel(dpy,scr);
   xgcv.function=GXcopy;
   gctext = XCreateGC(dpy, w, GCForeground|GCBackground|GCFunction, &xgcv);

   xgcv.background=WhitePixel(dpy,scr);
   xgcv.foreground=BlackPixel(dpy,scr);
   xgcv.function=GXcopy;
   gcfill = XCreateGC(dpy, w, GCForeground|GCBackground|GCFunction, &xgcv);
   XSetLineAttributes(dpy, gcfill, 1000, LineSolid, CapRound, JoinRound);    // very thick line, see FloodFill() for explanation

   // clear the screen
   XFillRectangle(dpy, pm, gcfill, 0,0,ScreenWidth,ScreenHeight);
   XClearWindow(dpy,w);

   // load an 8x13 font; the VGA font on which the partitioning of the screen is based is an 8x14 font
   fontinfo=XLoadQueryFont(dpy,"8x13");
   XSetFont(dpy,gctext,fontinfo->fid);
   XSetFont(dpy,gc,fontinfo->fid);
   fontyoffs=fontinfo->ascent;

   // allocate a set of colours corresponding to those of the VGA mode originally used by puff
   getpascalcolours();

   XSelectInput(dpy,w,KeyPressMask|KeyReleaseMask|StructureNotifyMask);

   XFlush(dpy);
}


void GetBox(int bn,int x,int y,int width,int height)
{
   XCopyArea(dpy, pm, boxes[bn], gc, x, y, width, height, 0, 0);
}

void PutBox(int bn,int x,int y,int width,int height)
{
   XCopyArea(dpy, boxes[bn], pm, gc, 0, 0, width, height, x, y);
}




/* below are a few other routines, unrelated to the 'crt' and 'graph' units,
   but needed anyway to compile PUFF on Linux/X11.
*/

int GetTimerTicks(void)
{
   struct timeval tv;
   struct timezone tz;
   gettimeofday(&tv, &tz);
   return (tv.tv_sec&0xffffff)*18.2+tv.tv_usec*18.2/1000000;
}




