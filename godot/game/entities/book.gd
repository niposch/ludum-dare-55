extends Entity

const GRAVITY = 9

var initiated
var speed

@onready var collision_polygon_2d = $CollisionPolygon2D


func init(start_x, start_y, speed_x, speed_y):
	damage = 300
	position.x = start_x
	position.y = start_y
	speed = Vector2(speed_x, speed_y)
	initiated = true


# Called when the node enters the scene tree for the first time.
func _ready():
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not initiated:
		return
	position += speed*delta
	speed.y += GRAVITY
	if position.y > 2000:
		queue_free()
