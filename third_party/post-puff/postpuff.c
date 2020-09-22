// postpuff.c PostPuff is a simple tool to calculate  K and D from a Puff file.

/*
 *      This program is free software: you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation, either version 3 of the License, or
 *      (at your option) any later version.
 * 
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      You should have received a copy of the GNU General Public License
 *      along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <math.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <complex.h>

#include <gtk/gtk.h>

#include <cairo/cairo.h>

#define MAXLEN 200
#define MAXDATA 1001
#define RAD 180.0/ M_PI
#define SIZEX 800.0
#define SIZEY 600.0

#define PROGRAM "POST-PUFF"
#define VERSION  "v 1.3a GTK"
#define COPYRIGHT "Andreas Fischer 1994-2017"
#define COMMENT "Post-Puff is a simple tool to calculate  K and D from a Puff file."
#define URI "https://github.com/andi-f/post-puff"

//#define DEBUG

GtkWidget *label;
FILE		*fp;					// filehandle */
const 		gchar	*file;			// filename */

int type;							// selected type of plot

double		puff_du;  	 			// upper dB-axis limit
double		puff_dl;  	  			// lower dB-axis limit
double   	puff_fl;		 		// lower frequency limit. fl>=0
double		puff_fu;	  			// upper frequency limit. fu>fl
unsigned int pts;					// plot points 

int			n = 0;					// counter */
int 		spara_line = 0;			// line counter */
int			m = 0;					// counter Cario */


char		*ptr;	

typedef struct _components {
		GtkWidget *window;
		GtkWidget *menubar1;
		GtkWidget *vbox1;
		GtkWidget *menu_file;
		GtkWidget *menuitem_file;
		GtkWidget *menu_plot;
		GtkWidget *menuitem_plot;
		GtkWidget *menu_png;
		GtkWidget *menuitem_png;
		GtkWidget *menu_about;
		GtkWidget *menuitem_about;
		GtkWidget *drawingArea;
		GtkWidget *vbox2;
} components;

static components this;

gint width = 1024, height = 768;	/* Window width & height */
	
typedef struct sdata
{
	double	qrg,
		s11,
		s11_dec,
		s12,
		s12_dec,
		s21,
		s21_dec,
		s22,
		s22_dec,
		K,
		D;
} sdata;

sdata spara[MAXDATA];

enum {
  None,
  S_parameter,
  K_parameter,
  D_parameter
};

static void createWindow();
static void destroy( GtkWidget *widget,gpointer data );

//Call Back
static void menuitem_open();
void about(GtkWidget *widget, gpointer data);
void file_ok_proc(GtkWidget *widget, gpointer data);
void s_para(GtkWidget *widget, gpointer data);
void k_para(GtkWidget *widget, gpointer data);
void d_para(GtkWidget *widget, gpointer data);
void s_para_png(GtkWidget *widget, gpointer data);
void k_para_png(GtkWidget *widget, gpointer data);
void d_para_png(GtkWidget *widget, gpointer data);

static gboolean on_expose_event(GtkWidget *widget, GdkEventExpose *event, gpointer data);

//Calculate K
void k_calc(sdata *actuell_value);

int main(int argc, char *argv[]) {

	gtk_init(&argc, &argv);

	createWindow();
		
	this.vbox1 = gtk_vbox_new(FALSE, 0);
	gtk_container_add(GTK_CONTAINER(this.window), this.vbox1);

	this.menubar1 = gtk_menu_bar_new();
	gtk_box_pack_start(GTK_BOX(this.vbox1), this.menubar1, FALSE, FALSE, 2);


	//File
	this.menu_file = gtk_menu_new();

	this.menuitem_file = gtk_menu_item_new_with_label("Open");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_file), "activate",
                     GTK_SIGNAL_FUNC(menuitem_open),"Load");
	gtk_menu_append(GTK_MENU(this.menu_file), this.menuitem_file);

	this.menuitem_file = gtk_menu_item_new_with_label("Quit");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_file), "activate",
                     GTK_SIGNAL_FUNC(gtk_main_quit), NULL);
	gtk_menu_append(GTK_MENU(this.menu_file), this.menuitem_file);

	this.menuitem_file = gtk_menu_item_new_with_label("File");
	gtk_menu_item_set_submenu(GTK_MENU_ITEM(this.menuitem_file),
			    this.menu_file);
	gtk_menu_bar_append(GTK_MENU_BAR(this.menubar1), this.menuitem_file);


	//On Screen
	this.menu_plot = gtk_menu_new();

	this.menuitem_plot = gtk_menu_item_new_with_label("S-Para");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_plot), "activate",
                     GTK_SIGNAL_FUNC(s_para),"S-Para");
	gtk_menu_append(GTK_MENU(this.menu_plot), this.menuitem_plot);

	this.menuitem_plot = gtk_menu_item_new_with_label("K-Para");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_plot), "activate",
                     GTK_SIGNAL_FUNC(k_para),"K-Para");
	gtk_menu_append(GTK_MENU(this.menu_plot), this.menuitem_plot);

	this.menuitem_plot = gtk_menu_item_new_with_label("D-Para");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_plot), "activate",
                     GTK_SIGNAL_FUNC(d_para),"D-Para");
	gtk_menu_append(GTK_MENU(this.menu_plot), this.menuitem_plot);

	this.menuitem_plot = gtk_menu_item_new_with_label("Plot");
	gtk_menu_item_set_submenu(GTK_MENU_ITEM(this.menuitem_plot),
			    this.menu_plot);
	gtk_menu_bar_append(GTK_MENU_BAR(this.menubar1), this.menuitem_plot);


	//PNG
	this.menu_png = gtk_menu_new();

	this.menuitem_png = gtk_menu_item_new_with_label("S-Para");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_png), "activate",
                     GTK_SIGNAL_FUNC(s_para_png),"S-Para");
	gtk_menu_append(GTK_MENU(this.menu_png), this.menuitem_png);

	this.menuitem_png = gtk_menu_item_new_with_label("K-Para");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_png), "activate",
                     GTK_SIGNAL_FUNC(k_para_png),"K-Para");
	gtk_menu_append(GTK_MENU(this.menu_png), this.menuitem_png);

	this.menuitem_png = gtk_menu_item_new_with_label("D-Para");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_png), "activate",
                     GTK_SIGNAL_FUNC(d_para_png),"D-Para");
	gtk_menu_append(GTK_MENU(this.menu_png), this.menuitem_png);
	
	this.menuitem_png = gtk_menu_item_new_with_label("Create PNG");
	gtk_menu_item_set_submenu(GTK_MENU_ITEM(this.menuitem_png),
			    this.menu_png);
	gtk_menu_bar_append(GTK_MENU_BAR(this.menubar1), this.menuitem_png);


	//About
	this.menu_about = gtk_menu_new();
	this.menuitem_about = gtk_menu_item_new_with_label("Info");
	gtk_signal_connect(GTK_OBJECT(this.menuitem_about), "activate",
                     GTK_SIGNAL_FUNC(about), "Info");
	gtk_menu_append(GTK_MENU(this.menu_about), this.menuitem_about);

	this.menuitem_about = gtk_menu_item_new_with_label("About");
	gtk_menu_item_set_submenu(GTK_MENU_ITEM(this.menuitem_about),
			    this.menu_about);
	gtk_menu_bar_append(GTK_MENU_BAR(this.menubar1), this.menuitem_about);

	
	this.drawingArea = gtk_drawing_area_new();
	gtk_box_pack_start (GTK_BOX(this.vbox1), this.drawingArea, TRUE, TRUE, 0);    	
	g_signal_connect(this.drawingArea, "expose-event", G_CALLBACK(on_expose_event), NULL);
	gtk_widget_set_app_paintable(this.drawingArea, TRUE);

	type = None;
	
	gtk_widget_show_all(this.window);

	gtk_main();

	return(0);
 }

