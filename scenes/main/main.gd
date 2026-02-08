extends Node2D

const TILE_SIZE := 32
const COLS := 12  # Extra column to fully cover 360px wide viewport
const ROWS := 20
const HORSE_BOUNDS := Rect2(40, 140, 272, 460)

# Grass tile atlas coords — wang_15 (all corners = upper/grass) is at col 0, row 3
const GRASS_ATLAS := Vector2i(0, 3)

@onready var grass_ground: TileMapLayer = $GrassGround
@onready var fence_layer: Node2D = $FenceLayer

var fence_texture: Texture2D


func _ready() -> void:
	fence_texture = load("res://assets/tiles/fence_tile.png")
	_setup_grass_tileset()
	_fill_grass()
	_build_fences()
	_setup_horses()


func _setup_grass_tileset() -> void:
	var tile_set := grass_ground.tile_set
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiles/grass_tileset.png")
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create the grass tile at atlas position (0, 3)
	atlas.create_tile(GRASS_ATLAS)

	tile_set.add_source(atlas, 0)


func _fill_grass() -> void:
	for x in range(COLS):
		for y in range(ROWS):
			grass_ground.set_cell(Vector2i(x, y), 0, GRASS_ATLAS)


func _setup_horses() -> void:
	for horse in $Horses.get_children():
		horse.bounds = HORSE_BOUNDS


func _build_fences() -> void:
	for x in range(COLS):
		_place_fence(x, 0)
		_place_fence(x, ROWS - 1)
	for y in range(1, ROWS - 1):
		_place_fence(0, y)
		_place_fence(COLS - 1, y)


func _place_fence(grid_x: int, grid_y: int) -> void:
	var pos := Vector2(
		grid_x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_y * TILE_SIZE + TILE_SIZE / 2.0
	)

	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0

	var sprite := Sprite2D.new()
	sprite.texture = fence_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape.shape = rect
	body.add_child(shape)

	fence_layer.add_child(body)
