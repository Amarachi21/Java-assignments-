import ddf.minim.*;
import ddf.minim.analysis.*;
 
Minim minim;
AudioPlayer song;
FFT fft;


float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20;   // 20%

// Create scores for the 3 zones
float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

// Track old scores for value ramping
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

// Rate at which the score decreases
float scoreDecreaseRate = 25;

// Initialize spheres function
int nbSpheres;
Sphere[] spheres;


// Initialize wall function
int nbMurs = 500;
Mur[] murs;
 
void setup()
{
  //Display in 3D on the whole screen
  fullScreen(P3D);
 
 // Initialize minim library
  minim = new Minim(this);
 
  // Load the song
  song = minim.loadFile("High.mp3");
  
  // Load the FFT object for spectral evaluation
  fft = new FFT(song.bufferSize(), song.sampleRate());
 
    // Connect cubes to frequencies
  nbSpheres = (int)(fft.specSize()*specHi);
  spheres = new Sphere[nbSpheres];
  
   // All the walls
  murs = new Mur[nbMurs];

  //Create the Sphere objects
  for (int i = 0; i < nbSpheres; i++) {
   spheres[i] = new Sphere(); 
  }
  
 // Create walls
  for (int i = 0; i < nbMurs; i+=4) {
   murs[i] = new Mur(0, height/2, 10, height); 
  }
  
  //Straight walls
  for (int i = 1; i < nbMurs; i+=4) {
   murs[i] = new Mur(width, height/2, 10, height); 
  }
  
  //low walls
  for (int i = 2; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, height, width, 10); 
  }
  
  //High walls
  for (int i = 3; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, 0, width, 10); 
  }
  
  //Black background
  background(0);
  
 // Start the song
  song.play(0);
}
 
void draw()
{

  // Move forward our evaluation of the song 1 "step"
  fft.forward(song.mix);
  
  // Calculate zone scores for this frame

  // Save old values (for easing)
  oldScoreLow = scoreLow;
  oldScoreMid = scoreMid;
  oldScoreHi = scoreHi;
  
    // - Reset values
  scoreLow = 0;
  scoreMid = 0;
  scoreHi = 0;
 
    // - Calculate lows, mids, high 
  for(int i = 0; i < fft.specSize()*specLow; i++)
  {
    scoreLow += fft.getBand(i);
  }
  
  for(int i = (int)(fft.specSize()*specLow); i < fft.specSize()*specMid; i++)
  {
    scoreMid += fft.getBand(i);
  }
  
  for(int i = (int)(fft.specSize()*specMid); i < fft.specSize()*specHi; i++)
  {
    scoreHi += fft.getBand(i);
  }
  
  // - Ease downward ramping of our zone scores based on decay rate
  if (oldScoreLow > scoreLow) {
    scoreLow = oldScoreLow - scoreDecreaseRate;
  }
  
  if (oldScoreMid > scoreMid) {
    scoreMid = oldScoreMid - scoreDecreaseRate;
  }
  
  if (oldScoreHi > scoreHi) {
    scoreHi = oldScoreHi - scoreDecreaseRate;
  }
  
  // # Create a "global" score that calculates the percieved intensity of all zones
  float scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
  
  // Set subtle background color based on intensity
  background(scoreLow/100, scoreMid/100, scoreHi/100);
  
  // Create Cubes for each frequency band
  for(int i = 0; i < nbSpheres; i++)
  {
    // Value of the frequency band
    float bandValue = fft.getBand(i);
    
    // Color hue and opacity changes based on overall scores
    spheres[i].display(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
  }
  
   // Walls lines, store preceding band value (and next) to connect them together
  float previousBandValue = fft.getBand(0);
  
// Distance between each line point, negative because on the z dimension
  float dist = -25;
  
  // Multiply the height by this constant
  float heightMult = 2;
  
    // Look through each band
  for(int i = 1; i < fft.specSize(); i++)
  {
    // Value of the frequency band, we multiply the bands farther away so that they are more visible.
    float bandValue = fft.getBand(i)*(1 + (i/50));
    
    // Color selection based on sound types
    stroke(100+scoreLow, 100+scoreMid, 100+scoreHi, 255-i);
    strokeWeight(1 + (scoreGlobal/100));
    
     // lower left line
    line(0, height-(previousBandValue*heightMult), dist*(i-1), 0, height-(bandValue*heightMult), dist*i);
    line((previousBandValue*heightMult), height, dist*(i-1), (bandValue*heightMult), height, dist*i);
    line(0, height-(previousBandValue*heightMult), dist*(i-1), (bandValue*heightMult), height, dist*i);
    
    // upper left line
    line(0, (previousBandValue*heightMult), dist*(i-1), 0, (bandValue*heightMult), dist*i);
    line((previousBandValue*heightMult), 0, dist*(i-1), (bandValue*heightMult), 0, dist*i);
    line(0, (previousBandValue*heightMult), dist*(i-1), (bandValue*heightMult), 0, dist*i);
    
    // lower right line
    line(width, height-(previousBandValue*heightMult), dist*(i-1), width, height-(bandValue*heightMult), dist*i);
    line(width-(previousBandValue*heightMult), height, dist*(i-1), width-(bandValue*heightMult), height, dist*i);
    line(width, height-(previousBandValue*heightMult), dist*(i-1), width-(bandValue*heightMult), height, dist*i);
   
    // lower right line
    line(width, (previousBandValue*heightMult), dist*(i-1), width, (bandValue*heightMult), dist*i);
    line(width-(previousBandValue*heightMult), 0, dist*(i-1), width-(bandValue*heightMult), 0, dist*i);
    line(width, (previousBandValue*heightMult), dist*(i-1), width-(bandValue*heightMult), 0, dist*i);
     
   // Save the band value for the next loop
    previousBandValue = bandValue;
  }
  
  // Wall rectangles
  for(int i = 0; i < nbMurs; i++)
  {
    //On assigne à chaque mur une bande, et on lui envoie sa force.
    float intensity = fft.getBand(i%((int)(fft.specSize()*specHi)));
    murs[i].display(scoreLow, scoreMid, scoreHi, intensity, scoreGlobal);
  }
}
// Class for cubes floating in space
class Sphere {
 // Z position of spawn and maximum Z position
  float startingZ = -10000;
  
  float maxZ = 1000; 
  
 
  // Position values
  float x, y, z;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;
  
    // Constructor
  Sphere() {
    // Make the cube appear at a random location
    x = random(0, width);
    //y = random(0 + height/3, height-height/3);
    y = height*0.5;
    z = random(startingZ, maxZ);
    
   // Give the cube a random rotation
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
  } 
  
  //======= Sphere ==========
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    
    // Color and opacity determined by intensity of the band
    color displayColor = color(scoreLow*0.9, scoreMid*0.9, scoreHi*0.9, intensity*5);
    fill(displayColor, 255);
    
    // Color lines, they disappear with the individual intensity of the cube
    color strokeColor = color(255, 150-(20*intensity));
    stroke(strokeColor);
    strokeWeight(1 + (scoreGlobal/300));
    
    // Creating a transformation matrix to perform rotations, enlargements
    pushMatrix();
    

    // Displacement
    translate(x, y, z);
    
     // Calculation of rotation as a function of intensity for the cube
    sumRotX += intensity*(rotX/1000);
    sumRotY += intensity*(rotY/1000);
    sumRotZ += intensity*(rotZ/1000);
    
   // Apply rotation
    rotateX(sumRotX);
    rotateY(sumRotY);
    rotateZ(sumRotZ);
    // Creation of the box, variable size depending on the intensity for the cube
    sphere(50+(intensity/2));
    
    // Apply matrix
    popMatrix();
    
     // Z displacement
    z+= (1+(intensity/5)+(pow((scoreGlobal/150), 2)));
    
    // Replace the box at the back when it is no longer visible
    if (z >= maxZ) {
      x = random(0, width);
      y = height*0.5;
      z = startingZ;
    }
  }
}


