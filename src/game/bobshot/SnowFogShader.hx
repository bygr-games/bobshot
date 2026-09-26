package bobshot;

class SnowFogShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var time : Float;
		@param var fogStrength : Float;

		function hash(p:Vec2) : Float {
			return fract(sin(dot(p, vec2(41.0, 289.0))) * 45758.5453);
		}

		function valueNoise(p:Vec2) : Float {
			var i = floor(p);
			var f = fract(p);

			var a = hash(i);
			var b = hash(i + vec2(1.0, 0.0));
			var c = hash(i + vec2(0.0, 1.0));
			var d = hash(i + vec2(1.0, 1.0));

			var u = f * f * (3.0 - 2.0 * f);
			return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
		}

		function fbm(p:Vec2) : Float {
			var v = 0.0;
			var amp = 0.5;
			for( i in 0...5 ) {
				v += amp * valueNoise(p);
				p = p * 2.0 + vec2(17.1, 31.7);
				amp *= 0.5;
			}
			return v;
		}

		function fogField(uv:Vec2, t:Float) : Float {
			var flow = fbm(uv * 0.9 + vec2(t * 0.05, t * 0.018));
			var warpUv = uv + vec2(flow * 0.35, flow * 0.18);
			var low = fbm(warpUv * vec2(1.1, 0.75) + vec2(-t * 0.03, t * 0.015));
			var mid = fbm(warpUv * vec2(2.35, 1.55) + vec2(t * 0.06, -t * 0.028));
			var wisps = fbm(warpUv * vec2(4.8, 2.8) + vec2(-t * 0.11, t * 0.09));

			var body = smoothstep(0.3, 0.72, low);
			var puffs = smoothstep(0.36, 0.78, mid);
			var wisp = smoothstep(0.55, 0.87, wisps);
			return body * 0.68 + puffs * 0.38 + wisp * 0.18;
		}

		function fragment() {
			var src = texture.get(calculatedUV);
			var uv = input.uv;
			var t = time * 0.22;

			var farField = fogField(uv * vec2(1.0, 0.9), t);
			var nearField = fogField(uv * vec2(1.45, 1.1) + vec2(0.3, -0.08), t + 8.0);
			var shapeField = farField * 0.72 + nearField * 0.86;
			var edgeBand = smoothstep(0.4, 0.58, shapeField) - smoothstep(0.58, 0.8, shapeField);
			var erode = fbm(uv * vec2(5.2, 3.4) + vec2(-t * 0.2, t * 0.13));
			var pocketMask = smoothstep(0.34, 0.76, erode);

			var horizon = smoothstep(0.0, 1.0, uv.y);
			var nearBoost = smoothstep(0.08, 1.0, uv.y);
			var cloudBase = shapeField * (0.55 * horizon + 0.45 * nearBoost);
			var cloudMask = smoothstep(0.36, 0.9, cloudBase);
			cloudMask *= mix(0.52, 1.0, pocketMask);
			cloudMask = clamp(cloudMask + edgeBand * 0.35, 0.0, 1.0);

			var haze = (0.03 + 0.08 * horizon) * fogStrength;
			var fogAlpha = clamp(haze + cloudMask * 0.72 * fogStrength, 0.0, 0.88);
			var lighting = clamp(0.42 + farField * 0.35 + edgeBand * 0.55, 0.0, 1.0);
			var fogColor = mix(vec3(0.72, 0.8, 0.88), vec3(0.95, 0.98, 1.0), lighting);

			// Keep src referenced so the filter's texture input remains a required shader param.
			var tiny = src.a * 0.0;
			pixelColor = vec4(fogColor * (fogAlpha + tiny), fogAlpha + tiny);
		}
	};

	public function new() {
		super();
		this.time = 0;
		this.fogStrength = 1.0;
	}
}
