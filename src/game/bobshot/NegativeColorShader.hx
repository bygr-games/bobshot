package bobshot;

class NegativeColorShader extends hxsl.Shader {
	static var SRC = {
		@param var intensity : Float;
		var pixelColor : Vec4;

		function fragment() {
			pixelColor.rgb = pixelColor.rgb * (1.0 - intensity) + (vec3(1.0) - pixelColor.rgb) * intensity;
		}
	};

	public function new() {
		super();
		intensity = 0;
	}
}
