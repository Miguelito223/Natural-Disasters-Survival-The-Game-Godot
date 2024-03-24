extends Node3D

var shake_nodes_strength = 1
var magnitude = 8.0
var magnitude_modifier = 0
var earthquake_simquality = 0.1
var next_physics_time = Time.get_ticks_msec()

func _physics_process(_delta):
    magnitude_modifier_increment()
    shake_nodes(get_parent())

func can_do_physics(nexttime: float) -> bool:
    if Time.get_ticks_msec() / 1000.0 >= self.next_physics_time:
        if Globals.hit_chance(1):
            self.next_physics_time = Time.get_ticks_msec() / 1000.0 + (randi_range(0, 250) / 100)
        else:
            self.next_physics_time = Time.get_ticks_msec() / 1000.0 + nexttime 
        return true
    else:
        return false

func magnitude_modifier_increment():
    # Ajustar el valor de MagnitudeModifier
    self.magnitude_modifier = clamp(self.magnitude_modifier + (get_physics_process_delta_time() / 4), 0, 1)


func shake_nodes(node):
    # Variables locales
    var t: float = self.earthquake_simquality
    var scale_velocity: float = 66 / (1 / get_physics_process_delta_time()) # Calcula la escala de la velocidad
    var mag: float = self.magnitude * self.magnitude_modifier

    # Si no podemos hacer física o la magnitud es menor que 3, salimos
    if not can_do_physics(t) or mag < 3:
        return

    # Calcula el factor de modificación de la física según la magnitud
    var mag_physmod: float = (mag - 3) / 7

    # Calcula el vector de velocidad
    var vec: Vector3 = Vector3(randi_range(-15, 15) / 10, randi_range(-5, 4) / 10, 0 ) * (mag * 25)

    # Calcula el vector de velocidad angular
    var ang_vv: Vector3 = Vector3(randi_range(-15, 15) / 10, randi_range(-5, 4) / 10, 0 ) * (mag * 8)

    # Si hay una probabilidad de golpear, aumenta el vector de velocidad angular
    if Globals.hit_chance(2):
        ang_vv *= 20

    print("LOowdokfqr3umoi1i")


    for child in node.get_children():
        if child.is_in_group("player"): # Verifica si el nodo es un Spatial (objeto 3D)
            if child.is_on_floor():
                child.set_velocity(vec * 1.125)
                child.move_and_slide()
        elif child.is_in_group("movable_objects"):
            var mass = child.mass or null
            var velocity_magnitude = child.linear_velocity.length()
            var vel_mod = 1 - clamp(velocity_magnitude / 2000, 0, 1)
            var ang_v = ang_vv * vel_mod
            if mass < 13600 or mass == null:
                child.add_constant_torque(ang_v * 8)
                child.add_central_force(ang_v * 4)
                child.freeze = false
                child.move_and_collide()

        # Llama recursivamente a la función para procesar los hijos del nodo actual
        if child.get_child_count() > 0:
            shake_nodes(child)
