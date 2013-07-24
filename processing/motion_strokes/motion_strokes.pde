PImage img_edge, img_yellow, img_magenta;
PImage img_original;
PImage intersection;
PImage buffer;
final int modulated_scale = 1; // both modulated_scale * size1 and modulated_scale * size2 should be in [0,255]
ArrayList<PVector> centroid_list1 = new ArrayList<PVector>(); // store the centroid and pixel count of a shape
ArrayList<PVector> centroid_list2 = new ArrayList<PVector>(); // store the centroid and pixel count of a shape
ArrayList<PVector> sample_list1 = new ArrayList<PVector>(); // store a sample point and intersection index of a shape
ArrayList<PVector> sample_list2 = new ArrayList<PVector>(); // store a sample point and intersection index of a shape
ArrayList<PVector> intersection_list = new ArrayList<PVector>(); // store pair of indexes for each intersection
int size1 = 0;
int size2 = 0;
int size3 = 0;
int channel = 0;

void reinitialise()
{
  centroid_list1.clear();
  centroid_list2.clear();
  sample_list1.clear();
  sample_list2.clear();
  intersection_list.clear();
  size1 = 0;
  size2 = 0;
  size3 = 0;
  channel = 0;
}

boolean in_range(PVector pos, PImage map)
{
  return (pos.x >= 0 && pos.x < map.width && pos.y >= 0 && pos.y < map.height);
}

color get_pixel(PVector pos, PImage map)
{
  int x = (int)pos.x;
  int y = (int)pos.y;
  return map.pixels[y * map.width + x];
}

void set_pixel(PVector pos, PImage map, color value)
{
  int x = (int)pos.x;
  int y = (int)pos.y;
  map.pixels[y * map.width + x] = value;
}

color get_modulated_colour(PVector pos, PImage map)
{
  color c = get_pixel(pos, map);
  if(channel == 1)
  { 
    return color(size1 * modulated_scale, green(c), blue(c)); 
  }else
  {
    return color(red(c), size2 * modulated_scale, blue(c));
  }
}

void add_centroid(int index, PVector pos)
{
  if(index > 0)
  {
    set_pixel(pos, buffer, get_modulated_colour(pos, buffer));
    if(channel == 1)
    {
      if(centroid_list1.size() < index)
      {
        centroid_list1.add(new PVector(0, 0, 0));
        sample_list1.add(new PVector(pos.x, pos.y, -1));
      }
      centroid_list1.get(index-1).add(new PVector(pos.x, pos.y, 1));
    }
    if(channel == 2)
    {
      if(centroid_list2.size() < index)
      {
        centroid_list2.add(new PVector(0, 0, 0));
        sample_list2.add(new PVector(pos.x, pos.y, -1));
      }
      centroid_list2.get(index-1).add(new PVector(pos.x, pos.y, 1));
    }
  }
}

