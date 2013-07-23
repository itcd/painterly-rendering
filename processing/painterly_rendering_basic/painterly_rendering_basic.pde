// The next line is needed if running in JavaScript Mode with Processing.js
/* @pjs preload="moonwalk.jpg"; */

PImage img;

void setup() {
  img = loadImage("lotus.jpg");  // Load the image into the program
  size(img.width, img.height);
}

void draw()
{
  background(255);
  noStroke();
  img.loadPixels();
  
  int radius = 4;
  for(int i=0; i<img.height/radius; i++)
  {
    for(int j=0; j<img.width/radius; j++)
    {
      int x = j * radius;
      int y = i * radius;
      int loc = x + y * img.width;
      float r = red(img.pixels[loc]);
      float g = green(img.pixels[loc]);
      float b = blue(img.pixels[loc]);
      float average = (r + g + b) / 3;
      fill(color(r, g, b)); //<>//
      draw_points(x, y, radius, (255 - average) / 255 * 8 / radius);
    }
  }
}

float offset(float radius)
{
  return random(radius * 2) - radius;
}

void draw_points(int x, int y, float radius, float density)
{
  // calculate how many points to draw
  float radius_square = radius * radius;
  float amount = radius_square * density;
  
  for(int i=0; i<amount; i++)
  {
    // get a point within the circle with the radius
    float dx, dy;
    do
    {
      dx = offset(radius);
      dy = offset(radius);
    }while(dx * dx + dy * dy > radius_square);
    
    // draw the new point
    int x2 = x + (int)(dx);
    int y2 = y + (int)(dy);
    if(x2 >= 0  && x2 < img.width && y2 >= 0  && y2 < img.height)
    {
      int loc = x2 + y2 * img.width;
      ellipse (x2, y2, random(radius) + 1, random(radius) + 1);
    }
  }
}
