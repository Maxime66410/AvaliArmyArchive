﻿
// surface shader version of https://forum.unity.com/threads/gltfutility-a-simple-gltf-plugin.654319/page-4#post-6854009
 
// how to enable transparency for surface shaders
// https://forum.unity.com/threads/transparency-with-standard-surface-shader.394551/
// https://forum.unity.com/threads/simply-adding-alpha-fade-makes-my-shader-only-work-in-scene-view.546852/
Shader "Custom/LitTransparentWithDepth"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalMap ("Normal", 2D) = "bump" {}
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _AlphaMinimum ("Alpha Minimum", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 200
 
        Pass {
            ZWrite On
            //Cull Off // make double sided
            ColorMask 0 // don't draw any color
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
 
            sampler2D _MainTex;
            float4 _MainTex_ST;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
 
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - .97); // remove non-opaque pixels from writing to zbuffer
                return col;
            }
            ENDCG
        }
 
        // ---------- Start Pass 2 ----------
        ZWrite Off
        //Cull Off // make double sided
        Blend SrcAlpha OneMinusSrcAlpha
 
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade 
 
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
 
        sampler2D _MainTex;
        sampler2D _NormalMap;
 
        struct Input
        {
            float2 uv_MainTex;
        };
 
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed _AlphaMinimum;
 
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
 
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = clamp(c.a, _AlphaMinimum, 1);
            half4 normalMap = tex2D (_NormalMap, IN.uv_MainTex);
            o.Normal = UnpackNormal(normalMap);
        }
        ENDCG
    }
    FallBack "Diffuse"
}