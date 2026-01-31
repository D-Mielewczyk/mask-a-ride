shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.3, 0.3, 0.3, 1.0); // Twój szary
uniform vec4 sky_color : source_color = vec4(0.9, 0.5, 0.1, 1.0); // Pomarańcz nieba
uniform float rim_power : hint_range(1.0, 10.0) = 3.0; // Siła świecenia krawędzi
uniform float atmosphere_density : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Pobierz oryginalną teksturę (kształt budynku)
    vec4 tex = texture(TEXTURE, UV);
    
    // Jeśli to przezroczyste tło, nie rysuj
    if (tex.a < 0.1) discard;

    // 1. GRADIENT PIONOWY (Atmosfera)
    // UV.y idzie od 0 (góra) do 1 (dół).
    // Na dole (UV.y=1) chcemy ciemniej, na górze jaśniej.
    float vertical_gradient = 1.0 - UV.y;
    // Mieszamy bazowy szary z kolorem nieba w zależności od wysokości
    vec3 atmospheric_color = mix(base_color.rgb * 0.5, sky_color.rgb, vertical_gradient * atmosphere_density);


    // 2. RIM LIGHT (Światło na krawędziach)
    // Prosta sztuczka 2D: sprawdzamy sąsiadujące piksele. Jeśli są przezroczyste,
    // a my jesteśmy nieprzezroczystym pikselem, to jesteśmy na krawędzi.
    float rim = 0.0;
    float offset = TEXTURE_PIXEL_SIZE.x * 2.0; // Grubość obrysu
    // Sprawdzamy lewo/prawo/góra/dół
    rim += step(texture(TEXTURE, UV + vec2(offset, 0.0)).a, 0.1);
    rim += step(texture(TEXTURE, UV - vec2(offset, 0.0)).a, 0.1);
    rim += step(texture(TEXTURE, UV + vec2(0.0, offset)).a, 0.1);
    rim += step(texture(TEXTURE, UV - vec2(0.0, offset)).a, 0.1);
    // Jeśli rim > 0, to znaczy że jesteśmy na krawędzi
    rim = clamp(rim, 0.0, 1.0);

    // 3. SKŁADANIE
    vec3 final_color = atmospheric_color;
    // Dodajemy światło krawędziowe (pomarańczowe)
    final_color += rim * sky_color.rgb * rim_power;

    COLOR = vec4(final_color, tex.a);
}