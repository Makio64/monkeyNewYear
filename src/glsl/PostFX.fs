varying vec2 vUv;
uniform sampler2D tInput;
uniform float noiseAmount;
uniform float noiseSpeed;
uniform float vignetteAmount;
uniform float vignetteFallOff;
uniform float invertRatio;
uniform float bwRatio;
uniform float mirrorX;
uniform float mirrorY;
uniform float divide4;
uniform float time;

float random(vec2 n, float offset ){
	return .5 - fract(sin(dot(n.xy + vec2( offset, 0. ), vec2(12.9898, 78.233)))* 43758.5453);
}

void main() {
	vec2 uv = vUv;

	//mirror
	// InterestingMirror
	// if(mirror>0.){ uv.x = abs(vUv.x-.5); }
	if(mirrorX>0.){ uv.x = abs(vUv.x-.5)+.5; }
	if(mirrorY>0.){ uv.y = abs(vUv.y-.5)+.5; }
	if(divide4>0.){ uv *= 2.; uv = mod(uv,vec2(1.)); }
	vec4 color = texture2D( tInput, uv );

	//noise
	color += vec4( vec3( noiseAmount * random( uv, .00001 * noiseSpeed * time ) ), 1. );

	//Vignette
	// float dist = distance(vUv, vec2(0.5, 0.5));
	// color.rgb *= smoothstep(0.8, vignetteFallOff * 0.799, dist * (vignetteAmount + vignetteFallOff));

	//invert
	color.rgb = mix(color.rgb, (1. - color.rgb),invertRatio);
	color.r = smoothstep(-0.2, 1.0, color.r);
	color.g = smoothstep(0.0, 1.0, color.g - 0.1);
	color.b = smoothstep(-0.3, 1.3, color.b);
	// color.rgb*=.6;
	//
	gl_FragColor = color;
}
