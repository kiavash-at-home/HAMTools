/*A computer program to predict VHF propogation */
/*This program has been placed in the Public Domain by its author - K2LMG */
/*Compile under TURBO-C -- The author used BCC Version 2.0 */
/*History:449 (Ver 1.1)*/ 

/*Ver 1.2: Ported from TURBO-C to ncurses*/
/*the following license only applies to the ported code*/

/* Copyright 2020 by Kiavash

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <ncurses.h>
#include <math.h>

#define FADE_VALUE 7
#define VERSION "1.2"

/*6m data, 0.5 64.3, 1 70.3, 5 118, 10 131, 20 144.5, 30 154, 40 161, 50
        169, 75 174, 100 177.5, 150 183.5, 200 188, 250 194, 300 207, 350 214,
        400 222, 450 229, 500 235, 550 242 */

double coef6m[] = {-1.484302997616194e-21, 4.1038152183463572e-18,
	-4.8551992957369198e-15, 3.2101311680399517e-12,
	-1.2996161086602211e-09, 3.3199292557524471e-07,
	-5.3228661204510353e-05, 0.0051731206040884119, -0.28532370451114214,
	8.1911236469791699, 67.635788039642023
};

/*2m data -- 0.5 73.9, 1 79.5, 5 93.9 10 131, 20 146, 30 157, 40 167, 50
        170, 75 174, 100 178, 150 184, 200 188.5, 250 194, 300 206.5, 350 214,
        400 222, 450 228, 500 234, 550 241 */

double coef2m[] = {-1.0140612223930305e-21, 2.8210504968786972e-18,
	-3.3639226709952115e-15, 2.2467324291152165e-12,
	-9.2161956771287313e-10, 2.3956384975135559e-07,
	-3.9329897909964029e-05, 0.0039527147149096397, -0.22900560651309843,
	7.0593776226319154, 76.297125007618945
};

/*1.25m data, 0.5 77.5, 1 83.5, 5 119, 10 132, 20 148, 30 160, 40 168, 50
        171, 75 175.5, 100 180, 150 186.5, 200 191, 250 197, 300 209, 350
        216.5, 400 224, 450 230, 500 236.5, 550 242 */

double coef125cm[] = {-9.3022498752972239e-22, 2.5942502213057621e-18,
	-3.1027271861262425e-15, 2.079688661769463e-12,
	-8.5672949008653612e-10, 2.2382801286343053e-07,
	-3.6971168328522354e-05, 0.0037433231319706261, -0.21886313655344825,
	6.8335531497848931, 79.398990370051834
};

/*70cm data -- 432 Mhz 0.5 83.4, 1 89.5, 5 103.4 10 132, 20 150, 30 163.5, 40
        170, 50 173, 75 178, 100 183, 150 190, 200 196, 250 202, 300 213, 350
        220.5, 400 228, 450 234, 500 240, 550 246 */

double coef70cm[] = {-4.5865358353610324e-22, 1.3108230411727579e-18,
	-1.6135046051301692e-15, 1.1190620728434546e-12,
	-4.8033074993680223e-10, 1.319708437884491e-07,
	-2.3222247971860489e-05, 0.0025516659663546628, -0.1661238781990346,
	5.9666161768039707, 81.595953373755762
};

/*33cm data, 0.5 89.7, 1 95.7, 5 119.5, 10 133, 20 153.5, 30 168.5, 40
        173.5, 50 177, 75 183.5, 100 189, 150 197, 200 202.5, 250 209, 300
        221.5, 350 228, 400 236, 450 241.5, 500 248, 550 251 */

double coef33cm[] = {-5.2781673891878704e-22, 1.4951138952704982e-18,
	-1.8211439179439397e-15, 1.2472237245268508e-12,
	-5.2709664954563149e-10, 1.4203323864028798e-07,
	-2.4385939877300226e-05, 0.0025983803016192764, -0.16327178023671626,
	5.7118712681798156, 89.957616754542244
};

