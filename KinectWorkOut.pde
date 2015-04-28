import SimpleOpenNI.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

SimpleOpenNI  context;
color[] userClr = new color[] { 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};

PVector[] prevhandPos = new PVector[6];
PVector[] prevhandPos2d = new PVector[6];

PVector[] nexthandPos = new PVector[6];
PVector[] nexthandPos2d = new PVector[6];

PVector[] ceilhandPos2d = new PVector[6];
  
int interval = 10;
int activeLevel = 150;

int hitCount = 0;

Minim minim;
AudioOutput out;
Oscil fm;

void setup()
{
  size(640*2, 480);

  context = new SimpleOpenNI(this);

  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  context.setMirror(true);
  // enable depthMap generation 
  context.enableRGB();
  context.enableDepth();
  // enable skeleton generation for all joints
  context.enableUser();

  strokeWeight(3);
  smooth();  

  textSize(32);

  rectMode(CORNERS);
  
  
  for(int i = 0; i<6; i++){
    prevhandPos[i] = new PVector();
    prevhandPos2d[i] = new PVector();
    
    nexthandPos[i] = new PVector();
    nexthandPos2d[i] = new PVector();
    
    ceilhandPos2d[i] = new PVector();
  }
  
   minim = new Minim(this);
   
   out   = minim.getLineOut();
  
  // make the Oscil we will hear.
  // arguments are frequency, amplitude, and waveform
  Oscil wave = new Oscil( 200, 0.8, Waves.TRIANGLE );
  // make the Oscil we will use to modulate the frequency of wave.
  // the frequency of this Oscil will determine how quickly the
  // frequency of wave changes and the amplitude determines how much.
  // since we are using the output of fm directly to set the frequency 
  // of wave, you can think of the amplitude as being expressed in Hz.
  fm   = new Oscil( 10, 2, Waves.SINE );
  // set the offset of fm so that it generates values centered around 200 Hz
  fm.offset.setLastValue( 200 );
  // patch it to the frequency of wave so it controls it
  fm.patch( wave.frequency );
  // and patch wave to the output
  wave.patch( out );
}

void draw()
{
  //clean the canvas
  background(255);

  // update the cam
  context.update();

  //draw rgmImageMap
  image(context.rgbImage(), 0, 0);

  //refresh each frame to get users data
  int[] userList = context.getUsers();
  //refresh the length of array
  PVector[] handPos = new PVector[userList.length];
  PVector[] handPos2d = new PVector[userList.length];

  fill(0);
  text(userList.length+" "+"users onboard", 640, 30);
  text("Rock score:" +" "+hitCount, 640, 70);
  
  //reference line
  stroke(255);
  line(0,height-activeLevel,640,height-activeLevel);
  
  float modulateAmount = map( mouseY, 0, height, 220, 1 );
  float modulateFrequency = map( mouseX, 0, width, 0.1, 100 );
  
  fm.setFrequency( modulateFrequency );
  fm.setAmplitude( modulateAmount );
  

  //for each user data
  for (int i=0; i<userList.length; i++)
  {  
    //initialize arrays of PVector
    handPos[i] = new PVector();
    handPos2d[i] = new PVector();

    if (context.isTrackingSkeleton(userList[i]))
    {
      //draw skeleton
      stroke(userClr[ (userList[i] - 1) % userClr.length ] );
      drawSkeleton(userList[i]);

      //convert PVectors
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, handPos[i]);
      context.convertRealWorldToProjective(handPos[i], handPos2d[i]);

      //visualise the result
      fill(userClr[ (userList[i] - 1) % userClr.length]);
      rect(640+150*i, 480, 640+150*i+100, handPos2d[i].y);
      text(handPos2d[i].y, 200*i, 30);
      
      
      
    }
    
    if (frameCount % interval == 0) {
        context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, prevhandPos[i]);
        context.convertRealWorldToProjective(prevhandPos[i], prevhandPos2d[i]);
      }

      if (frameCount % interval == interval/2) {
        context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, nexthandPos[i]);
        context.convertRealWorldToProjective(nexthandPos[i], nexthandPos2d[i]);
      }
      
      ceilhandPos2d[i].y = ceil(abs(prevhandPos2d[i].y-nexthandPos2d[i].y));
      //active level rect
      rect(100*i, 480, 100*i+100, 480-ceilhandPos2d[i].y);
        
      //average active level rect
      

  }
}

