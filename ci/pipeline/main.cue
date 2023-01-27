package pipeline

let imageName = "explore-oci-build--delete-me"

let greetings = close({
  spanish:   "¡Hola, mundo!"
	english:   "Hello, world!"
	ukrainian: "Привіт Світ!"
	italian:   "Ciao mondo!"
})

let defaultLanguage = "spanish"

let secretExp = "^\\(\\([a-z0-9_]+\\)\\)$"

#secrets: {
	// language=goregexp
	[string]: =~secretExp
}
secrets: #secrets & { "shared--gcr_service_account_key": "((bam_gcr_key))" }

let repoResource = {
	name: "explore-oci-build-task"
	type: "git"
	source: uri: "https://github.com/crhntr/explore-oci-build-task"
}

resources: [repoResource, {
	name: imageName
	type: "registry-image"
	source: {
		repository: "gcr.io/mapbu-cryogenics/pivotalcfbam/explore-oci-build--delete-me"
		username:   "_json_key"
		password:   =~secretExp | *"((bam_gcr_key))"
		tag:        "banana"
	}
}]

#task: {
	task: string
	privileged?: true | false
	image?: string
	file?: string
	config?: {
		platform: "linux"
		params?: {[string]: string}
		run: {path: string, args?: [string]}
	}
}

#buildImage: {
	#task
	task:       "build-image"
	privileged: true
	config: {
		platform: "linux"
		image_resource: {
			type: "registry-image"
			source: repository: "concourse/oci-build-task"
		}
		inputs: [{
			name: string
			path: "."
		}]
		outputs: [{name: "image"}]
		caches: [{path: "cache"}]
		params: UNPACK_ROOTFS: "true"
		run: path:             "build"
	}
}

#greet: close({
	#task
	task:  string | *"greet"
	image: string | *imageName
	config: {
		platform: "linux"
		params: GREETING: string | *greetings[defaultLanguage]
		run: path:        "/main"
	}
})

let buildJobName = "build"

jobs: [{
	name: buildJobName
	plan: [{
		get:     repoResource.name
		trigger: true
	}, #buildImage & {
		config: inputs: [{name: repoResource.name}]
	}, #greet & {
		task: "smoke-test"
		image: "image"
	}, {
		put: imageName
		params: image: "image/image.tar"
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
