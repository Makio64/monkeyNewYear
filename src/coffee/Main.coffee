# All great stories start with a Main.coffee

Stage 			= require('makio/core/Stage')
Stage3d 		= require('makio/core/Stage3d')
Interactions 	= require('makio/core/Interactions')
# gui				= require('makio/core/gui')
OrbitControl 	= require('makio/3d/OrbitControls')
Line 			= require('makio/3d/Line')
AudioTexture 	= require('makio/3d/AudioTexture')
VJ 				= require('makio/audio/VJ')


class Main

	# Entry point
	constructor:(@callback)->

		@callback(.5)

		# ---------------------------------------------------------------------- INIT

		Stage3d.init({background:0x131011})
		Stage3d.initPostProcessing()

		@bloomPass = new WAGNER.MultiPassBloomPass();
		@bloomPass.params.strength = .5;
		@bloomPass.params.blurAmount = 0.1;
		@bloomPass.params.applyZoomBlur = true;
		@bloomPass.params.zoomBlurStrength = 0.3;
		# gui.add( @bloomPass.params, 'blurAmount' ).min(0).max(2);
		# gui.add( @bloomPass.params, 'applyZoomBlur' );
		# gui.add( @bloomPass.params, 'strength' ).min(0).max(20);
		# gui.add( @bloomPass.params, 'zoomBlurStrength' ).min(0).max(2);
		# gui.add( @bloomPass.params, 'useTexture' );
		Stage3d.addPass(@bloomPass)

		noisePass = new WAGNER.NoisePass();
		noisePass.params.amount = 0.1
		noisePass.params.speed = 0.2
		# gui.add( noisePass.params, 'amount', 0, 10 );
		# gui.add( noisePass.params, 'speed', 0, 10 );
		Stage3d.addPass(noisePass)

		@vignette = new WAGNER.Vignette2Pass()
		@vignette.params.boost = 1.4
		@vignette.params.reduction = 2
		# gui.add( @vignette.params, 'boost', 0, 10 );
		# gui.add( @vignette.params, 'reduction', 0, 5 );
		Stage3d.addPass(@vignette)

		Stage3d.control = new OrbitControl(Stage3d.camera,500)
		Stage3d.dragActivated = false
		Stage3d.control.phi = 1.144271333985873
		Stage3d.control.theta = 0.6269963207446427

		# ---------------------------------------------------------------------- SOUND

		@time = 0
		@context = new AudioContext()
		@masterGain = @context.createGain()
		@masterGain.gain.value = .1
		@masterGain.connect(@context.destination)

		@analyser = @context.createAnalyser()
		@analyser.smoothingTimeConstant = 0.4
		@analyser.fftSize = 256
		@masterGain.connect(@analyser)
		@binCount = @analyser.frequencyBinCount
		@levelBins = Math.floor(@binCount / @levelsCount)
		@freqByteData = new Uint8Array(@binCount)
		@timeByteData = new Uint8Array(@binCount)
		@waveData = new Uint8Array(@binCount)

		a = document.createElement( 'audio' )
		a.src = "audio/faded.mp3"
		a.loop = true
		audioSource = @context.createMediaElementSource( a )
		audioSource.connect( @masterGain )


		# ---------------------------------------------------------------------- TEXTURE

		@lines = []

		@audioTexture = new AudioTexture(@binCount,1)


		# for j in [0...32] by 1
		# 	material = new THREE.MeshLineMaterial(
		# 		map: null,
		# 		audio: @audioTexture,
		# 		color: new THREE.Color( 0xFFFFFF*Math.random() ),
		# 		opacity: 1,
		# 		transparent: true,
		# 		resolution: Stage3d.resolution,
		# 		sizeAttenuation: true,
		# 		lineWidth: 3,
		# 		blending: THREE.AdditiveBlending,
		# 		side:THREE.DoubleSide
		# 		near: Stage3d.camera.near,
		# 		far: Stage3d.camera.far,
		# 		depthTest:true,
		# 		depthWrite:false,
		# 	)
		#
		# 	step = 50
		# 	p = (j+1)/32*2-1
		# 	radius = 110
		# 	radius = Math.sqrt(Math.pow(radius,2) - Math.pow(radius*p,2))
		#
		# 	for i in [0...step] by 1
		# 		points = new Float32Array(step*3)
		# 		for i in [0..step] by 1
		# 			percent = i / (step-1)
		# 			angle = Math.PI*2*percent
		# 			k = i*3
		# 			points[k+0] = Math.cos(angle)*radius
		# 			points[k+1] = 0
		# 			points[k+2] = Math.sin(angle)*radius
		# 		line = new THREE.MeshLine()
		# 		line.setGeometry( points )
		# 	mesh = new THREE.Mesh(line.geometry,material)
		# 	mesh.frustumCulled = true
		# 	mesh.position.y = -110+(j/32)*220+10
		# 	Stage3d.add(mesh)
		# 	@lines.push(mesh)

		# loader = new THREE.JSONLoader()
		# loader.load "obj/Lucy100k_bin.js", ( geo, mats ) ->
		# 	console.log geo, mats

		# SPHERE MIDDLE
		# material = new THREE.MeshBasicMaterial({color:0})
		# mesh = new THREE.Mesh( new THREE.SphereGeometry(100,32,32), material )
		# Stage3d.add(mesh)

		a.play()
		VJ.init(@context)
		VJ.onBeat.add(@onBeat)
		@masterGain.connect(VJ.analyser)
		Stage.onUpdate.add(@update)
		Stage.onResize.add(@resize)

		@callback(1)
		return

	# -------------------------------------------------------------------------- UPDATE

	update:(dt)=>
		Stage3d.control.theta += (Interactions.mouse.unitX*4-Stage3d.control.theta)*0.02
		Stage3d.control.phi += ((Interactions.mouse.normalizedY-.5)*1.9+Math.PI/2-Stage3d.control.phi)*0.02
		VJ.update(dt)
		@bloomPass.params.zoomBlurStrength = 0.1+VJ.volume;
		@vignette.params.boost += ((1 + VJ.volume*5)-@vignette.params.boost)*.22
		# @analyser.getByteFrequencyData(@freqByteData)
		# @analyser.getByteTimeDomainData(@timeByteData)
		# for i in [0...@binCount] by 1
		# 	@waveData[i] = (@timeByteData[i]/256)
		# if(@audioTexture)
		# 	@audioTexture.update(@freqByteData)
		# for l in @lines
		# 	l.material.uniforms.lineWidth.value = 1+VJ.volume*80
		# 	l.material.uniforms.intensity.value += -l.material.uniforms.intensity.value*.1
		# 	l.scale.x += (1-l.scale.x)*.1
		# 	l.scale.y += (1-l.scale.y)*.1
		# 	l.scale.z += (1-l.scale.z)*.1
		return

	onBeat:()=>
		# line = @lines[Math.floor(Math.random()*@lines.length)]
		# line.material.uniforms.intensity.value = 10100
		# line.scale.x = 2+Math.random()*5
		# line.scale.y = 2+Math.random()*5
		# line.scale.z = 2+Math.random()*5
		@vignette.params.boost = 5
		# Make one line thicker / light
		return
	# -------------------------------------------------------------------------- RESIZE

	resize:()=>
		return

module.exports = Main
