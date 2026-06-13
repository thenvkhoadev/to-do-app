#include <flutter/runtime_effect.glsl>

precision highp float;

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

float noise(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / u_resolution;
  vec2 p = (fragCoord * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

  vec3 color = vec3(0.05, 0.07, 0.13);

  float g1 = 0.5 / length(p - vec2(sin(u_time * 0.5) * 0.5, cos(u_time * 0.3) * 0.5));
  float g2 = 0.4 / length(p - vec2(cos(u_time * 0.4) * 0.6, sin(u_time * 0.6) * 0.4));

  color += vec3(0.4, 0.3, 0.8) * g1 * 0.2;
  color += vec3(0.2, 0.5, 0.9) * g2 * 0.15;

  float n = noise(uv * 10.0 + u_time * 0.1);
  if (n > 0.996) {
    color += vec3(0.55);
  }

  fragColor = vec4(color, 1.0);
}