// Callback for about
void about(GtkWidget *widget, gpointer data)
 {
  GtkWidget *dialog = gtk_about_dialog_new();
  gtk_about_dialog_set_name(GTK_ABOUT_DIALOG(dialog), PROGRAM);
  gtk_about_dialog_set_version(GTK_ABOUT_DIALOG(dialog), VERSION); 
  gtk_about_dialog_set_copyright(GTK_ABOUT_DIALOG(dialog), COPYRIGHT);
  gtk_about_dialog_set_comments(GTK_ABOUT_DIALOG(dialog), COMMENT);
  gtk_about_dialog_set_website(GTK_ABOUT_DIALOG(dialog), URI);
  gtk_dialog_run(GTK_DIALOG (dialog));
  gtk_widget_destroy(dialog);
 }

void k_calc(sdata *actuell_spara) {

	double real_part;
	double imag_part;
	
	double complex s11_c;				// s-para as a complex value
	double complex s12_c;				// s-para as a complex value
	double complex s21_c;				// s-para as a complex value
	double complex s22_c;				// s-para as a complex value
	double complex delta;				// delta as a complex value
	double K;							// K

	real_part = actuell_spara->s11 * cos(actuell_spara->s11_dec * M_PI/180.0);
	imag_part = actuell_spara->s11 * sin(actuell_spara->s11_dec * M_PI/180.0);
	
	s11_c = real_part + imag_part * I;
	
	real_part = actuell_spara->s12 * cos(actuell_spara->s12_dec * M_PI/180.0);
	imag_part = actuell_spara->s12 * sin(actuell_spara->s12_dec *M_PI/180.0); 
	
	s12_c = real_part + imag_part * I;

	real_part = actuell_spara->s21 * cos(actuell_spara->s21_dec * M_PI/180.0);
	imag_part = actuell_spara->s21 * sin(actuell_spara->s21_dec * M_PI/180.0); 

	s21_c = real_part + imag_part * I;

	real_part = actuell_spara->s22 * cos(actuell_spara->s22_dec * M_PI/180.0);
	imag_part = actuell_spara->s22 * sin(actuell_spara->s22_dec * M_PI/180.0); 
	
	s22_c = real_part + imag_part * I;

	// Calculate Rollet's K-factor from S-parameters
    
	delta = cabs(s11_c * s22_c - s12_c * s21_c);
	
	K = (1 - pow(cabs(s11_c),2) - pow(cabs(s22_c),2) + pow(delta,2) ) / 2.0 / cabs(s12_c * s21_c);
	
	actuell_spara->D = delta;
	actuell_spara->K = K;

	return;
}

