shader_type canvas_item;

uniform sampler2D trail_texture;  // Trail texture from a Viewport
uniform float fade_speed : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec4 trail_color = texture(trail_texture, UV);
    float fade = 1.0 - fade_speed;
    trail_color.a *= fade;
    COLOR = vec4(trail_color.rgb, trail_color.a);
}
