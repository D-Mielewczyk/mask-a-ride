shader_type canvas_item;

// --- KOLORY ---
uniform vec4 building_color : source_color = vec4(0.15, 0.15, 0.18, 1.0); // Baza (szary)
uniform vec4 sunset_color : source_color = vec4(1.0, 0.45, 0.2, 1.0); // Kolor tła/nieba

// --- USTAWIENIA WARSTWY (To zmieniasz dla każdej z 3 warstw) ---
uniform float fog_intensity : hint_range(0.0, 1.0) = 0.0; // 0 = blisko, 1 = daleko
uniform float darkness_bottom : hint_range(0.0, 1.0) = 0.6; // Jak ciemny jest dół budynku

// --- FAKTURA (Brud/Beton) ---
uniform sampler2D noise_texture : repeat_enable; // Wrzuć tu NoiseTexture2D
uniform float noise_strength : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	vec4 original_tex = texture(TEXTURE, UV);
	
	// 1. Sprawdzamy czy to nie jest przezroczyste tło lub okno (dziura)
	if (original_tex.a == 0.0) {
		discard;
	}

	// 2. Pobieramy szum (fakturę betonu) bazując na pozycji piksela
	// Używamy UV * liczba, żeby zagęścić szum
	float noise = texture(noise_texture, UV * vec2(5.0, 5.0)).r;
	
	// 3. Baza koloru budynku z domieszką szumu
	vec3 base = building_color.rgb + (noise * noise_strength);
	
	// 4. Gradient pionowy (góra jaśniejsza, dół ciemniejszy)
	// Zakładamy, że UV.y 0.0 to góra, 1.0 to dół
	float gradient = 1.0 - (UV.y * darkness_bottom);
	base *= gradient;

	// 5. Mieszanie z tłem (Aerial Perspective)
	// Im większy fog_intensity, tym bardziej kolor zmienia się w sunset_color
	vec3 final_color = mix(base, sunset_color.rgb, fog_intensity);

	COLOR = vec4(final_color, original_tex.a);
}