// Callback for file-select
void file_ok_proc(GtkWidget *widget, gpointer data)
{
	int i;
	char *sp[] = {"S11","S21", "S12", "S22"};
	int nspars = 0;
	char tmp[5][4];
	sdata  *sdata_ptr;					// Pointer for actuell data
	char		buf[MAXLEN];			// line buffer
	
	char		board = FALSE;			// flag board-Parameter active
	char		key = FALSE;			// flag plot-Parameter active
	//char		parts = FALSE;			// flag part-Beschreibung active
	char		sparameter = FALSE;		// flag S-Parameter active
	//char		circuit = FALSE;		// flag circuit active
	
	file =  gtk_file_selection_get_filename( GTK_FILE_SELECTION(data));
	
	gtk_widget_hide(data);

	if ( (fp = fopen(file,"r")) == NULL )
	{
		fprintf(stderr,"can't read file %s \n\r",file);
		type = None;
		return;
	}

	n = 0;

	while ( fgets(buf,MAXLEN,fp) != NULL)
	{
		buf[79] = 0x00;
		
		ptr = &buf[0];
		
		if((*ptr) == '\\')
		{
			ptr ++;

			if( (*ptr) == 'b' )
			{
				board = TRUE;
				key = FALSE;
				// parts = FALSE;
				sparameter = FALSE;
				// circuit = FALSE;
			}
			else
			if( (*ptr) == 'k' )
			{
				board = FALSE;
				key = TRUE;
				// parts = FALSE;
				sparameter = FALSE;
				// circuit = FALSE;
			}
			else
			if( (*ptr) == 'p' )
			{
				board = FALSE;
				key = FALSE;
				// parts = TRUE;
				sparameter = FALSE;
				// circuit = FALSE;
			}
			else
			if( (*ptr) == 's' )
			{
				board = FALSE;
				key = FALSE;
				// parts = FALSE;
				sparameter = TRUE;
				spara_line = 0u;
				// circuit = FALSE;
			}
			else
			if( (*ptr) == 'c' )
			{
				board = FALSE;
				key = FALSE;
				// parts = FALSE;
				sparameter = FALSE;
				// circuit = TRUE;
			}
		}

		if( board == TRUE)
		{
		}

		if( key == TRUE)
		{
			if( (*ptr) == 0x20)
				ptr ++;

			if( (*ptr) == 'f')
			{
				ptr ++;
				if( (*ptr) == 'u')
					puff_fu = atof(++ptr);
				else
				if( (*ptr) == 'l')
					puff_fl = atof(++ptr);
			}
			else
			if( (*ptr) == 'd')
			{
				ptr++;
				if( (*ptr) == 'u')
				{
					puff_du = atof(++ptr);
				}
				else
				if( (*ptr) == 'l')
				{
					puff_dl = atof(++ptr);
				}
			}
			else
			if( (*ptr) == 'p')
			{
				ptr++;
				if( (*ptr) == 't')
					ptr++;
				if( (*ptr) == 's')
					pts = atoi(++ptr);
			}
			
		}

		if( sparameter == TRUE)
		{
			spara_line ++;
		
			if( (spara_line == 2) )
			{			
				
				sscanf(buf, "%s %s %s %s %s", tmp[0], tmp[1], tmp[2], tmp[3], tmp[4]);
			    for (i=0; i<4; i++)
			    {
						if ((strcmp(sp[i], tmp[i+1])) == 0)
						{
							nspars++;
						}
				}
	
				if (nspars != 4)
				{
					printf("%s is missing! Need %s %s %s %s.\n", sp[nspars-1],sp[0],sp[1],sp[2],sp[3]);
					fclose(fp);
					return;
				}
			
			}
				
			if( (spara_line > 2) )
			{			
				sscanf(buf,"%lf %lf %lf %lf %lf %lf %lf %lf %lf",
					&spara[n].qrg,
					&spara[n].s11,
					&spara[n].s11_dec,
					&spara[n].s21,
					&spara[n].s21_dec,
					&spara[n].s12,
					&spara[n].s12_dec,
					&spara[n].s22,
					&spara[n].s22_dec);
					
				sdata_ptr = &spara[n]; 
				k_calc(sdata_ptr);
#ifdef DEBUG
				printf("%lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf\n\r",
					spara[n].qrg,
					spara[n].s11,
					spara[n].s11_dec,
					spara[n].s21,
					spara[n].s21_dec,
					spara[n].s12,
					spara[n].s12_dec,
					spara[n].s22,
					spara[n].s22_dec,
					spara[n].D,
					spara[n].K);
#endif
									
				n ++;					
			}
		}
	}
	fclose(fp);
		
	return;
}
 
// Callback for S
void s_para(GtkWidget *widget, gpointer data) {

	type = S_parameter;
		 
	gtk_widget_queue_draw_area(this.window, 0, 0, width, height);

  return;
 }
 
 // Callback for K
void k_para(GtkWidget *widget, gpointer data) {

	type = K_parameter;

	gtk_widget_queue_draw_area(this.window, 0, 0, width, height);


  return;
 }  

// Callback for D
void d_para(GtkWidget *widget, gpointer data) {

	type = D_parameter;
	
	gtk_widget_queue_draw_area(this.window, 0, 0, width, height);

  return;
 }

 