/*23cm data -- 0.5 92.8, 1 98.9, 5 120, 10 134, 20 157, 30 171.5, 40 178,
        50 182, 75 188.5, 100 195, 150 203.5, 200 210, 250 216, 300 228, 350
        234, 400 243, 450 248, 500 254, 550 257 */

double coef23cm[] = {-4.324473300406565e-22, 1.2258059596030557e-18,
	-1.4960261442115287e-15, 1.0285157566223974e-12,
	-4.3756476216365891e-10, 1.1917818401558418e-07,
	-2.0805095457433704e-05, 0.002273429714275005, -0.14832922840239154,
	5.4937966328715673, 92.663217031298927
};

/*Fade data -- Fading data 0.5 0, 5 0, 10 3, 20 5, 30 7, 40 9, 50 11.5, 60
        14.5, 70 16.5, 80 17.5, 90 18, 100 18, 110 17.5, 120 17, 130 16.5, 140
        15.5, 150 14.5, 160 13.5, 170 12.5, 180 11.5, 190 10, 200 9.5, 250 8.5,
        300 8, 350 7.5, 400 7, 450 7, 500 7 */

double coeffade[] = {-1.931900179565423e-22, 4.7890688047850891e-19,
	-5.0385411769900302e-16, 2.9177755838734291e-13,
	-1.0055284586681718e-10, 2.0690926814195451e-08,
	-2.3867831104375384e-06, 0.00013095435698746912, -0.003263676118036522,
	0.27959303349242731, -0.376155914778245
};

double coefheight[] = { 1.15144e-08, -3.48166e-06, 4.34947e-04, -2.98883e-02,
	1.20410e+00, -1.84529e+01
};

double poly_value(double dist, double coeff[], int degree)
{
	double term;
	int i;
	term = coeff[0];
	for (i = 1; i <= degree; i++)
		term = term *dist + coeff[i];
	return term;
}

double path_loss_func(double dist, int freq_index)
{
	double ret = 0;
	if (dist < 1.0) dist = 1.0;
	switch (freq_index)
	{
		case 0:
			ret = poly_value(dist, coef6m, 10);
			break;
		case 1:
			ret = poly_value(dist, coef2m, 10);
			break;
		case 2:
			ret = poly_value(dist, coef125cm, 10);
			break;
		case 3:
			ret = poly_value(dist, coef70cm, 10);
			break;
		case 4:
			ret = poly_value(dist, coef33cm, 10);
			break;
		case 5:
			ret = poly_value(dist, coef23cm, 10);
			break;
	}

	return ret;
}

double fade_func(double dist)
{
	if (dist < 0.5) dist = 0.5;
	return poly_value(dist, coeffade, 10);
}

double height_gain(double height)
{
	if (height > 100) return 8.0;
	if (height < 0) return -7.0;
	return poly_value(height, coefheight, 5);
}


/*trans array: power, distance, antenna_gain, antenna_height,
	site_height, line_loss, site_angle
 *rec array:   modulation_loss, noise_figure, antenna_gain, antenna_height,
	site_height, line_loss, site_angle, bandwidth, band, dummy;
 */

