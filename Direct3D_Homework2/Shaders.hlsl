struct MATERIAL
{
	float4					m_cAmbient;
	float4					m_cDiffuse;
	float4					m_cSpecular; //a = power
	float4					m_cEmissive;
};

cbuffer cbCameraInfo : register(b1)
{
	matrix		gmtxView : packoffset(c0);
	matrix		gmtxProjection : packoffset(c4);
	float3		gvCameraPosition : packoffset(c8);
};

cbuffer cbGameObjectInfo : register(b2)
{
	matrix		gmtxGameObject : packoffset(c0);
	MATERIAL	gMaterial : packoffset(c4);
	uint		gnTexturesMask : packoffset(c8);
};

cbuffer cbFrameworkInfo : register(b3)
{
    float gfCurrentTime : packoffset(c0.x);
    float gfElapsedTime : packoffset(c0.y);
};

#include "Light.hlsl"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//#define _WITH_VERTEX_LIGHTING

#define MATERIAL_ALBEDO_MAP			0x01
#define MATERIAL_SPECULAR_MAP		0x02
#define MATERIAL_NORMAL_MAP			0x04
#define MATERIAL_METALLIC_MAP		0x08
#define MATERIAL_EMISSION_MAP		0x10
#define MATERIAL_DETAIL_ALBEDO_MAP	0x20
#define MATERIAL_DETAIL_NORMAL_MAP	0x40

//#define _WITH_STANDARD_TEXTURE_MULTIPLE_PARAMETERS

#ifdef _WITH_STANDARD_TEXTURE_MULTIPLE_PARAMETERS
Texture2D gtxtAlbedoTexture : register(t6);
Texture2D gtxtSpecularTexture : register(t7);
Texture2D gtxtNormalTexture : register(t8);
Texture2D gtxtMetallicTexture : register(t9);
Texture2D gtxtEmissionTexture : register(t10);
Texture2D gtxtDetailAlbedoTexture : register(t11);
Texture2D gtxtDetailNormalTexture : register(t12);
#else
Texture2D gtxtStandardTextures[7] : register(t0);
#endif

SamplerState gssWrap : register(s0);

struct VS_STANDARD_INPUT
{
	float3 position : POSITION;
	float2 uv : TEXCOORD;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 bitangent : BITANGENT;
};

struct VS_STANDARD_OUTPUT
{
	float4 position : SV_POSITION;
	float3 positionW : POSITION;
	float3 normalW : NORMAL;
	float3 tangentW : TANGENT;
	float3 bitangentW : BITANGENT;
	float2 uv : TEXCOORD;
};

VS_STANDARD_OUTPUT VSStandard(VS_STANDARD_INPUT input)
{
	VS_STANDARD_OUTPUT output;

	output.positionW = (float3)mul(float4(input.position, 1.0f), gmtxGameObject);
	output.normalW = mul(input.normal, (float3x3)gmtxGameObject);
	output.tangentW = (float3)mul(float4(input.tangent, 1.0f), gmtxGameObject);
	output.bitangentW = (float3)mul(float4(input.bitangent, 1.0f), gmtxGameObject);
	output.position = mul(mul(float4(output.positionW, 1.0f), gmtxView), gmtxProjection);
	output.uv = input.uv;

	return(output);
}

float4 PSStandard(VS_STANDARD_OUTPUT input) : SV_TARGET
{
	float4 cAlbedoColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	float4 cSpecularColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	float4 cNormalColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	float4 cMetallicColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
	float4 cEmissionColor = float4(0.0f, 0.0f, 0.0f, 1.0f);

#ifdef _WITH_STANDARD_TEXTURE_MULTIPLE_PARAMETERS
	if (gnTexturesMask & MATERIAL_ALBEDO_MAP) cAlbedoColor = gtxtAlbedoTexture.Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_SPECULAR_MAP) cSpecularColor = gtxtSpecularTexture.Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_NORMAL_MAP) cNormalColor = gtxtNormalTexture.Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_METALLIC_MAP) cMetallicColor = gtxtMetallicTexture.Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_EMISSION_MAP) cEmissionColor = gtxtEmissionTexture.Sample(gssWrap, input.uv);
#else
	if (gnTexturesMask & MATERIAL_ALBEDO_MAP) cAlbedoColor = gtxtStandardTextures[0].Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_SPECULAR_MAP) cSpecularColor = gtxtStandardTextures[1].Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_NORMAL_MAP) cNormalColor = gtxtStandardTextures[2].Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_METALLIC_MAP) cMetallicColor = gtxtStandardTextures[3].Sample(gssWrap, input.uv);
	if (gnTexturesMask & MATERIAL_EMISSION_MAP) cEmissionColor = gtxtStandardTextures[4].Sample(gssWrap, input.uv);
