THREE.MeshLine = function() {
	this.positions = [];
	this.previous = [];
	this.next = [];
	this.side = [];
	this.width = [];
	this.indices_array = [];
	this.uvs = [];
	this.geometry = new THREE.BufferGeometry();
	this.widthCallback = null;
}

THREE.MeshLine.prototype.setGeometry = function( g, c ) {
	this.widthCallback = c;
	this.positions = [];
	if( g instanceof Float32Array || g instanceof Array ) {
		for( var j = 0; j < g.length; j += 3 ) {
			this.positions.push( g[ j ], g[ j + 1 ], g[ j + 2 ] );
			this.positions.push( g[ j ], g[ j + 1 ], g[ j + 2 ] );
		}
	}
	this.process();
}

THREE.MeshLine.prototype.compareV3 = function( a, b ) {

	var aa = a * 6;
	var ab = b * 6;
	return ( this.positions[ aa ] === this.positions[ ab ] ) && ( this.positions[ aa + 1 ] === this.positions[ ab + 1 ] ) && ( this.positions[ aa + 2 ] === this.positions[ ab + 2 ] );

}

THREE.MeshLine.prototype.copyV3 = function( a ) {

	var aa = a * 6;
	return [ this.positions[ aa ], this.positions[ aa + 1 ], this.positions[ aa + 2 ] ];

}

THREE.MeshLine.prototype.process = function() {

	var l = this.positions.length / 6;

	this.previous = [];
	this.next = [];
	this.side = [];
	this.width = [];
	this.indices_array = [];
	this.uvs = [];

	for( var j = 0; j < l; j++ ) {
		this.side.push( 1 );
		this.side.push( -1 );
	}

	var w;
	for( var j = 0; j < l; j++ ) {
		if( this.widthCallback ) w = this.widthCallback( j / ( l ) );
		else w = 1;
		this.width.push( w );
		this.width.push( w );
	}

	for( var j = 0; j < l; j++ ) {
		this.uvs.push( j / ( l+1 ), 0 );
		this.uvs.push( j / ( l+1 ), 1 );
	}

	var v;

	if( this.compareV3( 0, l - 1 ) ){
		v = this.copyV3( l - 2 );
	} else {
		v = this.copyV3( 0 );
	}
	this.previous.push( v[ 0 ], v[ 1 ], v[ 2 ] );
	this.previous.push( v[ 0 ], v[ 1 ], v[ 2 ] );
	for( var j = 0; j < l - 1; j++ ) {
		v = this.copyV3( j );
		this.previous.push( v[ 0 ], v[ 1 ], v[ 2 ] );
		this.previous.push( v[ 0 ], v[ 1 ], v[ 2 ] );
	}

	for( var j = 1; j < l; j++ ) {
		v = this.copyV3( j );
		this.next.push( v[ 0 ], v[ 1 ], v[ 2 ] );
		this.next.push( v[ 0 ], v[ 1 ], v[ 2 ] );
	}

	if( this.compareV3( l - 1, 0 ) ){
		v = this.copyV3( 1 );
	} else {
		v = this.copyV3( l - 1 );
	}
	this.next.push( v[ 0 ], v[ 1 ], v[ 2 ] );
	this.next.push( v[ 0 ], v[ 1 ], v[ 2 ] );

	for( var j = 0; j < l - 1; j++ ) {
		var n = j * 2;
		this.indices_array.push( n, n + 1, n + 2 );
		this.indices_array.push( n + 2, n + 1, n + 3 );
	}

	this.attributes = {
		position: new THREE.BufferAttribute( new Float32Array( this.positions ), 3 ),
		previous: new THREE.BufferAttribute( new Float32Array( this.previous ), 3 ),
		next: new THREE.BufferAttribute( new Float32Array( this.next ), 3 ),
		side: new THREE.BufferAttribute( new Float32Array( this.side ), 1 ),
		width: new THREE.BufferAttribute( new Float32Array( this.width ), 1 ),
		uv: new THREE.BufferAttribute( new Float32Array( this.uvs ), 2 ),
		index: new THREE.BufferAttribute( new Uint16Array( this.indices_array ), 1 )
	}

	this.geometry.addAttribute( 'position', this.attributes.position );
	this.geometry.addAttribute( 'previous', this.attributes.previous );
	this.geometry.addAttribute( 'next', this.attributes.next );
	this.geometry.addAttribute( 'side', this.attributes.side );
	this.geometry.addAttribute( 'width', this.attributes.width );
	this.geometry.addAttribute( 'uv', this.attributes.uv );

	this.geometry.setIndex( this.attributes.index );

}

