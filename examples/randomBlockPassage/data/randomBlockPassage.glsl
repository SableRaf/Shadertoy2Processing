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
uniform float     iTimeDelta;            // render time (in seconds)
uniform int       iFrame;                // shader playback frame

uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform vec4      iDate;                 // (year, month, day, time in seconds)

//uniform float     iChannelTime[2];
//uniform vec3      iChannelResolution[2];


// Channels can be either 2D maps or Cubemaps.
// Pick the ones you need and uncomment them.


// uniform float     iChannelTime[1..4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[1..4]; // channel resolution (in pixels)

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

/*
uniform samplerCube iChannel0;
uniform samplerCube iChannel1;
uniform samplerCube iChannel2;
uniform samplerCube iChannel3;

uniform vec3  iChannelResolution[4]; // channel resolution (in pixels)

uniform float iChannelTime[4]; // Channel playback time (in seconds)
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord );

void main() {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}

// ------------------------------
//  SHADERTOY CODE BEGINS HERE  -
// ------------------------------

/*

	Random Block Passage
	--------------------

    A simple random block geometric flythrough with a dark tomb like feel. I see a lot of
	this kind of imagery on the net -- Usually, rendered in nice brightly lit pathtraced
    still-image form with reflections and so forth. This one is just a practice run for
    something more interesting I have in mind.

	I'll sometimes break the rule, but I try my best to get a scene running on my fast machine
	in fullscreen with reasonable efficiency. This one is borderline, but I'd imagine it'd
	run OK in the 800 by 450 window on a lot of systems. I could definitely get things running
	faster, but wanted the code to at least be mildly legible, so have only performed minor
	optimization.

	I also wanted to keep the character count down to a dull roar, so the scene is pretty
	basic. Although, it should still be mildy interesting... for about 15 seconds before you
	yawn and shut it down. :D

*/

// Maximum ray distance.
#define FAR 80.

// vec3 to float hash.
float hash31(vec3 p){

    float n = dot(p, vec3(13.163, 157.247, 7.951));
    return fract(sin(n)*43758.5453);
}


// Non-standard float to vec3 hash function.
vec3 hash13(float n){ return fract(vec3(2097152, 262144, 32768)*sin(n)); }


// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n ){

    n = max(abs(n), 0.001);
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;

    // Textures are stored in sRGB (I think), so you have to convert them to linear space
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);

}


// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){
    //return vec2(0); // Debug: Straight path.

    // Windy path.
    vec2 a = vec2(sin(z*.055), cos(z*.07));
    return vec2(a.x - a.y*.75, a.y*1.275 + a.x*1.125);
}




// Individual object IDs. Not used here.
//vec4 aID;
//float svObjID;

/*
// IQ's 3D signed box formula: I tried saving calculations by using the unsigned one, and
// couldn't figure out why the edges and a few other things weren't working. It was because
// functions that rely on signs require signed distance fields... Who would have guessed? :D
float sBoxS(vec3 p, vec3 b, float r){

  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)) + r/2., 0.) + length(max(d + r/2., 0.)) - r;
}

float sBoxS(vec3 p, vec3 b){

  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0.));
}
*/

float sBox(vec3 p, vec3 b){

  return length(max(abs(p) - b, 0.));
}


// Individual tile scale. "1" and "2" look OK, but it doesn't really work for values
// outside that.
const float gSc = 1.5;

// The overlapping random block distance field: In order to render repeat object that either
// sit up against one another, or slightly overlap, you have to render more than one cell to
// avoid artifacts. Four cells need to be considered, which means rendering everything four
// times. This would be better unrolled, tweaked, etc, but I think it reads a little better
// this way. Anyway, I've explained the process in other examples, like the "Jigsaw"
// example, and so forth.
//
float blocks(in vec3 p, float rndZ){

    // Warp the XY plane a bit to give the scene an undulated look.

    // Box scale. If you change this, you might need to make box size changes, etc.
    const float sc = gSc;

    // Cell centering.
    p += sc*.5;

    // The initial distance. I can't remember why I wanted this smallish amount. Usually,
    // you'd set it to some large number.
    float d = 1e5;

    //objID = vec2(0);

    // Unrolling and tweaking would speed this up, but at the expense of readability.
    // Hopefully, the compiler will do a bit of the work.
    for (int i=0; i<=1; i++){
        for (int j=0; j<=1; j++){

            // The cell ID.
            vec2 ip = floor(p.xy/sc - vec2(i, j)/2.)*sc + vec2(i, j)/2.*sc;

            // Local cell position. I remember figuring these out a while
            // back... I'll take my own word for it. :)
            vec3 q = vec3((mod(p.xy + vec2(i, j)/2.*sc, sc) - sc/2.), p.z);

            // Random cell number... to do some random stuff. :)
            float rnd = (hash31(vec3(ip, rndZ))*15. + 1.)/64.;

            // Shifts the base of the objects to a level point.
            q -= vec3(0, 0, -rnd);

            // IQ's unsigned box equation: If you don't need the negative surface values
            // (no refraction, edging, etc), save some cycles and use this.
            float obj = sBox(q, vec3(sc/4. - .02, sc/4. - .02, rnd));

            // Alternate overlapping cylinders. Doesn't suit the scene.
            //float obj = max(length(q.xy) - (sc/4. + .1), abs(q.z) - rnd);

            // Edged boxes. More expensive and doesn't really add to the scene..
            //float obj = sBoxS(q, vec3(sc/4. - .02, sc/4. - .02, rnd)); // Outer box.
            //obj = max(obj, -sBoxS(q + vec3(0, 0, rnd - .02/2.), vec3(sc/4. - .1, sc/4. - .1, .02))); // Inner.

			// Individual object ID. Not used here.
            //objID = (obj<d)? ip : objID;

            // Minimum of the four cell objects. Similar to the way Voronoi cells are handled.
            d = min(d, obj);


        }
	}


    // Return the scene distance, and include a bit of ray shortening to avoid a few minor
    // inconsistancies.
    return d;

}