#endif

	float4 cIllumination = float4(1.0f, 1.0f, 1.0f, 1.0f);
	float4 cColor = cAlbedoColor + cSpecularColor + cEmissionColor;
	if (gnTexturesMask & MATERIAL_NORMAL_MAP)
	{
		float3 normalW = input.normalW;
		float3x3 TBN = float3x3(normalize(input.tangentW), normalize(input.bitangentW), normalize(input.normalW));
		float3 vNormal = normalize(cNormalColor.rgb * 2.0f - 1.0f); //[0, 1] → [-1, 1]
		normalW = normalize(mul(vNormal, TBN));
		cIllumination = Lighting(input.positionW, normalW);
		cColor = lerp(cColor, cIllumination, 0.5f);
	}

	return(cColor);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
struct VS_SKYBOX_CUBEMAP_INPUT
{
	float3 position : POSITION;
};

struct VS_SKYBOX_CUBEMAP_OUTPUT
{
	float3	positionL : POSITION;
	float4	position : SV_POSITION;
};

VS_SKYBOX_CUBEMAP_OUTPUT VSSkyBox(VS_SKYBOX_CUBEMAP_INPUT input)
{
	VS_SKYBOX_CUBEMAP_OUTPUT output;

	output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
	output.positionL = input.position;

	return(output);
}

TextureCube gtxtSkyCubeTexture : register(t7);
SamplerState gssClamp : register(s1);

float4 PSSkyBox(VS_SKYBOX_CUBEMAP_OUTPUT input) : SV_TARGET
{
    float4 cColor = gtxtSkyCubeTexture.Sample(gssClamp, input.positionL);

	return(cColor);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Texture2D gtxtTexture : register(t8);
//SamplerState gSamplerState : register(s0);

struct VS_TEXTURED_INPUT
{
    float3 position : POSITION;
    float2 uv : TEXCOORD;
};

struct VS_TEXTURED_OUTPUT
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD;
};

VS_TEXTURED_OUTPUT VSTextureToScreen(VS_TEXTURED_INPUT input)
{
    VS_TEXTURED_OUTPUT output;

    output.position = float4(input.position, 1.0f);
    output.uv = input.uv;

    return (output);
}