// Callback for S PNG
void s_para_png(GtkWidget *widget, gpointer data) {
	double		A;						// actual value
	
	double		X_DIV = 10.0;			// 10 div/x
	double		Y_DIV = 10.0;			// 10 div/y

	double		MAX_f = 12.0;			// max. frequency
	double		MIN_f = 2.0;			// min frequency

	double 		XMAX;					// max dots x-scale
	double 		YMAX;					// max dots y-scale
	double 		XOFFSET;				// start of diagramm
	double		YOFFSET;				// start of diagramm
	double		x, y;					// actual plot postion
	double		x_alt,y_alt;			// last plot postion
	double		x_scale,y_scale;		// scale for axis
	double		x_zero,y_zero;			// point of origin
	char		buf[MAXLEN];			// line buffer
	
	cairo_surface_t *surface;
	cairo_t *cr;

	surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, SIZEX, SIZEY);
	cr = cairo_create(surface);

	cairo_rectangle(cr, 0.0, 0.0, SIZEX, SIZEY);
	cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
	cairo_fill(cr);

	cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
 
	cairo_set_font_size(cr, 10.0);
	cairo_set_line_width(cr, 1.0);

	XMAX = 0.8 * SIZEX;
	YMAX = 0.8 * SIZEY;

	XOFFSET = 0.5 * (SIZEX-XMAX);
	YOFFSET = 0.5 * (SIZEY-YMAX);

	if((puff_fu == 0) || (puff_fl == 0)) {
		MAX_f = 1;
		MIN_f = 12;
	}	
	else {
		MAX_f = puff_fu;
		MIN_f = puff_fl;
	}

	if((puff_du == 0) || (puff_dl == 0)) {
		puff_du = 20;
		puff_dl = -20;
	}	
	
	x_scale = XMAX / (MAX_f-MIN_f);
	y_scale = YMAX / (puff_du-puff_dl);		

	x_zero = - MIN_f * x_scale + XOFFSET;
	y_zero = YMAX + puff_dl * y_scale + YOFFSET;

	cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
	
	sprintf(buf,"%s %s",PROGRAM,VERSION);
	cairo_move_to (cr,10, 0.2* YOFFSET);
	cairo_show_text(cr, buf); 	

	cairo_move_to(cr,XMAX-XOFFSET,0.2 * YOFFSET);
	cairo_show_text(cr, file); 	

	cairo_stroke(cr);

	y_scale = YMAX / (puff_du-puff_dl);		
	
	cairo_move_to(cr,XOFFSET+XMAX/2, 0.2 * YOFFSET);
	cairo_show_text(cr,"S-PARAMETER");

	for(m = 0; m < X_DIV+1;m ++)
	{
		x =  m * XMAX / X_DIV + XOFFSET;
		if( (x >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x,YOFFSET);
			cairo_line_to(cr,x,YMAX+YOFFSET);
		
			if(m == (m/2*2))
			{
				sprintf(buf,"%2.3f",m / X_DIV * (MAX_f-MIN_f) + MIN_f);
				cairo_move_to(cr,x-20,YOFFSET+YMAX+10);
				cairo_show_text(cr, buf); 	
			}
		}
	}

	cairo_move_to(cr,XMAX /2 + XOFFSET,YOFFSET+YMAX+20);
	cairo_show_text(cr,"f/[GHz]"); 	

	for(m = 0; m < Y_DIV+1;m ++)
	{
		y = m * YMAX / Y_DIV + YOFFSET;
		cairo_move_to(cr,XOFFSET,y);
		cairo_line_to (cr,XMAX+XOFFSET,y);
	
		sprintf(buf,"% 3.1f",puff_du - m / Y_DIV * (puff_du-puff_dl) );
		cairo_move_to(cr,20,y);
		cairo_show_text(cr, buf); 	
	}

	cairo_move_to(cr,0,YMAX/2+YOFFSET);
	cairo_show_text(cr,"dB"); 	
	cairo_stroke(cr);
		
	cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
	cairo_move_to(cr,XOFFSET,0.4 * YOFFSET);
	cairo_show_text(cr,"s11"); 	
	cairo_stroke(cr);
		
	A = 20 * log10(spara[0].s11);
	if(A > puff_du)
	{
		A = puff_du;
	}
	else
	if(A < puff_dl)
	{
		A = puff_dl;
	}

	x_alt =  x_zero + spara[0].qrg * x_scale;
	y_alt =  y_zero - A * y_scale;

	for(m = 1; m <= (n-1); m ++)
	{

		A = 20 * log10(spara[m].s11);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x =  x_zero + spara[m].qrg * x_scale;
		y =  y_zero - A * y_scale;

		if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x_alt,y_alt);
			cairo_line_to (cr,x,y);
		}				
		x_alt = x;
		y_alt = y;
	}

	cairo_stroke(cr);

	cairo_set_source_rgb(cr, 0.0, 1.0, 0.0);
	cairo_move_to(cr,XOFFSET,0.6 * YOFFSET);
	cairo_show_text(cr,"s22"); 	
	cairo_stroke(cr);

	A = 20 * log10(spara[0].s22);
	if(A > puff_du)
	{
		A = puff_du;
	}
	else
	if(A < puff_dl)
	{
		A = puff_dl;
	}
	x_alt = x_zero + spara[0].qrg * x_scale;
	y_alt = y_zero - A * y_scale;

	for(m = 1; m <= (n-1); m ++)
	{
		A = 20 * log10(spara[m].s22);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x =  x_zero + spara[m].qrg * x_scale;
		y =  y_zero - A * y_scale;
		if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x_alt,y_alt);
			cairo_line_to (cr,x,y);
		}				
		x_alt = x;
		y_alt = y;
	}
	cairo_stroke(cr);

	cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
	cairo_move_to(cr,2 * XOFFSET,0.4 * YOFFSET);
	cairo_show_text(cr,"s21"); 	
	cairo_stroke(cr);
	
	A = 20 * log10(spara[0].s21);
	if(A > puff_du)
	{
		A = puff_du;
	}
	else
	if(A < puff_dl)
	{
		A = puff_dl;
	}
	x_alt =  x_zero + spara[0].qrg * x_scale;
	y_alt =  y_zero - A * y_scale;

	for(m = 1; m <= (n-1); m ++)
	{
		A = 20 * log10(spara[m].s21);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x =  x_zero + spara[m].qrg * x_scale;
		y =  y_zero - A * y_scale;
		if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x_alt,y_alt);
			cairo_line_to (cr,x,y);
		}				
		x_alt = x;
		y_alt = y;
	}
	cairo_stroke(cr);

	cairo_set_source_rgb(cr, 1.0, 0.0, 1.0);
	cairo_move_to(cr,2 * XOFFSET,0.6 * YOFFSET);
	cairo_show_text(cr,"s12"); 	
	cairo_stroke(cr);
	A = 20 * log10(spara[0].s12);
	if(A > puff_du)
	{
		A = puff_du;
	}
	else
	if(A < puff_dl)
	{
		A = puff_dl;
	}
	x_alt =  x_zero + spara[0].qrg * x_scale;
	y_alt =  y_zero - A * y_scale;
	for(m = 1; m <= (n-1); m ++)
	{
		A = 20 * log10(spara[m].s12);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x =  x_zero + spara[m].qrg * x_scale;
		y =  y_zero -  A * y_scale;
		if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x_alt,y_alt);
			cairo_line_to (cr,x,y);
		}				
		x_alt = x;
		y_alt = y;
	}
	cairo_stroke(cr);		

	strcpy(buf,file);
	strcat(buf,"-S-Para.png");
	cairo_surface_write_to_png(surface, buf);
	
	cairo_surface_destroy(surface);

	return;
 }