/// Scanline Floodfill Algorithm With Stack http://lodev.org/cgtutor/floodfill.html
void flood_fill_recursive(PImage map, PVector start_node, color target_colour, color replacement_colour, int index)
{
  int N = 2;
  PVector diff[] = new PVector[N];
  diff[0] = new PVector(-1, 0);
  diff[1] = new PVector(1, 0);
  if(in_range(start_node, map) && get_pixel(start_node, map) == target_colour)
  {
    PVector dy = new PVector(0, 1);
    PVector pos = new PVector(start_node.x, start_node.y);

    // fill the current position
    set_pixel(pos, map, replacement_colour);
    add_centroid(index, pos);
    pos.add(dy);
    
    // fill scanline
    while(in_range(pos, map) && get_pixel(pos, map) == target_colour)
    {
      set_pixel(pos, map, replacement_colour);   
      add_centroid(index, pos);
      pos.add(dy);
    }
    
    // fill scanline
    dy.set(0, -1);
    pos = PVector.add(start_node, dy);
    while(in_range(pos, map) && get_pixel(pos, map) == target_colour)
    {
      set_pixel(pos, map, replacement_colour);
      add_centroid(index, pos);
      pos.add(dy);
    }
    
    // put a seed to its neighbour
    pos.y = start_node.y;
    while(in_range(pos, map) && get_pixel(pos, map) == replacement_colour)
    {
      PVector left = PVector.add(pos, diff[0]);
      PVector right = PVector.add(pos, diff[1]);
      if(in_range(left, map) && get_pixel(left, map) == target_colour)
      {
        flood_fill_recursive(map, left, target_colour, replacement_colour, index);
      }
      if(in_range(right, map) && get_pixel(right, map) == target_colour)
      {
        flood_fill_recursive(map, right, target_colour, replacement_colour, index);
      }
      pos.add(dy);
    }
    
    // put a seed to its neighbour
    dy.set(0, 1);
    pos.y = start_node.y + 1;
    while(in_range(pos, map) && get_pixel(pos, map) == replacement_colour)
    {
      PVector left = PVector.add(pos, diff[0]);
      PVector right = PVector.add(pos, diff[1]);
      if(in_range(left, map) && get_pixel(left, map) == target_colour)
      {
        flood_fill_recursive(map, left, target_colour, replacement_colour, index);
      }
      if(in_range(right, map) && get_pixel(right, map) == target_colour)
      {
        flood_fill_recursive(map, right, target_colour, replacement_colour, index);
      }
      pos.add(dy);
    }
  }
}

int decode_index_from_pixel(PVector pos, PImage map, int colour_channel)
{
  color c = get_pixel(pos, map);
  int index = 0;
  if(colour_channel == 1)
  {
    index = (int)(red(c) / modulated_scale);
  }else
  {
    if(colour_channel == 2)
    {
      index = (int)(green(c) / modulated_scale);
    }
  }
  return index - 1;
}

void increase_pixel_count(int index, PVector pos)
{
  int index1 = decode_index_from_pixel(pos, buffer, 1);
  int index2 = decode_index_from_pixel(pos, buffer, 2);
  
  if(intersection_list.size() < index)
  {
    intersection_list.add(new PVector(index1, index2, 0));
  }
  intersection_list.get(index-1).add(new PVector(0, 0, 1));
}

/// search for overlapping area by flood fill
void flood_fill_recursive_search(PImage map, PVector start_node, color target_colour, color replacement_colour, int index)
{
  int N = 2;
  PVector diff[] = new PVector[N];
  diff[0] = new PVector(-1, 0);
  diff[1] = new PVector(1, 0);
  if(in_range(start_node, map) && get_pixel(start_node, map) == target_colour)
  {
    PVector dy = new PVector(0, 1);
    PVector pos = new PVector(start_node.x, start_node.y);

    // fill the current position
    set_pixel(pos, map, replacement_colour);
    increase_pixel_count(index, pos);
    pos.add(dy);
    
    // fill scanline
    while(in_range(pos, map) && get_pixel(pos, map) == target_colour)
    {
      set_pixel(pos, map, replacement_colour);
      increase_pixel_count(index, pos);
      pos.add(dy);
    }
    
    // fill scanline
    dy.set(0, -1);
    pos = PVector.add(start_node, dy);
    while(in_range(pos, map) && get_pixel(pos, map) == target_colour)
    {
      set_pixel(pos, map, replacement_colour);
      increase_pixel_count(index, pos);
      pos.add(dy);
    }
    
    // put a seed to its neighbour
    pos.y = start_node.y;
    while(in_range(pos, map) && get_pixel(pos, map) == replacement_colour)
    {
      PVector left = PVector.add(pos, diff[0]);
      PVector right = PVector.add(pos, diff[1]);
      if(in_range(left, map) && get_pixel(left, map) == target_colour)
      {
        flood_fill_recursive_search(map, left, target_colour, replacement_colour, index);
      }
      if(in_range(right, map) && get_pixel(right, map) == target_colour)
      {
        flood_fill_recursive_search(map, right, target_colour, replacement_colour, index);
      }
      pos.add(dy);
    }
    
    // put a seed to its neighbour
    dy.set(0, 1);
    pos.y = start_node.y + 1;
    while(in_range(pos, map) && get_pixel(pos, map) == replacement_colour)
    {
      PVector left = PVector.add(pos, diff[0]);
      PVector right = PVector.add(pos, diff[1]);
      if(in_range(left, map) && get_pixel(left, map) == target_colour)
      {
        flood_fill_recursive_search(map, left, target_colour, replacement_colour, index);
      }
      if(in_range(right, map) && get_pixel(right, map) == target_colour)
      {
        flood_fill_recursive_search(map, right, target_colour, replacement_colour, index);
      }
      pos.add(dy);
    }
  }
}

