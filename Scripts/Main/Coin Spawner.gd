extends AbstractSpawner
class_name CoinSpawner

export var _coins_spawned := 5

const COIN_SPAWN_INTERVAL := 0.01

var _timer := 0.0
var _spawning = false

func _physics_process(delta):
	if _spawning:
		if _timer >= COIN_SPAWN_INTERVAL:
			create_object()
			_coins_spawned -= 1
			_timer = 0
			if _coins_spawned == 0:
				_spawning = false
		_timer += delta

func spawn_coins(coin_amount := _coins_spawned):
	_coins_spawned = coin_amount
	_spawning = true
