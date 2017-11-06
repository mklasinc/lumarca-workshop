float hue = 0.1;
float hue_increase = 0.1;

void setup(){
  size(displayWidth,displayHeight);
  colorMode(HSB, 360,100,100);
}

void draw(){
  //float mx = map(mouseX,0,width,0,360);
  if(hue < 0){
    hue_increase *= -1;
  }else if(hue > 360){
    hue_increase *= -1;
  }
  hue += hue_increase;
  background(hue,100,100);
  fill(360 - hue,100,100);
  //rect(400,400, 400,400);
  println(hue);
  //println(mx,100,100);
}