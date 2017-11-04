/*

 Wiremap Renderer for 2 Globes
 by 
 
 /      \
 ______/________\______
 /      \        /      \
 /________\      /________\______
 /                \         |     \
 /   /      \       \_____   |      \
 /________\______         |      /
 \        /      \        |_____/
 \      /________\
 \          \     /
 \_____      \ /
 / \
 /     \
 
 For more information on the project please visit:
 http://num_of_stringsmap.phedhex.com
 
 This program builds two separate 3d globes.  I have two separate functions (& sets of variables) because I haven't quite yet figured out how call a function twice.  Elementary stuff, I know, but I'll get to it when I can.
 
 Some conventions to be aware of:
 
 1 - This particular program builds in millimeters.
 2 - Also, I use a left-handed coordinate system, with positive X going right, positive Y going up, and positive Z going forward.
 
 
 */

//  Fullscreen stuff:

/* Variable declarations
 ---------------------------------------------------------*/

/* Physical Wiremap, in inches
 ---------------------------------------------------------*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Write down our own units
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float depth             = 52.0;               // The mapline lies 3 meters away from the projector's focal point WAS 70
float map_length        = 32.0;               // The mapline is 1.28 meters wide
float depth_unit        = 0.5;               // Each depth unit is 5 millimeters
float map_unit          = 0.5;               // Each mapline unit is 5 millimeters
int num_of_strings      = 64;                // There are 128 strings in this Wiremap
float depth_thickness   = 20.0;                 // How deep is the field (perpendicular to the mapline)


/* Projector
 ---------------------------------------------------------*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// What do we do here?????
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


float ppi               = 32;                  // Pixels per millimeter (unit conversion).  Only true for mapline plane - 4 pixels every 5 millimeters
int string_pix_count    = 2;                   // How many columns of pixels are being projected on each string


/* Map
 ---------------------------------------------------------*/

float[] map             = new float[num_of_strings];    // example: map[0] = 90 means that the first string is 45 cm away from the mapline
float[] x_by_ind        = new float[num_of_strings];    // x coordinate for each num_of_strings
float[] z_by_ind        = new float[num_of_strings];    // z coordinate for each num_of_strings


/* Globe A
 ---------------------------------------------------------*/

float[] globe           = new float[3];       // globe x,y,z coords
float radius            = 31.00;              // default globe radius
int dot_height          = 15;                 // height of surface pixels.
boolean render_globe    = true;               // toggle globe rendering

/* Key input
 ---------------------------------------------------------*/

float step              = .2;                 // how far the globe moves / button press
boolean mouse           = true;               // is mouse clicked?
int colorval_r          = 0;                  // red
int colorval_g          = 0;                  // green
int colorval_b          = 255;                // blue
boolean xpin            = false;              // the mouse controls the globe's y & z axis
boolean ypin            = true;               // x & z
boolean zpin            = false;              // x & y
int start_time          = 0;                  // for beat mapper
int end_time            = 0;                  //
float beat_multiplier   = 1;                  // multiplies freqeuncy of how often beat hits



/* Beat Mapper Variables
 ---------------------------------------------------------*/

int[] last_32 = new int[32];                        // last 32 times the spacebar has been pressed
int times_struck;                                   // nubmer of times spacebar struck since timer was reset
int first_strike;                                   // millis value for when timer was reset
int period = 500;                                   // time between beats (this is the metronome)
int offset = 1;                                     // how far away in time we are from the last beat


/* wave variables
 ---------------------------------------------------------*/
int trail = 350;                                    // number of iterations of past mouse clicks we keep
int[] click_time = new int[trail];                  // array of times (millis) associated w/ clicks
int[] click_x = new int[trail];                     // array of x locales for clicks
int[] click_y = new int[trail];                     // array of y locales for clicks
float[] click_x_trans = new float[trail];           // translations from mouse x to xyz
float[] click_y_trans = new float[trail];           // translations from mouse y to xyz
float amplitude = .6;                              // amplitude of waves
int decay = 3000;                                   // how long it takes for waves to die down
float wave_velocity = .035;                          // inches/milliseconds
int trail_frequency = 10;                           // milliseconds - NOT frequency of wave, but how often a new value gets pushed into the trail arrays (above)
int trail_cycle_count;                              // this gets updated once every (trail_frequency)
int trail_cycle_count_compare;                      // this is used to check to see if we need a new value
int water_color = 0;                                // 