// Callback for K PNG
void k_para_png(GtkWidget *widget, gpointer data) {
	double		K;						// actual value
	
	double		X_DIV = 10.0;			// 10 div/x
	double		Y_DIV = 10.0;			// 10 div/y

	double		MAX_K = 2.0;			// max K scale
	double		MIN_K = 0.0;			// min K scale

	double		MAX_f = 12.0;			// max. frequency
	double		MIN_f = 2.0;			// min frequency

	double 		XMAX;					// max dots x-scale
	double 		YMAX;					// max dots y-scale
	double 		XOFFSET;				// start of diagramm
	double		YOFFSET;				// start of diagramm
	double		x, y;					// actual plot postion
	double		x_alt,y_alt;			// last plot postion
	double		x_scale,y_scale;		// scale for axis
	double		x_zero,y_zero;			// point of origin
	char		buf[MAXLEN];			// line buffer
	
	cairo_surface_t *surface;
	cairo_t *cr;

	surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, SIZEX, SIZEY);
	cr = cairo_create(surface);
	
	cairo_rectangle(cr, 0.0, 0.0, SIZEX, SIZEY);
	cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
	cairo_fill(cr);

	cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
 
	cairo_set_font_size(cr, 10.0);
	cairo_set_line_width(cr, 1.0);

	XMAX = 0.8 * SIZEX;
	YMAX = 0.8 * SIZEY;

	XOFFSET = 0.5 * (SIZEX-XMAX);
	YOFFSET = 0.5 * (SIZEY-YMAX);

	if((puff_fu == 0) || (puff_fl == 0)) {
		MAX_f = 1;
		MIN_f = 12;
	}	
	else {
		MAX_f = puff_fu;
		MIN_f = puff_fl;
	}

	if((puff_du == 0) || (puff_dl == 0)) {
		puff_du = 20;
		puff_dl = -20;
	}	
	
	x_scale = XMAX / (MAX_f-MIN_f);
	y_scale = YMAX / (puff_du-puff_dl);		

	x_zero = - MIN_f * x_scale + XOFFSET;
	y_zero = YMAX + puff_dl * y_scale + YOFFSET;

	cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
	
	sprintf(buf,"%s %s",PROGRAM,VERSION);
	cairo_move_to (cr,10, 0.2* YOFFSET);
	cairo_show_text(cr, buf); 	

	cairo_move_to(cr,XMAX-XOFFSET,0.2 * YOFFSET);
	cairo_show_text(cr, file); 	

	cairo_stroke(cr);

		
	y_scale = YMAX / (MAX_K-MIN_K);
	y_zero = YMAX + MIN_K * y_scale + YOFFSET;
		
	cairo_move_to(cr,XOFFSET+XMAX/2, 0.2 * YOFFSET);
	cairo_show_text(cr,"K-PARAMETER");

	for(m = 0; m < X_DIV+1;m ++)
	{
		x =  m * XMAX / X_DIV + XOFFSET;
		if( (x >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x,YOFFSET);
			cairo_line_to(cr,x,YMAX+YOFFSET);
		
			if(m == (m/2*2))
			{
				sprintf(buf,"%2.3f",m / X_DIV * (MAX_f-MIN_f) + MIN_f);
				cairo_move_to(cr,x-20,YOFFSET+YMAX+10);
				cairo_show_text(cr, buf); 	
			}
		}
	}

	cairo_move_to(cr,XMAX /2 + XOFFSET,YOFFSET+YMAX+20);
	cairo_show_text(cr,"f/[GHz]"); 	

	for(m = 0; m < Y_DIV+1;m ++)
	{
		y = m * YMAX / Y_DIV + YOFFSET;

		cairo_move_to(cr,XOFFSET,y);
		cairo_line_to (cr,XMAX+XOFFSET,y);
		
		sprintf(buf,"% 3.1f",MAX_K- m / Y_DIV * (MAX_K-MIN_K) );
		cairo_move_to(cr,20,y);
		cairo_show_text(cr, buf); 	
	}

	cairo_move_to(cr,0,YMAX/2+YOFFSET);
	cairo_show_text(cr,""); 	
	cairo_stroke(cr);
	
	K = spara[0].K;

	if(K > MAX_K)
	{
		K = MAX_K;
	}
	else
	if(K < MIN_K)
	{
		K = MIN_K;
	}
	
	x_alt =  x_zero + spara[0].qrg * x_scale;
	y_alt =  y_zero - K * y_scale;

	for(m = 1; m <= (n-1); m ++)
	{
		cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
			
		K = spara[m].K;	
		
		if(K < 1.0)
		{
			cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);	
		}
	
		if(spara[m].K > MAX_K)
		{
			K = MAX_K;
		}
		else
		if(spara[m].K < MIN_K)
		{
			K = MIN_K;
		}

		x =  x_zero + spara[m].qrg * x_scale;
		y =  y_zero - K * y_scale;
		if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x_alt,y_alt);
			cairo_line_to (cr,x,y);
		}				
		x_alt = x;
		y_alt = y;
	}
	cairo_stroke(cr);

	strcpy(buf,file);
	strcat(buf,"-K-Para.png");
	cairo_surface_write_to_png(surface, buf);
	
	cairo_surface_destroy(surface);

	return;
 }

