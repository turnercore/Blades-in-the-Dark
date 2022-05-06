#This class is a way to store node references that all refer to the same data
class_name NodeReference
extends Reference

signal data_updated(id, data)
var id:String setget ,_get_id
var members: = []


func _on_group_data_updated(id:String, data:Dictionary)-> void:
	emit_signal("data_updated", id, data)


#Returns true if there is a group id found in data, false otherwise
func has(member)-> bool:
	if members.has(member):
		return true
	else:
		return false


func send_method(method:String, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null)-> void:
	for member in members:
		if member.has_method(method):
			if arg5:
				member.call(method, arg1, arg2, arg3, arg4, arg5)
			elif arg4:
				member.call(method, arg1, arg2, arg3, arg4)
			elif arg3:
				member.call(method, arg1, arg2, arg3)
			elif arg2:
				member.call(method, arg1, arg2)
			elif arg1:
				member.call(method, arg1)
			else:
				member.call(method)


func get_property(property:String):
	var value
	if not members.empty():
		value = members.front().get(property)
		return value
	else:
		return null


func connect_to_members(signal_name:String, node:Node, callback:String)-> void:
	for member in members:
		if member.has_signal(signal_name) and not member.is_connected(signal_name, node, callback):
			member.connect(signal_name, node, callback)


func disconnect_from_members(signal_name:String, node:Node, callback:String)-> void:
	for member in members:
		if member.has_signal(signal_name) and member.is_connected(signal_name, node, callback):
			member.disconnect(signal_name, node, callback)


func update_property(property:String, value)-> void:
	for member in members:
		if property in member:
			member.set(property, value)

#adds the node to the reference and returns the id of the reference
func add(node:SyncNode)-> String:
	if not members.has(node):
		members.append(node)

	if not node.is_connected("updated", self, "_on_member_updated"):
		node.connect("updated", self, "_on_member_updated", [node])
	if not node.is_connected("group_deleted", self, "_on_member_group_deleted"):
		node.connect("group_deleted", self, "_on_member_group_deleted")
	if not node.is_connected("freed", self, "_on_member_freed"):
		node.connect("freed", self, "_on_member_freed")
	return self.id

func _on_member_freed()-> void:
	var members_empty: = true
	for member in members:
		if not is_instance_valid(member):
			members.erase(member)
			continue
		elif member.is_queued_for_deletion():
			members.erase(member)
			continue
		else:
			members_empty = false
			break

	if members_empty:
		members.empty()


func modify(data:Dictionary, exception_node: SyncNode = null)-> void:
	#For each value to update, loops through the nodes in the reference and sets the property in each node
	for member in members:
		if not is_instance_valid(member): continue
		if exception_node and exception_node == member: continue
		member.import(data)


func delete()-> void:
	for member in members:
		member.queue_free()


func _on_member_updated(data:Dictionary, node:SyncNode)->void:
	call_deferred("modify", data, node)
	call_deferred("emit_signal", "data_updated", id, node.package())


func _on_member_group_deleted()-> void:
	self.delete()



func _get_id()->String:
	if not id:
		if not members.empty():
			if "id" in members.front():
				id = members.front().id
	return id

#
#func _notification(what: int) -> void:
#	if what == NOTIFICATION_PREDELETE:
#		for node in members:
#			node.queue_free()

