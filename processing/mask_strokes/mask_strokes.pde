// The next line is needed if running in JavaScript Mode with Processing.js
/* @pjs preload="moonwalk.jpg,mask.jpg"; */ 

PImage img;
PImage imgMask;

void setup() {
  size(640, 360);
  img = loadImage("moonwalk_cropped.png");
  imgMask = loadImage("stroke3.png");
  img.mask(imgMask);
  imageMode(CENTER);
}

void draw() {
  background(0, 102, 153);
  image(img, width/2, height/2);
  image(img, mouseX, mouseY);
}
