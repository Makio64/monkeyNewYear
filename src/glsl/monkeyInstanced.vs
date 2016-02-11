precision lowp float;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float scale;
uniform float time;

attribute vec3 position;
attribute vec3 normal;
attribute vec3 aTranslate;
attribute float aTime;
attribute vec4 orientation;

varying vec3 vNormal;
varying vec3 vPos;

$snoise2D

void main() {
	vNormal = normal;
	vPos = position;

	vec3 vPosition = position;
	vec3 o = orientation.xyz;
	vec3 vcV = cross(o, vPosition);
	vPosition = vcV * (2.0 * orientation.w) + (cross(o, vcV) * 2.0 + vPosition);

	vec3 pos = (vPosition*0.2+(aTranslate));
	vec4 mvPosition = modelViewMatrix * vec4( pos, 1.0 );
	gl_Position = projectionMatrix * mvPosition;
}
