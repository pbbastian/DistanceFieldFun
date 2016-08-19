Shader "Hidden/DistanceFieldShader"
{
  Properties
  {
	  _MainTex ("Texture", 2D) = "white" {}
  }
  SubShader
  {
	  // No culling or depth
	  Cull Off ZWrite Off ZTest Always

	  Pass
	  {
CGPROGRAM
#pragma vertex vert_img
#pragma fragment frag
			
#include "UnityCG.cginc"
			
sampler2D _MainTex;

float distanceToNearestSurface(float3 p)
{
  return length(p) - 1.0;
}

float3 computeSurfaceNormal(float3 p)
{
  // const delta vectors for normal calculation
  const float eps = 0.01;

  float d = distanceToNearestSurface(p);
  return normalize(float3(
    distanceToNearestSurface(p+float3(eps, 0, 0)) - distanceToNearestSurface(p-float3(eps, 0, 0)),
    distanceToNearestSurface(p+float3(0, eps, 0)) - distanceToNearestSurface(p-float3(0, eps, 0)),
    distanceToNearestSurface(p+float3(0, 0, eps)) - distanceToNearestSurface(p-float3(0, 0, eps))
  ));
}

float3 shadeSurface(float3 p)
{
  float3 lightWS = float3(100 * _SinTime.w, 30 * _CosTime.w, 50 * _CosTime.w);
  float3 light = normalize(lightWS - p);
  float3 normal = computeSurfaceNormal(p);
  return dot(light, normal);
}

float3 intersectWithWorld(float3 p, float3 dir)
{
  float dist = 0.0;
  for (int i = 0; i < 20; i++) {
    float nearest = distanceToNearestSurface(p + dir*dist);
    if (nearest < 0.01) {
      return p + dir*dist;
    }
    dist += nearest;
  }
  return 0.0;
}

fixed4 frag (v2f_img i) : SV_Target
{
	fixed4 col = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST));
	
  const float3 cameraPosition = float3(0.0, 0.0, 10.0);
  const float3 cameraDirection = float3(0.0, 0.0, -1.0);
  const float3 cameraUp = float3(0.0, 1.0, 0.0);

  const float PI = 3.14159265359;
  const float fov = 50.0;
  const float fovx = PI * fov / 360.0;
  float fovy = fovx * _ScreenParams.y / _ScreenParams.x;
  float ulen = tan(fovx);
  float vlen = tan(fovy);

  float2 uv = i.uv;
  #if UNITY_UV_STARTS_AT_TOP
  uv.y = 1 - uv.y;
  #endif

  float2 camUV = uv * 2 - 1;
  float3 cameraRight = normalize(cross(cameraUp, cameraDirection));
  float3 pixel = cameraPosition + cameraDirection + cameraRight*camUV.x*ulen + cameraUp*camUV.y*vlen;
  float3 rayDirection = normalize(pixel - cameraPosition);

  float3 surfacePosition = intersectWithWorld(cameraPosition, rayDirection);
  if (length(surfacePosition) > 0) {
    float3 pixelColor = shadeSurface(surfacePosition);
    return fixed4(pixelColor, 1.0);
  }

	return col;
}
ENDCG
	  }
  }

  Fallback off
}
