// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/DistanceField"
{
	Properties
	{
        _Color ("Color", Color) = (1,1,1,1)
        _SpecularPower ("Specular power", Float) = 20
        _Gloss ("Gloss", Float) = 1
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
#include "Lighting.cginc"

struct appdata
{
    float4 vertex : POSITION;
};

struct v2f
{
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    float3 osDirection : TEXCOORD1;
    float3 osPosition : TEXCOORD2;
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _Color;
float _SpecularPower;
float _Gloss;

v2f vert (appdata v)
{
    v2f o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
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

float sdf_smin(float a, float b, float k = 32)
{
	float res = exp(-k*a) + exp(-k*b);
	return -log(max(0.0001,res)) / k;
}

float world(float3 p)
{
    //p.x = (abs(p.x) % 3) - 1.5;
    //return sphere(p, 0, 1);
    return sdf_smin(cube(p, 0, 0.3), sphere(p, 0.25, 0.15), 16);
    //return cube(p, 0, 1);
}

#define EPS 0.001
#define NORMAL_EPS 0.000001
#define ITERATIONS 50

float3 computeSurfaceNormal(float3 p)
{
    // const delta vectors for normal calculation
    const float eps = 0.01;

    float d = world(p);
    return normalize(float3(
        world(p+float3(NORMAL_EPS, 0, 0)) - world(p-float3(NORMAL_EPS, 0, 0)),
        world(p+float3(0, NORMAL_EPS, 0)) - world(p-float3(0, NORMAL_EPS, 0)),
        world(p+float3(0, 0, NORMAL_EPS)) - world(p-float3(0, 0, NORMAL_EPS))
    ));
}

float3 shadeSurface(float3 p)
{
    float3 lightDirection = normalize(mul(unity_WorldToObject, float4(_WorldSpaceLightPos0.xyz, 0)).xyz);
    float3 lightColor = _LightColor0.rgb;
    float3 normal = computeSurfaceNormal(p);

    // Diffuse
    float NdotL = dot(lightDirection, normal);

    // Specular
    float3 osCamera = mul(unity_WorldToObject, _WorldSpaceCameraPos);
    float3 viewDirection = normalize(p - osCamera);
    float3 halfVec = (lightDirection - viewDirection) / 2;
    float specular = pow(dot(normal, halfVec), _SpecularPower) * _Gloss;

    return NdotL * _Color.xyz * lightColor + specular;
}

fixed4 intersect(float3 p, float3 dir)
{
    for (int i = 0; i < ITERATIONS; i++) {
        float distance = world(p);
        if (distance < EPS) {
            return fixed4(shadeSurface(p), 1);
        }
        p += distance * dir;
    }

    return 0;
}

fixed4 frag (v2f i) : SV_Target
{
    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, col);

    return intersect(i.osPosition, normalize(i.osDirection));
}
ENDCG
		}
	}
}
