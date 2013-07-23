//PShader blur;
PImage img;

void setup() {
  img = loadImage("apples.png");
  size(img.width, img.height);
  image(img, 0, 0); 
}

void draw() {
  filter(BLUR);
}