// Class to display the lines on the sides
class Mur {
  // Min/max Z position
  float startingZ = -10000;
  float maxZ = 50;
 
  // Position values
  float x, y, z;
  float sizeX, sizeY;
  
  // Constructor
  Mur(float x, float y, float sizeX, float sizeY) {
    // Line positioning
    this.x = x;
    this.y = y;
   // Random z depth
    this.z = random(startingZ, maxZ);  
    
     // Size is determined because the walls on the floors have a different size than those on the sides
    this.sizeX = sizeX;
    this.sizeY = sizeY;
  }
  
 // Display function
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    //Color determined by low, medium and high sounds
    color displayColor = color(scoreLow*0.79, scoreMid*0.79, scoreHi*0.79, scoreGlobal);
    
    //Make lines disappear in the distance to give an illusion of fog
    fill(displayColor, ((scoreGlobal-5)/1000)*(255+(z/25)));
    noStroke();
    
    // First band
    pushMatrix();
    
    // Displace
    translate(x, y, z);
    
     // Scale
    if (intensity > 100) intensity = 100;
    scale(sizeX*(intensity/100), sizeY*(intensity/100), 20);
    
    // Create a box
    box(4);
    popMatrix();
    
     // Second band, the one that is still the same size
    displayColor = color(scoreLow*0.5, scoreMid*0.5, scoreHi*0.5, scoreGlobal);
    fill(displayColor, (scoreGlobal/5000)*(255+(z/25)));
     // Transform matrix
    pushMatrix();
    
        // Displace
    translate(x, y, z);
    
    // Scale
    scale(sizeX, sizeY, 10);
    
     // Create box
    box(1);
    popMatrix();
    
     // Z displacement
    z+= (pow((scoreGlobal/150), 2));
    if (z >= maxZ) {
      z = startingZ;  
    }
  }
}
