# All great stories start with a Main.coffee

Stage 			= require('makio/core/Stage')
Stage3d 		= require('makio/core/Stage3d')
Interactions 	= require('makio/core/Interactions')
OrbitControl 	= require('makio/3d/OrbitControls')
Line 			= require('makio/3d/Line')
AudioTexture 	= require('makio/3d/AudioTexture')
VJ 				= require('makio/audio/VJ')



class Main

	# Entry point
	constructor:(@callback)->

		@callback(.5)

		@_idx = 0

		# ---------------------------------------------------------------------- INIT

		Stage3d.init({background:0x131011,clearAlpha:0.4})
		Stage3d.initPostProcessing()

		Stage3d.control = new OrbitControl(Stage3d.camera,500)
		Stage3d.control.phi = 1.144271333985873
		Stage3d.control.theta = -1.12

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
		a.src = "audio/daddy.mp3"
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
		@c1 = new THREE.Vector3( 255, 0, 255 )
		@colors.push( @c1 )

		@lights.push(new THREE.Vector3( -100, 100, 100 ))
		@c2 = new THREE.Vector3( 0, 255, 0 )
		@colors.push( @c2 )

		@lights.push(new THREE.Vector3( 0, -100, 0 ))
		@c3 = new THREE.Vector3( 0, 0, 255 )
		@colors.push( @c3 )

		@lights.push(new THREE.Vector3( 0, 100, 0 ))
		@c4 = new THREE.Vector3( 255, 0, 0 )
		@colors.push( @c4 )


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
			opacity:		{ type: "f", value: .75 }
			scale:		{ type: "f", value: 0 }
		}

		@uniformsA = {
			time: 	   { type: "f", value: 0 }
			lights:		{ type: "v3v", value: @lights }
			colors:		{ type: "v3v", value: @colors }
			opacity:		{ type: "f", value: .65 }
			scale:		{ type: "f", value: 0 }
		}

		@material = new THREE.ShaderMaterial( {
			uniforms:       @uniformsA
			vertexShader:   require('monkey.vs')
			fragmentShader: require('monkey.fs')
			depthTest:      true
			depthWrite:     false
			transparent:    true
			# blending: 		THREE.AdditiveBlending
		})





		loader = new THREE.JSONLoader()
		@materials = [@material1()]

		@instancieds = []
		loader.load( "obj/suzanneHi.js", ( geo, mat ) =>
				@monkeykeyMAIIIN = new THREE.Mesh( geo, @material )
				Stage3d.add @monkeykeyMAIIIN

				@container1 = new THREE.Object3D()
				@m1 = new THREE.Mesh( geo, @material )
				@m1.position.x = -100
				@m1.scale.multiplyScalar( .8 )
				@container1.add @m1
				@m2 = new THREE.Mesh( geo, @material )
				@m2.position.x = 100
				@m2.scale.multiplyScalar( .8 )
				@container1.add @m2
				Stage3d.add @container1

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
						lights:		{ type: "v3v", value: @lights }
						colors:		{ type: "v3v", value: @colors }
						opacity:		{ type: "f", value: 1 }
					}

					material = new THREE.RawShaderMaterial( {
						vertexShader: require('monkeyInstanced.vs'),
						fragmentShader: require('monkey.fs'),
						uniforms: @uniforms,
						depthTest: true,
						depthWrite: true,
						blending: 		THREE.AdditiveBlending
					} )

					meshInstanced = new THREE.Mesh( geometry, @materials[0] )
					# Stage3d.add meshInstanced
					@instancieds.push(meshInstanced)
					@frustumCulled = false

				Stage3d.add @instancieds[Math.floor(Math.random()*@instancieds.length)]

				@monkeykey = new THREE.Mesh( geo, @materials[0] )
				Stage3d.add @monkeykey

				@uniforms2 = {
					time: 	   { type: "f", value: 0 }
					lights:		{ type: "v3v", value: @lights }
					colors:		{ type: "v3v", value: @colors }
					opacity:		{ type: "f", value: .125 }
					scale: {type:'f', value:0}
				}

				material = new THREE.RawShaderMaterial( {
					vertexShader: require('monkeyInstanced.vs'),
					fragmentShader: require('monkey.fs'),
					uniforms: @uniforms2,
					depthTest: true,
					depthWrite: true
					transparent: true,
					blending: THREE.AdditiveBlending
				} )
				@monkeykeyMiddle = new THREE.Mesh( geo, material )
				@monkeykeyMiddle.scale.multiplyScalar( 4.5 )
				Stage3d.add @monkeykeyMiddle

				@uniforms3 = {
					time: 	   { type: "f", value: 0 }
					lights:		{ type: "v3v", value: @lights }
					colors:		{ type: "v3v", value: @colors }
					opacity:		{ type: "f", value: .125 }
					# scale: {type:'f', value:1}
					scale: {type:'f', value:.175}
				}

				material = new THREE.RawShaderMaterial( {
					vertexShader: require('monkeyInstanced.vs'),
					fragmentShader: require('monkey.fs'),
					uniforms: @uniforms3,
					depthTest: true,
					depthWrite: true
					transparent: true,
					blending: THREE.AdditiveBlending
				} )
				@monkeykey = new THREE.Mesh( geo, material )
				@monkeykey.scale.multiplyScalar( 6.5 )
				Stage3d.add @monkeykey

				@uniforms4 = {
					time: 	   { type: "f", value: 0 }
					lights:		{ type: "v3v", value: @lights }
					colors:		{ type: "v3v", value: @colors }
					opacity:		{ type: "f", value: .2 }
					scale: {type:'f', value:.2}
				}

				material = new THREE.RawShaderMaterial( {
					vertexShader: require('monkeyInstanced.vs'),
					fragmentShader: require('monkey.fs'),
					uniforms: @uniforms4,
					depthTest: true,
					depthWrite: true
					transparent: true,
					blending: THREE.AdditiveBlending
				} )
				@monkeykey = new THREE.Mesh( geo, material )
				@monkeykey.scale.multiplyScalar( 7.5 )
				Stage3d.add @monkeykey

				# @uniforms3 = {
				# 	time: 	   { type: "f", value: 0 }
				# 	lights:		{ type: "v3v", value: @lights }
				# 	colors:		{ type: "v3v", value: @colors }
				# 	opacity:		{ type: "f", value: .3 }
				# }
				#
				# material = new THREE.RawShaderMaterial( {
				# 	vertexShader: require('monkeyInstanced.vs'),
				# 	fragmentShader: require('monkey.fs'),
				# 	uniforms: @uniforms3,
				# 	depthTest: true,
				# 	depthWrite: true
				# 	transparent: true
				# } )
				# @monkeykey = new THREE.Mesh( geo, material )
				# @monkeykey.scale.multiplyScalar( 3 )
				# Stage3d.add @monkeykey

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
		@uniformsMaterial1.scale.value = VJ.volume*1
		@uniforms2.scale.value = VJ.volume
		@uniformsA.scale.value = VJ.volume
		# @uniformsA.scale.value = 1 + VJ.volume
		@uniforms3.scale.value = VJ.volume*1.5
		@uniforms4.scale.value = VJ.volume*10#+1
		if @_idx > 6
			for i in @instancieds
				if i.parent
					Stage3d.remove(i)
			Stage3d.add @instancieds[Math.floor(Math.random()*@instancieds.length)]
			@_idx = 0
			@uniforms3.opacity.value = .125 * Math.random()
			@uniforms4.opacity.value = .15 * Math.random()
		@_idx++
		r = Math.random()
		@material.wireframe = r < .05
		@material1.uniforms.opacity.value = if r < .05 then 0 else .65 + VJ.volume * .1
		@uniformsMaterial1.scale.value = .15 + VJ.volume*1

		if r < .4
			@monkeykeyMAIIIN.material.uniforms.opacity.value = 0
		else
			@monkeykeyMAIIIN.material.uniforms.opacity.value = .65

		if VJ.volume > .12
			@m1.material.uniforms.opacity.value = 0
		else
			@m1.material.uniforms.opacity.value = .23

		if VJ.volume > .12
			@m2.material.uniforms.opacity.value = 0
		else
			@m2.material.uniforms.opacity.value = .23

		@c1.x = VJ.volume * .4 * 4
		@c1.z = VJ.volume * .3 * 4
		@c2.y = VJ.volume * .2 * 4
		@c3.z = VJ.volume * .2 * 4
		@c4.x = VJ.volume * .4 * 4
		return

	# ---------------------------------------------------------------------- MATERIAL

	material1:()->
		@uniformsMaterial1 = {
			time: {type:'f', value:0}
			scale: {type:'f', value:0}
			lights:		{ type: "v3v", value: @lights }
			colors:		{ type: "v3v", value: @colors }
			# opacity:		{ type: "f", value: .4 }
			opacity:		{ type: "f", value: .75}
		}

		@material1= new THREE.RawShaderMaterial( {
			vertexShader: require('monkeyInstanced.vs'),
			fragmentShader: require('monkey.fs'),
			uniforms: @uniformsMaterial1,
			depthTest: true,
			depthWrite: true,
			transparent: true,
			# blending: THREE.AdditiveBlending
		} )
		return @material1

	onBeat:()=>
		Stage3d.bouboup = false#!Stage3d.bouboup
		Stage3d.setColorFromOption({background:0xFFFFFF*Math.random()})
		Stage3d.control.radius = Stage3d.control._radius = Math.random()*500+200
		Stage3d.control.phi = 1.144271333985873
		Stage3d.control.theta = -Math.PI/2+(Math.random()-.5)*.5
		return
	# -------------------------------------------------------------------------- RESIZE

	resize:()=>
		return

module.exports = Main
