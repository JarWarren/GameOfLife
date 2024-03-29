extends TileMap

const TILE_SIZE = 16

@export var height: int
@export var width: int
@export var resolution: Vector2

@onready var camera = $Camera2D
@onready var start_button = $CanvasLayer/StartButton
@onready var stop_label = $CanvasLayer/StopLabel
@onready var lifespan_slider = $CanvasLayer/Stats/Lifespan/LifespanSlider
@onready var generation_label = $CanvasLayer/Stats/GenerationVBox/GenerationLabel
@onready var population_label = $CanvasLayer/Stats/PopulationVBox/PopulationLabel
@onready var info_label = $CanvasLayer/InfoLabel

var is_simulating = false
var _time: int
var _next_generation = []
var _generation_number = 0
var _population = 0

func _ready():
	_time = lifespan_slider.value
	var grid_size = Vector2(width, height) * TILE_SIZE
	camera.position = grid_size / 2
	camera.zoom = grid_size / resolution
	for row in range(height):
		var next_row = []
		for column in range(width):
			next_row.append(0)
			_set_cell(row, column, 0)
		_next_generation.append(next_row)


func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var click_coordinate = (get_global_mouse_position() / TILE_SIZE).floor()
		var id = get_cell_source_id(0, click_coordinate, false)
		_set_cell(click_coordinate.x, click_coordinate.y, 1 - id)
		_population += 1 if id == 0 else -1
	if Input.is_action_just_pressed("ui_accept"):
		if is_simulating:
			_reset()
		else:
			_on_start_button_pressed()
	if !is_simulating: 
		population_label.text = "%d" % _population
		return
	_time -= 1
	if _time <= 0:
		_time = lifespan_slider.value
		_new_generation()


func _new_generation():
	_population = 0
	for row in range(height):
		for column in range(width):
			var live_neighbors = 0
			var neighbor_coordinates = [
				Vector2(column - 1, row - 1),
				Vector2(column - 1, row),
				Vector2(column - 1, row + 1),
				Vector2(column, row - 1),
				Vector2(column, row + 1),
				Vector2(column + 1, row - 1),
				Vector2(column + 1, row),
				Vector2(column + 1, row + 1),
			]
			for neighbor in neighbor_coordinates:
				if get_cell_source_id(0, neighbor, false) == 1:
					live_neighbors += 1
			if get_cell_source_id(0, Vector2(column, row), false) == 1:
				if live_neighbors in [2, 3]:
					_population += 1
					_next_generation[row][column] = 1
				else:
					_next_generation[row][column] = 0
			elif live_neighbors == 3:
				_population += 1
				_next_generation[row][column] = 1
			else:
				_next_generation[row][column] = 0
	for row in range(height):
		for column in range(width):
			_set_cell(column, row, _next_generation[row][column])
	_generation_number += 1
	generation_label.text = "%d" % _generation_number
	population_label.text = "%d" % _population


func _set_cell(column: int, row: int, id: int):
	set_cell(0, Vector2(column, row), id, Vector2.ZERO, 0)


func _reset():
	is_simulating = false
	start_button.visible = true
	stop_label.visible = false
	_generation_number = 0


func _on_start_button_pressed():
	start_button.visible = false
	stop_label.visible = true
	generation_label.text = "0"
	is_simulating = true


func _on_patterns_button_mouse_entered():
	set_layer_enabled(1, true)


func _on_button_mouse_exited():
	info_label.visible = false
	set_layer_enabled(1, false)


func _on_info_button_mouse_entered():
	info_label.visible = true
