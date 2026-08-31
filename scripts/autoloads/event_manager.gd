extends Node

# Event Bus for decoupled communication

# Emitted when a card needs special handling upon placement (e.g. showing a popup)
signal card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource)

# Emitted by a controller/popup when the interaction is confirmed
signal card_placement_interaction_confirmed(card_name: String, tile: Node3D, card_data: Resource, extra_data: Dictionary)

# Emitted by a controller/popup when the interaction is cancelled
signal card_placement_interaction_cancelled(card_name: String, tile: Node3D, card_data: Resource)

# Emitted when a card expires without being played
signal card_expired(process_id: String)

