package pipeline

let imageName = "explore-oci-build--delete-me"

let greetings = close({
  spanish:   "¡Hola, mundo!"
	english:   "Hello, world!"
	ukrainian: "Привіт Світ!"
	italian:   "Ciao mondo!"
})

let defaultLanguage = "spanish"

#secrets: {
	// language=goregexp
	[string]: =~ "^\\(\\([a-z0-9_]+\\)\\)$"
}
secrets: #secrets & { "shared--gcr_service_account_key": "((bam_gcr_key))" }

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

#greet: close({
	task:  string | *"greet"
	image: imageName
	config: close({
		platform: "linux"
		params: GREETING: string | *greetings[defaultLanguage]
		run: path:        "/main"
	})
})

let buildJobName = "build"

jobs: [{
	name: buildJobName
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
		passed: [buildJobName]
	}, {
		in_parallel: steps: [ for lang, message in greetings {
			#greet & {
				task: lang
				config: params: GREETING: message
			}
		}]
	}]
}]
