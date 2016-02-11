precision lowp float;

// varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;

uniform vec3 lights[4];
uniform vec3 colors[4];

float exponentialIn(float t) {
  return t == 0.0 ? t : pow(2.0, 10.0 * (t - 1.0));
}

void main(void) {
	vec3 col = vec3( .25 );

	for( int i = 0; i < 4; i++ ) {
		vec3 lPos = lights[ i ] * 1.;
		vec3 lCol = colors[ i ];

		float d = distance( vPos, lPos );
		// float d2 = distance( vPos, vec3( 0. ) );
		// float e = exponentialIn(1.-smoothstep( 0., d2, d ));
		// col += ( lCol * d ) * pow( e, 2. );
		float intens = max( dot( vNormal, lPos ), 0. );
		float att = clamp( 1.0 - d * d / ( 190. * 190. ), 0., 1. );
		att *= att;
		// col += ( lCol * )
		col += lCol * intens;
	}

	gl_FragColor = vec4(col, 1.0);
}
