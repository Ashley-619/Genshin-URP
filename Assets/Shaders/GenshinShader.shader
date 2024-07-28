Shader "TA/GenshinV1.0" {
    Properties {
        [Header(BaseColorMap)]
        [MainTexture]_BaseColorMap ("BaseColorMap", 2D) = "white" { }

        [Header(NormalMap)]
        [Toggle(_USE_NORMALMAP)] _Use_NormalMap ("UseNormalMap", Float) = 1
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" { }

        [Header(LightMap)]
        _LightMap ("Light Map", 2D) = "white" { }

        [Toggle(_IS_PROCESSLIGHTMAP)] _Is_ProcessLightMap ("IsProcessLightMap", Float) = 0//部分lightmap.g毛刺处理,简单说就是上下限中的处理到上下限均值；以外不变
        _ProcessLightMapMinValue("ProcessLightMapMinValue", Float) = 0
        _ProcessLightMapMaxValue("ProcessLightMapMaxValue", Float) = 0

        [Header(ShadowRamp)]
        _ShadowRamp ("ShadowRamp", 2D) = "white" { }
        _ShadowOffset ("Shadow Offset", Float) = 0.1
        _ShadowSmoothness ("Shadow Smoothness", Float) = 0.3

        [Header(Specular)]
        [Toggle(_USE_SPECULAR)] _UseSpecular ("UseSpecular", Float) = 1
        _MetalMap ("Metal Map", 2D) = "white" { }
        _SpecularSmoothness ("SpecularSmoothness", Float) = 0.5
        _MetallicIntensity ("MetallicIntensity", Float) = 1
        _NonMetallicIntensity ("NonMetallicIntensity", Float) = 0.3

        [Header(Face)]
        [Toggle(_IS_FACE)] _IsFace ("Is Face", Float) = 0
        _FaceLightMap ("FaceLightMap", 2D) = "white" { }
        _RougeColor ("RougeColor", Color) = (1, 0.78, 0.78, 1)
        _RougeIntensity ("RougeIntensity", Float) = 0.15

        [Header(Hair)]
        [Toggle(_IS_HAIR)] _IsHAIR ("IsHAIR", Float) = 0

        //边缘光效果
        [Header(Rim)]
        [Toggle(_USE_RIM)] _UseRim ("UseRim", Float) = 0
        _RimOffSet ("RimOffSet", Float) = 0.3
        _RimThreshold ("RimThreshold", Float) = 0.1
        _RimColor ("RimColor", Color) = (1, 1, 1, 1)
        _RimIntensity ("RimIntensity", Float) = 0.6

        //描边
        [Header(Otuline)]
        [Toggle(_USE_OUTLINE)] _UseOutline ("UseOutLine", Float) = 0
        _OutlineColor ("OutLineColor", Color) = (0, 0, 0, 1)
        _OutlineWidth ("OutlineWidth", Float) = 0.000003

        //自发光
        [Header(Emission)]
        [Toggle(_USE_EMISSION)] _UseEmission ("UseEmission", Float) = 0
        _EmissionIntensity ("EmissionIntensity", Float) = 0

        
        [Header(LightColor)]
        [Toggle(_USE_LIGHTCOLOR)] _Use_LightColor ("UseLightColor", Float) = 1

        [Header(others)]
        [ToggleUI] _IsDayTime ("Is Day Time", Float) = 1
        //渲染双面材质的一些设置
        [Toggle(_DOUBLE_SIDED)] _DoubleSided ("Double Sided", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
    }
    SubShader {
        Tags { "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True"
        }


        Pass {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            Cull[_Cull]
            ZWrite On
            Blend[_SrcBlend][_DstBlend]


            HLSLPROGRAM
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            //变体
            #pragma shader_feature_local_fragment _USE_LIGHTCOLOR
            #pragma shader_feature_local_fragment _DOUBLE_SIDED
            #pragma shader_feature_local_fragment _IS_FACE
            #pragma shader_feature_local_fragment _USE_SPECULAR
            #pragma shader_feature_local_fragment _USE_NORMALMAP
            #pragma shader_feature_local_fragment _IS_PROCESSLIGHTMAP
            #pragma shader_feature_local_fragment _IS_HAIR
            #pragma shader_feature_local_fragment _USE_RIM
            #pragma shader_feature_local_fragment _USE_EMISSION
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma vertex vert
            #pragma fragment frag



            TEXTURE2D(_BaseColorMap);
            SAMPLER(sampler_BaseColorMap);
            float4 _BaseColorMap_ST;


            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            //lightMap
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);
            float _ProcessLightMapMinValue;
            float _ProcessLightMapMaxValue;

            TEXTURE2D(_ShadowRamp);
            SAMPLER(sampler_ShadowRamp);

            TEXTURE2D(_MetalMap);
            SAMPLER(sampler_MetalMap);

            //面部
            TEXTURE2D(_FaceLightMap);
            SAMPLER(sampler_FaceLightMap);
            half4 _RougeColor;
            half _RougeIntensity;

            half _ShadowOffset;
            half _ShadowSmoothness;


            float _IsDayTime;

            //双面渲染相关的
            half _Cull;
            half _SrcBlend;
            half _DstBlend;

            //高光
            float _ShowSpecular;
            float _SpecularSmoothness;
            float _MetallicIntensity;
            float _NonMetallicIntensity;

            //边缘光
            float _RimOffSet;
            float _RimThreshold;
            half4 _RimColor;
            float _RimIntensity;

            //自发光,神之眼
            float _EmissionIntensity;

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 backUV : TEXCOORD1;
            };

            struct Varyings {
                float2 uv : TEXCOORD0;
                float2 backUV : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
                half3 positionWS : TEXCOORD3;
                float4 positionNDC : TEXCOORD4;
                float3 positionVS : TEXCOORD5;
                half3 tangentWS : TEXCOORD6;
                half3 bitangentWS : TEXCOORD7;
                half4 color : COLOR;
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes input) {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv = TRANSFORM_TEX(input.uv, _BaseColorMap);
                output.backUV = TRANSFORM_TEX(input.backUV, _BaseColorMap);
                output.color = input.color;

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.positionNDC = vertexInput.positionNDC;
                output.positionVS = vertexInput.positionVS;

                output.normalWS = normalInput.normalWS;

                return output;
            }

            //越大表明越不是阴影
            half GetShadowValue(Varyings input, half3 lightDirection, half aoFactor) {
                half NDotL = dot(input.normalWS, lightDirection);
                half halfLambert = 0.5 * NDotL + 0.5;
                //半兰伯特
                half shadow = saturate(2.0 * halfLambert * aoFactor);
                return shadow;
            }

            half3 GetShadowColor(half shadow, half material, half isDayTime) {
                //全黑取第4列
                int index = 4;
                index = lerp(index, 1, step(0.2, material));
                index = lerp(index, 2, step(0.4, material));
                index = lerp(index, 0, step(0.6, material));
                index = lerp(index, 3, step(0.8, material));


                half rangeMin = 0.5 + _ShadowOffset -_ShadowSmoothness;
                half rangeMax = 0.5 + _ShadowOffset;

                half rampU = smoothstep(rangeMin, rangeMax, shadow);//我个人认为这个平滑的本质是压缩，比如0-1，颗粒度会很大；压缩到0.3范围，锯齿就不明显了。
                half rampV = saturate(0.5 * isDayTime + index / 10.0 + 0.05);
                half2 rampUV = half2(rampU, rampV);
                half3 shadowRamp = SAMPLE_TEXTURE2D(_ShadowRamp, sampler_ShadowRamp, rampUV);

                half3 shadowColor = lerp(shadowRamp, half3(1.0,1.0,1.0), step(rangeMax, shadow));

                return shadowColor;
            }



            half3 GetSpecularColor(Varyings input, half3 lightDirection, half3 lightMap, half3 baseColor) {
                //blinn模型
                half3 V = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half3 H = SafeNormalize(lightDirection + V);
                half NDotH = dot(input.normalWS, H);
                half blinn = pow(saturate(NDotH), _SpecularSmoothness);
                
                //matcap
                half3 normalVS = TransformWorldToViewNormal(input.normalWS, true);
                half2 matcapUV = 0.5 * normalVS.xy + 0.5;
                half3 metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, matcapUV);

                half3 metallic = lerp(half3(0,0,0),blinn * lightMap.b * baseColor * metalMap * _MetallicIntensity * lightMap.r,step(0.9, lightMap.r));
                half3 nonMetallic = lerp(blinn * lightMap.b * baseColor  * _NonMetallicIntensity *lightMap.r,half3(0,0,0),step(0.9, lightMap.r));
                half3 specular = metallic+nonMetallic;

                return specular;
            }

            //脸部阴影（硬）
            int GetFaceShadowValue(Varyings input, half3 lightDirection) {
                //角色通过建模软件导出后，结果变成了 y forward， -x up， -z right。
                half3 Front = TransformObjectToWorldDir(half3(0, 1, 0));
                half3 Right = TransformObjectToWorldDir(half3(0, 0, -1));

                half3 L = SafeNormalize(half3(lightDirection.x, 0.0, lightDirection.z));
                half FDotL = dot(Front.xz, L.xz);
                half RDotL = dot(Right.xz, L.xz);

                half2 shadowUV = input.uv;
                if (RDotL > 0) {
                    shadowUV.x = 1.0 - shadowUV.x;
                }
                half faceShadowMap = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, shadowUV).r;
                int faceShadow = step(-0.5 * FDotL + 0.5, faceShadowMap);

                return faceShadow;
            }

            //齐次裁剪转视口（unity中的NDC和《入门精要》的NDC有一点差异），这里参考下面GetVertexPositionInputs的实现
            float4 TransformHClipToViewPortPos(float4 positionCS) {
                float4 o = positionCS * 0.5f;
                o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;//_ProjectionParams.x用于处理DX11和OpenGL的Y分量相反的情况，其实就是没除w
                o.zw = positionCS.zw;
                return o / o.w;
            }

            //VertexPositionInputs GetVertexPositionInputs(float3 positionOS) {
            //    VertexPositionInputs input;
            //    input.positionWS = TransformObjectToWorld(positionOS);
            //    input.positionVS = TransformWorldToView(input.positionWS);
            //    input.positionCS = TransformWorldToHClip(input.positionWS);

            //    float4 ndc = input.positionCS * 0.5f;
            //    input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
            //    input.positionNDC.zw = input.positionCS.zw;

            //    return input;
            //}

            half3 GetRimColor(Varyings input, half3 baseColor) {
                half3 normalVS = TransformWorldToViewNormal(input.normalWS, true);
                half3 samplePositionVS = half3(input.positionVS.xy + normalVS.xy * _RimOffSet*0.01, input.positionVS.z);
                //0.01是一个缩放系数，方便调整，无实际意义；由于后面的变化没有用到关于Z的参数，理论上z没有影响。这里值得继续深究。

                float4 samplePositionCS = TransformWViewToHClip(samplePositionVS);
                float4 samplePositionNDC = TransformHClipToViewPortPos(samplePositionCS);

                float depth = SampleSceneDepth(input.positionNDC.xy / input.positionNDC.w);
                float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);

                float offsetDepth = SampleSceneDepth(samplePositionNDC / samplePositionNDC.w);
                float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);

                float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
                half3 rimColor = smoothstep(0.0, _RimThreshold, depthDiff) * baseColor * _RimIntensity * _RimColor;
                return rimColor;
            }


            float4 frag(Varyings input, FRONT_FACE_TYPE facing : FRONT_FACE_SEMANTIC) : SV_Target {
                //光照
                Light mainLight = GetMainLight();
                half3 lightDirection = SafeNormalize(mainLight.direction);

                #if _DOUBLE_SIDED
                    input.uv = lerp(input.uv, input.backUV, IS_FRONT_VFACE(facing, 0.0, 1.0));
                #endif

                half4 baseColorRGBA = SAMPLE_TEXTURE2D(_BaseColorMap, sampler_BaseColorMap, input.uv);
                half3 baseColor = baseColorRGBA.rgb;

                #if _USE_NORMALMAP
                    //这里的目的是把法线纹理（切线空间）映射到世界空间中，方便用来计算光照效果
                    half3x3 tangentToWorld = half3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                    half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
                    half3 normalTS = UnpackNormal(normalMap);
                    half3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld, true);
                    input.normalWS = normalWS;
                #endif
                
                //光照贴图
                half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv);
                #if _IS_PROCESSLIGHTMAP
                
                    //针对霄宫lightmap的特殊优化，应该只有头发需要开启，非常奇怪的问题，lightmap似乎画坏了
                    if (lightMap.g < _ProcessLightMapMaxValue) 
                    {
                        if (lightMap.g > _ProcessLightMapMinValue) 
                        {
                            lightMap.g = (_ProcessLightMapMaxValue+_ProcessLightMapMinValue)*0.5;
                        }
                    }
                #endif
                //腮红,正片叠底
                #if _IS_FACE
                    baseColor = (1.0 - baseColorRGBA.a * _RougeIntensity) * baseColor + _RougeIntensity * _RougeColor.rgb * baseColorRGBA.a;
                #endif
                //阴影计算(面部和身体)
                #if _IS_FACE
                    half shadowValue = GetFaceShadowValue(input, lightDirection);
                    half3 shadowColor = GetShadowColor(shadowValue, 1, _IsDayTime);
                #else
                    half aoFactor = lightMap.g * input.color.r;
                    half shadowValue = GetShadowValue(input, lightDirection, aoFactor);
                    half3 shadowColor = GetShadowColor(shadowValue, lightMap.a, _IsDayTime);
                #endif
                //高光
                half3 specularColor = half3(0, 0, 0);
                #if !_IS_FACE
                    #if _USE_SPECULAR
                        specularColor = GetSpecularColor(input, lightDirection, lightMap.rgb, baseColor);
                    #endif
                #endif

                //边缘光
                half3 rimColor = half3(0, 0, 0);
                #if _USE_RIM
                    rimColor = GetRimColor(input, baseColor);
                #endif

                //自发光
                half3 emission = 0.0;
                #if _USE_EMISSION
                    //自发光
                    half isEmissionArea = step(0.5, baseColorRGBA.a);
                    half sinValue = (_SinTime.a  + 1.0) * 0.5;
                    emission = baseColor * _EmissionIntensity * sinValue * isEmissionArea;
                #endif


                half3 finalColor = baseColor * shadowColor + specularColor + rimColor + emission;

                #if _USE_LIGHTCOLOR 
                    finalColor = mainLight.color * (baseColor * shadowColor + specularColor + rimColor + emission);   
                #endif
                
                return half4(finalColor, 1);
            }



            ENDHLSL
        }


        Pass {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            ENDHLSL
        }

        Pass {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"

            ENDHLSL
        }


        Pass {
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma shader_feature _USE_OUTLINE

            float4 _OutlineColor;
            float _OutlineWidth;

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            Varyings vert(Attributes input) {
                #if !_USE_OUTLINE
                    _OutlineWidth = 0;
                #endif

                //屏幕等宽的描边，我觉得效果没有模型等宽的描边好
                //Varyings output= (Varyings)0;


                //VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                //half4 positionCS = vertexInput.positionCS;

                //VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                //half3 normalVS = TransformWorldToViewNormal(normalInput.normalWS, true);
                
                //half2 normalCSxy =  mul((float2x2)UNITY_MATRIX_P, normalVS.xy);
                //float2 offset = normalize(normalCSxy) * _OutlineWidth * positionCS.w *input.color.a;

                //positionCS.xy += offset;

                //output.pos =positionCS;
                //output.uv = input.uv;
                //output.color = input.color;
                //return output;

                Varyings output = (Varyings)0;
                float3 offset = input.normalOS * _OutlineWidth * input.color.a;
                float4 posOSOffset = float4(input.positionOS.xyz + offset, input.positionOS.w);
                output.positionCS = TransformObjectToHClip(posOSOffset);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings i) : SV_TARGET {
                return _OutlineColor;
            }

            ENDHLSL
        }
    }
}