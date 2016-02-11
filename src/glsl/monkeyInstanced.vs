precision lowp float;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float scale;
uniform float time;
uniform float orientationMode;
uniform float normalMode;

attribute vec3 position;
attribute vec3 normal;
attribute vec3 aTranslate;
attribute vec4 orientation;

varying vec3 vNormal;
varying vec3 vPos;

void main() {
	vNormal = normal;
	vPos = position;

	vec3 vPosition = position;

	if(orientationMode==1.){
		vec3 o = orientation.xyz;
		vec3 vcV = cross(o, vPosition);
		vPosition = vcV * (2.0 * orientation.w) + (cross(o, vcV) * 2.0 + vPosition);
	}

	if(normalMode==1.){
		vec3 o = normal.xyz;
		vec3 vcV = cross(o, vPosition);
		vPosition = vcV * (2.0 * orientation.w) + (cross(o, vcV) * 2.0 + vPosition);
	}

	vec3 pos = (vPosition*scale+(aTranslate));
	vec4 mvPosition = modelViewMatrix * vec4( pos, 1.0 );
	gl_Position = projectionMatrix * mvPosition;
}
