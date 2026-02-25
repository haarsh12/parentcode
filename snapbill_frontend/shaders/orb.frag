precision highp float;

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

float noise(vec2 p) {
    return sin(p.x) * sin(p.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv = uv * 2.0 - 1.0;

    float r = length(uv);
    if (r > 1.0) {
        discard;
    }

    float angle = atan(uv.y, uv.x);

    float wave1 = sin(angle * 3.0 + u_time * 2.0);
    float wave2 = sin(angle * 5.0 - u_time * 1.5);

    float mixWave = wave1 * 0.6 + wave2 * 0.4;

    vec3 color1 = vec3(0.0, 0.9, 0.6);
    vec3 color2 = vec3(0.0, 0.6, 0.5);

    float lighting = 1.0 - r;
    vec3 finalColor = mix(color1, color2, mixWave * 0.5 + 0.5);

    finalColor *= lighting;

    fragColor = vec4(finalColor, 1.0);
}