int main()
{
	WINDOW * mainwin;

	/* Initialize ncurses  */

	if ((mainwin = initscr()) == NULL)
	{
		fprintf(stderr, "Error initializing ncurses.\n");
		exit(EXIT_FAILURE);
	}
	
	/* Min needed Terminal size */
	const int Resize_lines = 25;
	const int Resize_cols = 80;
	if ((LINES < Resize_lines) | (COLS < Resize_cols)) 
	{
		delwin(mainwin);
		endwin();
		fprintf(stderr, "VHFProp needs at least 80x25 terminal size.\n");
		exit(EXIT_SUCCESS);
	}

	noecho(); /* Turn off key echoing                 */
	keypad(mainwin, TRUE); /* Enable the keypad for non-char keys  */
	cbreak();	// don't wait for return key
	nodelay(stdscr, TRUE); 	// don't wait for pressing a key

	char input[20];
	int i, key, row, col, stop, index=0, mod_index, reliability, band_index,
	fading, key_save;
	double value;
	double transmit[] = { 50, 10, 0, 0, 0, 0, 0 };
	double receiver[] = { 7, 1, 0, 0, 0, 0, 0, 5, 1, 0 };
	double distance, hor_dist, dist_lineof_sight, signal2noise, station_gain,
	path_loss, rec_sensitivity, h_gain_trans, h_gain_rec;
	int next_row_left_down[] = { 0, 0, 0, 5, 5, 6, 7, 8, 9, 10, 13, 13, 13, 5, 5, 5, 5, 5, 5 };
	int next_row_left_up[] = { 0, 0, 0, 13, 13, 13, 5, 6, 7, 8, 9, 10, 10, 10, 13, 13, 13, 13, 13, 13 }; /*this has row 17 defined */
	int next_row_right_down[] = { 0, 0, 0, 5, 5, 6, 7, 8, 9, 10, 11, 15, 15, 15, 15, 16, 17, 18, 5 };
	int next_row_right_up[] = { 0, 0, 0, 18, 18, 18, 5, 6, 7, 8, 9, 10, 11, 11, 11, 11, 15, 16, 17 };
	char *mod_mode[] = { "fm", "ssb", "cw", "am" };
	double mod_value[] = { 7, 3, 0, 7 };
	char *reliab_mode[] = { "50%", "99%" };
	char *fade_mode[] = { "No", "Yes" };
	char *band[] = { "6m", "2m", "1.25m", "70cm", "33cm", "23cm" };
	double band_value[] = { 50, 146, 222, 440, 902, 1280 };

	row = 13; /*cursor starting position */
	col = 30;
	band_index = reliability = fading = 1;
	mod_index = 0;
	key_save = 0;

	mvprintw(1, 7, "VHFProp -- An interactive Signal Analysis Program -- Version %s", VERSION);
	mvprintw(3, 5, "Transmitting Station Parameters");
	mvaddch(3, 40, ACS_VLINE);
	mvprintw(3, 45, "Receiving Station Parameters");
	mvprintw(24, 65, "Press q to Quit");
	move(4, 1);
	hline(ACS_HLINE, 76);	//TODO: Check the number
	mvaddch(4, 40, ACS_SSSS);
	move(5, 40);
	vline(ACS_VLINE, 7);
	move(14, 42);
	hline(ACS_HLINE, 34); /*underline Modes */	//TODO: Check the number
	mvprintw(18, 14, "Results");
	move(19, 2);
	hline(ACS_HLINE, 34); /*underline Results */	//TODO: Check the number

	for (;;)
	{
		mvprintw(5, 2, "Power (watts):");
		mvprintw(5, 30, "%7.1lf", transmit[0]);
		mvprintw(5, 42, "Noise Figure (db):");
		mvprintw(5, 69, "%7.1lf\n", receiver[1]);
		mvprintw(6, 2, "Line Loss (db):");
		mvprintw(6, 30, "%7.1lf", transmit[5]);
		mvprintw(6, 42, "Line Loss (db): ");
		mvprintw(6, 69, "%7.1lf\n", receiver[5]);
		mvprintw(7, 2, "Antenna Gain (db): ");
		mvprintw(7, 30, "%7.1lf", transmit[2]);
		mvprintw(7, 42, "Antenna Gain (db): ");
		mvprintw(7, 69, "%7.1lf\n", receiver[2]);
		mvprintw(8, 2, "Antenna Height (feet): ");
		mvprintw(8, 30, "%7.1lf", transmit[3]);
		mvprintw(8, 42, "Antenna Height (feet): ");
		mvprintw(8, 69, "%7.1lf\n", receiver[3]);
		mvprintw(9, 2, "Site Height (feet): ");
		mvprintw(9, 30, "%7.1lf", transmit[4]);
		mvprintw(9, 42, "Site Height (feet): ");
		mvprintw(9, 69, "%7.1lf", receiver[4]);
		mvprintw(10, 2, "Horizon Angle (degrees): ");
		mvprintw(10, 30, "%7.1lf", transmit[6]);
		mvprintw(10, 42, "Horizon Angle (degrees): ");
		mvprintw(10, 69, "%7.1lf", receiver[6]);
		mvprintw(11, 42, "Bandwidth (KHz):");
		mvprintw(11, 69, "%7.1lf\n", receiver[7]);
		mvprintw(13, 2, "Distance (miles): ");
		mvprintw(13, 30, "%7.1lf", transmit[1]);
		mvprintw(13, 42, "  Modes - Select with Enter Key");
		mvprintw(15, 42, "Frequency Band: ");
		mvprintw(15, 69, "%7s", band[band_index]);
		mvprintw(16, 42, "Modulation: ");
		mvprintw(16, 69, "%7s", mod_mode[mod_index]);
		mvprintw(17, 42, "Reliability: ");
		mvprintw(17, 69, "%7s", reliab_mode[reliability]);
		mvprintw(18, 42, "Include Fading: ");
		mvprintw(18, 69, "%7s", fade_mode[fading]);
		move(row, col);
		refresh();

		stop = FALSE;

		/*Change the parameters
		 *key_save remembers the input termination key.  If it is an arrow
		 *go in the specified direction.
		 */
		do {
			if (!key_save)
			{
				key = getch();
				if (key != 0 && (isdigit(key) || key == '\n' /*KEY_ENTER*/)) stop = TRUE;
			}

			key_save = 0;
			switch (key)
			{
				case KEY_UP:	// UP Arrow
					if (col > 40) row = next_row_right_up[row];
					else row = next_row_left_up[row];
					move(row, col);
					break;
				case KEY_DOWN:	// DOWN Arrow
					if (row < 19)
					{
						if (col > 40) row = next_row_right_down[row];
						else row = next_row_left_down[row];
					}

					move(row, col);
					break;
				case KEY_LEFT:	// LEFT Arrow
					if (col == 69) col = 30;
					row = next_row_left_up[row + 1];
					move(row, col);
					break;
				case KEY_RIGHT:	// RIGHT Arrow
					if (col == 30) col = 69;
					row = next_row_right_up[row + 1];
					move(row, col);
					break;
				case '\n' /*KEY_ENTER*/:	// ENTER or Send
					if (row == 15)
					{
						if (band_index < 5) band_index++;
						else band_index = 0;
					}
					else
					if (row == 16)
					{
						if (mod_index < 3) mod_index++;
						else mod_index = 0;
					}
					else
					if (row == 17) reliability ^= 1;
					else
					if (row == 18) fading ^= 1;
					else stop = FALSE;
					key = 0;
					break;
				case 'q':	// Exit the program
					mvprintw(22, 25, "Thank you for using VHFProp -- de K2LMG");
					/* Clean up after ourselves  */
					delwin(mainwin);
					endwin();
					refresh();
					fprintf(stderr, "Thank you for using VHFProp -- de K2LMG\n");
					exit(EXIT_SUCCESS);
			}
		} while (!stop);

		input[0] = key &0x0ff;
		if (key > 0)
		{
			printw("%c         \b\b\b\b\b\b\b\b\b", input[0]); /*clear the previous value */
			i = 1;
			do {
				key = getch();
				if (key == 0) break;
				if (key == '\b')
				{
					if (i > 0)
					{
						i--;
						printw("\b \b"); /*do editing the hard way */
					}
				}
				else if ((isdigit(key) || key == '.') && i < 8)
				{
					printw("%c", key);
					input[i++] = key;
				}
			} while (key != '\n' /*KEY_ENTER*/);	
			input[i] = '\0';
		}

		key_save = key &0xff00; /*last key input */
		value = strtod(input, NULL);
		if (col < 42) /*set index to store value in correct array element */
		{
			switch (row)
			{
				case 5:
					index = 0;
					break;
				case 6:
					index = 5;
					break;
				case 7:
					index = 2;
					break;
				case 8:
					index = 3;
					break;
				case 9:
					index = 4;
					break;
				case 10:
					index = 6;
					break;
				case 13:
					index = 1;
					break;
			}

			transmit[index] = value;
		}
		else
		{
			switch (row)
			{
				case 5:
					index = 1;
					break;
				case 6:
					index = 5;
					break;
				case 7:
					index = 2;
					break;
				case 8:
					index = 3;
					break;
				case 9:
					index = 4;
					break;
				case 10:
					index = 6;
					break;
				case 11:
					index = 7;
					break;
				case 15:
					index = 8;
					value = band_value[band_index];
					break;
				case 16:
					index = 0;
					value = mod_value[mod_index];
					break;
				case 17:
					index = 9;
				case 18:
					index = 9; /*8 is when result not saved */
					break;
			}

			receiver[index] = value;
		}

		distance = transmit[1];
		hor_dist = (transmit[6] + receiver[6]) *69.0;

		/*look for values which could give problems */
		if (distance > 500)
		{
			beep();
			distance = transmit[1] = 500.0;
		}

		if (distance + hor_dist <= 0.0 || distance + hor_dist > 500.0)
		{
			if (col < 42) transmit[6] = 0.0;
			else receiver[6] = 0.0;
			beep();
			hor_dist = 0.0;
		}

		distance += hor_dist;
		if (distance > 500)
		{
			beep();
			distance = 500.0;
		}

		if (transmit[0] < 0.01) /*power */
		{
			transmit[0] = 0.01;
			beep();
		}

		if (transmit[3] < 0) /*antenna height */
		{
			transmit[3] = 0.0;
			beep();
		}

		if (receiver[3] < 0)
		{
			receiver[3] = 0.0;
			beep();
		}

		if (transmit[4] < 0) /*site height */
		{
			transmit[4] = 0.0;
			beep();
		}

		if (receiver[4] < 0)
		{
			receiver[4] = 0.0;
			beep();
		}

		dist_lineof_sight = 1.225 *(sqrt(transmit[4]) + sqrt(receiver[4]));
		if (dist_lineof_sight *1.075 < distance) /*when divisor -> distance - dist_lineof_sight < - is too small error occur */
		{
			path_loss = path_loss_func(distance - dist_lineof_sight, band_index);
			path_loss += 20* log10(distance / (distance - dist_lineof_sight));
		}
		else
		{
			path_loss = 36.6 + 20.0* log10(distance) + 20.0* log10(receiver[8]);
			dist_lineof_sight = distance;
		}

		if (reliability) path_loss += fade_func(distance - dist_lineof_sight);
		rec_sensitivity = 10* log10(pow(10, receiver[1] / 10) *receiver[7] /
			2.188e17) + receiver[5]; /*as per QST article include line_loss here */
		h_gain_trans = height_gain(transmit[3]);
		h_gain_rec = height_gain(receiver[3]);
		station_gain = 10* log10(transmit[0]) + h_gain_trans + transmit[2] +
			h_gain_rec + receiver[2] - transmit[5] -
			receiver[0] - rec_sensitivity;
		if (fading) station_gain -= FADE_VALUE *(distance - dist_lineof_sight) /
			distance;
		signal2noise = station_gain - path_loss;

		mvprintw(15, 2, "Line of sight distance:");
		mvprintw(15, 30, "%7.1lf", dist_lineof_sight);
		mvprintw(16, 2, "Eff. scatter distance:");
		mvprintw(16, 30, "%7.1lf", distance - dist_lineof_sight);
		mvprintw(20, 2, "Signal to Noise Ratio (db):");
		mvprintw(20, 30, "%7.1lf", signal2noise);
		mvprintw(21, 2, "Path Loss (db):");
		mvprintw(21, 30, "%7.1lf", path_loss);
		mvprintw(22, 2, "Receiver Sensitivity (db):");
		mvprintw(22, 30, "%7.1lf", rec_sensitivity);
		mvprintw(23, 2, "Station Gain (db):");
		mvprintw(23, 30, "%7.1lf\n", station_gain);
		refresh();
	}
}