// draw centroids
void draw_centroids()
{
  noFill();
  for(int i=0; i<size1; i++)
  {
    PVector p = centroid_list1.get(i);
    stroke(255);
    ellipse(p.x, p.y, 9, 9);
    stroke(0, 0, 255);
    ellipse(p.x, p.y, 7, 7);
    stroke(255);
    ellipse(p.x, p.y, 5, 5);
  }
  for(int i=0; i<size2; i++)
  {
    PVector p = centroid_list2.get(i);
    stroke(255);
    ellipse(p.x, p.y, 9, 9);
    stroke(0, 255, 0);
    ellipse(p.x, p.y, 7, 7);
    stroke(255);
    ellipse(p.x, p.y, 5, 5);
  }
}

boolean is_intersected(float rate1, float rate2)
{
  if(rate1 > 0.5 && rate2 > 0.5)
  {
    if(rate1 * rate2 > 95.449974)
    {
      println("  rate1 * rate2 = " + rate1 * rate2 + " > 95.449974 shapes are too close so no connection line is drawn for the above intersection");
      return false;
    }else
    {
      return true;
    }
  }else
 {
   return false;
 } 
}

// draw lines between centroids
void compute_and_draw_connection_lines()
{
  for(int i=0; i<size3; i++)
  {
    PVector p = intersection_list.get(i);
    int index1 = (int)p.x;
    int index2 = (int)p.y;
    PVector p1 = centroid_list1.get(index1);
    PVector p2 = centroid_list2.get(index2);
    float rate1 = p.z / p1.z;
    float rate2 = p.z / p2.z;
    PVector pp1 = sample_list1.get(index1);
    PVector pp2 = sample_list2.get(index2);
    
//    println("i=" + i + " index " + index1 + " " + index2 + " intersection count "+ p.z + " pixel count " + p1.z + " " + p2.z + " rate " + rate1 + " " + rate2);
    
    if(pp1.z == -1)
    {
      pp1.z = i;
//      println("  pp1.z==-1");
    }else
    {
      int pre_index = (int)pp1.z;
      PVector pre_p = intersection_list.get(pre_index);
      int pre_index1 = (int)pre_p.x;
      int pre_index2 = (int)pre_p.y;
      PVector pre_centroid1 = centroid_list1.get(pre_index1);
      PVector pre_centroid2 = centroid_list2.get(pre_index2);
      float pre_rate1 = pre_p.z / pre_centroid1.z;
      float pre_rate2 = pre_p.z / pre_centroid2.z;
//      println("  previous i=" + pp1.z + " index " + pre_index1 + " " + pre_index2 + " rate " + pre_rate1 + " " + pre_rate2);
      if(rate1 * rate2 > pre_rate1 * pre_rate2)
      {
        pp1.z = i;
//        println("  rate1 * rate2 > pre_rate1 * pre_rate2");
      }
    }
    if(pp2.z == -1)
    {
      pp2.z = i; 
//      println("  pp2.z==-1");
    }else
    {
      int pre_index = (int)pp2.z;
      PVector pre_p = intersection_list.get(pre_index);
      int pre_index1 = (int)pre_p.x;
      int pre_index2 = (int)pre_p.y;
      PVector pre_centroid1 = centroid_list1.get(pre_index1);
      PVector pre_centroid2 = centroid_list2.get(pre_index2);
      float pre_rate1 = pre_p.z / pre_centroid1.z;
      float pre_rate2 = pre_p.z / pre_centroid2.z;
//      println("  previous i=" + pp2.z  + " index " + pre_index1 + " " + pre_index2 + " rate " + pre_rate1 + " " + pre_rate2);
      if(rate1 * rate2 > pre_rate1 * pre_rate2)
      {
        pp1.z = i;
//        println("  rate1 * rate2 > pre_rate1 * pre_rate2");
      }
    }
    
    if(is_intersected(rate1, rate2))
    {
      strokeWeight(3);  // Thicker
      stroke(255, 0, 0);
      line(p1.x, p1.y, p2.x, p2.y);
      strokeWeight(1);  // Thicker
      stroke(255);
      line(p1.x, p1.y, p2.x, p2.y);
    }
  }  
}

