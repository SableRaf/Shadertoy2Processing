# Shadertoy2Processing
Get GLSL code from Shadertoy.com to run inside of Processing

## Porting GLSL code from Shadertoy

Shadertoy and Processing both have their own quirks when it comes to shader programming. We need to make some changes in order to make Shadertoy code work with Processing.

1) Replace:
`void mainImage( out vec4 fragColor, in vec2 fragCoord )` -> `void main( void )`

2) Add the following line at the end of the mainImage() function:
`gl_FragColor = fragColor;`

There is more to it, but these tips should cover the most basic shaders.

Now go dig for some [shaders](https://www.shadertoy.com/results?query=filter) and help us extend the library of shaders available for Processing!


## To Do
- iChannelXX support
- Keyboard input
- Sound input
- cubemap example


## Examples
Input - Keyboard    : https://www.shadertoy.com/view/lsXGzf
Input - Microphone  : https://www.shadertoy.com/view/llSGDh
Input - Mouse       : https://www.shadertoy.com/view/Mss3zH
Input - Sound       : https://www.shadertoy.com/view/Xds3Rr
Input - SoundCloud  : https://www.shadertoy.com/view/MsdGzn
Input - Time        : https://www.shadertoy.com/view/lsXGz8
Input - TimeDelta   : https://www.shadertoy.com/view/lsKGWV
Input - 3D Texture  : https://www.shadertoy.com/view/4llcR4
