#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// From Processing 2.1 and up, this line is optional
#define PROCESSING_COLOR_SHADER

// if you are using the filter() function, replace the above with
// #define PROCESSING_TEXTURE_SHADER

// ----------------------
//  SHADERTOY UNIFORMS  -
// ----------------------

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds) (replaces iGlobalTime which is now obsolete)

uniform sampler2D iChannel0;             // here we are wiring bufferA


void mainImage( out vec4 fragColor, in vec2 fragCoord );

void main() {
  mainImage(gl_FragColor,gl_FragCoord.xy);
}

// ------------------------------
//  SHADERTOY CODE BEGINS HERE  -
// ------------------------------


/*
	Reaction Diffusion - 2 Pass
	---------------------------

	Simple 2 pass reaction-diffusion, based off of "Flexi's" reaction-diffusion examples.
	It takes about ten seconds to reach an equilibrium of sorts, and in the order of a
	minute longer for the colors to really settle in.

	I'm really thankful for the examples Flexi has been putting up lately. From what I
	understand, he's used to showing his work to a lot more people on much bigger screens,
	so his code's pretty reliable. Reaction-diffusion examples are temperamental. Change
	one figure by a minute fraction, and your image can disappear. That's why it was really
	nice to have a working example to refer to.

    Anyway, I've done things a little differently, but in essense, this is just a rehash
	of Flexi's "Expansive Reaction-Diffusion" example. I've stripped this one down to the
	basics, so hopefully, it'll be a little easier to take in than the multitab version.

	There are no outside textures, and everything is stored in the A-Buffer. I was
	originally going to simplify things even more and do a plain old, greyscale version,
	but figured I'd better at least try to pretty it up, so I added color and some very
	basic highlighting. I'll put up a more sophisticated version at a later date.

	By the way, for anyone who doesn't want to be weighed down with extras, I've provided
	a simpler "Image" tab version below.

	One more thing. Even though I consider it conceptually impossible, it wouldn't surprise
	me at all if someone, like Fabrice, produces a single pass, two tweet version. :)

	Based on:

	// Gorgeous, more sophisticated example:
	Expansive Reaction-Diffusion - Flexi
	https://www.shadertoy.com/view/4dcGW2

	// A different kind of diffusion example. Really cool.
	Gray-Scott diffusion - knighty
	https://www.shadertoy.com/view/MdVGRh


*/

/*
// Ultra simple version, minus the window dressing.
void mainImage(out vec4 fragColor, in vec2 fragCoord){

    fragColor = 1. - texture(iChannel0, fragCoord/iResolution.xy).wyyw;

}
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord){


  // The screen coordinates.
  vec2 uv = fragCoord/iResolution.xy;

  // Read in the blurred pixel value. There's no rule that says you can't read in the
  // value in the "X" channel, but blurred stuff is easier to bump, that's all.
  float c = 1. - texture(iChannel0, uv).y;
  // Reading in the same at a slightly offsetted position. The difference between
  // "c2" and "c" is used to provide the highlighting.
  float c2 = 1. - texture(iChannel0, uv + .5/iResolution.xy).y;


  // Color the pixel by mixing two colors in a sinusoidal kind of pattern.
  //
  float pattern = -cos(uv.x*.75*3.14159 - .9)*cos(uv.y*1.5*3.14159 - .75)*.5 + .5;
  //
  // Blue and gold, for an abstract sky over a... wheat field look. Very artsy. :)
  vec3 col = pow(vec3(1.5, 1, 1)*c, vec3(1, 2.25, 6));
  col = mix(col, col.zyx, clamp(pattern - .2, 0., 1.) );

  // Extra color variations.
  //vec3 col = mix(vec3(c*1.2, pow(c, 8.), pow(c, 2.)), vec3(c*1.3, pow(c, 2.), pow(c, 10.)), pattern );
  //vec3 col = mix(vec3(c*1.3, c*c, pow(c, 10.)), vec3(c*c*c, c*sqrt(c), c), pattern );

  // Adding the highlighting. Not as nice as proper bump mapping, but still pretty effective.
  col += vec3(.6, .85, 1.)*max(c2*c2 - c*c, 0.)*12.;

  // Apply a vignette and increase the brightness for that fake spotlight effect.
  col *= pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y) , .125)*1.15;

  // Fade in for the first few seconds.
  col *= smoothstep(0., 1., iTime/2.);

  // Done... Edit: Final values should be gamma corrected, unless you're deliberately
  // not doing it for stylistic purposes... In this case, I forgot, but let's just pretend
  // it's a postprocessing effect. :D
  fragColor = vec4(min(col, 1.), 1);


}