// Callback for D PNG
void d_para_png(GtkWidget *widget, gpointer data) {
	double		D;						// actual value
	
	double		X_DIV = 10.0;			// 10 div/x
	double		Y_DIV = 10.0;			// 10 div/y

	double		MAX_D = 2.0;			// max K scale
	double		MIN_D = 0.0;			// min K scale

	double		MAX_f = 12.0;			// max. frequency
	double		MIN_f = 2.0;			// min frequency

	double 		XMAX;					// max dots x-scale
	double 		YMAX;					// max dots y-scale
	double 		XOFFSET;				// start of diagramm
	double		YOFFSET;				// start of diagramm
	double		x, y;					// actual plot postion
	double		x_alt,y_alt;			// last plot postion
	double		x_scale,y_scale;		// scale for axis
	double		x_zero,y_zero;			// point of origin
	char		buf[MAXLEN];			// line buffer
	
	cairo_surface_t *surface;
	cairo_t *cr;

	surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, SIZEX, SIZEY);
	cr = cairo_create(surface);
	
	cairo_rectangle(cr, 0.0, 0.0, SIZEX, SIZEY);
	cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
	cairo_fill(cr);

	cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
 
	cairo_set_font_size(cr, 10.0);
	cairo_set_line_width(cr, 1.0);

	XMAX = 0.8 * SIZEX;
	YMAX = 0.8 * SIZEY;

	XOFFSET = 0.5 * (SIZEX-XMAX);
	YOFFSET = 0.5 * (SIZEY-YMAX);	
	
	if((puff_fu == 0) || (puff_fl == 0)) {
		MAX_f = 1;
		MIN_f = 12;
	}	
	else {
		MAX_f = puff_fu;
		MIN_f = puff_fl;
	}

	if((puff_du == 0) || (puff_dl == 0)) {
		puff_du = 20;
		puff_dl = -20;
	}	
	
	x_scale = XMAX / (MAX_f-MIN_f);
	y_scale = YMAX / (puff_du-puff_dl);		

	x_zero = - MIN_f * x_scale + XOFFSET;
	y_zero = YMAX + puff_dl * y_scale + YOFFSET;

	cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
	
	sprintf(buf,"%s %s",PROGRAM,VERSION);
	cairo_move_to (cr,10, 0.2* YOFFSET);
	cairo_show_text(cr, buf); 	

	cairo_move_to(cr,XMAX-XOFFSET,0.2 * YOFFSET);
	cairo_show_text(cr, file); 	

	cairo_stroke(cr);

	y_scale = YMAX / (MAX_D-MIN_D);
	y_zero = YMAX + MIN_D * y_scale + YOFFSET;
			
	cairo_move_to(cr,XOFFSET+XMAX/2, 0.2 * YOFFSET);
	cairo_show_text(cr,"D-PARAMETER");
	
	for(m = 0; m < X_DIV+1;m ++) {
		x =  m * XMAX / X_DIV + XOFFSET;
		if( (x >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x,YOFFSET);
			cairo_line_to(cr,x,YMAX+YOFFSET);
		
			if(m == (m/2*2)) {
				sprintf(buf,"%2.3f",m / X_DIV * (MAX_f-MIN_f) + MIN_f);
				cairo_move_to(cr,x-20,YOFFSET+YMAX+10);
				cairo_show_text(cr, buf); 	
			}
		}
	}

	cairo_move_to(cr,XMAX /2 + XOFFSET,YOFFSET+YMAX+20);
	cairo_show_text(cr,"f/[GHz]"); 	

	for(m = 0; m < Y_DIV+1;m ++) {
		y = m * YMAX / Y_DIV + YOFFSET;
		
		cairo_move_to(cr,XOFFSET,y);
		cairo_line_to (cr,XMAX+XOFFSET,y);
		
		sprintf(buf,"% 3.1f",MAX_D - m / Y_DIV * (MAX_D-MIN_D) );
		cairo_move_to(cr,20,y);
		cairo_show_text(cr, buf); 	
	}

	cairo_move_to(cr,0,YMAX/2+YOFFSET);
	cairo_show_text(cr,""); 	
	cairo_stroke(cr);
	
	D = spara[0].D;
		
	if(D > MAX_D)
	{
		D = MAX_D;
	}
	else
	if(D < MIN_D)
	{
		D = MIN_D;
	}
	
	x_alt =  x_zero + spara[0].qrg * x_scale;
	y_alt =  y_zero - D * y_scale;

	for(m = 1; m <= (n-1); m ++)
	{
		
		cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
		
		D = spara[m].D;		

		if(D > 1.0)	
			cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
	
		if(D > MAX_D)
		{
			D = MAX_D;
		}
		else
		if(D < MIN_D)
		{
			D = MIN_D;
		}

		x =  x_zero + spara[m].qrg * x_scale;
		y =  y_zero - D * y_scale;
		if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
		{
			cairo_move_to(cr,x_alt,y_alt);
			cairo_line_to (cr,x,y);
		}				
		x_alt = x;
		y_alt = y;
	}

	cairo_stroke(cr);

	strcpy(buf,file);
	strcat(buf,"-D-Para.png");
	cairo_surface_write_to_png(surface, buf);
	
	cairo_surface_destroy(surface);

	return;
 }

 
 // File selct menu
static void menuitem_open() {
	GtkWidget *filesel;
	/* Create the selector */
	filesel = gtk_file_selection_new ("Please select a file for editing.");
	gtk_signal_connect(GTK_OBJECT(filesel), "delete_event",
                     GTK_SIGNAL_FUNC(gtk_widget_hide),&filesel);
	gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION(filesel)->ok_button),"clicked", 
                     GTK_SIGNAL_FUNC(file_ok_proc), filesel);
	gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filesel)->cancel_button),"clicked", 
							GTK_SIGNAL_FUNC(gtk_widget_hide),GTK_OBJECT(filesel));
	/* Display that dialog */
	gtk_widget_show (filesel);

}
 
 // Create WGT-Windows
 static void createWindow() {
	this.window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_position(GTK_WINDOW(this.window), GTK_WIN_POS_CENTER);
	gtk_window_set_default_size(GTK_WINDOW(this.window),1024, 768);
	gtk_window_set_title(GTK_WINDOW(this.window),PROGRAM);

	gtk_signal_connect(GTK_OBJECT(this.window), "delete_event",
                     GTK_SIGNAL_FUNC(gtk_main_quit), NULL);

  g_signal_connect (G_OBJECT (this.window), "destroy",
                    G_CALLBACK (destroy), NULL);
}
 

static void destroy( GtkWidget *widget, gpointer   data ) {
  gtk_main_quit ();
}

