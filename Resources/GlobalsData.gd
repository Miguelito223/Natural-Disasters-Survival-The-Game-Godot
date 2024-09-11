class_name DataResource extends Resource

static var path = "user://GlobalsData.tres"

#Globals Settings
@export var vsync = false
@export var FPS = false
@export var antialiasing = false
@export var volumen = 1
@export var volumen_music = 1
@export var timer_disasters = 60
@export var fullscreen = false
@export var resolution = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
@export var quality = 0

func save_file():
    ResourceSaver.save(self, path)

static func load_file():
    var data: DataResource = load(path) as DataResource
    if not data:
        data = DataResource.new()

    return data