// use scanline flood fill to search for intersection
void search_for_intersection()
{
  color target = color(255, 255, 255);
  int n = img_yellow.width * img_yellow.height;
  
  buffer.loadPixels();
  
  channel = 1;
  img_yellow.loadPixels();
  flood_fill_recursive(img_yellow, new PVector(0, 0), target, color(0, 0, 0), 0);
  for (int i = 1; i < n; i++)
  {
    if(img_yellow.pixels[i] == target)
    {
      size1++;
      flood_fill_recursive(img_yellow, new PVector(i % img_yellow.width, i / img_yellow.width), target, color(0, 0, 255), size1);
    }
  }
  img_yellow.updatePixels();
  
  channel = 2;
  img_magenta.loadPixels();
  flood_fill_recursive(img_magenta, new PVector(0, 0), target, color(0, 0, 0), 0);
  for (int i = 1; i < n; i++)
  {
    if(img_magenta.pixels[i] == target)
    {
      size2++;
      flood_fill_recursive(img_magenta, new PVector(i % img_magenta.width, i / img_magenta.width), target, color(0, 255, 0), size2);
    }
  }
  img_magenta.updatePixels();
  
  buffer.updatePixels();
  
  println("size1="+ size1 + " size2="+ size2 + " scale=" + modulated_scale + " (scale*size should be less than 256)");
  
  // compute controids
  for(int i=0; i<size1; i++)
  {
    PVector p = centroid_list1.get(i);
//    print(p.x + ", " + p.y + ", " + p.z + "\t");
    p.x = p.x / p.z;
    p.y = p.y / p.z;
//    println(centroid_list1.get(i).x + ", " + centroid_list1.get(i).y);
  }
  for(int i=0; i<size2; i++)
  {
    PVector p = centroid_list2.get(i);
    p.x = p.x / p.z;
    p.y = p.y / p.z;
  }
  
  intersection.loadPixels();
  for (int i = 0; i < n; i++)
  {
    int r, g, b;
    r = g = b = 0;
    if(img_yellow.pixels[i] == color(0, 0, 255))
    {
      b = 255;
    }
    if(img_magenta.pixels[i] == color(0, 255, 0))
    {
      g = 255;
    }
    if(r + g + b == 0)
    {
      r = g = b = 255;
    }
    intersection.pixels[i] = color(r, g, b);
  }

  target = color(0, 255, 255);
  flood_fill_recursive_search(intersection, new PVector(0, 0), target, color(0, 0, 0), 0);
  for (int i = 1; i < n; i++)
  {
    if(intersection.pixels[i] == target)
    {
      size3++;
      flood_fill_recursive_search(intersection, new PVector(i % intersection.width, i / intersection.width), target, color(128, 128, 128), size3);
    }
  }
  
  intersection.updatePixels();
}

