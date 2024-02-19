extends RigidBody2D
class_name Planet

var g; # game object

var bigG=  3000

var display_step = 0.1
var min_mass=1.0


var max_merge_force =   2000 # 5000 # below this, MERGE
var min_impact_force =  7000 # 20000 # above this, HIGH IMPACT

var pts_max = 500
var pts = PoolVector2Array()

var line2Dpath
var node2Dorbit

func _ready():	
	g = get_parent()
#	while g.name != 'Game':
#		g = g.get_parent()

	# set GRAVITY from this object
	$Gravity.gravity = mass*bigG
		
	resize_from_mass() 
	
	#move path LINE to top level game node
	line2Dpath = $Line2Dpath
	remove_child(line2Dpath)
	g.call_deferred("add_child",line2Dpath)	
	
	#move orbit NODE to top level game node
	node2Dorbit = $Node2Dorbit
	remove_child(node2Dorbit)
	g.call_deferred("add_child",node2Dorbit)	
	

	

var lastDistanceToStar=0.0
#var lastDistanceToParent=0.0
var lastVelocMag=0.0

var ptCtrMax = 5
var ptCtr = 0
func _process(_delta):

	# central star
	var parentStar=g.get_node_or_null('Star')
	
	#rotate sprite towards star
	var parentStarAngle
	if parentStar != null:
		parentStarAngle = (parentStar.global_position - global_position).angle()
		get_node('Sprite').rotation= parentStarAngle + deg2rad(120)
	
	# set display values
	$Label.text = str(stepify(mass, display_step))
	$Label2.text = str(stepify(lastVelocMag, display_step))
	$Label3.text = str(stepify(parentStarAngle, display_step))
	$Label4.text = str(stepify(lastDistanceToStar, display_step))
	
	#set velocity marker
	$Line2DVeloc.set_point_position(1,linear_velocity*1)

	# set GRAVITY from this object
	$Gravity.gravity = mass*bigG

	# store recent path
	ptCtr +=  1
	if ptCtr > ptCtrMax:
		ptCtr=0
		pts.append( global_position )
		if pts.size()> pts_max:
			pts.remove(0)
		line2Dpath.set_points(pts)

	if visible:
		line2Dpath.visible=true
	else:
		line2Dpath.visible=false

	# set display values and draw line to parent	
	if parentStar != null:
		lastDistanceToStar= global_position.distance_to(parentStar.global_position)	
		lastVelocMag=linear_velocity.length()
		$Line2DDistance.set_point_position(1,(parentStar.global_position - global_position))
		
		# check for leaving star system
		if lastDistanceToStar > parentStar.max_distance_allowed:
			g.logMsg("Left Star system: "+name)
			clean_queue_free()

				
var collision_force : Vector2 = Vector2.ZERO
var previous_linear_velocity : Vector2 = Vector2.ZERO
func _integrate_forces(state : Physics2DDirectBodyState)->void:
	collision_force = Vector2.ZERO

	if state.get_contact_count() > 0:
		var dv : Vector2 = state.linear_velocity - previous_linear_velocity
		collision_force = dv / (state.inverse_mass * state.step)

	previous_linear_velocity = state.linear_velocity



func _on_Planet_body_shape_entered(_body_id, body, _body_shape, _local_shape):
	if body.is_in_group('planet'):
		if body.collision_force != Vector2.ZERO && collision_force != Vector2.ZERO:
			
			var impactScore = (self.collision_force.length()/self.mass) + (body.collision_force.length()/body.mass)
				
			g.logMsg("impactScore: "+str(stepify(impactScore, display_step)))
			
			if impactScore>min_impact_force:
				impact_with(body)	
			elif impactScore<max_merge_force:
				combine_with_and_destroy(body)
			else:
				g.logMsg("Bounced: "+name+ " and "+body.name)
				
	elif body.is_in_group('star'):
		g.logMsg("Collided with Star: "+name)
		body.mass = body.mass + self.mass
		clean_queue_free()

func impact_with(body:RigidBody2D):
	var largerBody
	var smallerBody
	if  self.mass >= body.mass:
		largerBody = self
		smallerBody = body
	else:
		largerBody = body
		smallerBody = self
	
	g.logMsg("IMPACT: "+smallerBody.name+ " into "+largerBody.name)	
		
	var new_mass = (largerBody.mass/2) + (smallerBody.mass/2) 
	var _new_pos = Vector2((largerBody.position.x+smallerBody.position.x)/2,(largerBody.position.y+smallerBody.position.y)/2)
	var _new_vel = Vector2((largerBody.linear_velocity.x+smallerBody.linear_velocity.x)/2,(largerBody.linear_velocity.y+smallerBody.linear_velocity.y)/2)

	largerBody.remove_mass_and_resize(largerBody.mass - new_mass)
	smallerBody.remove_mass_and_resize(smallerBody.mass - new_mass)
	
		
func combine_with_and_destroy(body:Planet):
	var largerBody
	var smallerBody
	if  self.mass >= body.mass:
		largerBody = self
		smallerBody = body
	else:
		largerBody = body
		smallerBody = self
	
	g.logMsg("Merging: "+smallerBody.name+ " into "+largerBody.name)
		
	largerBody.mass += smallerBody.mass
	largerBody.resize_from_mass()
	
	smallerBody.clean_queue_free()