THREE.MeshLineMaterial = function ( parameters ) {

	var vertexShaderSource = [
		// '#extension GL_OES_standard_derivatives : enable',
'precision highp float;',

'attribute vec3 position;',
'attribute vec3 previous;',
'attribute vec3 next;',
'attribute float side;',
'attribute float width;',
'attribute vec2 uv;',

'uniform mat4 projectionMatrix;',
'uniform mat4 modelViewMatrix;',
'uniform vec2 resolution;',
'uniform float lineWidth;',
'uniform vec3 color;',
'uniform float opacity;',
'uniform float near;',
'uniform float far;',
'uniform float sizeAttenuation;',
'uniform float time;',

'varying vec4 vColor;',
'uniform sampler2D audio;',

'float quadraticOut(float t) { return -t * (t - 2.0);}',

'vec2 fix( vec4 i, float aspect ) {',
'    vec2 res = i.xy / i.w;',
'    res.x *= aspect;',
'    return res;',
'}',
'',
'void main() {',
'    float aspect = resolution.x / resolution.y;',
'	 float pixelWidthRatio = 1. / (resolution.x * projectionMatrix[0][0]);',
'    vColor = vec4( color, opacity );',
'    mat4 m = projectionMatrix * modelViewMatrix;',
'    vec4 finalPosition = m * vec4( position, 1.0 );',
'    vec4 prevPos = m * vec4( previous, 1.0 );',
'    vec4 nextPos = m * vec4( next, 1.0 );',
'    vec2 currentP = fix( finalPosition, aspect );',
'    vec2 prevP = fix( prevPos, aspect );',
'    vec2 nextP = fix( nextPos, aspect );',
'	 float pixelWidth = finalPosition.w * pixelWidthRatio;',
'    float w = 1.8 * pixelWidth * lineWidth * width;',
'    if( sizeAttenuation == 1. ) {',
'        w = 1.8 * lineWidth * width;',
'    }',
'    vec2 dir;',
'    if( nextP == currentP ) dir = normalize( currentP - prevP );',
'    else if( prevP == currentP ) dir = normalize( nextP - currentP );',
'    else {',
'        vec2 dir1 = normalize( currentP - prevP );',
'        vec2 dir2 = normalize( nextP - currentP );',
'        dir = normalize( dir1 + dir2 );',
'        vec2 perp = vec2( -dir1.y, dir1.x );',
'        vec2 miter = vec2( -dir.y, dir.x );',
'        //w = clamp( w / dot( miter, perp ), 0., 4. * lineWidth * width );',
'    }',
'    vec2 normal = vec2( -dir.y, dir.x );',
'    normal.x /= aspect;',
'    normal *= .5 * w;',
'    vec4 offset = vec4( normal * side, 0.0, 1.0 );',
'   finalPosition.xy += offset.xy;',
'   gl_Position = finalPosition;',
'}' ];

	var fragmentShaderSource = [
		// '#extension GL_OES_standard_derivatives : enable',
'precision highp float;',
'uniform sampler2D map;',
'varying vec4 vColor;',
'uniform float opacity;',
'uniform float intensity;',

'void main() {',
'    vec4 c = vColor;',
'	c.rgb *= intensity;',
'    gl_FragColor = c;',
'}' ];

	function check( v, d ) {
		if( v === undefined ) return d;
		return v;
	}

	THREE.Material.call( this );

	parameters = parameters || {};

	this.lineWidth = check( parameters.lineWidth, 1 );
	this.map = check( parameters.map, null );
	this.useMap = check( parameters.useMap, 0 );
	this.color = check( parameters.color, new THREE.Color( 0xffffff ) );
	this.opacity = check( parameters.opacity, 1 );
	this.resolution = check( parameters.resolution, new THREE.Vector2( 1, 1 ) );
	this.sizeAttenuation = check( parameters.sizeAttenuation, 1 );
	this.near = check( parameters.near, 1 );
	this.far = check( parameters.far, 1 );
	this.time = check( parameters.time, 0 );
	this.intensity = check( parameters.intensity, 0 );
	this.audioIndex = check( parameters.audioIndex, 0 );
	this.audio = check( parameters.audio, null );

	var uniforms = {
		time: { type: 'f', value: this.time },
		hIntensity: { type: 'fv1', value: parameters.hI },
		hPositions: { type: 'v3v', value: parameters.hP },
		intensity: { type: 'f', value: this.intensity },
		audioIndex: { type: 'f', value: this.audioIndex },
		lineWidth: { type: 'f', value: this.lineWidth },
		map: { type: 't', value: this.map },
		audio: { type: 't', value: this.audio },
		useMap: { type: 'f', value: this.useMap },
		color: { type: 'c', value: this.color },
		opacity: { type: 'f', value: this.opacity },
		resolution: { type: 'v2', value: this.resolution },
		sizeAttenuation: { type: 'f', value: this.sizeAttenuation },
		near: { type: 'f', value: this.near },
		far: { type: 'f', value: this.far },
	}

	// uniforms = THREE.UniformsUtils.merge([uniforms,THREE.UniformsLib.fog])
	var material = new THREE.RawShaderMaterial( {
		uniforms: uniforms,
		vertexShader: vertexShaderSource.join( '\r\n' ),
		fragmentShader: fragmentShaderSource.join( '\r\n' )
	});

	delete parameters.lineWidth;
	delete parameters.map;
	delete parameters.audio;
	delete parameters.useMap;
	delete parameters.hI;
	delete parameters.hP;
	delete parameters.color;
	delete parameters.opacity;
	delete parameters.resolution;
	delete parameters.sizeAttenuation;
	delete parameters.near;
	delete parameters.far;
	delete parameters.idx;
	delete parameters.time;
	delete parameters.intensity;
	delete parameters.audioIndex;

	material.type = 'MeshLineMaterial';
	parameters.fog = true
	material.setValues( parameters );
	return material;

};

THREE.MeshLineMaterial.prototype = Object.create( THREE.Material.prototype );
THREE.MeshLineMaterial.prototype.constructor = THREE.MeshLineMaterial;
