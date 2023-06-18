extends Node2D
class_name PropNode

var properties : PropResource
var prop_name : String
var sprite : Sprite2D

func _init(propResource : PropResource, default_variant := "default"):
	properties = propResource
	prop_name = propResource.prop_name
	sprite = properties.variants[default_variant]
