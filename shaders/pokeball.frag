#version 460 core

// Pokébola 3D renderizada por píxel: se calcula la esfera, se rota,
// se pinta el patrón de cada tipo y se ilumina con luz difusa,
// brillo especular y borde (fresnel).

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uYaw;
uniform float uPitch;
uniform float uPattern;
uniform vec3 uTop;
uniform vec3 uBottom;
uniform vec3 uBand;
uniform vec3 uAccent;
uniform vec3 uAccent2;

out vec4 fragColor;

const float PI = 3.14159265;

vec3 rotX(vec3 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec3(v.x, c * v.y - s * v.z, s * v.y + c * v.z);
}

vec3 rotY(vec3 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z);
}

// 1 dentro (d < 0), 0 fuera, con borde suavizado de ancho aa.
float inside(float d, float aa) {
  return 1.0 - smoothstep(-aa, aa, d);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float hash(vec3 p) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float s = min(uSize.x, uSize.y);
  vec2 uv = (frag - 0.5 * uSize) / (0.5 * s);
  uv.y = -uv.y;

  float px = 2.0 / s;
  float r = length(uv);
  float alpha = inside(r - (1.0 - 1.5 * px), px);
  if (alpha <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // Normal en espacio de vista y punto equivalente sobre la esfera sin rotar.
  float z = sqrt(max(1.0 - r * r, 0.0));
  vec3 n = vec3(uv, z);
  vec3 p = rotY(rotX(n, -uPitch), -uYaw);
  float aa = px * 1.2 / max(z, 0.2);

  int pattern = int(uPattern + 0.5);
  float top = smoothstep(-aa, aa, p.y);
  vec3 col = mix(uBottom, uTop, top);

  if (pattern == 1) {
    // Super Ball: dos franjas rojas a los lados.
    float l = max(
      dot(p, normalize(vec3(1.0, 0.35, 0.0))),
      dot(p, normalize(vec3(-1.0, 0.35, 0.0)))
    );
    col = mix(col, uAccent, inside(0.8 - l, aa) * top);
  } else if (pattern == 2) {
    // Ultra Ball: "H" amarilla sobre fondo negro.
    float leg = abs(abs(p.x) - 0.5) - 0.16;
    float bar = max(abs(p.z) - 0.13, abs(p.x) - 0.5);
    col = mix(col, uAccent, inside(min(leg, bar), aa) * top);
  } else if (pattern == 3) {
    // Master Ball: manchas rosas y una "M" blanca.
    float spot = max(
      dot(p, normalize(vec3(0.85, 0.5, 0.15))),
      dot(p, normalize(vec3(-0.85, 0.5, 0.15)))
    );
    col = mix(col, uAccent, inside(0.93 - spot, aa) * top);

    vec3 c = normalize(vec3(0.0, 0.6, 0.8));
    vec3 up = vec3(0.0, c.z, -c.y);
    vec2 q = vec2(p.x, dot(p, up));
    float m = sdSegment(q, vec2(-0.21, -0.14), vec2(-0.21, 0.14));
    m = min(m, sdSegment(q, vec2(-0.21, 0.14), vec2(0.0, -0.04)));
    m = min(m, sdSegment(q, vec2(0.0, -0.04), vec2(0.21, 0.14)));
    m = min(m, sdSegment(q, vec2(0.21, 0.14), vec2(0.21, -0.14)));
    float front = step(0.7, dot(p, c));
    col = mix(col, uAccent2, inside(m - 0.042, aa) * front);
  } else if (pattern == 4) {
    // Malla Ball: red negra sobre la mitad superior.
    float lat = asin(clamp(p.y, -1.0, 1.0));
    float lon = atan(p.x, p.z);
    float step1 = 0.26;
    float step2 = PI / 7.0;
    float dl = abs(fract(lat / step1 + 0.5) - 0.5) * step1;
    float dm = abs(fract(lon / step2 + 0.5) - 0.5) * step2 * cos(lat);
    col = mix(col, uAccent, inside(min(dl, dm) - 0.022, aa) * top);
  } else if (pattern == 5) {
    // Safari Ball: manchas verdes irregulares.
    vec3 g = p * 3.2;
    vec3 cell = floor(g);
    float d = 10.0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        for (int k = 0; k < 3; k++) {
          vec3 o = cell + vec3(float(i) - 1.0, float(j) - 1.0, float(k) - 1.0);
          vec3 punto = o + vec3(hash(o), hash(o + 11.1), hash(o + 27.3));
          d = min(d, length(g - punto));
        }
      }
    }
    col = mix(col, uAccent, inside(d - 0.38, aa * 3.2) * top);
  } else if (pattern == 6) {
    // Lujo Ball: franja roja, línea dorada y corona dorada.
    col = mix(col, uAccent, inside(abs(p.y - 0.16) - 0.07, aa));
    col = mix(col, uAccent2, inside(abs(p.y - 0.27) - 0.025, aa));
    col = mix(col, uAccent2, inside(0.92 - p.y, aa));
  }

  // Banda central.
  float band = inside(abs(p.y) - 0.065, aa);
  col = mix(col, uBand, band);

  // Botón frontal: anillo, botón blanco y línea interior.
  float dist = length(p - vec3(0.0, 0.0, 1.0));
  float ring = inside(dist - 0.34, aa);
  col = mix(col, uBand, ring);
  float btn = inside(dist - 0.25, aa);
  col = mix(col, vec3(0.96, 0.96, 0.97), btn);
  col = mix(col, vec3(0.78, 0.79, 0.82), inside(abs(dist - 0.165) - 0.012, aa) * btn);
  float matte = max(band, ring * (1.0 - btn));

  // Iluminación.
  vec3 L = normalize(vec3(-0.5, 0.65, 0.8));
  float diff = max(dot(n, L), 0.0);
  vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
  float spec = pow(max(dot(n, H), 0.0), mix(80.0, 18.0, matte)) * mix(0.7, 0.12, matte);
  float fres = pow(1.0 - z, 2.5);

  vec3 lit = col * (0.32 + 0.78 * diff);
  lit += vec3(spec);
  lit += fres * 0.22 * vec3(0.85, 0.9, 1.0);
  lit += col * 0.12 * max(-n.y, 0.0);

  fragColor = vec4(clamp(lit, 0.0, 1.0) * alpha, alpha);
}