// expose event
static gboolean on_expose_event(GtkWidget *widget, GdkEventExpose *event, gpointer data) {

	double		A;						// actual value
	double		K;						// actual value
	double		D;						// actual value
	
	double		X_DIV = 10.0;			// 10 div/x
	double		Y_DIV = 10.0;			// 10 div/y

	double		MAX_K = 2.0;			// max K scale
	double		MIN_K = 0.0;			// min K scale
	double		MAX_D = 2.0;			// max D-scale
	double		MIN_D = 0.0;			// min D-scale

	double		MAX_f = 12.0;			// max. frequency
	double		MIN_f = 2.0;			// min frequency

	double 		XMAX;					// max dots x-scale
	double 		YMAX;					// max dots y-scale
	double 		XOFFSET;				// start of diagramm
	double		YOFFSET;				// start of diagramm
	double		x, y;					// actual plot postion
	double		x_alt,y_alt;			// last plot postion
	double		x_scale,y_scale;		// scale for axis
	double		x_zero,y_zero;			// point of origin
	gint width, height;					// Window width & height
	char		buf[MAXLEN];			// line buffer
	
	cairo_t *cr;

	cr = gdk_cairo_create(widget->window);
  
	gdk_drawable_get_size(widget->window, &width, &height);

	cairo_rectangle(cr, 0.0, 0.0, width, height);
	cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
	cairo_fill(cr);

	cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
 
	cairo_set_font_size(cr, 10.0);
	cairo_set_line_width(cr, 1.0);

	XMAX = 0.8 * width;
	YMAX = 0.8 * height;

	XOFFSET = 0.5 * (width-XMAX);
	YOFFSET = 0.5 * (height-YMAX);

	if((puff_fu == 0) || (puff_fl == 0)) {
		MAX_f = 1;
		MIN_f = 12;
	}	
	else {
		MAX_f = puff_fu;
		MIN_f = puff_fl;
	}

	if((puff_du == 0) || (puff_dl == 0)) {
		puff_du = 20;
		puff_dl = -20;
	}	
	
	x_scale = XMAX / (MAX_f-MIN_f);
	y_scale = YMAX / (puff_du-puff_dl);		

	x_zero = - MIN_f * x_scale + XOFFSET;
	y_zero = YMAX + puff_dl * y_scale + YOFFSET;

	cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
	
	sprintf(buf,"%s %s",PROGRAM,VERSION);
	cairo_move_to (cr,10, 0.2* YOFFSET);
	cairo_show_text(cr, buf); 	

	cairo_move_to(cr,XMAX-XOFFSET,0.2 * YOFFSET);
	cairo_show_text(cr, file); 	

	cairo_stroke(cr);

	switch(type) {
		case None:
		break;
		
		case S_parameter:

		y_scale = YMAX / (puff_du-puff_dl);		
		
		cairo_move_to(cr,XOFFSET+XMAX/2, 0.2 * YOFFSET);
		cairo_show_text(cr,"S-PARAMETER");

		for(m = 0; m < X_DIV+1;m ++)
		{
			x =  m * XMAX / X_DIV + XOFFSET;
			if( (x >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x,YOFFSET);
				cairo_line_to(cr,x,YMAX+YOFFSET);
			
				if(m == (m/2*2))
				{
					sprintf(buf,"%2.3f",m / X_DIV * (MAX_f-MIN_f) + MIN_f);
					cairo_move_to(cr,x-20,YOFFSET+YMAX+10);
					cairo_show_text(cr, buf); 	
				}
			}
		}

		cairo_move_to(cr,XMAX /2 + XOFFSET,YOFFSET+YMAX+20);
		cairo_show_text(cr,"f/[GHz]"); 	


		for(m = 0; m < Y_DIV+1;m ++)
		{
			y = m * YMAX / Y_DIV + YOFFSET;

			cairo_move_to(cr,XOFFSET,y);
			cairo_line_to (cr,XMAX+XOFFSET,y);
		
			sprintf(buf,"% 3.1f",puff_du - m / Y_DIV * (puff_du-puff_dl) );
			cairo_move_to(cr,20,y);
			cairo_show_text(cr, buf); 	
		}

		cairo_move_to(cr,0,YMAX/2+YOFFSET);
		cairo_show_text(cr,"dB"); 	
		cairo_stroke(cr);
		
		cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
		cairo_move_to(cr,XOFFSET,0.4 * YOFFSET);
		cairo_show_text(cr,"s11"); 	
		cairo_stroke(cr);
		
		A = 20 * log10(spara[0].s11);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}

		x_alt =  x_zero + spara[0].qrg * x_scale;
		y_alt =  y_zero - A * y_scale;

		for(m = 1; m <= (n-1); m ++)
		{

			A = 20 * log10(spara[m].s11);
			if(A > puff_du)
			{
				A = puff_du;
			}
			else
			if(A < puff_dl)
			{
				A = puff_dl;
			}
			x =  x_zero + spara[m].qrg * x_scale;
			y =  y_zero - A * y_scale;

			if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x_alt,y_alt);
				cairo_line_to (cr,x,y);
			}				
			x_alt = x;
			y_alt = y;
		}


		cairo_stroke(cr);

		cairo_set_source_rgb(cr, 0.0, 1.0, 0.0);
		cairo_move_to(cr,XOFFSET,0.6 * YOFFSET);
		cairo_show_text(cr,"s22"); 	
		cairo_stroke(cr);

		A = 20 * log10(spara[0].s22);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x_alt = x_zero + spara[0].qrg * x_scale;
		y_alt = y_zero - A * y_scale;

		for(m = 1; m <= (n-1); m ++)
		{
			A = 20 * log10(spara[m].s22);
			if(A > puff_du)
			{
				A = puff_du;
			}
			else
			if(A < puff_dl)
			{
				A = puff_dl;
			}
			x =  x_zero + spara[m].qrg * x_scale;
			y =  y_zero - A * y_scale;
			if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x_alt,y_alt);
				cairo_line_to (cr,x,y);
			}				
			x_alt = x;
			y_alt = y;
		}
		cairo_stroke(cr);

		cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
		cairo_move_to(cr,2 * XOFFSET,0.4 * YOFFSET);
		cairo_show_text(cr,"s21"); 	
		cairo_stroke(cr);
	
		A = 20 * log10(spara[0].s21);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x_alt =  x_zero + spara[0].qrg * x_scale;
		y_alt =  y_zero - A * y_scale;

		for(m = 1; m <= (n-1); m ++)
		{
			A = 20 * log10(spara[m].s21);
			if(A > puff_du)
			{
				A = puff_du;
			}
			else
			if(A < puff_dl)
			{
				A = puff_dl;
			}
			x =  x_zero + spara[m].qrg * x_scale;
			y =  y_zero - A * y_scale;
			if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x_alt,y_alt);
				cairo_line_to (cr,x,y);
			}				
			x_alt = x;
			y_alt = y;
		}
		cairo_stroke(cr);

		cairo_set_source_rgb(cr, 1.0, 0.0, 1.0);
		cairo_move_to(cr,2 * XOFFSET,0.6 * YOFFSET);
		cairo_show_text(cr,"s12"); 	
		cairo_stroke(cr);
		A = 20 * log10(spara[0].s12);
		if(A > puff_du)
		{
			A = puff_du;
		}
		else
		if(A < puff_dl)
		{
			A = puff_dl;
		}
		x_alt =  x_zero + spara[0].qrg * x_scale;
		y_alt =  y_zero - A * y_scale;
		for(m = 1; m <= (n-1); m ++)
		{
			A = 20 * log10(spara[m].s12);
			if(A > puff_du)
			{
				A = puff_du;
			}
			else
			if(A < puff_dl)
			{
				A = puff_dl;
			}
			x =  x_zero + spara[m].qrg * x_scale;
			y =  y_zero -  A * y_scale;
			if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x_alt,y_alt);
				cairo_line_to (cr,x,y);
			}				
			x_alt = x;
			y_alt = y;
		}
		cairo_stroke(cr);		
		break;
		
		case K_parameter:
		
		y_scale = YMAX / (MAX_K-MIN_K);
		y_zero = YMAX + MIN_K * y_scale + YOFFSET;
		
		cairo_move_to(cr,XOFFSET+XMAX/2, 0.2 * YOFFSET);
		cairo_show_text(cr,"K-PARAMETER");

		for(m = 0; m < X_DIV+1;m ++)
		{
			x =  m * XMAX / X_DIV + XOFFSET;
			if( (x >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x,YOFFSET);
				cairo_line_to(cr,x,YMAX+YOFFSET);
			
				if(m == (m/2*2))
				{
					sprintf(buf,"%2.3f",m / X_DIV * (MAX_f-MIN_f) + MIN_f);
					cairo_move_to(cr,x-20,YOFFSET+YMAX+10);
					cairo_show_text(cr, buf); 	
				}
			}
		}

		cairo_move_to(cr,XMAX /2 + XOFFSET,YOFFSET+YMAX+20);
		cairo_show_text(cr,"f/[GHz]"); 	

		for(m = 0; m < Y_DIV+1;m ++)
		{
			y = m * YMAX / Y_DIV + YOFFSET;

			cairo_move_to(cr,XOFFSET,y);
			cairo_line_to (cr,XMAX+XOFFSET,y);
		
			sprintf(buf,"% 3.1f",MAX_K- m / Y_DIV * (MAX_K-MIN_K) );
			cairo_move_to(cr,20,y);
			cairo_show_text(cr, buf); 	
		}

		cairo_move_to(cr,0,YMAX/2+YOFFSET);
		cairo_show_text(cr,""); 	
		cairo_stroke(cr);
		
		K = spara[0].K;
	
		if(K > MAX_K)
		{
			K = MAX_K;
		}
		else
		if(K < MIN_K)
		{
			K = MIN_K;
		}
	
		x_alt =  x_zero + spara[0].qrg * x_scale;
		y_alt =  y_zero - K * y_scale;

		for(m = 1; m <= (n-1); m ++)
		{
			cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
			
			K = spara[m].K;	
		
			if(K < 1.0)
			{
				cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);	
				// printf("%lf \n\r",K);
			}
		
			if(spara[m].K > MAX_K)
			{
				K = MAX_K;
			}
			else
			if(spara[m].K < MIN_K)
			{
				K = MIN_K;
			}

			x =  x_zero + spara[m].qrg * x_scale;
			y =  y_zero - K * y_scale;
			if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x_alt,y_alt);
				cairo_line_to (cr,x,y);
			}				
			x_alt = x;
			y_alt = y;
		}
		cairo_stroke(cr);
		break;
		
		case D_parameter:

		y_scale = YMAX / (MAX_D-MIN_D);
		y_zero = YMAX + MIN_D * y_scale + YOFFSET;
			
		cairo_move_to(cr,XOFFSET+XMAX/2, 0.2 * YOFFSET);
		cairo_show_text(cr,"D-PARAMETER");
	
		for(m = 0; m < X_DIV+1;m ++) {
			x =  m * XMAX / X_DIV + XOFFSET;
			if( (x >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x,YOFFSET);
				cairo_line_to(cr,x,YMAX+YOFFSET);
			
				if(m == (m/2*2)) {
					sprintf(buf,"%2.3f",m / X_DIV * (MAX_f-MIN_f) + MIN_f);
					cairo_move_to(cr,x-20,YOFFSET+YMAX+10);
					cairo_show_text(cr, buf); 	
				}
			}
		}

		cairo_move_to(cr,XMAX /2 + XOFFSET,YOFFSET+YMAX+20);
		cairo_show_text(cr,"f/[GHz]"); 	

		for(m = 0; m < Y_DIV+1;m ++) {
			y = m * YMAX / Y_DIV + YOFFSET;

			cairo_move_to(cr,XOFFSET,y);
			cairo_line_to (cr,XMAX+XOFFSET,y);
		
			sprintf(buf,"% 3.1f",MAX_D - m / Y_DIV * (MAX_D-MIN_D) );
			cairo_move_to(cr,20,y);
			cairo_show_text(cr, buf); 	
		}

		cairo_move_to(cr,0,YMAX/2+YOFFSET);
		cairo_show_text(cr,""); 	
		cairo_stroke(cr);
	
		D = spara[0].D;
		
		if(D > MAX_D)
		{
			D = MAX_D;
		}
		else
		if(D < MIN_D)
		{
			D = MIN_D;
		}
	
		x_alt =  x_zero + spara[0].qrg * x_scale;
		y_alt =  y_zero - D * y_scale;

		for(m = 1; m <= (n-1); m ++)
		{
		
			cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
		
			D = spara[m].D;		

			if(D > 1.0)	
				cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
		
			if(D > MAX_D)
			{
				D = MAX_D;
			}
			else
			if(D < MIN_D)
			{
				D = MIN_D;
			}

			x =  x_zero + spara[m].qrg * x_scale;
			y =  y_zero - D * y_scale;
			if( (x_alt >= XOFFSET) && (x <= XOFFSET+XMAX) )
			{
				cairo_move_to(cr,x_alt,y_alt);
				cairo_line_to (cr,x,y);
			}				
			x_alt = x;
			y_alt = y;
		}
		cairo_stroke(cr);
		break;		
	}     

	cairo_destroy(cr);

  return TRUE;
}