float plane_angle = .0;                            // the angle of the plane of the water (think m in y = mx + b)
float plane_intercept = 0;                        // where the plane intersects the origin (think b in y = mx + b)


float[] time_since_click = new float[trail];                  //  the difference between now and the array of clicks
float[] amp_modifier = new float[trail];                      //  the amp according to decay and time since click
float[] distance_since_pass = new float[trail];               //  the distance since the head of the wave has passed the string
float[] distance_since_pass_fraction = new float[trail];      //  the distance gets multiplied by a fraction for beat mapping (period)
float[] time_since_pass = new float[trail];                   //  amount of time that has passed since head of wave & num_of_strings intersection
float[] wave_head_distance = new float[trail];                //  distance between epicenter and head of wave
float[] amp = new float[trail];

/* globe variables
 ---------------------------------------------------------*/
PVector blue_pos;
color blue;
PVector red_pos;
color red;

PVector keyboard_pos;

// OPENGL renderer
import processing.opengl.*;

static public void main(String args[]) {
  PApplet.main(new String[] { "--present", "custom_sine" });
}

void setup() {
  size(displayWidth, displayHeight, P3D); // opengl rendered in the original file
  background(255);

  blue_pos = new PVector(0, 0, 0);
  blue = color(0, 0, 255);

  red_pos = new PVector(0, 0, 0);
  red = color(255, 0, 0);

  keyboard_pos = new PVector(0, 0, 0);

  loader();
}

void draw() {
  noCursor();
  noStroke();
  frameRate(30);
  fill(0);
  rect(0, 0, width, height);
  colorval_r = 255;
  colorval_g = 0;
  colorval_b = 0;
  
  if(keyPressed == true){
    if (key == CODED) {
    if (keyCode == DOWN) {
      keyboard_pos.z -= 10;
    } else if (keyCode == UP) {
      keyboard_pos.z += 10;
    } else if (keyCode == LEFT) {
      keyboard_pos.x -= 10;
    } else if (keyCode == RIGHT) {
      keyboard_pos.x += 10;
    }
  }
  }
  
  sineSurface();
}

