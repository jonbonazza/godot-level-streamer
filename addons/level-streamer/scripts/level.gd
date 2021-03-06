
const Task = preload("res://addons/level-streamer/scripts/streamer.gd").Task

var filename
var bounds
var transform
var count = 0

var _cache_resource
var _levels_root
var _resource
var _instance
var _mu = Mutex.new()

func _init(filename, transform, bounds, levels_root, _resource=null):
	self.filename = filename
	self.transform = transform
	self.bounds = bounds
	self._levels_root = levels_root
	self._cache_resource = _resource != null
	self._resource = _resource

func add_ref(d):
	_mu.lock()
	count += d
	_mu.unlock()

func ref():
	add_ref(1)
	
func deref():
	add_ref(-1)

func load_level(main_thread):
	_mu.lock()
	if count == 0:
		if not _resource:
			_resource = load(filename)
			main_thread.push_back(Task.new(self, "_instance"))
	ref()
	_mu.unlock()

func unload_level(main_thread):
	_mu.lock()
	if count == 1:
		main_thread.push_back(Task.new(self, "_uninstance"))
	deref()
	_mu.unlock()

func _instance():
	_mu.lock()
	if _resource:
		_instance = _resource.instance()
		_instance.transform = transform
		_levels_root.add_child(_instance)
	_mu.unlock()

func _uninstance():
	_mu.lock()
	_levels_root.call_deferred("remove_child", _instance)
	_instance.queue_free()
	_instance = null
	if not _cache_resource:
		_resource = null
	_mu.unlock()

func _is_loaded():
	_mu.lock()
	var ins = _instance
	_mu.unlock()
	return ins != null
