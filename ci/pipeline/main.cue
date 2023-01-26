package pipeline

let imageName = "explore-oci-build--delete-me"

secrets: "shared--gcr_service_account_key": "((bam_gcr_key))"

resources: [{
	name: "explore-oci-build-task"
	type: "git"
	source: uri: "https://github.com/crhntr/explore-oci-build-task"
}, {
	name: imageName
	type: "registry-image"
	source: {
		repository: "gcr.io/mapbu-cryogenics/pivotalcfbam/explore-oci-build--delete-me"
		username:   "_json_key"
		password:   "((bam_gcr_key))"
		tag:        "banana"
	}
}]

#greet: {
	task:  string | *"greet"
	image: imageName
	config: {
		platform: "linux"
		params: GREETING: string | *"¡Hola, mundo!"
		run: path:        "/main"
	}
}

jobs: [{
	name: "build"
	plan: [{
		get:     resources[0].name
		trigger: true
	}, {
		task:       "build-image"
		privileged: true
		config: {
			platform: "linux"
			image_resource: {
				type: "registry-image"
				source: repository: "concourse/oci-build-task"
			}
			inputs: [{
				name: resources[0].name
				path: "."
			}]
			outputs: [{name: "image"}]
			caches: [{path: "cache"}]
			params: UNPACK_ROOTFS: true
			run: path:             "build"
			output_mapping: image: imageName
		}
	}, #greet & {
		task: "smoke-test"
	}, {
		put: imageName
		params: image: imageName + "/image.tar"
	}]
}, {
	name: "i18n"
	plan: [{
		get:     imageName
		trigger: true
		passed: ["build"]
	}, {
		in_parallel: steps: [
			#greet & {
				task: "spanish"
			}, #greet & {
				task: "english"
				config: params: GREETING: "Hello, world!"
			},
			#greet & {
				task: "ukrainian"
				config: params: GREETING: "Привіт Світ!"
			}, #greet & {
				task: "italian"
				config: params: GREETING: "Ciao mondo!"
			}]
	}]
}]