void sineSurface() {

  /*     trail_frequency appends clicks to the mouse trail arrays   */

  int remainder = millis() % trail_frequency;
  trail_cycle_count = (millis() - remainder) / trail_frequency;
  if (trail_cycle_count != trail_cycle_count_compare) {
    trail_cycle_count_compare = trail_cycle_count;
    append_click(mouseX, mouseY);
  }


  time_since_click = new float[trail];                  //  the difference between now and the array of clicks
  amp_modifier = new float[trail];                      //  the amp according to decay and time since click
  distance_since_pass = new float[trail];               //  the distance since the head of the wave has passed the string
  distance_since_pass_fraction = new float[trail];      //  the distance gets multiplied by a fraction for beat mapping (period)
  time_since_pass = new float[trail];                   //  amount of time that has passed since head of wave & num_of_strings intersection
  wave_head_distance = new float[trail];                //  distance between epicenter and head of wave
  amp = new float[trail];                               //  amplitude of wave @ num_of_strings point according to mouse movement & beatmapping

  /*  for each num_of_strings...   */

  for (int i=0; i<num_of_strings; i+=1) {
    float final_amp = z_by_ind[i]*plane_angle + plane_intercept ;                     //  the baseline for the final amplitude is an upward slope when looking @ the num_of_stringsmap... used y = mx + b

    for (int x = 0; x < trail; x ++ ) {

      float local_hyp = sqrt(sq(x_by_ind[i] - click_x_trans[x])+sq(z_by_ind[i] - click_y_trans[x]));
      time_since_click[x] = millis() - click_time[x];
      wave_head_distance[x] = time_since_click[x] * wave_velocity;
      distance_since_pass[x] = wave_head_distance[x] - local_hyp;
      distance_since_pass_fraction[x] = distance_since_pass[x] / float(period / 6);
      time_since_pass[x] = distance_since_pass[x] / wave_velocity;
      if (time_since_pass[x] > 0 && time_since_pass[x] < decay ) {
        amp_modifier[x] = time_since_pass[x] / decay - 1;
      } else {
        amp_modifier[x] = 0;
      }
      amp[x] = - amplitude * amp_modifier[x] * sin((2 * PI * distance_since_pass_fraction[x]));

      final_amp = final_amp + amp[x];
    }

    float y_top_coord = final_amp;
    float y_bot_coord = -20;
    float y_top_proj = y_top_coord * depth / z_by_ind[i];                      // compensate for projection morphing IN INCHES
    float y_bot_proj = y_bot_coord * depth / z_by_ind[i];
    float y_height_proj = y_top_proj - y_bot_proj;
    fill(255);                                                                    // draw a rectangle at that intersect

    // rect 1 is top dot for sliver
    float left1 = i * (width) / num_of_strings;
    float top1 = (height/ppi - y_top_proj) * ppi;
    float wide1 = string_pix_count;
    float tall1 = dot_height;
    rect(left1, top1, wide1, tall1);                                                        // draw a rectangle at that intersect

    // rect 3 is filler for sliver
    fill(0, 0, water_color);
    float left3 = i * (width) / num_of_strings;
    float top3 = (height/ppi - y_top_proj) * ppi + dot_height;
    float wide3 = string_pix_count;
    float tall3 = y_height_proj * ppi - (dot_height * 2);
    rect(left3, top3, wide3, tall3);                                                        // draw a rectangle at that intersect
  }

  red_pos = getThreadedPosition(mouseX, 0, mouseY);
  blue_pos = getThreadedPosition(keyboard_pos.x, 0, keyboard_pos.z);

  float radius = (sin(TWO_PI * float((millis() - offset) % period) / float(period)) + 1) / 2;

  if (render_globe == true) {
    gen_globe(red_pos.x, -red_pos.y, red_pos.z, 5, red);
    gen_globe(blue_pos.x, -blue_pos.y, blue_pos.z, 5, blue);
  }
}

PVector getThreadedPosition(float _x, float _y, float _z) {

  PVector threadedPos = new PVector(0, 0, 0);

  threadedPos.x = (_x / float(width)) * (map_length) - (map_length / 2);
  threadedPos.z = depth - (_z) / float(height) * (depth_thickness);

  float y_amp = _z*plane_angle + plane_intercept; //calculate amplitude of the radius based on how deep it is

  for (int x = 0; x < trail; x ++ ) {

    float local_hyp = sqrt(sq(red_pos.x - click_x_trans[x])+sq(red_pos.z - click_y_trans[x]));
    time_since_click[x] = millis() - click_time[x];
    wave_head_distance[x] = time_since_click[x] * wave_velocity;

    distance_since_pass[x] = wave_head_distance[x] - local_hyp;
    distance_since_pass_fraction[x] = distance_since_pass[x] / float(period / 6);
    time_since_pass[x] = distance_since_pass[x] / wave_velocity;

    if (time_since_pass[x] > 0 && time_since_pass[x] < decay ) {
      amp_modifier[x] = - time_since_pass[x] / decay + 1;
    } else {
      amp_modifier[x] = 0;
    }

    amp[x] = - amplitude * amp_modifier[x] * sin((2 * PI * distance_since_pass_fraction[x]));

    y_amp = y_amp + amp[x];
  }

  threadedPos.y = y_amp;

  return threadedPos;
}

void append_click(int local_mouseX, int local_mouseY) {
  //extract the a version of the click_time array with the first element removed
  // this is equivalent to removing the oldest element
  click_time = subset(click_time, 1);
  click_x = subset(click_x, 1);
  click_y = subset(click_y, 1);
  click_x_trans = subset(click_x_trans, 1);
  click_y_trans = subset(click_y_trans, 1);

  //then we add the new click
  click_time = append(click_time, millis());
  click_x = append(click_x, local_mouseX);
  click_y = append(click_y, local_mouseY);
  click_x_trans = append(click_x_trans, (local_mouseX / float(width)) * (map_length) - (map_length / 2));
  click_y_trans = append(click_y_trans, depth - (local_mouseY) / float(height) * (depth_thickness));
}


