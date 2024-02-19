extends Node2D

var bigG=  3000

var max_planets=25

var planetSceneTemplate = preload("res://Planet.tscn")
var display_step = 0.1
var new_planet_start_mass = 10

func _ready():
#	Engine.time_scale =  0.25
	$CanvasLayer/labelTimeScale.text = str(Engine.time_scale)
	
	# set initial estimated veloc for each starting planet based on distance to star
	for member in get_tree().get_nodes_in_group("planet"):
		member.g = self
		member.apply_impulse(Vector2.ZERO,circle_orbit($Star,member)) 		
	
	
	

func circle_orbit(b1,b2):
#		print("sm  ",b1.mass)		
#		print("pm  ",b2.mass)		

		var direction = b2.global_position.direction_to(b1.global_position)
#		print(direction)

		var distance = b2.global_position.distance_to(b1.global_position)
#		print("dis  ",distance)		

		var dir_tangent=direction.tangent()
		dir_tangent = dir_tangent # .rotated(deg2rad(30) )
#		print("tan  ",dir_tangent)
		
		var mag:float = circle_orbit_veloc(b1.mass,b2.mass,distance)
#		print("mag  ", mag)	

		var velo=dir_tangent * mag
#		print("velo ", velo)		

		return velo

func circle_orbit_veloc(m1,m2,d):
#		var bigG:float = 6.6743 * pow(10, -11)  # soo low
#		var bigG=  98
#		var bigG=  1
#		print("G   ", bigG)	
		var mag:float= sqrt(bigG * (m1 + m2)/d) 
#		print("mag  ", mag)		
#		var accf:float=(bigG*(m1+m2))/(d*d)  # not used currently
#		print("acc  ", accf)		
		return mag

var totalDelta	= 0.0	
var gameTick = 0
func _process(delta):
	totalDelta += delta
	
	if gameTick < int(totalDelta):
		gameTick =  int(totalDelta)
		doGameTick()

	$CanvasLayer/labelTotalDelta.text = str(gameTick)
	$Camera2D.position = $Star.global_position	
	
var emitted=false
func doGameTick():
	pass
	var new_mass=5

	if !emitted:
		if int(gameTick % 2) == 0:
			
			var direction = $Area2DEmitter.position.direction_to($Star.position)
			var distance = $Area2DEmitter.position.distance_to($Star.position)
			var dir_tangent=direction.tangent() 
			# dir_tangent = dir_tangent.tangent().tangent()  
			var mag = circle_orbit_veloc($Star.mass,new_mass,distance)
			var velo=dir_tangent * mag
			add_planet(new_mass, $Area2DEmitter.position, velo)
			emitted=true
	else:
		$Area2DEmitter.visible=false

func add_planet(mass, pos:Vector2, linvel:Vector2):
	
	if get_tree().get_nodes_in_group("planet").size() < max_planets:
		var newp = planetSceneTemplate.instance()
		newp.g = self	
		newp.mass=mass
		newp.position=pos
		newp.linear_velocity=linvel
	
		newp.get_node('Line2Dpath').width = 8 * pow(2, int($Camera2D.zoom.x)/10.0)
		newp.get_node('Line2DDistance').width = 8 * pow(2, int($Camera2D.zoom.x)/10.0)
			
		if(int($Camera2D.zoom.x)>10):
			newp.get_node('Label').visible = false
			newp.get_node('Label2').visible = false
		else:
			newp.get_node('Label').visible = true
			newp.get_node('Label2').visible = true			
			
		if(int($Camera2D.zoom.x)>15):
			newp.get_node('Line2DVeloc').visible = false
		else:
			newp.get_node('Line2DVeloc').visible = true		
			
	
		call_deferred("add_child", newp)
		# body_shape_entered?
		
		if linvel == Vector2.ZERO:
			logMsg("Added body: "+str(newp.mass) )
		else:
			logMsg("Added body with orbit: "+str(newp.mass) )
	
func _on_HSlider_value_changed(value):
	$CanvasLayer/labelTimeScale.text = str(value)
	Engine.time_scale = value

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			
			add_planet(new_planet_start_mass, get_global_mouse_position(), Vector2.ZERO)
			
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			var direction = get_global_mouse_position().direction_to($Star.position)
			var distance = get_global_mouse_position().distance_to($Star.position)
			var dir_tangent=direction.tangent() 
#			dir_tangent = dir_tangent.tangent().tangent()  
			
			var new_mass=new_planet_start_mass
			var mag = circle_orbit_veloc($Star.mass,new_mass,distance)

			var velo=dir_tangent * mag
			add_planet(new_mass, get_global_mouse_position(), velo)

		elif event.button_index == BUTTON_WHEEL_UP and event.pressed:
			zoomIn()
	
		elif event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			zoomOut()
		   
func zoomIn():
	if int($Camera2D.zoom.x) > 1:
		$Camera2D.zoom = $Camera2D.zoom - Vector2.ONE			

		for member in get_tree().get_nodes_in_group("planet"):
			member.line2Dpath.width = 8 * pow(2, int($Camera2D.zoom.x)/10.0)
			member.get_node('Line2DDistance').width = 8 * pow(2, int($Camera2D.zoom.x)/10.0)
			
		if(int($Camera2D.zoom.x)>10):
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Label').visible = false
				member.get_node('Label2').visible = false
		else:
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Label').visible = true
				member.get_node('Label2').visible = true
				
		if(int($Camera2D.zoom.x)>15):
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Line2DVeloc').visible = false			
		else:
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Line2DVeloc').visible = true						
				
				
func zoomOut():
	
	if int($Camera2D.zoom.x) < 49:
		$Camera2D.zoom = $Camera2D.zoom + Vector2.ONE

		for member in get_tree().get_nodes_in_group("planet"):
			member.line2Dpath.width = 8 * pow(2, int($Camera2D.zoom.x)/10.0)
			member.get_node('Line2DDistance').width = 8 * pow(2, int($Camera2D.zoom.x)/10.0)

		if(int($Camera2D.zoom.x)>10):
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Label').visible = false
				member.get_node('Label2').visible = false
		else:
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Label').visible = true
				member.get_node('Label2').visible = true

		if(int($Camera2D.zoom.x)>15):
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Line2DVeloc').visible = false			
		else:
			for member in get_tree().get_nodes_in_group("planet"):
				member.get_node('Line2DVeloc').visible = true						
								
	
var logMsgs = Array()
var logMaxMsgs = 20
func logMsg(msg,clear_first=false):
	if clear_first:
		logMsgs.clear()
	logMsgs.append(msg)
	if logMsgs.size() > logMaxMsgs:
		logMsgs.remove(0)
	$CanvasLayer/LogPanel/labelLog.text = PoolStringArray(logMsgs).join("\n")


func _on_Area2DVelocDamp_body_entered(body):
	body.PushRetrograde(10*body.mass)
func _on_Area2DVelocDamp_body_exited(_body):
	pass
	
func _on_Area2DVelocBump_body_entered(body):
	body.PushPrograde(10*body.mass)
func _on_Area2DVelocBump_body_exited(_body):
	pass

func _on_Area2DVoid_body_entered(body):
	body.EnterVoid()
func _on_Area2DVoid_body_exited(_body):
	pass # Replace with function body.


func _on_Game_draw():
	draw_arc($Star.global_position, $Star.max_distance_allowed, 0, TAU, 1000, Color.white)

