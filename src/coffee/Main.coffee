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
		@uniforms = {
			time: 	   { type: "f", value: 0 }
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
		@instancieds = []
		loader.load( "obj/suzanneHi.js", ( geo, mat ) =>
				@monkeykey = new THREE.Mesh( geo, @material )
				# Stage3d.add @monkeykey

				for k in [0...10]
					geometry = new THREE.InstancedBufferGeometry()
					g = new THREE.BufferGeometry()
					g.fromGeometry( geo )
					geometry.copy( g )

					particleCount = Math.floor(geo.vertices.length/10)
					translates = new Float32Array( particleCount * 3 )
					rotations = new Float32Array( particleCount * 3 )
					timeArray = new Float32Array( particleCount )
					orientations = new THREE.InstancedBufferAttribute( new Float32Array( particleCount * 4 ), 4, 1 );
					vector = new THREE.Vector4()
					for i in [0...particleCount] by 1
						i3 = i*3
						# UNIFORMS & ATTRIBUTES
						timeArray[i] =  Math.random()*1023
						translates[ i3 + 0 ] = geo.vertices[i+k*particleCount].x
						translates[ i3 + 1 ] = geo.vertices[i+k*particleCount].y
						translates[ i3 + 2 ] = geo.vertices[i+k*particleCount].z
						vector.set( (Math.random() * 2 - 1), (Math.random() * 2 - 1), (Math.random() * 2 - 1), 1 );
						vector.normalize();
						orientations.setXYZW( i, vector.x, vector.y, vector.z, vector.w );

					geometry.addAttribute( "aTranslate", new THREE.InstancedBufferAttribute( translates, 3, 1 ) )
					geometry.addAttribute( "aTime", new THREE.InstancedBufferAttribute( timeArray, 1, 1 ) )
					geometry.addAttribute( 'orientation', orientations );

					@uniforms = {
						time: {type:'f', value:0}
					}

					material = new THREE.RawShaderMaterial( {
						vertexShader: require('monkeyInstanced.vs'),
						fragmentShader: require('monkeyInstanced.fs'),
						uniforms: @uniforms,
						depthTest: true,
						depthWrite: true
					} )

					meshInstanced = new THREE.Mesh( geometry, material )
					# Stage3d.add meshInstanced
					@instancieds.push(meshInstanced)
					@frustumCulled = false


				a.play()
				VJ.init(@context)
				VJ.onBeat.add(@onBeat)
				@masterGain.connect(VJ.analyser)

			)

		# ---------------------------------------------------------------------- START SOUND



		# ---------------------------------------------------------------------- STAGE EVENTS
		Stage.onUpdate.add(@update)
		Stage.onResize.add(@resize)
		@callback(1)
		return

	# -------------------------------------------------------------------------- UPDATE

	update:(dt)=>
		VJ.update(dt)
		@vignette.params.boost += ((1 + VJ.volume*5)-@vignette.params.boost)*.22
		for i in @instancieds
			if i.parent
				Stage3d.remove(i)
		Stage3d.add @instancieds[Math.floor(Math.random()*@instancieds.length)]
		# @analyser.getByteFrequencyData(@freqByteData)
		# @analyser.getByteTimeDomainData(@timeByteData)
		return

	onBeat:()=>
		return
	# -------------------------------------------------------------------------- RESIZE

	resize:()=>
		return

module.exports = Main
