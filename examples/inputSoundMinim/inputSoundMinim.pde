// https://www.shadertoy.com/view/Xds3Rr

import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioPlayer soundfile;
FFT fft;
float fftScale = 5;

PImage audioDataTexture;

// Define how many FFT bands we want
int bands = 512;

// Define how many samples of the Waveform you want to be able to read at once
int samples = 512;

PShader myShader;

// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)

// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube

float previousTime = 0.0;

boolean mouseDragged = false;

PVector lastMousePosition;
float mouseClickState = 0.0;

void setup() {
  size(640, 360, P2D);
  
  audioDataTexture = createImage(bands, 2, ARGB);

  minim = new Minim(this);
  
  //Load a soundfile
  soundfile = minim.loadFile("../inputSound/data/beat.aiff", 1024);

  // Load the shader file from the "data" folder
  myShader = loadShader("input_sound.glsl");

  // We assume the dimension of the window will not change over time,
  // therefore we can pass its values in the setup() function
  myShader.set("iResolution", float(width), float(height), 0.0);

  lastMousePosition = new PVector(float(mouseX),float(mouseY));

  // Play the file in a loop
  soundfile.loop();
  
  // Create and patch the FFT analyzer
  fft = new FFT( soundfile.bufferSize(), soundfile.sampleRate() );
}

void draw() {
  
  // Perform the analysis
  fft.forward(soundfile.mix);
  
  audioDataTexture.loadPixels();
  for (int i = 0; i < bands; i++) {      
      audioDataTexture.pixels[i] = 
        (int)constrain(fft.getBand(i) * fftScale, 0, 255) << 16;     
      audioDataTexture.pixels[i+audioDataTexture.width] = 
        (int)constrain(128 + 127 * soundfile.mix.get(i), 0, 255) << 16;
  }
  audioDataTexture.updatePixels();

  myShader.set("iChannel0", audioDataTexture);

  // shader playback time (in seconds)
  float currentTime = millis()/1000.0;
  myShader.set("iTime", currentTime);

  // render time (in seconds)
  float timeDelta = currentTime - previousTime;
  previousTime = currentTime;
  myShader.set("iDeltaTime", timeDelta);

  // shader playback frame
  myShader.set("iFrame", frameCount);

  // mouse pixel coords. xy: current (if MLB down), zw: click
  if(mousePressed) {
    lastMousePosition.set(float(mouseX),float(mouseY));
    mouseClickState = 1.0;
  } else {
    mouseClickState = 0.0;
  }
  myShader.set( "iMouse", lastMousePosition.x, lastMousePosition.y, mouseClickState, mouseClickState);

  // Set the date
  // Note that iDate.y and iDate.z contain month-1 and day-1 respectively,
  // while x does contain the year (see: https://www.shadertoy.com/view/ldKGRR)
  float timeInSeconds = hour()*3600 + minute()*60 + second();
  myShader.set("iDate", year(), month()-1, day()-1, timeInSeconds );

  // This uniform is undocumented so I have no idea what the range is
  myShader.set("iFrameRate", frameRate);

  // Apply the specified shader to any geometry drawn from this point
  shader(myShader);

  // Draw the output of the shader onto a rectangle that covers the whole viewport.
  rect(0, 0, width, height);

  resetShader();
  
  //image(audioDataTexture,0,0,width,height);

}
