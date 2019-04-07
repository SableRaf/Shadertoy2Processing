// Reaction Diffusion - 2 Pass
// By Shane
// https://www.shadertoy.com/view/XsG3z1
// Ported to Processing by Kazik Pogoda

PShader bufferAShader;
PShader imageShader;
PGraphics bufferA;


float previousTime = 0.0;


void setup() {
  size(640, 360, P2D);
  //fullScreen(P2D);
  
  bufferA = createGraphics(width, height, P2D);

  // Load the shader files from the "data" folder
  bufferAShader = loadShader("bufferA.glsl");
  imageShader = loadShader("image.glsl");
  
  // We assume the dimension of the window will not change over time, 
  // therefore we can pass its values in the setup() function  
  bufferAShader.set("iResolution", float(width), float(height), 0.0);
  imageShader.set("iResolution", float(width), float(height), 0.0);
  bufferAShader.set("iChannel0", bufferA); // feedback loop
  imageShader.set("iChannel0", bufferA);
}


void draw() {
  
  // shader playback time (in seconds)
  float currentTime = millis()/1000.0;
  bufferAShader.set("iTime", currentTime);
  imageShader.set("iTime", currentTime);

  // shader playback frame
  bufferAShader.set("iFrame", frameCount);

  // draw bufferA first
  bufferA.beginDraw();
  bufferA.shader(bufferAShader);
  bufferA.rect(0, 0, width, height);
  bufferA.endDraw();

  // Apply the specified shader to any geometry drawn from this point  
  shader(imageShader);

  // Draw the output of the shader onto a rectangle that covers the whole viewport.
  rect(0, 0, width, height);

}
