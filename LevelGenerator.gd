extends Node2D

@export_multiline var level_data: String = ""
@export var ball_scene: PackedScene = preload("res://ball.tscn")
@export var hole_scene: PackedScene = preload("res://Hole.tscn")
@export var tileset: TileSet = preload("res://platform/tileset_yellow.tres")

const CELL_SIZE = 64
const TILE_SOURCE_OFFSET = 2 # IDs start at 2 for the 3x3 block

# 3x3 Block Mapping
# 0 1 2
# 3 4 5
# 6 7 8
#
# ID Mapping in TileSet resource (verified from file):
# 2: TL, 3: T, 4: TR
# 5: L,  6: C, 7: R
# 8: BL, 9: B, 10: BR

func _ready():
	generate_level()

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

