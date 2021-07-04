package appshield.dockerfile.DS001

import data.lib.docker

__rego_metadata__ := {
	"id": "DS001",
	"title": "Use a tag name in FROM statement",
	"version": "v1.0.0",
	"severity": "MEDIUM",
	"type": "Dockerfile Security Check",
	"description": "When using 'FROM' statement you should use a specific tag to avoid uncontrolled behavior when image is updated",
	"recommended_actions": "Add a tag to the image in the FROM statement",
}

__rego_input__ := {
	"combine": false,
	"selector": [{"type": "dockerfile"}],
}

# image_names returns the image in FROM statement.
image_names[image_name] {
	from := docker.from[_]
	image_name := from.Value[0]
}

# image_tags returns the image and tag.
parse_tag(name) = [img, tag] {
	[img, tag] = split(name, ":")
}

# image_tags returns the image and "latest" if a tag is not specified.
parse_tag(img) = [img, tag] {
	tag := "latest"
	not contains(img, ":")
}

#base scenario
image_tags[[img, tag]] {
	name := image_names[_]
	not startswith(name, "$")
	[img, tag] = parse_tag(name)
}

#If variable is using with FROM then it's value should contain a tag
image_tags[[img, tag]] {
	some i, j, k, l
	name := image_names[i]

	cmd_obj := input.stages[j][k]

	possibilities := {"arg", "env"}
	cmd_obj.Cmd == possibilities[l]

	bare_var := trim_prefix(name, "$")

	startswith(cmd_obj.Value[0], bare_var)

	[_, bare_image_name] := regex.split(`\s*=\s*`, cmd_obj.Value[0])

	[img, tag] = parse_tag(bare_image_name)
}

# fail_latest is true if image is not scratch and
# tag is latest.
fail_latest[img] {
	[img, tag] := image_tags[_]
	img != "scratch"
	tag == "latest"
}

deny[res] {
	img := fail_latest[_]
	res := sprintf("Specify tag for image %s", [img])
}
