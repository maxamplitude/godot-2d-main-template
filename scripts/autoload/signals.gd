# Global signal bus

extends Node
class_name Signals

signal player_spawned(player)
signal player_died
signal enemy_spawned(enemy)
signal enemy_killed(enemy)

signal game_paused
signal game_resumed
