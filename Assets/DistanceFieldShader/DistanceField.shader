// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/DistanceField"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
		LOD 100

		Pass
		{
            Blend SrcAlpha OneMinusSrcAlpha
CGPROGRAM

#pragma vertex vert
#pragma fragment frag
// make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    float3 osDirection : TEXCOORD1;
    float3 osPosition : TEXCOORD2;
};

sampler2D _MainTex;
float4 _MainTex_ST;

v2f vert (appdata v)
{
    v2f o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);

    float3 osCameraPosition = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    o.osDirection = normalize(v.vertex - osCameraPosition);
    o.osPosition = v.vertex;

    return o;
}

float cube(float3 p, float3 o, float3 s)
{
    float3 d = abs(o - p) - s;
    return min(max(d.x, max(d.y,d.z)), 0.0)
            + length(max(d, 0.0));
}

float sphere(float3 p, float3 o, float3 s)
{
    return length(o - p) - s;
}

float world(float3 p)
{
    //p.x = (abs(p.x) % 3) - 1.5;
    //return sphere(p, 0, 1);
    return min(cube(p, 0, 0.3), sphere(p, 0.3, 0.2));
    //return cube(p, 0, 1);
}

float3 computeSurfaceNormal(float3 p)
{
    // const delta vectors for normal calculation
    const float eps = 0.01;

    float d = world(p);
    return normalize(float3(
        world(p+float3(eps, 0, 0)) - world(p-float3(eps, 0, 0)),
        world(p+float3(0, eps, 0)) - world(p-float3(0, eps, 0)),
        world(p+float3(0, 0, eps)) - world(p-float3(0, 0, eps))
    ));
}

float3 shadeSurface(float3 p)
{
    float3 lightWS = float3(100 * _SinTime.w, 30 * _CosTime.w, 50 * _CosTime.w);
    float3 light = normalize(lightWS - p);
    float3 normal = computeSurfaceNormal(p);
    return dot(light, normal) * (normal * 0.5 + 0.5);
}

float3 intersect(float3 p, float3 dir)
{
    float t = 0.0;
    float eps = 0.01;
    float finalEps = 0.1;
    float steps = 50;
    float epsStep = (finalEps - eps) / steps;
    float nearest = 3.402823466e+38F;

    for (int i = 0; i < steps; i++) {
        float distance = world(p + dir*t);
        if (distance < eps) {
        return p + dir*t;
        }
        nearest = min(nearest, distance);
        eps += epsStep;
        t += nearest;
    }

    return 0;
}

fixed4 frag (v2f i) : SV_Target
{
    // sample the texture
    fixed4 col = tex2D(_MainTex, i.uv);

    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, col);

    float3 surfacePosition = intersect(i.osPosition, normalize(i.osDirection));
    if (length(surfacePosition) > 0) {
        float3 pixelColor = shadeSurface(surfacePosition);
        return fixed4(pixelColor, 1.0);
    }

    return fixed4(0, 0, 0, 0);
}
ENDCG
		}
	}
}
