// The next line is needed if running in JavaScript Mode with Processing.js
/* @pjs preload="moonwalk.jpg"; */

PImage img;
PImage sobel;
PImage kuwahara;

void setup() {
  String image_file = "cute_white_kitten.jpg";
  img = loadImage(image_file);  // Load the image into the program
  sobel = loadImage(image_file);
  kuwahara = loadImage(image_file);
  size(img.width, img.height);
  noLoop();
}

float get_value(int x, int y)
{
  int loc = x + y*img.width;
  color c = img.pixels[loc];
  return (red(c) + green(c) + blue(c)) / 3;
}

float get_value(int x, int y, PImage image)
{
  int loc = x + y*image.width;
  color c = image.pixels[loc];
  return (red(c) + green(c) + blue(c)) / 3;
}

void sobel_filter(PImage image1, PImage image2)
{
  image2.loadPixels();
  float gx, gy;
  for (int y = 1; y < img.height-1; y++)
  {
    for (int x = 1; x < img.width-1; x++)
    {
      gx = (get_value(x+1, y-1, image1) - get_value(x-1, y-1, image1)) + (get_value(x+1, y, image1) - get_value(x-1, y, image1)) * 2 + (get_value(x+1, y+1, image1) - get_value(x-1, y+1, image1));
      gy = (get_value(x-1, y+1, image1) - get_value(x-1, y-1, image1)) + (get_value(x, y+1, image1) - get_value(x, y-1, image1)) * 2 + (get_value(x+1, y+1, image1) - get_value(x+1, y-1, image1));
      int loc = x + y*image1.width;
      //float angle = atan(gy/gx);
      //println(angle/PI*180);
      image2.pixels[loc] = color(gx, gy, 0);
    }
  }
  image2.updatePixels();
}

void kuwahara_filter(PImage image1, PImage image2)
{
  int M = 4, N = 9;
  int[][] dx = {
  {0, -1, -2, 0, -1, -2, 0, -1, -2},
  {0, 1, 2, 0, 1, 2, 0, 1, 2},
  {0, -1, -2, 0, -1, -2, 0, -1, -2},
  {0, 1, 2, 0, 1, 2, 0, 1, 2}};
  int[][] dy = {
  {0, 0, 0, -1, -1, -1, -2, -2, -2},
  {0, 0, 0, -1, -1, -1, -2, -2, -2},
  {0, 0, 0, 1, 1, 1, 2, 2, 2},
  {0, 0, 0, 1, 1, 1, 2, 2, 2}};
  
  
  image2.loadPixels();
  float gx, gy;
  for (int y = 2; y < img.height-2; y++)
  {
    for (int x = 2; x < img.width-2; x++)
    {
      float [] variances = {0, 0, 0, 0};
      float [] means = {0, 0, 0, 0};
      for(int m=0; m<M; m++)
      {
        float sum = 0;
        for(int n=0; n<N; n++)
        {
          sum += get_value(x+dx[m][n], y+dy[m][n], image1);
        }
        means[m] = sum / N;
        
        float variance_sum = 0;
        for(int n=0; n<N; n++)
        {
          float difference = get_value(x+dx[m][n], y+dy[m][n], image1) - means[m];
          variance_sum += difference * difference;
        }
        variances[m] = variance_sum;
      }
      
      float mean_min = means[0];
      for(int m=0; m<M; m++)
      {
        if(means[m] < mean_min)
        {
          mean_min = means[m];
        }
      }
      int loc = x + y*image1.width;
      image2.pixels[loc] = color(mean_min, mean_min, mean_min);
    }
  }
  image2.updatePixels();
}

float arc_tangent(float y, float x)
{
  float angle;
  if(abs(x)<1e-6)
    angle = HALF_PI;
  else
    angle = atan(y/x);
  return angle + HALF_PI;
}

void draw()
{
  img.loadPixels();

  kuwahara_filter(img, kuwahara);
  sobel_filter(kuwahara, sobel);

  background(255);
  background(img);
  filter(BLUR, 6);
  
  int radius = 4;
  
/*  
  // fill background
  noStroke();
  for(int i=0; i<img.height/radius; i++)
  {
    for(int j=0; j<img.width/radius; j++)
    {
      int x = j * radius;
      int y = i * radius;
      int loc = x + y * img.width;
      fill(img.pixels[loc]);
      rect(x, y, radius, radius);
    }
  }
 */
 
 
 // draw points as stippling
  for(int i=1; i<img.height/radius; i++)
  {
    for(int j=1; j<img.width/radius; j++)
    {
      int x = j * radius;
      int y = i * radius;
      int loc = x + y * img.width;
      float r = red(img.pixels[loc]);
      float g = green(img.pixels[loc]);
      float b = blue(img.pixels[loc]);
      float average = (r + g + b) / 3;
      fill(color(r, g, b));
      stroke(color(r, g, b));
      draw_points(x, y, radius, (255 - average) / 255 * 16 / radius);
    }
  }
  
  //noStroke();
  //fill(color(0, 0, 0));
  stroke(color(0, 0, 0));
  for(int i=1; i<img.height/radius; i++)
  {
    for(int j=1; j<img.width/radius; j++)
    {
      int x = j * radius;
      int y = i * radius;
      int loc = x + y * img.width; 
      color c = sobel.pixels[loc];
      float r = red(c);
      float g = green(c);
      if(r+g > 32)
      {
        float angle = arc_tangent(g, r);
        float length = random((r+g)/255*8*radius);
        float xx = length * cos(angle);
        float yy = length * sin(angle);
        //ellipse(x, y, radius, radius);
        float weight = 2;
        strokeWeight(weight);
        line(x-xx, y-yy, x+xx, y+yy);
      }
    }
  }

  //background(sobel);
  //background(kuwahara);
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
      //ellipse (x2, y2, random(radius)+1, random(radius)+1);
      int loc = x + y * img.width;
      color c = sobel.pixels[loc];
      float r = red(c);
      float g = green(c);
      if(r+g > 32)
      {
//        float angle = arc_tangent(g, r);
        float angle = atan2(g, r);
        //ellipse (x2, y2, r/255*radius, g/255*radius);
        float length = random((r+g)/255*8*radius);
        float xx = length * cos(angle);
        float yy = length * sin(angle);
        //pushMatrix();
        float weight = 3;
        strokeWeight(weight);
        line(x2-xx, y2-yy, x2+xx, y2+yy);
        //rotate(angle+HALF_PI);
        //line(x2, y2, x2, y2+length);
        //popMatrix();
      }
    }
  }
}