float offset(float radius)
{
  return random(radius * 2) - radius;
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

// draw motion strokes on intersected shapes
void draw_motion_lines(int x, int y, float radius, float density, PVector pos1, PVector pos2)
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
    if(x2 >= 0  && x2 < img_original.width && y2 >= 0  && y2 < img_original.height)
    {
      //ellipse (x2, y2, random(radius)+1, random(radius)+1);
//      int loc = x + y * img_original.width;
      PVector dir = PVector.sub(pos1, pos2);
//      color c = sobel.pixels[loc];
//      float r = red(c); // gx
//      float g = green(c); // gy
//      if(r+g > 32)
      { //<>//
//        float angle = arc_tangent(dir.y, dir.x);
        float angle = atan2(dir.y, dir.x);
        //ellipse (x2, y2, r/255*radius, g/255*radius);
        float length = random((dir.x+dir.y)/255*8*radius);
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

//// draw motion strokes on intersected shapes
//void draw_motion_strokes(int x, int y, float radius, float density, PVector pos1, PVector pos2)
//{
//  PVector dir = PVector.sub(pos1, pos2);
//  float angle = atan2(dir.y, dir.x);
//  pushMatrix();
//  rotate(angle);
//  line(x - radius, y - radius, x + radius, y + radius);
//  popMatrix();
//  
////  // calculate how many points to draw
////  float radius_square = radius * radius;
////  float amount = radius_square * density;
////  
////  for(int i=0; i<amount; i++)
////  {
////    // get a point within the circle with the radius
////    float dx, dy;
////    do
////    {
////      dx = offset(radius);
////      dy = offset(radius);
////    }while(dx * dx + dy * dy > radius_square);
////    
////    // draw the new point
////    int x2 = x + (int)(dx);
////    int y2 = y + (int)(dy);
////    if(x2 >= 0  && x2 < img_original.width && y2 >= 0  && y2 < img_original.height)
////    {
////      //ellipse (x2, y2, random(radius)+1, random(radius)+1);
////      int loc = x + y * img_original.width;
////      PVector dir = PVector.sub(pos1, pos2);
//////      color c = sobel.pixels[loc];
//////      float r = red(c); // gx
//////      float g = green(c); // gy
//////      if(r+g > 32)
////      {
////        float angle = arc_tangent(dir.y, dir.x);
////        //ellipse (x2, y2, r/255*radius, g/255*radius);
////        float length = random((dir.x+dir.y)/255*8*radius);
////        float xx = length * cos(angle);
////        float yy = length * sin(angle);
////        //pushMatrix();
////        float weight = 3;
////        strokeWeight(weight);
////        line(x2-xx, y2-yy, x2+xx, y2+yy);
////        //rotate(angle+HALF_PI);
////        //line(x2, y2, x2, y2+length);
////        //popMatrix();
////      }
////    }
////  }
//}

String get_edge_filename(int n)
{
  if(n < 10)
    return "6/frame0000" + n + ".png";
  if(n >= 10 && n < 100)
    return "6/frame000" + n + ".png";
  if(n >= 100 && n < 1000)
    return "6/frame00" + n + ".png";
  if(n >= 1000 && n < 10000)
    return "6/frame0" + n + ".png";
  return "6/frame" + n + ".png";
}

String get_original_filename(int n)
{
  if(n < 10)
    return "1/frame0000" + n + ".png";
  if(n >= 10 && n < 100)
    return "1/frame000" + n + ".png";
  if(n >= 100 && n < 1000)
    return "1/frame00" + n + ".png";
  if(n >= 1000 && n < 10000)
    return "1/frame0" + n + ".png";
  return "1/frame" + n + ".png";
}

String get_target_filename(int n)
{
  if(n < 10)
    return "output/frame0000" + n + ".png";
  if(n >= 10 && n < 100)
    return "output/frame000" + n + ".png";
  if(n >= 100 && n < 1000)
    return "output/frame00" + n + ".png";
  if(n >= 1000 && n < 10000)
    return "output/frame0" + n + ".png";
  return "output/frame" + n + ".png";
}

void setup() {
  noLoop();

  String edge_image_str = get_edge_filename(0);
  img_edge = loadImage(edge_image_str);
  size(img_edge.width, img_edge.height);
}

void draw() {
////////////////////////////////////////////////////////////////
/// initialize
  final int radius = 2;
  for(int file_index=0; file_index<1; file_index++)
  {
    reinitialise();
    String edge_image_str = get_edge_filename(file_index);
    String original_image_str = get_original_filename(file_index);
    println(original_image_str);
    img_edge = loadImage(edge_image_str);
    img_original = loadImage(original_image_str);
  
    final int n = width * height;
    
    img_yellow = loadImage(edge_image_str);
    img_yellow.loadPixels();
    for (int i = 0; i < n; i++)
    {
      float r = red(img_yellow.pixels[i]);
      float g = green(img_yellow.pixels[i]);
      float b = blue(img_yellow.pixels[i]);
      img_yellow.pixels[i] = color(255, 255, b);
    }
    img_yellow.updatePixels();
    
    img_magenta = loadImage(edge_image_str);
    img_magenta.loadPixels();
    for (int i = 0; i < n; i++)
    {
      float r = red(img_magenta.pixels[i]);
      float g = green(img_magenta.pixels[i]);
      float b = blue(img_magenta.pixels[i]);
      img_magenta.pixels[i] = color(255, g, 255);
    }
    img_magenta.updatePixels();
    
    buffer = createImage(img_edge.width, img_edge.height, RGB);
    intersection = createImage(img_edge.width, img_edge.height, RGB);
  ////////////////////////////////////////////////////////////////
    
    search_for_intersection();
  //  intersection.copy(buffer, 0, 0, buffer.width, buffer.height, 0, 0, intersection.width, intersection.height);
  //  background(img_original);
    draw_centroids();
    compute_and_draw_connection_lines();
    
    buffer.loadPixels();
    intersection.loadPixels();
    img_original.loadPixels();
    
    background(255);
   
    // fill background
    noStroke();
    for(int i=0; i<img_original.height/radius; i++)
    {
      for(int j=0; j<img_original.width/radius; j++)
      {
        int x = j * radius;
        int y = i * radius;
        int loc = x + y * img_original.width;
        fill(img_original.pixels[loc]);
        rect(x, y, radius, radius);
      }
    }
    
    filter(BLUR);
    
   // draw motion strokes on intersected shapes
    for(int i=1; i<img_original.height/radius; i++)
    {
      for(int j=1; j<img_original.width/radius; j++)
      {
        int x = j * radius;
        int y = i * radius;
        int loc = x + y * img_original.width;
        
        PVector pos = new PVector(x, y);
  
        int i1 = decode_index_from_pixel(pos, buffer, 1);
        int i2 = decode_index_from_pixel(pos, buffer, 2);
        int index1 = -1;
        int index2 = -1;
        int index3 = -1;
        
        if(i1 != -1)
        {
          PVector sp1 = sample_list1.get(i1);
          if(sp1.z != -1)
          {
            index1 = i1;
            index3 = (int)sp1.z;
            PVector p3 = intersection_list.get(index3);
            index2 = (int)p3.y;
          }
        }else
        {
          if(i2 != -1)
          {
            PVector sp2 = sample_list2.get(i2);
            if(sp2.z != -1)
            {
              index2 = i2;
              index3 = (int)sp2.z;
              PVector p3 = intersection_list.get(index3);
              index1 = (int)p3.x;
            }
          }
        }
         
        if(index1 != -1 && index2 != -1 && index3 != -1)
        {
//          println("x=" + x + " y=" + y + "i1=" + i1 + " i2=" + i2 + " indexes " + index1 + " " + index2 + " " + index3);
          PVector centroid1 = centroid_list1.get(index1);
          PVector centroid2 = centroid_list2.get(index2);
          PVector p3 = intersection_list.get(index3);
          float rate1 = p3.z / centroid1.z;
          float rate2 = p3.z / centroid2.z;
          
          if(is_intersected(rate1, rate2))
          {
            float r = red(img_original.pixels[loc]);
            float g = green(img_original.pixels[loc]);
            float b = blue(img_original.pixels[loc]);
            float average = (r + g + b) / 3;
            fill(color(r, g, b));
            stroke(color(r, g, b));
            draw_motion_lines(x, y, radius, (255 - average) / 255 * 16 / radius, centroid1, centroid2);          
          }
        }
//        else
//        {
//          noStroke();
//          for(int ii=0; ii<radius; ii++)
//          {
//            for(int jj=0; jj<radius; jj++)
//            {
//              int xx = x + ii;
//              int yy = y + jj;
//              int loc2 = xx + yy * img_original.width;
//              fill(img_original.pixels[loc2]);
//              rect(xx, yy, 1, 1);
//            }
//          } 
//        }
      }
    }
    
    save(get_target_filename(file_index));    
  }
}
