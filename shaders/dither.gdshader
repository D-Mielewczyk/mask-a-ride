shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.2, 0.1, 0.0, 1.0);    // Ciemny brąz/czerwień u góry
uniform vec4 bottom_color : source_color = vec4(0.9, 0.6, 0.2, 1.0); // Jasny pomarańcz na dole
uniform float dither_size : hint_range(1.0, 8.0) = 2.0; // Rozmiar "kropek"

void fragment() {
	// 1. Zwykły gradient pionowy
	float gradient = UV.y; // 0.0 góra, 1.0 dół

	// 2. Macierz Bayera 4x4 (Wzór ditheringu)
	// To tworzy wrażenie cieniowania kropkami
	float x = floor(FRAGCOORD.x / dither_size);
	float y = floor(FRAGCOORD.y / dither_size);
	
	// Matematyka wzoru szachownicy (nie musisz tego analizować, to gotowy wzór)
	int dither_index = int(int(x) % 4 + (int(y) % 4) * 4);
	float limit = 0.0;
	
	if (dither_index == 0) limit = 0.0625;
	else if (dither_index == 1) limit = 0.5625;
	else if (dither_index == 2) limit = 0.1875;
	else if (dither_index == 3) limit = 0.6875;
	else if (dither_index == 4) limit = 0.8125;
	else if (dither_index == 5) limit = 0.3125;
	else if (dither_index == 6) limit = 0.9375;
	else if (dither_index == 7) limit = 0.4375;
	else if (dither_index == 8) limit = 0.25;
	else if (dither_index == 9) limit = 0.75;
	else if (dither_index == 10) limit = 0.125;
	else if (dither_index == 11) limit = 0.625;
	else if (dither_index == 12) limit = 1.0;
	else if (dither_index == 13) limit = 0.5;
	else if (dither_index == 14) limit = 0.875;
	else if (dither_index == 15) limit = 0.375;

	// 3. Mieszanie skokowe
	// Jeśli gradient jest jaśniejszy niż wartość z macierzy -> rysuj jasny kolor
	// Jeśli ciemniejszy -> rysuj ciemny
	// Dodałem 'step', żeby kolory były ostre (retro), a nie rozmyte.
	
	// Możesz użyć 'smoothstep' dla miękkiego efektu, lub logicznego progu dla twardego
	float threshold = gradient + (limit - 0.5) * 0.5; // *0.5 to siła ditheringu
	
	vec3 final_color = mix(top_color.rgb, bottom_color.rgb, threshold);
	
	COLOR = vec4(final_color, 1.0);
}