﻿Shader "Unlit/Sphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Loop ("Loop", Range(1, 100)) = 30
        _Color ("Color", Color) = (0.5, 0.5, 0.5, 1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #define CAMERA_POSITION     _WorldSpaceCameraPos
            #define CAMERA_FORWARD      -UNITY_MATRIX_V[2].xyz
            #define CAMERA_UP           UNITY_MATRIX_V[1].xyz
            #define CAMERA_RIGHT        UNITY_MATRIX_V[0].xyz
            #define CAMERA_FOCAL_LENGTH abs(UNITY_MATRIX_P[1][1])
            #define CAMERA_MAX_DISTANCE (_ProjectionParams.z - _ProjectionParams.y)

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float3 hsv2rgb(float3 c) {
                c = float3(c.x, clamp(c.yz, 0.0, 1.0));
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float smin(float a, float b) {
                float k = 0.24;
                float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
                return lerp(a, b, h) - k*h*(1.0-h);
            }

            float DistanceFunc(float3 pos, float y)
            {
                float3 center = float3(floor(pos.x) + 0.5, y, floor(pos.z) + 0.5);
                float r = 0.5;
                float d1 = length(pos - (center + float3(-1.0, 0.0, -1.0))) - r;
                float d2 = length(pos - (center + float3(0.0, 0.0, -1.0))) - r;
                float d3 = length(pos - (center + float3(1.0, 0.0, -1.0))) - r;
                float d4 = length(pos - (center + float3(-1.0, 0.0, 0.0))) - r;
                float d5 = length(pos - (center + float3(0.0, 0.0, 0.0))) - r;
                float d6 = length(pos - (center + float3(1.0, 0.0, 0.0))) - r;
                float d7 = length(pos - (center + float3(-1.0, 0.0, 1.0))) - r;
                float d8 = length(pos - (center + float3(0.0, 0.0, 1.0))) - r;
                float d9 = length(pos - (center + float3(1.0, 0.0, 1.0))) - r;

                //return min(d1, min(d2, min(d3, min(d4, min(d5, min(d6, min(d7, min(d8, d9))))))));
                return smin(d1, smin(d2, smin(d3, smin(d4, smin(d5, smin(d6, smin(d7, smin(d8, d9))))))));
            }

            float DistanceFunc(float3 pos) {
                return min(min(DistanceFunc(pos, 7.0), DistanceFunc(pos, 0.0)), DistanceFunc(pos, 3.5));
            }

            float3 GetNormal(float3 pos)
            {
                const float d = 0.001;
                return 0.5 + 0.5 * normalize(float3(
                    DistanceFunc(pos + float3(  d, 0.0, 0.0)) - DistanceFunc(pos + float3( -d, 0.0, 0.0)),
                    DistanceFunc(pos + float3(0.0,   d, 0.0)) - DistanceFunc(pos + float3(0.0,  -d, 0.0)),
                    DistanceFunc(pos + float3(0.0, 0.0,   d)) - DistanceFunc(pos + float3(0.0, 0.0,  -d))));
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 projPos : TEXCOORD0;
                float4 worldPos  : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            int _Loop;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPos = 2 * (i.projPos.xy / i.projPos.w - 0.5);
                screenPos.x *= _ScreenParams.x / _ScreenParams.y;

                float3 up = CAMERA_UP;
                float3 right = CAMERA_RIGHT;
                float3 forward = CAMERA_FORWARD;
                float focalLen = CAMERA_FOCAL_LENGTH;

                float3 rayDir = normalize(
                    right * screenPos.x + 
                    up   * screenPos.y + 
                    forward * focalLen);

                float3 pos = i.worldPos;
                float len = length(pos - CAMERA_POSITION);
                float dist = 0.0;

                for (int i = 0; i < _Loop; ++i) 
                {
                    dist = DistanceFunc(pos);
                    len += dist;
                    pos += rayDir * dist;
                    if (dist < 0.01) break;
                }

                if (dist > 0.01) discard;

                float3 normal = GetNormal(pos);
                float3 lightDir = _WorldSpaceLightPos0.xyz;

                fixed4 col;
                col.rgb = max(dot(normal, lightDir), 0.0) * _Color.rgb;
                col.a = _Color.a;
                return col;
            }
            ENDCG
        }
    }
}
