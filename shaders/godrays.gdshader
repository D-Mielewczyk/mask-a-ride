shader_type canvas_item;

uniform vec4 ray_color : source_color = vec4(1.0, 0.9, 0.6, 1.0); // Kolor promienia
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float ray_density : hint_range(0.0, 20.0) = 10.0;
uniform float ray_width : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Tworzymy ruchomy wzór pasków
    float noise = sin(UV.x * ray_density + TIME * speed) * cos(UV.x * ray_density * 0.5 - TIME * speed * 0.5);
    
    // Przycinamy, żeby były wyraźne pasy (dla stylu pixel art można użyć step)
    float rays = smoothstep(1.0 - ray_width, 1.0, noise);
    
    // Gradient zanikania (promienie słabną w dół)
    float fade = 1.0 - UV.y;
    
    // Mieszanie koloru z przezroczystością
    vec4 final_color = ray_color;
    final_color.a *= rays * fade; // Aplikujemy kształt promieni i zanikanie
    
    COLOR = final_color;
}
