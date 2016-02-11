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

		noisePass = new WAGNER.NoisePass();
		noisePass.params.amount = 0.1
		noisePass.params.speed = 0.2
		Stage3d.addPass(noisePass)

		@vignette = new WAGNER.Vignette2Pass()
		@vignette.params.boost = 1.4
		@vignette.params.reduction = 2
		Stage3d.addPass(@vignette)

		Stage3d.control = new OrbitControl(Stage3d.camera,500)
		Stage3d.control.phi = 1.144271333985873
		Stage3d.control.theta = 0.6269963207446427

		# ---------------------------------------------------------------------- SOUND

		@time = 0
		@context = new AudioContext()
		@masterGain = @context.createGain()
		@masterGain.gain.value = .1
		# @masterGain.connect(@context.destination)

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

		# MONKEY MONKEY

		@lights = []
		@colors = []
		# phi = 1.18
		# theta = 0
		# for i in [0...10] by 1
		# 	theta += (1 / 10)*Math.PI*2
		@lights.push(new THREE.Vector3( 100, 100, 100 ))
		@colors.push(new THREE.Vector3( 255, 0, 255 ))

		@lights.push(new THREE.Vector3( -100, 100, 100 ))
		@colors.push(new THREE.Vector3( 0, 255, 0 ))

		@lights.push(new THREE.Vector3( 0, -100, 0 ))
		@colors.push(new THREE.Vector3( 0, 0, 255 ))

		@lights.push(new THREE.Vector3( 0, 100, 0 ))
		@colors.push(new THREE.Vector3( 255, 0, 0 ))


		# @uniforms = {
		# 	opacity:    { type: "f", value: 1 }
		# 	time:  	    { type: "f", value: 0 }
		# 	# lights have 4 component : intensity, radius, theta, phi
		# 	lights:		{ type: "v4v", value: @lights }
		# 	sunIntensity:  { type: "f", value:1 }
		# 	sunColor:	   { type: "v3", value:new THREE.Vector3(2,2,2) }
		# 	skyColor:		{type: "v3", value:new THREE.Vector3(2,2,2) }
		# }

		@uniforms = {
			time: 	   { type: "f", value: 0 }
			lights:		{ type: "v3v", value: @lights }
			colors:		{ type: "v3v", value: @colors }
		}

		@material = new THREE.ShaderMaterial( {
			uniforms:       @uniforms
			vertexShader:   require('monkey.vs')
			fragmentShader: require('monkey.fs')
			depthTest:      true
			depthWrite:     false
			transparent:    true
			blending: 		THREE.AdditiveBlending
		})

		loader = new THREE.JSONLoader()
		loader.load( "obj/suzanneHi.js", ( geo, mat ) =>
				@monkeykey = new THREE.Mesh( geo, @material )
				# @monkeykey.scale.multiplyScalar( .25 )
				Stage3d.add @monkeykey
			)

		# ---------------------------------------------------------------------- START SOUND

		a.play()
		VJ.init(@context)
		VJ.onBeat.add(@onBeat)
		@masterGain.connect(VJ.analyser)


		# ---------------------------------------------------------------------- STAGE EVENTS
		Stage.onUpdate.add(@update)
		Stage.onResize.add(@resize)
		@callback(1)
		return

	# -------------------------------------------------------------------------- UPDATE

	update:(dt)=>
		VJ.update(dt)
		@vignette.params.boost += ((1 + VJ.volume*5)-@vignette.params.boost)*.22
		# @analyser.getByteFrequencyData(@freqByteData)
		# @analyser.getByteTimeDomainData(@timeByteData)
		return

	onBeat:()=>
		return
	# -------------------------------------------------------------------------- RESIZE

	resize:()=>
		return

module.exports = Main
