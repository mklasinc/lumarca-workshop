String[] filenames = {"final_output64.txt","final_output80.txt","final_output96.txt","final_output100.txt","final_output128.txt"};

int field_width;
int field_height;
int x_step;
int y_step;
int origin_x;
int origin_y = 10;
//////////////////
int y_step_num = 40;
int string_num;
//////////////////
int[] y_pos_array;

String visualize_file = filenames[0];
  
//////////////////// TO DO LIST
/*
-- make an array of all the file names
-- from the setup, call a certain file to be drawn, like so: load_file(5);
-- use display height x width to distribute the circles all over the display window
-- what are all the possible x-y ratio for the display fields
-- 
*/


void setup(){

size(720,480);
load_file();

}

void draw(){
  fill(255,255,255);
  //println("drawing!");
  //rect(origin_x,origin_y,field_width,field_height);
  noStroke();
  fill(0,0,0);
  for(int i = 0; i < y_pos_array.length; i++){
    ellipse(origin_x + i*x_step, origin_y + y_pos_array[i]*y_step,5,5);
  }

}

void load_file(){
  String[] lines = loadStrings(visualize_file);
  println("There are " + lines.length + " lines.");
  String split_filename_string = "output";
  int dot_index = visualize_file.indexOf(".");
  int end_of_output_index = visualize_file.indexOf(split_filename_string) + split_filename_string.length();
  string_num = int(visualize_file.substring(end_of_output_index,dot_index));
  println("The number of strings is: " + string_num);
  y_pos_array = new int[string_num];

  
  for(int i = 0; i < lines.length; i++){
    println("we are called!,y_pos_array is: " + y_pos_array.length);
    lines[i] = lines[i].substring(lines[i].length() - 3,lines[i].length() - 1).trim();
    y_pos_array[i] = int(lines[i]);
  };
  
  param_setup();
  //printArray(yPos);
}

void param_setup(){
  field_width = int(width*0.8);
  origin_x = int(width*0.1);
  println("field width is: " + field_width);
  x_step = round(field_width/string_num);
  y_step = x_step;
  field_height = y_step_num*y_step;
}