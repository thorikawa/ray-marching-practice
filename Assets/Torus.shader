﻿Shader "Unlit/Torus"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Loop ("Loop", Range(1, 100)) = 30
        _Color ("Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _R1 ("Radius1", Float) = 10.0
        _R2 ("Radius2", Float) = 2.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off

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
            float _R1;
            float _R2;

            float3 hsv2rgb(float3 c) {
                c = float3(c.x, clamp(c.yz, 0.0, 1.0));
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float smin(float a, float b) {
                float k = 0.25;
                float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
                return lerp(a, b, h) - k*h*(1.0-h);
            }

            float DistanceFunc(float3 pos, float y)
            {
                float2 dir1 = _R1 * normalize(float2(pos.x, pos.z));
                float d = length(pos - float3(dir1.x, y, dir1.y)) - _R2;
                float d2 = 0.2 * sin(5 * pos.x + _Time.x) * sin(5 * pos.y + _Time.y) * sin(5 * pos.z + _Time.z);
                return d + d2;
            }

            float DistanceFunc(float3 pos) {
                return DistanceFunc(pos, 0.0);
            }

            float3 GetNormal(float3 pos)
            {
                const float d = 0.001;
                return 0.5 + 0.5 * normalize(float3(
                    DistanceFunc(pos + float3(  d, 0.0, 0.0)) - DistanceFunc(pos + float3( -d, 0.0, 0.0)),
                    DistanceFunc(pos + float3(0.0,   d, 0.0)) - DistanceFunc(pos + float3(0.0,  -d, 0.0)),
                    DistanceFunc(pos + float3(0.0, 0.0,   d)) - DistanceFunc(pos + float3(0.0, 0.0,  -d))));
            }

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
                float theta = atan2(pos.z, pos.x) + _Time.z;
                //float fx = frac(pos.x * 0.1 / 1.0) * 10.0;
                float3 hsvCol = float3(theta / (2 * 3.141592), 0.9, 1.0);
                col.rgb = max(dot(normal, lightDir), 0.0) * hsv2rgb(hsvCol) * 1.2;
                col.a = _Color.a;
                return col;
            }
            ENDCG
        }
    }
}