void gen_globe(float x, float y, float z, float rad, color col) {

  for (int i = 0; i < num_of_strings; i += 1) {

    //we're checking for the x component of each string, see if it's within radius
    if ((x_by_ind[i] >= (x - rad)) && (x_by_ind[i] <= (x + rad))) {                  // if a num_of_strings's x coord is close enough to the globe's center
      float local_hyp = sqrt(sq(x_by_ind[i] - x) + sq(z_by_ind[i] - z));            // find the distance from the num_of_strings to the globe's center
      if (local_hyp <= rad) {                                                        // if the num_of_strings's xz coord is close enough to the globe's center
        float y_abs           = sqrt(sq(rad) - sq(local_hyp));                      // find the height of the globe at that point
        float y_top_coord     = y + y_abs;                                          // find the top & bottom coords
        float y_bot_coord     = y - y_abs;                                          // 
        float y_top_proj      = y_top_coord * depth / z_by_ind[i];                  // compensate for projection morphing
        float y_bot_proj      = y_bot_coord * depth / z_by_ind[i];
        float y_height_proj   = y_top_proj - y_bot_proj;


        /* Top dot
         ---------------------------------------------------------*/
        fill(col);                                   // Fill the globe pixels this color
        float left1           = i * (width) / num_of_strings;
        float top1            = (height/ppi - y_top_proj) * ppi + dot_height;     // ppi = pixel / mm.  These are conversions to & from pixels and mm
        float wide1           = string_pix_count;
        float tall1           = y_height_proj * ppi - (dot_height * 2);
        rect(left1, top1, wide1, tall1);


        fill(255);                                                                  // Fill the surface pixels White

        /* Top Surface
         ---------------------------------------------------------*/
        float left2           = i * (width) / num_of_strings;
        float top2            = (height/ppi - y_top_proj) * ppi;
        float wide2           = string_pix_count;
        float tall2           = dot_height;
        rect(left2, top2, wide2, tall2);

        /* Bottom Surface
         ---------------------------------------------------------*/
        float left3           = i * (width) / num_of_strings;
        float top3            = (height/ppi - y_bot_proj) * ppi - dot_height;
        float wide3           = string_pix_count;
        float tall3           = dot_height;
        rect(left3, top3, wide3, tall3);
      }
    }
  }
}



void mousePressed() {
  if (mouseButton == LEFT) {
    append_click(mouseX, mouseY);
    append_click(mouseX, mouseY);
    append_click(mouseX, mouseY);
    append_click(mouseX, mouseY);
    append_click(mouseX, mouseY);
    append_click(mouseX, mouseY);
    append_click(mouseX, mouseY);
  } else if (mouseButton == RIGHT) {
    if (water_color == 255) {
      water_color = 0;
    } else {
      water_color = 255;
    }
  }
}

void keyPressed() {

  /* Globe A
   ---------------------------------------------------------*/
  if (true == true) {                                    
    if (key == 'w') {                                       // adds value to the dimension that the mouse cannot move in
      if (xpin == true) {
        globe[0] = globe[0] + step;
      } else if (ypin == true) {
        globe[1] = globe[1] + step;
      } else if (zpin == true) {
        globe[2] = globe[2] + step;
      }
    } else if (key == 's') {
      if (xpin == true) {                                   // subtracts value from the dimension that the mouse cannot move in
        globe[0] = globe[0] - step;
      } else if (ypin == true) {
        globe[1] = globe[1] - step;
      } else if (zpin == true) {
        globe[2] = globe[2] - step;
      }
    } else if (key == 'e') {                                // adds to radius
      radius = radius + step;
    } else if (key == 'd') {                                // subs from to radius
      radius = radius - step;
    } else if (key == 'a') {                                // allows mouse control for radius (hold down 'a' and bring mouse up or down)
      radius = (height - mouseY) * .8;
      mouse = false;
    } else if (key == 'q') {                                // stops ball in place so that you can pop it somewhere else
      mouse = false;
    } else if (key == 'z') {                                // color control (hold down buttons and bring mouse up or down)
      colorval_r = (height - mouseY) * 255 / height;
    } else if (key == 'x') {
      colorval_g = (height - mouseY) * 255 / height;
    } else if (key == 'c') {
      colorval_b = (height - mouseY) * 255 / height;
    } else if (key == 'v') {
      colorval_r = (height - mouseY) * 255 / height;
      colorval_g = (height - mouseY) * 255 / height;
      colorval_b = (height - mouseY) * 255 / height;
    } else if (key == '1') {                                // x y z pin switches
      xpin = true;
      ypin = false;
      zpin = false;
    } else if (key == '2') {
      xpin = false;
      ypin = true;
      zpin = false;
    } else if (key == '3') {
      xpin = false;
      ypin = false;
      zpin = true;
    } else if (key == 't') {                                 // beat mapper buttons - start, stop, effects, and multipliers
      start_time = millis();
    } else if (key == 'y') {
      end_time = millis();
      period = end_time - start_time;
      offset = start_time % period;
    } else if (key == 'g') {
      beat_multiplier = 1;
    } else if (key == 'h') {
      beat_multiplier = 2;
    } else if (key == 'j') {
      beat_multiplier = 4;
    } else if (key == 'k') {
      beat_multiplier = 8;
    } else if (key == 'b') {
      if (render_globe == false) {
        render_globe = true;
      } else {
        render_globe = false;
      }
    }
  }
}