// Ignoring the random blocks, this is a pretty simple scene. There's a large square tube with
// variable sized repeat boxes dispersed through it, and a small square tube carved through it.
// The surfaces are then coverd with random boxes. Simple in concept, but a little fiddly to
// code. Nevertheless, not too taxing.
float map(vec3 p){

    p.xy -= path(p.z);

    const float sc = 32.; // Section Z spacing.
    float ipZ = floor(p.z/sc); // Unique section ID.
    vec3 rnd3 = floor(vec3(4, 2, 4)*hash13(ipZ)); // Variable sized rooms.

    // We're using an "abs" operation to render two X, Y and Z walls at once, but we keep note
    // of their polarity to feed to a random generator to give different patterns on each side.
    vec3 sq = sign(p);


    // Repeat Z sections.
    vec3 q = vec3(p.xy, mod(p.z, sc) - sc/2.);

    vec3 walls = abs(q - vec3(2, .5, 0)) - vec3(5, 3, 6) - rnd3;
    float s2 = walls.z;

    // Scene distance: Initially set to a base room structure.
    float d = -max(max(walls.x, walls.y), walls.z);

    // Edging the walls out according to the individual tile scale.
    walls -= gSc/2.;

    // Left and right random block walls.
    float blX = blocks(vec3(q.yz, walls.x), sq.x);
    // Top and bottom random block walls -- offset half a tile width, because I thought it looked
    // more interesting that way.
    float blY = blocks(vec3(q.xz - gSc/4., walls.y), sq.y);
    // Front and back walls.
    float blZ = blocks(vec3(q.xy, walls.z), ipZ);

    // Combine the walls with the existing room structure.
    d = min(d, min(min(blX, blY), blZ));


    /////
    q = p;
    // Left and right block walls in the small square tube.
    float blXSm = blocks(vec3(q.yz - gSc/4., abs(q.x) - 1.5 - gSc/2.), sq.x);
    // Top and bottom block walls in the small square tube.
    float blYSm = blocks(vec3(q.xz, abs(q.y) - 1.5 - gSc/2.), sq.y);

    q = abs(q);

    // Carve out the small square tube and apply the random block walls to its
    // internal surface. The messy line below is equivalent to the following:
    // float smTube = max(q.x - 1.5, q.y - 1.5);
    // d = max(d, -smTube);
    // d = min(d, max(min(blXSm, blYSm), -s2));
    d = max(d, min(max(min(blXSm, blYSm), -s2), -max(q.x - 1.5, q.y - 1.5)));

    // It'd be a much simpler example with no room sections, but less interesting.
    //d = min(blX, blY);

    // No individual object IDs used, so we're saving the cyles.
    //aID.xyz = vec3(d, 1e5, 1e5);


    return d*.8;



}


/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap(sampler2D tx, in vec3 p, in vec3 n, float bf){

    const vec2 e = vec2(0.001, 0);

    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));

    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);

    return normalize(n + g*bf); // Bumped normal. "bf" - bump factor.

}
*/


// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0., d;
    for(int i = 0; i<96; i++){

        d = map(ro+rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001*(t*.125 + 1.) || t>FAR) break; // Alternative: .001*max(t*.25, 1.)
        t += d;

    }

    return min(t, FAR);
}

// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
    // Note the wider sample spread for an antialiasing effect. It looks better in some situations, but
    // far worse in others. Normally, something like ".001" would be used.
	const vec2 e = vec2(0.005, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
}



