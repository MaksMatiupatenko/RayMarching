uniform vec2 resolution;
uniform vec3 cameraPos;
uniform vec3 forward;
uniform vec3 right;
uniform vec3 up;


const float RENDER_DIST = 1e4;
const float MIN_DIST = 1e-3;
const int RENDER_ITERATIONS = 256;
const float EPS = 1e-3;
const float INF = 1e9;


float sphereDist(vec3 pos, float radius, vec3 point) {
	return length(pos - point) - radius;
}
float planeDist(vec3 norm, float h, vec3 point) {
	return dot(point, norm) - h;
}

vec2 objUnion(vec2 obj1, vec2 obj2) {
	if (obj1.x < obj2.x) return obj1;
	else return obj2;
}
vec2 objIntersection(vec2 obj1, vec2 obj2) {
	if (obj1.x > obj2.x) return obj1;
	else return obj2;
}
vec2 objDifference(vec2 obj1, vec2 obj2) {
	if (obj1.x > -obj2.x) return obj1;
	else return obj2;
}

vec3 cycle(vec3 point, vec3 c) {
	return mod(point + 0.5 * c, c) - 0.5 * c;
}

vec2 map(vec3 point) {
	vec2 obj;

	// sphere
	{
	int id = 1;

	obj = vec2(sphereDist(vec3(0, 0, 0), 1, cycle(point, vec3(0, 0, 0))), id);
	}

	//plane
	{
	int id = 2;

	obj = objUnion(obj, vec2(planeDist(vec3(0, 0, 1), -5, point), id));
	}

	return obj;
}


vec4 castRay(vec3 rayPos, vec3 rayDir) {
	float mnDist = RENDER_DIST;
	for (int i = 0; i < RENDER_ITERATIONS; ++i) {
		float dist = map(rayPos).x;
		mnDist = min(mnDist, dist);
		rayPos += rayDir * dist;
		if (dist < 0) break;
	}
	return vec4(rayPos, mnDist);
}

vec3 getNormal(vec3 point) {
	vec2 eps = {EPS, 0};
	vec3 norm = vec3(map(point).x) - vec3(map(point - eps.xyy).x, map(point - eps.yxy).x, map(point - eps.yyx).x);
	return normalize(norm);
}

vec3 getMaterial(float _id) {
	int id = int(_id);
	vec3 col;

	if (id == 1) col = vec3(0.5, 1.0, 0.3);
	if (id == 2) col = vec3(0.3, 0.7, 0.7);

	return col;
}
vec3 getColor(vec3 point) {
	vec3 lightPos = vec3(-20, 10, 50);
	vec3 norm = getNormal(point);
	float lightness = dot(normalize(lightPos - point), norm);

	vec3 material = getMaterial(map(point).y);

	//shadow
	float d = length(castRay(point + norm * 0.05, normalize(lightPos - point)) - point);
	if (d < length(lightPos - point)) lightness = 0;

	return vec3(lightness) * material;
}

vec3 background = {0, 0, 0};
vec3 render(vec3 rayPos, vec3 rayDir) {
	vec4 casted = castRay(rayPos, rayDir);

	if (casted.w > MIN_DIST || length(casted.xyz - rayPos) > RENDER_DIST) {
		return background;
	}
	return getColor(casted.xyz);
}

void main() {
	vec2 coord = (gl_FragCoord.xy / resolution - 0.5) * resolution / resolution.y;
	coord.y *= -1;

	vec3 rayDir = normalize(forward + right * coord.x + up * coord.y);

	vec3 col = render(cameraPos, rayDir);

	gl_FragColor = vec4(col, 1);
}