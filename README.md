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
