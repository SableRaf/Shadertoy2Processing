// https://www.shadertoy.com/view/Xds3Rr

import processing.sound.*;

SoundFile soundfile;
FFT fft;
Waveform waveform;

PGraphics audioDataTexture;

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
  
  audioDataTexture = createGraphics(512,2,P2D);

  //Load a soundfile
  soundfile = new SoundFile(this, "beat.aiff");

  // Load the shader file from the "data" folder
  myShader = loadShader("input_sound.glsl");

  // We assume the dimension of the window will not change over time,
  // therefore we can pass its values in the setup() function
  myShader.set("iResolution", float(width), float(height), 0.0);

  lastMousePosition = new PVector(float(mouseX),float(mouseY));

  // Play the file in a loop
  soundfile.loop();
  
  // Create and patch the FFT analyzer
  fft = new FFT(this, bands);
  fft.input(soundfile);
  
  // Create the Waveform analyzer and connect the playing soundfile to it.
  waveform = new Waveform(this, samples);
  waveform.input(soundfile);
}


void draw() {
  
  // Perform the analysis
  waveform.analyze();
  fft.analyze();
  
  audioDataTexture.beginDraw();
  //audioDataTexture.background(0);
  audioDataTexture.colorMode(RGB,1.0);
  audioDataTexture.noFill();
  for (int i = 0; i < bands; i++) {
      float colorValueFromFFT = fft.spectrum[i];
      float colorValueFromWaveform = waveform.data[i];
      
      audioDataTexture.loadPixels();
      
      audioDataTexture.stroke(colorValueFromFFT,colorValueFromFFT,colorValueFromFFT); // fft
      audioDataTexture.pixels[i] = color(colorValueFromFFT*255,0,0);
      
      audioDataTexture.stroke(colorValueFromWaveform,colorValueFromWaveform,colorValueFromWaveform); // waveform
      audioDataTexture.pixels[i+512] = color(colorValueFromWaveform*255,0,0);
      
      audioDataTexture.updatePixels();

  }
  audioDataTexture.endDraw();
  
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
