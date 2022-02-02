// Made by Thomas / Mewily at ISIMA
// Ytb : https://www.youtube.com/channel/UCMzM4J9w0OEAb077mfrfXog
// Licence : CC0 1.0 Universal (CC0 1.0) Public Domain Dedication
// (Do whatever you want with it)
// 02/02/2022 (so many 2...)

import processing.video.*;

Capture cam;
PImage camGray;
int tick = 0;

float[][] gray;
float[][] oldGray;
float[][] mov;
float avgX, avgY, oldAvgX, oldAvgY;
float movX, movY;
float movLength;

void setup() {
  size(640, 480);
  surface.setResizable(true);
  surface.setTitle("Test Movement Detection from Webcam");

  String[] cameras = Capture.list(); 
  printArray(cameras); 

  if (0 == cameras.length) {
    println("No camera on this computer !");
    exit();
  } 

  float divCoef = 1;
  cam = new Capture(this, int(640/divCoef), int(480/divCoef), cameras[0]);
  cam.start();

  camGray = createImage(cam.width, cam.height, ARGB);
  gray    = new float[camGray.width][camGray.height];
  oldGray = new float[camGray.width][camGray.height];
  mov     = new float[camGray.width][camGray.height];


  stroke(color(255, 0, 0));
  strokeWeight(10);

  fill(color(255));
  textSize(32);
  textAlign(LEFT);
}


void draw() {

  tick++;

  if (cam.available() == true)
  {
    cam.read();

    // Miror >|< effect on cam and camGray
    for (int x = 0; x < camGray.width/2; x++)
    {
      for (int y = 0; y < camGray.height; y++)
      {
        int opX = camGray.width-x-1;

        color swap = get(x, y, cam);
        set(x, y, get(opX, y, cam), cam);
        set(opX, y, swap, cam);

        set(x, y, get(x, y, cam), camGray);
        set(opX, y, swap, camGray);
      }
    }


    int step = 2;
    oldAvgX = avgX;
    oldAvgY = avgY;

    // Avegare of gray/white surface position (for movement)
    float tmpAvgX = 0;
    float tmpAvgY = 0;
    // NbTo avoid 0 division if no pixels are found
    float tmpAvgTotal = 0.001; 

    for (int x = step; x < camGray.width-step; x++)
    {
      for (int y = step; y < camGray.height-step; y++)
      { 
        oldGray[x][y] = (oldGray[x][y]*0+gray[x][y])/1;
        gray   [x][y] = grayScale(get(x, y, camGray));

        float c = abs(gray[x][y]-oldGray[x][y]); // c is inside [0, 255]
        c = c < 16 ? 0 : c; // limit noise
        mov[x][y] = c;
        float cOne = c/255; // cOne is inside [0, 1]

        set(x, y, color(c), camGray);
        tmpAvgX += cOne*x;
        tmpAvgY += cOne*y;
        tmpAvgTotal += cOne;
      }
    }
    tmpAvgX /= tmpAvgTotal;
    tmpAvgY /= tmpAvgTotal;

    avgX = (avgX*9+tmpAvgX)/10; // Smooth the value
    avgY = (avgY*9+tmpAvgY)/10;

    movX = (avgX-oldAvgX);
    movY = (avgY-oldAvgY);


    float movTmpLength = sqrt(movX*movX+movY*movY);
    movLength = (movLength*1+movTmpLength)/2; // Smooth the value

    // To fight against noisy pixels. Subtract this value to the current movement (movX, movY) vector
    float minLengthToDetect = 1.5; 
    movLength = movLength < minLengthToDetect ? 0 : movLength-minLengthToDetect;

    if (movLength == 0)
    {
      movX = 0;
      movY = 0;
    } else
    {
      movX = movX*movLength/movTmpLength;
      movY = movY*movLength/movTmpLength;
    }
    camGray.updatePixels();

    image(camGray, 0, 0, width, height);
    //Turn on to see the camera :
    //image(cam, 0, 0, width, height); 

    int line = 1;
    int textXpos = 10;
    text("movX : "+(movX >= 0 ? "+" : "")+nf(movX, 0, 3), textXpos, (line++)*30);
    text("movY : "+(movX >= 0 ? "+" : "")+nf(movY, 0, 3), textXpos, (line++)*30);
    text("length : "+movLength, textXpos, (line++)*30);

    // draw the movement vector 
    line(width/2, height/2, width/2+ 10*movX, height/2+10*movY);
  }
}

void keyPressed() {
  println(frameRate);
}

void exit() {
  println("Stop the cam");
  if (cam != null) // Check if cam is null (if the program exit in setup because there is no camera for instance)
  {
    cam.stop();
  }
  super.exit();
}

int PosTo1d(int x, int y, int w)    { return x+y*w; }
int PosTo1d(int x, int y, PImage p) { return PosTo1d(x, y, p.width); }

color get(int x, int y, PImage p) { return p.pixels[PosTo1d(x, y, p)]; }
void  set(int x, int y, color c, PImage p) { p.pixels[PosTo1d(x, y, p)] = c; }

float grayScale(color c) {  return (red(c)+green(c)+blue(c))/3.0; }
