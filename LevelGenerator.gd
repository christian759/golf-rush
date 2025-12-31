extends Node2D

@export_multiline var level_data: String = ""
@export var ball_scene: PackedScene = preload("res://ball.tscn")
@export var hole_scene: PackedScene = preload("res://Hole.tscn")

const CELL_SIZE = 64
const TILE_SOURCE_OFFSET = 2 # IDs start at 2 for the 3x3 block

# 3x3 Block Mapping
# 0 1 2
# 3 4 5
# 6 7 8
#
# ID Mapping in TileSet (programmatically created):
# 2: TL (tileYellow_01.png), 3: T (tileYellow_02.png), 4: TR (tileYellow_03.png)
# 5: L (tileYellow_04.png),  6: C (tileYellow_05.png), 7: R (tileYellow_06.png)
# 8: BL (tileYellow_07.png), 9: B (tileYellow_08.png), 10: BR (tileYellow_09.png)

var tileset: TileSet

func _ready():
	_create_tileset()
	generate_level()

func _create_tileset():
	# Create TileSet programmatically to avoid .tres loading issues
	tileset = TileSet.new()
	
	# Add physics layer
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	
	# Tile mapping: source ID -> image filename
	var tile_images = {
		2: "res://platform/tileYellow_01.png",  # Top-Left
		3: "res://platform/tileYellow_02.png",  # Top
		4: "res://platform/tileYellow_03.png",  # Top-Right
		5: "res://platform/tileYellow_04.png",  # Left
		6: "res://platform/tileYellow_05.png",  # Center
		7: "res://platform/tileYellow_06.png",  # Right
		8: "res://platform/tileYellow_07.png",  # Bottom-Left
		9: "res://platform/tileYellow_08.png",  # Bottom
		10: "res://platform/tileYellow_09.png"  # Bottom-Right
	}
	
	# Create collision polygon points (standard rectangle)
	var collision_points = PackedVector2Array([
		Vector2(-32, -32),
		Vector2(32, -32),
		Vector2(32, 32),
		Vector2(-32, 32)
	])
	
	# Create atlas source for each tile
	for source_id in tile_images.keys():
		var atlas = TileSetAtlasSource.new()
		var texture = load(tile_images[source_id])
		atlas.texture = texture
		
		# Set texture size in atlas
		atlas.texture_region_size = Vector2i(64, 64)
		
		# Create tile at 0,0
		atlas.create_tile(Vector2i(0, 0))
		
		# Add physics layer with collision
		var tile_data = atlas.get_tile_data(Vector2i(0, 0), 0)
		tile_data.set_collision_polygons_count(0, 1)
		tile_data.set_collision_polygon_points(0, 0, collision_points)
		
		# Add source to tileset
		tileset.add_source(atlas, source_id)

func generate_level():
	# Clean children
	for child in get_children():
		child.queue_free()
	
	# Create TileMapLayer
	var tilemap = TileMapLayer.new()
	tilemap.tile_set = tileset
	tilemap.name = "Terrain"
	add_child(tilemap)
	
	# Parse Grid
	var lines = level_data.split("\n", false)
	var grid = {}
	var width = 0
	var height = lines.size()
	
	for y in range(height):
		var line = lines[y]
		if line.length() > width:
			width = line.length()
		for x in range(line.length()):
			var char = line[x]
			if char == "#":
				grid[Vector2i(x, y)] = true
			elif char.to_upper() == "O":
				spawn_ball(x, y)
			elif char.to_upper() == "H":
				spawn_hole(x, y)
	
	# Place Tiles
	for pos in grid.keys():
		var x = pos.x
		var y = pos.y
		var source_id = get_tile_source_id(grid, x, y)
		# Coords in Atlas?
		# The TileSet is setup as separate AtlasSources for each image.
		# Each source has ID 2..10. Each source has 1 tile at 0,0.
		tilemap.set_cell(pos, source_id, Vector2i(0, 0))

func get_tile_source_id(grid, x, y) -> int:
	var top = grid.has(Vector2i(x, y - 1))
	var bot = grid.has(Vector2i(x, y + 1))
	var left = grid.has(Vector2i(x - 1, y))
	var right = grid.has(Vector2i(x + 1, y))
	
	# Determine Type based on Open Sides
	# Sources:
	# 2: TL (Open T, L)
	# 3: T (Open T)
	# 4: TR (Open T, R)
	# 5: L (Open L)
	# 6: C (Closed)
	# 7: R (Open R)
	# 8: BL (Open B, L)
	# 9: B (Open B)
	# 10: BR (Open B, R)
	
	if !top and !left: return 2
	if !top and !right: return 4
	if !top: return 3
	
	if !bot and !left: return 8
	if !bot and !right: return 10
	if !bot: return 9
	
	if !left: return 5
	if !right: return 7
	
	return 6 # Center

func spawn_ball(grid_x, grid_y):
	var ball = ball_scene.instantiate()
	ball.position = Vector2(grid_x * CELL_SIZE + CELL_SIZE/2, grid_y * CELL_SIZE + CELL_SIZE/2)
	# Add to Level Root (parent of generator)
	# Ideally Ball should be sibling of TileMap logic-wise, but for collision it's fine.
	# We need to find where 'Level.gd' expects things.
	# Level.gd usually looks for "Ball" as a direct child or waits for signal.
	# Let's add it to the PARENT (The Level Node) if possible, or Self.
	# The Level.gd script expects children named "Ball".
	if get_parent().has_method("add_child"):
		ball.name = "Ball"
		get_parent().call_deferred("add_child", ball)

func spawn_hole(grid_x, grid_y):
	var hole = hole_scene.instantiate()
	hole.position = Vector2(grid_x * CELL_SIZE + CELL_SIZE/2, grid_y * CELL_SIZE + CELL_SIZE/2)
	if get_parent().has_method("add_child"):
		hole.name = "Hole"
		get_parent().call_deferred("add_child", hole)

func generate_daily_level(seed_val: int):
	# Procedural Generation
	# 30x15 grid
	var width = 30
	var height = 15
	
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# Clear
	for child in get_children():
		child.queue_free()
		
	var tilemap = TileMapLayer.new()
	tilemap.tile_set = tileset
	tilemap.name = "Terrain"
	add_child(tilemap)
	
	var grid = {}
	
	# Basic Algorithm: Perlin-ish height or Random Walk
	# Let's do a simple "Platformer" walker.
	
	var current_y = 10
	var ground_y = 12
	
	# Start Platform
	for x in range(0, 5):
		for y in range(current_y, height):
			grid[Vector2i(x, y)] = true
	
	# Place Ball
	spawn_ball(1, current_y - 2)
	
	# Middle Section
	for x in range(5, 25):
		# Randomly decide to move up, down, or stay flat
		# Or create gap
		var r = rng.randf()
		
		if r < 0.1: # Gap
			# No blocks
			pass
		else:
			if r < 0.3: # Step Up
				current_y = max(4, current_y - 1)
			elif r < 0.5: # Step Down
				current_y = min(height - 2, current_y + 1)
			
			# Fill column
			for y in range(current_y, height):
				grid[Vector2i(x, y)] = true
				
	# End Platform
	for x in range(25, 30):
		for y in range(current_y, height):
			grid[Vector2i(x, y)] = true
			
	# Place Hole
	spawn_hole(28, current_y - 1)
	
	# Render Grid
	for pos in grid.keys():
		var x = pos.x
		var y = pos.y
		var source_id = get_tile_source_id(grid, x, y)
		tilemap.set_cell(pos, source_id, Vector2i(0, 0))

