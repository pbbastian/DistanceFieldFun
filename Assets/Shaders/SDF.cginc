float sdf_cube(float3 p, float3 o, float3 s)
{
    float3 d = abs(o - p) - s;
    return min(max(d.x, max(d.y,d.z)), 0.0)
            + length(max(d, 0.0));
}

float sdf_sphere(float3 p, float3 o, float3 s)
{
    return length(o - p) - s;
}

float sdf_smin(float a, float b, float k = 32)
{
	float res = exp(-k*a) + exp(-k*b);
	return -log(max(0.0001,res)) / k;
}