// Basic soft shadows.
float getShad(in vec3 ro, in vec3 n, in vec3 lp){

    const float eps = .001;

	float t = 0., sh = 1., dt;

    ro += n*eps*1.1;

    vec3 ld = (lp - ro);
    float lDist = length(ld);
    ld /= lDist;

    //t += hash31(ro + ld)*.005;

	for(int i=0; i<24; i++){

    	dt = map(ro + ld*t);

        sh = min(sh, 12.*dt/t);

 		t += clamp(dt, .02, .5);
        if(dt<0. || t>lDist){ break; }
	}

    return max(sh, 0.);
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float getAO(in vec3 p, in vec3 nor){

	float sca = 2., occ = 0.;

    for(float i=0.; i<5.; i++){
        float hr = .01 + i*.5/4.;
        float dd = map(nor*hr + p);
        occ += (hr - dd)*sca;
        sca *= .7;
    }

    return clamp(1. - occ, 0., 1.);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

	// Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*0.5)/iResolution.y;

	// Camera Setup.
    vec3 ro = vec3(0, 0, iTime*4.); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, 0, .25);  // "Look At" position.


    // Light positioning.
 	vec3 lp = ro + vec3(0., .25, 6);// Put it a bit in front of the camera.
 	vec3 lp2 = ro + vec3(0., .125, 16);// Put it a bit in front of the camera.

	// Using the Z-value to perturb the XY-plane.
	// Sending the camera, "look at," and two light vectors down the tunnel. The "path" function is
	// synchronized with the distance function. Change to "path2" to traverse the other tunnel.
	lk.xy += path(lk.z);
	ro.xy += path(ro.z);
	lp.xy += path(lp.z);
	lp2.xy += path(lp2.z);

    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159265/3.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x ));
    vec3 up = cross(fwd, rgt);

    // rd - Ray direction.
    vec3 rd = normalize(fwd + (uv.x*rgt + uv.y*up)*FOV);

    // Fish eye lens.
    //vec3 rd = normalize(forward + (uv.x*right + uv.y*up)*FOV);
    //rd = normalize(vec3(rd.xy, rd.z - dot(rd.xy, rd.xy)*.15));

    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy = r2( path(lk.z).x/32. )*rd.xy;

    // Standard ray marching routine. I find that some system setups don't like anything other than
    // a "break" statement (by itself) to exit.
	float t = trace(ro, rd);

    // Individual scene object sorting. Not used here.
    //svObjID = aID.x<aID.y && aID.x<aID.z? 0. : aID.y<aID.z? 1. : 2.;
    //svObjID2 = objID;

    // Initialize the scene color.
    vec3 col = vec3(0);

	// The ray has effectively hit the surface, so light it up.
	if(t<FAR){


    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    vec3 sn = getNormal(sp);


        // Texture positioning.
        const float txSc0 = .25;
        vec3 txP = vec3(sp.xy - path(sp.z), sp.z); // Line it up with the camera path. Optional.

        // Texture based bump mapping.
        //sn = doBumpMap(iChannel0, txP*txSc0, sn, .01);

        // Shadows andambient occlusion.
	    float ao = getAO(sp, sn);
        float sh = getShad(sp, sn, lp2);
        sh = min(sh + ao*.3, 1.);

    	// Light direction vectors.
	    vec3 ld = lp - sp;
	    vec3 ld2 = lp2 - sp;

        // Distance from respective lights to the surface point.
	    float distlpsp = max(length(ld), .001);
 	    float distlpsp2 = max(length(ld2), .001);

    	// Normalize the light direction vectors.
	    ld /= distlpsp;
	    ld2 /= distlpsp2;

	    // Light attenuation, based on the distances above.
	    float atten = 1.5/(1. + distlpsp*distlpsp*.25); // + distlpsp*distlpsp*0.025
	    float atten2 = 3./(1. + distlpsp2*distlpsp2*.25); // + distlpsp*distlpsp*0.025


    	// Ambient light.
	    float amb = ao*.35;

    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        float diff2 = max( dot(sn, ld2), 0.);
        //diff = pow(diff, 2.)*2.;
        //diff2 = pow(diff2, 2.)*2.;


    	// Specular lighting.
	    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
	    float spec2 = pow(max( dot( reflect(-ld2, sn), -rd ), 0.0 ), 32.);

	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = clamp(dot(sn, rd) + 1., .0, 1.);

        // Object texturing.
        vec3 texCol = tex3D(iChannel0, txP*txSc0, sn);
        texCol = smoothstep(0., .5, texCol);


    	// Combining the above terms to produce the final color. It was based more on acheiving a
        // certain aesthetic than science.
        col = (texCol*(diff*vec3(.4, .6, 1) + amb + vec3(.4, .6, 1)*spec*4.))*atten; // Light one.
        col += (texCol*(diff2*vec3(1, .4, .2) + amb + vec3(1, .4, .2)*spec2*4.))*atten2; // Light two.
        //col += texCol*vec3(1, .05, .15)*pow(fre, 4.)*2.*(atten + atten2);


	    // Applying the ambient occlusion and shadows.
        col *= ao*sh;

	}

    // Blend the scene with some background light. Interesting, but I wanted more of a dark tomb kind of feel.
    //col = mix(col, vec3(1.8, 1, .9), smoothstep(.2, .99, t/FAR));

    // Cooler colors... as in, less warm. :)
    //col *= vec3(.85, .95, 1.25);

    // Vignette.
    uv = fragCoord/iResolution.xy;
    col = mix(col, vec3(0), (1. - pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .0625)));


    // Clamp and present the pixel to the screen.
	fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.0);

}

// ----------------------------
//  SHADERTOY CODE ENDS HERE  -
// ----------------------------
