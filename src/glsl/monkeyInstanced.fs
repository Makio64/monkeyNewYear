precision highp float;

varying vec3 vNormal;
varying vec3 vPos;

void main() {
	gl_FragColor = vec4(vNormal,1.);

}
