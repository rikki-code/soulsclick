## How an attack kind glows during its telegraph. Data keyed by kind id; unknown kinds use the default.
class_name GlowStyles
extends RefCounted

const DEFAULT_STYLE := {"tint": null, "period": 0.35, "peak": 0.9, "shake": 8.0}
const BY_KIND := {
	&"quick": {"tint": null, "period": 0.22, "peak": 0.8, "shake": 8.0},
	&"heavy": {"tint": Color(1.0, 0.55, 0.15), "period": 0.5, "peak": 1.0, "shake": 22.0},
	&"combo": {"tint": Color(1.0, 0.85, 0.3), "period": 0.28, "peak": 0.9, "shake": 10.0},
}

static func style_for(kind_id: StringName) -> Dictionary:
	return BY_KIND.get(kind_id, DEFAULT_STYLE)

static func color_for(kind_id: StringName, accent: Color) -> Color:
	var tint: Variant = style_for(kind_id)["tint"]
	return tint if tint != null else accent
