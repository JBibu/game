class_name Utils

const BLEND_TIME := 0.15

static func find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = find_anim_player(child)
		if result:
			return result
	return null

static func create_audio_player(parent: Node, path: String, volume_db: float = 0.0, spatial: bool = false) -> Node:
	var player: Node
	if spatial:
		player = AudioStreamPlayer3D.new()
	else:
		player = AudioStreamPlayer.new()

	if ResourceLoader.exists(path):
		player.stream = load(path)
	player.volume_db = volume_db
	parent.add_child(player)
	return player
