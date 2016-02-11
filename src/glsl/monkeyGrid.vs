precision lowp float;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float time;

attribute vec3 position;
attribute vec3 normal;
attribute vec3 aTranslate;
attribute vec4 orientation;

void main() {
	vec3 vPosition = position;

	vec3 o = vec3(0.,time,0.);
	vec3 vcV = cross(o, vPosition);
	vPosition = vcV * (2.0 * orientation.w) + (cross(o, vcV) * 2.0 + vPosition);

	vec3 pos = (vPosition*.1+(aTranslate));
	vec4 mvPosition = modelViewMatrix * vec4( pos, 1.0 );
	gl_Position = projectionMatrix * mvPosition;
}
