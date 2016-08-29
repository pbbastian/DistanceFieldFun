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
#include "SDF.cginc"

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

float world(float3 p)
{
    //p.x = (abs(p.x) % 3) - 1.5;
    //return sphere(p, 0, 1);
    //return min(sdf_cube(p, 0, 0.2), sdf_sphere(p, float3(0.2, 0.2*_SinTime.w, 0.2*_CosTime.w), 0.15));
    // return sdf_pillar(p, 0, 0.1);

    // Attempt at an infinite, twisting pillar.
    // Shouldn't use a repeated cube, as that leaves artifacts.
    float theta = p.y * 3.14 * 2 * _SinTime.w;
    float3x3 rotY = float3x3(
        cos(theta), 0, sin(theta),
        0, 1, 0,
        -sin(theta), 0, cos(theta)
    );
    float3 q = mul(rotY, p);
    return min(
        sdf_pillar(q, float3(0.08, 0, 0), 0.05),
        sdf_pillar(q, float3(0, 0, 0.08), 0.05)
    );
}

#define EPS 0.001
#define NORMAL_EPS 0.001
#define AO_STEP 0.01
#define AO_SCALE 10
#define AO_ITERATIONS 5
#define SHADOW_MIN_T 0.1
#define SHADOW_MAX_T 1
#define SHADOW_ITERATIONS 5
#define ITERATIONS 50

float3 computeNormal(float3 p)
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

float shadow(float3 p, float3 lightDirection)
{
    for (float t = SHADOW_MIN_T; t < SHADOW_MAX_T;) {
        float distance = world(p + lightDirection * t);
        if (distance < EPS) {
            return 0;
        }
        t += distance;
    }
    return 1;
}

float softshadow(float3 p, float3 lightDirection, float k = 32)
{
    float result = 1;
    for (float t = SHADOW_MIN_T; t < SHADOW_MAX_T;) {
        float distance = world(p + lightDirection * t);
        if (distance < EPS) {
            return 0;
        }
        result = min(result, k*distance/t);
        t += distance;
    }
    return result;
}

float ao(float3 p, float3 normal)
{
    float occlusion = 0;
    for (int i = 1; i <= AO_ITERATIONS; ++i) {
        float distance = world(p + i * AO_STEP * normal);
        occlusion += (i * AO_STEP - distance) / pow(2, i);
    }
    return 1 - clamp(AO_SCALE * occlusion, 0, 1);
}

float3 shadeSurface(float3 p)
{
    float3 lightDirection = normalize(mul(unity_WorldToObject, float4(_WorldSpaceLightPos0.xyz, 0)).xyz);
    float3 lightColor = _LightColor0.rgb;
    float3 normal = computeNormal(p);

    // Diffuse
    float NdotL = max(dot(lightDirection, normal), 0);

    // Specular
    float3 osCamera = mul(unity_WorldToObject, _WorldSpaceCameraPos);
    float3 viewDirection = normalize(p - osCamera);
    float3 halfVec = (lightDirection - viewDirection) / 2;
    float specular = pow(dot(normal, halfVec), _SpecularPower) * _Gloss;

    float3 ambient = unity_AmbientSky * ao(p, normal);

    return softshadow(p, lightDirection, 16)
            * (NdotL * _Color.xyz * lightColor + specular)
         + ambient;
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
    fixed4 col = intersect(i.osPosition, normalize(i.osDirection));

    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, col);

    return col;
}
ENDCG
		}
	}
}