float4 PSTextureToScreen(VS_TEXTURED_OUTPUT input) : SV_TARGET
{
    float4 cColor = gtxtTexture.Sample(gssWrap, input.uv);
    //float4 cColor = { 1.0f, 1.0f, 0.0f, 1.0f};

//    if ((cColor.r > 0.85f) && (cColor.g > 0.85f) && (cColor.b > 0.85f)) discard;
	
    return (cColor);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Texture2D gtxtTerrainBaseTexture : register(t9); // 터레인 기본 텍스처
Texture2D gtxtTerrainDetailTexture : register(t10); // 터레인 디테일 텍스처
SamplerState gwrapState : register(s0);

// 버텍스 셰이더 입력 구조체
struct VS_TERRAIN_INPUT
{
    float3 position : POSITION; // 위치 데이터
    float4 color : COLOR; // 색상 데이터
    float2 uv0 : TEXCOORD0; // 텍스처 좌표 0
    float2 uv1 : TEXCOORD1; // 텍스처 좌표 1
};

// 버텍스 셰이더 출력 구조체
struct VS_TERRAIN_OUTPUT
{
    float4 position : SV_POSITION; // 변환된 위치
    float4 color : COLOR; // 색상 데이터
    float2 uv0 : TEXCOORD0; // 텍스처 좌표 0
    float2 uv1 : TEXCOORD1; // 텍스처 좌표 1
};

// 버텍스 셰이더
VS_TERRAIN_OUTPUT VSTerrain(VS_TERRAIN_INPUT input)
{
    VS_TERRAIN_OUTPUT output;

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
    // 상수 버퍼를 사용하는 경우: 월드, 뷰, 프로젝션 행렬 곱셈
    output.position = mul(mul(mul(float4(input.position, 1.0f), gcbGameObjectInfo.mtxWorld), gcbCameraInfo.mtxView), gcbCameraInfo.mtxProjection);
#else
    // 상수 버퍼를 사용하지 않는 경우: 전역 행렬 곱셈
    output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
#endif
    output.color = input.color; // 색상 전달
    output.uv0 = input.uv0; // 텍스처 좌표 0 전달
    output.uv1 = input.uv1; // 텍스처 좌표 1 전달

    return (output); // 출력 반환
}

// 픽셀 셰이더
float4 PSTerrain(VS_TERRAIN_OUTPUT input) : SV_TARGET
{
    //기본 텍스처와 디테일 텍스처 샘플링
    float4 cBaseTexColor = gtxtTerrainBaseTexture.Sample(gwrapState, input.uv0);
    float4 cDetailTexColor = gtxtTerrainDetailTexture.Sample(gwrapState, input.uv1);
    
    // 색상 조합 및 최종 색상 반환
    float4 cColor = input.color * saturate((cBaseTexColor * 0.5f) + (cDetailTexColor * 0.5f));
    //float4 cColor = { 1.0f, 1.0f, 0.0f, 1.0f };
	
    return (cColor); // 최종 픽셀 색상 반환
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//bullet

struct VS_DIFFUSED_INPUT
{
    float3 position : POSITION;
};

struct VS_DIFFUSED_OUTPUT
{
    float4 position : SV_POSITION; // SV_POSITION 사용
    float3 positionL : POSITION; // 월드 공간 좌표
};

VS_DIFFUSED_OUTPUT VSDiffused(VS_DIFFUSED_INPUT input)
{
    VS_DIFFUSED_OUTPUT output;

    // 행렬 곱셈에 괄호 추가
    output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
    output.positionL = input.position;

    return output;
}

TextureCube gtxtBulletTexture : register(t11);
SamplerState gssWrap2 : register(s0);

float4 PSDiffused(VS_DIFFUSED_OUTPUT input) : SV_TARGET
{
    // 입력 위치를 방향 벡터로 변환
    float3 direction = normalize(input.positionL); // 방향 벡터로 정규화

    // 큐브 텍스처 샘플링
    float4 cColor = gtxtBulletTexture.Sample(gssWrap2, direction);

    return cColor;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TOWER

struct VS_TOWER_INPUT
{
    float3 position : POSITION;
};

struct VS_TOWER_OUTPUT
{
    float4 position : SV_POSITION; // SV_POSITION 사용
    float3 positionL : POSITION; // 월드 공간 좌표
};

VS_TOWER_OUTPUT VSTOWER(VS_TOWER_INPUT input)
{
    VS_TOWER_OUTPUT output;

    // 행렬 곱셈에 괄호 추가
    output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
    output.positionL = input.position;

    return output;
}

TextureCube gtxtTOWERTexture : register(t12);
SamplerState gssWrap3 : register(s0);

float4 PSTOWER(VS_TOWER_OUTPUT input) : SV_TARGET
{
    // 입력 위치를 방향 벡터로 변환
    float3 direction = normalize(input.positionL); // 방향 벡터로 정규화

    // 큐브 텍스처 샘플링
    float4 cColor = gtxtTOWERTexture.Sample(gssWrap3, direction);

    return cColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
#define _WITH_BILLBOARD_ANIMATION

VS_TEXTURED_OUTPUT VSBillboard(VS_TEXTURED_INPUT input)
{
    VS_TEXTURED_OUTPUT output;

#ifdef _WITH_CONSTANT_BUFFER_SYNTAX
	output.position = mul(mul(mul(float4(input.position, 1.0f), gcbGameObjectInfo.mtxWorld), gcbCameraInfo.mtxView), gcbCameraInfo.mtxProjection);
#else
    output.position = mul(mul(mul(float4(input.position, 1.0f), gmtxGameObject), gmtxView), gmtxProjection);
#endif

#ifdef _WITH_BILLBOARD_ANIMATION
    if (input.uv.y < 0.7f)
    {
        float fShift = 0.0f;
        int nResidual = ((int) gfCurrentTime % 4);
        if (nResidual == 1)
            fShift = -gfElapsedTime * 0.5f;
        if (nResidual == 3)
            fShift = +gfElapsedTime * 0.5f;
        input.uv.x += fShift;
    }
#endif
    output.uv = input.uv;

    return (output);
}

float4 PSBillboard(VS_TEXTURED_OUTPUT input) : SV_TARGET
{
//    float4 cColor = gtxtTexture.SampleLevel(gssWrap, input.uv, 0);
////	float4 cColor = gtxtTexture.Sample(gWrapSamplerState, input.uv);
//    if (cColor.a <= 0.3f)
//        discard; //clip(cColor.a - 0.3f);

    float4 cColor = {1.0f, 1.0f, 0.0f, 0.0f };
    
    return (cColor);
}