func resize_from_mass():
	var a = 2
	var b = 10000
	var c = 0
	var newscale = ((log(mass+1)/(log(b)+1))*a)+c
	
	get_node('Sprite').scale = Vector2(newscale,newscale)
	get_node('CollisionShape2D2').scale = Vector2(newscale,newscale)
	get_node('LightOccluder2D').scale = Vector2(newscale,newscale)
	
func remove_mass_and_resize(mass_to_remove):
	mass -= mass_to_remove
	if mass < min_mass:
		g.logMsg("Too small: "+name)
		clean_queue_free()
	else:
		resize_from_mass()

func clean_queue_free():
	line2Dpath.queue_free()
	node2Dorbit.queue_free()
	queue_free()

func EnterVoid():
	clean_queue_free()

func PushRetrograde(force):
	var retro = linear_velocity.normalized().tangent().tangent()
	apply_impulse(Vector2.ZERO,  retro * force  )
	
func PushPrograde(force):
	var pro = linear_velocity.normalized()
	apply_impulse(Vector2.ZERO,  pro * force  )





const POINT_COUNT = 60
func _on_Node2Dorbit_draw():
	pass
	var parentStar=g.get_node_or_null('Star')
	if parentStar != null:
		var parentStarAngle = (parentStar.global_position - self.global_position).angle()
		
		
		var offset_center = Vector2.ZERO
		var _offset_angle = parentStarAngle + deg2rad(90+45+45) # TODO need to check this after other elements are in place
		var pivot_global_position = Vector2.ZERO
		var _gravForce:float=0.0
		var com = parentStar.global_position

		lastDistanceToStar= global_position.distance_to(parentStar.global_position)	
		var parentStarDirection = parentStar.global_position.direction_to(self.global_position)
		com = parentStarDirection * (self.mass/parentStar.mass)	
		
		# offset focus
		offset_center.x = com.x
		offset_center.y = com.y

		node2Dorbit.draw_circle(com,45,Color.darkmagenta) # ROTATION PIVOT CENTER		

		# PIVOT AND POSITION THE ELLIPSE
		node2Dorbit.draw_circle(Vector2(0,0),35,Color.darkblue) # ROTATION PIVOT CENTER
		node2Dorbit.get_node('nodeEllipse').position = Vector2(offset_center.x,offset_center.y)
#		node2Dorbit.rotation=offset_angle
		
		pivot_global_position = parentStar.global_position
		node2Dorbit.global_position = pivot_global_position  + Vector2(-3,-180)
		
	node2Dorbit.update()


func _on_nodeEllipse_draw():
	pass
	
	var parentStar=g.get_node_or_null('Star')
	if parentStar != null:	
		var sizeA = 0.0
		var sizeB = 0.0
		var offset_center = Vector2.ZERO
		
		lastDistanceToStar= global_position.distance_to(parentStar.global_position)	
		var parentStarDirection = parentStar.global_position.direction_to(self.global_position)
		var _gravForce:float=0.0
		var com = parentStarDirection * (self.mass/parentStar.mass)		
			
		# ellipse axis TODO - need to calculate these somehow
		sizeA = 266 # lastDistanceToStar
		sizeB = 318# lastDistanceToStar
#		sizeA =  a *2
#		sizeB =  sizeA  * e
		
		# offset focus
		offset_center.x = com.x
		offset_center.y = com.y
		
		# DRAW ELLIPSE
		franco_draw_ellipse_scaled(sizeA, sizeB, offset_center.x, offset_center.y, Color.green)	
#		franco_draw_ellipse_scaled(sizeA, sizeA, offset_center.x, offset_center.y, Color.green)	

	node2Dorbit.update()

	
func franco_draw_ellipse_scaled(x_radius, y_radius, offset_x=0, offset_y=0, color=Color.white, fill = false):
	
	node2Dorbit.get_node('nodeEllipse').draw_circle(Vector2(0,0),25,Color.white) # ELLIPSE CENTER
#	node2Dorbit.get_node('nodeEllipse').draw_circle(global_position-Vector2(offset_x, offset_y),45,Color.red)
#	node2Dorbit.get_node('nodeEllipse').draw_circle(Vector2(offset_x-center_x,offset_y-center_y),20,Color.purple)
#	node2Dorbit.get_node('nodeEllipse').draw_circle(Vector2(center_x-offset_x,center_y-offset_y),20,Color.yellow)

	node2Dorbit.get_node('nodeEllipse').draw_set_transform(Vector2(0, 0), 0, Vector2(x_radius, y_radius))
	if (fill):
		node2Dorbit.get_node('nodeEllipse').draw_circle(Vector2(0.0, 0.0), 1.0, color)
	else:
		node2Dorbit.get_node('nodeEllipse').draw_arc(Vector2(0.0, 0.0), 1.0, 0.0, 2.0 * PI, POINT_COUNT, color)
#	node2Dorbit.get_node('nodeEllipse').draw_rect(Rect2(0,0,1,1),Color.white,false,1)
	node2Dorbit.get_node('nodeEllipse').draw_set_transform(Vector2(0.0, 0.0), 0, Vector2(1.0, 1.0))

#	node2Dorbit.get_node('nodeEllipse').position = Vector2(offset_x-250,offset_y+250)
	node2Dorbit.get_node('nodeEllipse').position = Vector2(offset_x,offset_y)


