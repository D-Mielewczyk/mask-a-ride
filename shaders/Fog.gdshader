shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// --- PIXELATION ---
uniform float pixel_size : hint_range(1.0, 16.0) = 3.0; 

// --- Konfiguracja Mgły ---
uniform vec4 fog_color : source_color = vec4(0.9, 0.6, 0.2, 1.0);
uniform float fog_height : hint_range(0.0, 1.0) = 0.25;
uniform float fog_density : hint_range(0.0, 1.0) = 0.8;
uniform float fog_edge_softness : hint_range(0.01, 0.5) = 0.1; 

// --- Konfiguracja Krawędzi (Edge Wobble) ---
group_uniforms EdgeWobble;
uniform float edge_noise_scale : hint_range(1.0, 20.0) = 5.0;
uniform float edge_noise_speed : hint_range(0.0, 2.0) = 0.5;
uniform float edge_noise_strength : hint_range(0.0, 0.3) = 0.1;

// --- Balatro Effect ---
group_uniforms BalatroInnerEffect;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.1;
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.005;
uniform float time_scale : hint_range(0.0, 5.0) = 2.0;

// --- FUNKCJE SZUMU ---
float hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise_2d(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i + vec2(0.0, 0.0));
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 uv) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		value += amplitude * noise_2d(uv);
		uv *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	// 1. Obliczanie Maski (Używamy zwykłego SCREEN_UV, żeby krawędź była płynna)
	
	// Generowanie falowania krawędzi
	vec2 noise_coord = SCREEN_UV * edge_noise_scale;
	noise_coord.x += TIME * edge_noise_speed;
	noise_coord.y += TIME * edge_noise_speed * 0.3;
	float wobble = fbm(noise_coord);
	float wobble_offset = (wobble - 0.5) * edge_noise_strength * 2.0;

	// Maska wysokości
	float base_start_y = 1.0 - fog_height;
	float noisy_start_y = base_start_y + wobble_offset;
	
	// Używamy SCREEN_UV dla maski! (Ważne dla poprawnego odcięcia)
	float mask = smoothstep(noisy_start_y, noisy_start_y + fog_edge_softness, SCREEN_UV.y);

	// 2. Pobranie CZYSTEGO tła (Dla góry ekranu)
	vec4 clean_screen = texture(screen_texture, SCREEN_UV);

	// 3. Pobranie SPIKSELOWANEGO tła (Dla dołu/mgły)
	
	// Obliczamy "Kratkę" pikseli tylko na potrzeby mgły
	vec2 block_size = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 pixel_uv = floor(SCREEN_UV / block_size) * block_size;
	
	// Efekt Distortion (Pływanie) na pikselach
	vec2 distorted_uv = pixel_uv;
	distorted_uv.x += sin(pixel_uv.y * 50.0 + TIME * time_scale) * distortion_strength;
	// Ponowne zatrzaśnięcie do siatki po zniekształceniu (żeby piksele nie rozjeżdżały się na połówki)
	distorted_uv = floor(distorted_uv / block_size) * block_size;

	// Pobieramy kolor zniekształcony i spikselowany
	vec4 foggy_screen = texture(screen_texture, distorted_uv);

	// --- DODATKI (Szum i Paski - też pikselowe) ---
	float noise = hash(pixel_uv + fract(TIME * time_scale * 0.1));
	float grain_effect = mix(1.0, noise, noise_strength);

	float scanline = sin(pixel_uv.y * 200.0 + TIME * time_scale * 2.0) * 0.5 + 0.5;
	float scanline_effect = mix(1.0, scanline, scanline_strength);

	// Aplikujemy efekty do warstwy mglistej
	vec4 fog_layer = mix(foggy_screen, fog_color, fog_density);
	fog_layer.rgb *= grain_effect;
	fog_layer.rgb *= scanline_effect;

	// 4. MIESZANIE OSTATECZNE
	// Tu dzieje się magia: Mieszamy Czysty Ekran z Warstwą Mgły na podstawie maski.
	COLOR = mix(clean_screen, fog_layer, mask);
}