void keyReleased() 
{
  if (mouse == false) {
    mouse = true;
  }
  if (key==' ') {
    if (millis()-last_32[31] > 1500) {
      last_32[31] = 0;
    }
    last_32 = subset(last_32, 1);
    last_32 = append(last_32, millis());
    for (int i=31; i>=0; i--) {
      if (last_32[i] == 0) {
        times_struck = 31 - i;
        first_strike = last_32[i+1];
        break;
      } else {
        times_struck = 32;
        first_strike = last_32[0];
      }
    }
    if (times_struck > 1) {
      period = (last_32[31] - first_strike) / (times_struck - 1);
    }
    offset = last_32[31];
  }
}


void loader() {                                           // loads data for this particular num_of_stringsmap
  map[0] = 15;
  map[1] = 13;
  map[2] = 0;
  map[3] = 29;
  map[4] = 37;
  map[5] = 6;
  map[6] = 31;
  map[7] = 14;
  map[8] = 9;
  map[9] = 0;
  map[10] = 12;
  map[11] = 24;
  map[12] = 3;
  map[13] = 26;
  map[14] = 39;
  map[15] = 18;
  map[16] = 3;
  map[17] = 28;
  map[18] = 11;
  map[19] = 18;
  map[20] = 1;
  map[21] = 20;
  map[22] = 24;
  map[23] = 8;
  map[24] = 7;
  map[25] = 22;
  map[26] = 17;
  map[27] = 34;
  map[28] = 37;
  map[29] = 1;
  map[30] = 23;
  map[31] = 10;
  map[32] = 2;
  map[33] = 33;
  map[34] = 6;
  map[35] = 34;
  map[36] = 27;
  map[37] = 12;
  map[38] = 19;
  map[39] = 25;
  map[40] = 11;
  map[41] = 14;
  map[42] = 5;
  map[43] = 15;
  map[44] = 27;
  map[45] = 4;
  map[46] = 25;
  map[47] = 8;
  map[48] = 32;
  map[49] = 35;
  map[50] = 7;
  map[51] = 30;
  map[52] = 21;
  map[53] = 4;
  map[54] = 16;
  map[55] = 2;
  map[56] = 20;
  map[57] = 17;
  map[58] = 38;
  map[59] = 22;
  map[60] = 32;
  map[61] = 36;
  map[62] = 30;
  map[63] = 10;

  for (int i = 0; i < trail; i ++ ) {
    click_time[i] = 0 - (i * 500);
  }
  for (int j=0; j<num_of_strings; j++) {                           // calculate x and z coordinates of each num_of_strings
    float xmap = (0 - (map_length / 2)) + j*map_unit;
    float hyp = sqrt(sq(xmap) + sq(depth));
    z_by_ind[j] = depth - map[j]*depth_unit;
    x_by_ind[j] = xmap - xmap*map[j]/hyp*depth_unit;
  }
}