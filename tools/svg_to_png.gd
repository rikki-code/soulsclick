extends SceneTree
## Rasterizes SVG files to PNG with Godot's own ThorVG, so previews match the game.
## Usage:
##   godot --headless --path <project> -s tools/svg_to_png.gd -- <in.svg> <out.png> [scale]
##   godot --headless --path <project> -s tools/svg_to_png.gd -- --list <jobs.txt>
## A jobs file has one "in.svg<TAB>out.png<TAB>scale" line per job (scale optional).


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var jobs: Array = []
	if args.size() >= 2 and args[0] == "--list":
		for line in FileAccess.get_file_as_string(args[1]).split("\n", false):
			var cols := line.split("\t")
			if cols.size() >= 2:
				jobs.append([cols[0], cols[1], float(cols[2]) if cols.size() > 2 else 1.0])
	elif args.size() >= 2:
		jobs.append([args[0], args[1], float(args[2]) if args.size() > 2 else 1.0])
	else:
		push_error("usage: svg_to_png.gd -- <in.svg> <out.png> [scale] | --list <jobs.txt>")
		quit(2)
		return
	var failed := 0
	for job in jobs:
		if not _render(job[0], job[1], job[2]):
			failed += 1
	quit(1 if failed > 0 else 0)


func _render(in_path: String, out_path: String, scale: float) -> bool:
	if not FileAccess.file_exists(in_path):
		push_error("missing svg: %s" % in_path)
		return false
	var image := Image.new()
	var err := image.load_svg_from_string(FileAccess.get_file_as_string(in_path), scale)
	if err != OK:
		push_error("svg load failed (%s): %s" % [error_string(err), in_path])
		return false
	err = image.save_png(out_path)
	if err != OK:
		push_error("png save failed (%s): %s" % [error_string(err), out_path])
		return false
	print("wrote %s (%dx%d)" % [out_path, image.get_width(), image.get_height()])
	return true
