
/// NOTE: if using Unlit mode:
/// SSAO with depth normals doesn't work (keyword _SCREEN_SPACE_OCCLUSION doesn't seem to make a difference), but SSAO with just depth does
/// for shadows you need to add Boolean Keywords:
/// _MAIN_LIGHT_SHADOWS_CASCADE, Global Multi-Compile
/// _SHADOWS_SOFT, Global Multi-Compile
/// _ADDITIONAL_LIGHT_SHADOWS, Global Multi-Compile


#ifndef DIDIMO_INCLUDED
#define DIDIMO_INCLUDED


#ifndef SHADERGRAPH_PREVIEW 

half getMainShadow(float3 wP)
{
	float4 shadowCoord = TransformWorldToShadowCoord(wP);
	ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
	half4 shadowParams = GetMainLightShadowParams();
	return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
}

#endif


void GetCurrentInstanceID_float(in float2 IDUV, out float res)
{
#if UNITY_ANY_INSTANCING_ENABLED
	res = unity_InstanceID;
#else
	res = ceil(IDUV.x);
#endif
}

void MatrixBranch_half(in bool predicate, in float4x4 matrixA, in float4x4 matrixB, out float4x4 result)
{
	result = predicate ? matrixA : matrixB;
}

void MatrixBranch_float(in bool predicate, in float4x4 matrixA, in float4x4 matrixB, out float4x4 result)
{
	result = predicate ? matrixA : matrixB;
}

void GetCurrentInstanceID_half(in float2 IDUV, out float res)
{
#if UNITY_ANY_INSTANCING_ENABLED
	res = unity_InstanceID;
#else
	res = round(IDUV.x);
#endif
}

void evalDiffuse(in half3 tN, in half3 tD, half sssAdd, in half3 lightColor, inout half3 diffuse, inout half3 psuedoSss, inout half3 transmission)
{
	half lambert = dot(tN, tD);
	//diffuse += lightColor * max(0, lambert);
	psuedoSss += lightColor * clamp(lambert + sssAdd, 0, 1);
	half tLambert = dot(-tN, tD);
	transmission += lightColor * max(0, tLambert * tLambert * tLambert);
}

void PsuedoSSS_float(in half3x3 tS, in float3 wP, in float3 tN, in half4 ssUv, in half3 baseColor, in half3 sssColor, in half sssAdd, in half3 transColor, in half transMap, out half3 outColor)
{
#ifdef SHADERGRAPH_PREVIEW

	outColor = baseColor;

#else

	half3 diffuse = half3(0, 0, 0);
	half3 psuedoSss = half3(0, 0, 0);
	half3 transmission = half3(0, 0, 0);

	Light mainLight = GetMainLight();

	float3 tD = normalize(mul(tS, mainLight.direction));
	half ShadowAtten = getMainShadow(wP);

	evalDiffuse(tN, tD, sssAdd, mainLight.color * mainLight.distanceAttenuation * ShadowAtten, diffuse, psuedoSss, transmission);

	int pixelLightCount = GetAdditionalLightsCount();
	for (int i = 0; i < pixelLightCount; ++i)
	{
		Light light = GetAdditionalLight(i, wP);
		tD = normalize(mul(tS, light.direction));

		evalDiffuse(tN, tD, sssAdd, light.color * light.distanceAttenuation * light.shadowAttenuation, diffuse, psuedoSss, transmission);
	}

	half3 wN = normalize(mul(tN, tS));

	half3 indDiff = SampleSH(wN);
	psuedoSss += indDiff * 0.5 * sssAdd;

	psuedoSss *= sssColor * baseColor;

	half ao = lerp(1, SampleAmbientOcclusion(ssUv.xy), 0.5);
	psuedoSss *= ao;

	const half3 LuminanceVector = { 0.299f, 0.587f, 0.114f };
	half lum = min(dot(diffuse, LuminanceVector), 1);

	half lumSss = min(dot(psuedoSss, LuminanceVector), 1);

	transmission *= transColor * transMap * ao;

	// outColor = lerp(psuedoSss, lumSss, (lum + lumSss) * 0.5);
	outColor = lerp(psuedoSss, lumSss, lum) + transmission;

#endif
}



/*


float GetBlinnPhongIntensity(const in C_Ray ray, const in C_Material mat, const in vec3 vLightDir, const in vec3 vNormal)
{
	vec3 vHalf = normalize(vLightDir - ray.vDir);
	float fNdotH = max(0.0, dot(vHalf, vNormal));

	float shadowDot = max(0.0, dot(vNormal, vLightDir));

	float fSpecPower = exp2(mat.fSmoothness);
	float fSpecIntensity = fSpecPower * mat.fSpecularIntensity;

	fSpecIntensity *=  pow(fNdotH, fSpecPower);
	fSpecIntensity *= blinn_specular_energy_conservation(fSpecPower);
	//stop weird highlights but perhaps messes with fresnel
	#ifdef SHADOWBYDOT
	fSpecIntensity *= shadowDot;
	#endif
	return fSpecIntensity ;
}
*/


void VertexSphereUnion_float(in float3 pos, in float3 sc, in float sr, out float3 opos)
{
	float3 spos = pos - sc;
	float l = length(spos);
	if (l < sr)
	{
		float3 n = spos / l;
		opos = sc + n * sr;
		return;
	}
	opos = pos;
}

void VertexSphereUnion_half(in float3 pos, in float3 sc, in float sr, out float3 opos)
{
	float3 spos = pos - sc;
	float l = length(spos);
	if (l < sr)
	{
		float3 n = spos / l;
		opos = sc + n * sr;
		return;
	}
	opos = pos;
}


float gaussCurve(float x, float a, float b, float c)
{
	float e = 2.71828;
	float x_b = x - b;
	x_b *= x_b;
	float _2c2 = 2.0 * c * c;

	return a * pow(e, -(x_b / _2c2));
}


void Gauss_half(in float4 x, in float a, in float b, in float c, out float4 res)
{
	float4 xb = x - float4(b, b, b, b);
	res = exp(xb);// a* exp((xb * xb) / (2 * c * c));	
}

float innerfunc(in float x, in  float a, in  float b, in  float c)
{
	return pow(x, a + (x + b) * c);
}

float Sigmoid(in float x, in float a, in float b, in float c)
{
	return (1 / 1 + exp(-x * a - c) + b);
}

void Sigmoid_half(in float4 x, in float a, in float b, in float c, out float4 res)
{
	res = float4(Sigmoid(x.x, a, b, c), Sigmoid(x.y, a, b, c), Sigmoid(x.z, a, b, c), Sigmoid(x.w, a, b, c));
}


void PowCurveTwoStep_half(in float4 x, in float a, in float b, in float c, out float4 res)
{
	//+\left(y+a\right)\cdot d
	res = float4(pow(x.x, a + (x.x + b) * c),
		pow(x.y, a + (x.y + b) * c),
		pow(x.z, a + (x.z + b) * c),
		pow(x.w, a + (x.w + b) * c));

	//res = pow(x, b);
}

void CentredScale_half(in float2 uv, in float2 centre, in float2 scale, out float2 result)
{
	result = ((uv - centre) * scale) + centre;
}

float smoothLerp(in float x, in float a, in float b)
{
	float v = x * x * (3.0 - 2.0 * x);
	return a + (b - a) * v;
}

#define TRANSPOSE_MATRIX_CONVERT
#ifdef TRANSPOSE_MATRIX_CONVERT
void convertMat4ToMat3_float(in float4x4 mat, out float3x3 outmat)
{
	outmat = float3x3(mat[0][0], mat[0][1], mat[0][2],
					  mat[1][0], mat[1][1], mat[1][2],
					  mat[2][0], mat[2][1], mat[2][2]);
}

void convertMat4ToMat3_half(half3x3 mat, out half3x3 outmat)
{
	outmat = half3x3 (mat[0][0], mat[0][1], mat[0][2],
					mat[1][0], mat[1][1], mat[1][2],
					mat[2][0], mat[2][1], mat[2][2]);
}
#else
void convertMat4ToMat3_float(in float4x4 mat, out float3x3 outmat)
{
	outmat = float3x3(mat[0][0], mat[1][0], mat[2][0],
					  mat[0][1], mat[1][1], mat[2][1],
					  mat[0][2], mat[1][2], mat[2][2]);
}

void convertMat4ToMat3_half(half3x3 mat, out half3x3 outmat)
{
	outmat = half3x3 (mat[0][0], mat[1][0], mat[2][0],
		mat[0][1], mat[1][1], mat[2][1],
		mat[0][2], mat[1][2], mat[2][2]);
}
#endif

//takes input from 0..1 and reforms it in to an envelope between x = 0..t[0]..t[1]..1 with output values in range 0..p[0]..p[1]..1
//TODO: replace this curve with a texture lookup perhaps
float linearStepedLerp(in float x, in float3 t, in float3 p)
{
	if (x < t[0])
	{
		float d = x / t[0];
		return (d * (p[0]));
	}
	else if (x < t[1])
	{
		float d = (x - t[0]) / (t[1] - t[0]);
		return lerp(p[0], p[1], d);
	}
	else if (x < t[2])
	{
		float d = (x - t[1]) / (t[2] - t[1]);
		return lerp(p[1], p[2], d);
	}
	else if (x < 1.0)
	{
		float d = (x - t[2]) / (1.0 - t[2]);
		return lerp(p[2], 1.0, d);
	}
	else
		return x;
}

/*
def smoothFuncPlot(x, v):
	t = [v[0],v[2]]
	p = [v[1],v[3]]

	if x < t[0]:
		d = x / t[0]
		return smoothLerp(d, 0.0, p[0])
	elif x < t[1]:
		d = (x - t[0]) / (t[1]-t[0])
		return smoothLerp(d, p[0], p[1])
	elif x < 1.0:
		d = (x - t[1]) / (1.0-t[1])
		return smoothLerp(d, p[1], 1.0)
	else:
		return 1.0
*/

void EyeBaseUVAdjust_float(in float2 uv, in float3 t, float3 p, out float2 res2)
{
	//+\left(y+a\right)\cdot d
	float2 abvec = uv - float2(0.5, 0.5);
	float dist = length(abvec);
	abvec /= dist;
	//float fval = gaussCurve(1.0 - dist, a, b, c);
	float fval = linearStepedLerp(dist, t, p);

	res2 = float2(0.5, 0.5) + abvec * fval;
	//res2 = uv;
}




void Quadratic_float(in float4 x, in float a, in float b, in float c, out float4 res)
{
	res = (a * x * x) + (b * x) + c;
}

float _DidimoEyeDarken;
float _DidimoEyeRefraction;

void PrepareEyeUv_float(in float3 tV, in float2 uv, in float eyeRefraction, out float2 refrUv, out float refrHeight, out float3 concaveNormal) {
	const half3 ctN = half3(0, 0, 1);

#ifdef SHADERGRAPH_PREVIEW

	concaveNormal = ctN;
	refrUv = uv;
	refrHeight = 0;

#else

	const float radius = 0.12;
	const half2 center = half2(0.5, 0.5);

	half3 diffuse = half3(0, 0, 0);
	half3 irisSpec = half3(0, 0, 0);

	float irisMask = 0;
	refrHeight = 0;

	concaveNormal = ctN;

	half fromCenterX = uv.x - center.x;
	fromCenterX *= fromCenterX;

	half fromCenterY = uv.y - center.y;
	fromCenterY *= fromCenterY;

	if (fromCenterX + fromCenterY < radius * radius) /// inside circle test
	{
		refrHeight = 1 - (length(uv - center) / radius);
		irisMask = 1;

		half2 newXy = center - uv;

		half3 _concaveNormal = normalize(half3(newXy / radius, 0.5));
		concaveNormal = normalize(lerp(concaveNormal, _concaveNormal, refrHeight * 15));
	}

	tV = normalize(tV);

	// refrHeight *= refrHeight;

	half2 offset = tV.xy * tV.z * refrHeight * eyeRefraction * 0.4;

	refrUv = uv - offset;
#endif

}

float2 RotateZ(const in float2 vPos, const in float fAngle)
{
	const float DEG_TO_RAD = 0.01745329251;
	const float fAngleRad = fAngle * DEG_TO_RAD;
	float s = sin(fAngleRad);
	float c = cos(fAngleRad);

	return float2(c * vPos.x + s * vPos.y, -s * vPos.x + c * vPos.y);
}

float distanceToElipse(in float2 pt, in float2 c, in float2 r, in float rot)
{
	float2 rpt = RotateZ(pt - c, rot);
	return sqrt((rpt.x * rpt.x) / (r.x * r.x) + (rpt.y * rpt.y) / (r.y * r.y));
}

/*
void DeskinMatrix_half(in half4x4 skinMatrix, in int matrixIdx, out half4x4 invMatrix)
{
	invMatrix = _SkinMatrices[matrixIdx];
	invMatrix = transpose(invMatrix);
}*/


void EyeAOCalculations_float(in float2 uv,
	in float2 centre,
	in float2 radii,
	in float rotation,
	in float radPow,
	out float AO)
{
	AO = pow(clamp((distanceToElipse(uv, centre, radii, rotation)), 0.0, 1.0), radPow);
}


void EyeAOBezierCalculations_float(in float4x4 parameters,
	in float radPow,
	out float AO)
{

	AO = 1.0;
	//AO = pow(clamp((distanceToElipse(uv, centre, radii, rotation)), 0.0, 1.0), radPow);
}


/*
#ifdef EYE_SHADOW_COLOUR

							in float3 eyeShadowColor,
#endif
*/


half evalBlinn(in half3 lightDir, in half3 normal, in half3 viewVec, in float Shadow, in float shininess = 5)
{
	half3 halfVec = normalize(lightDir + viewVec); // n.b. it's '+' in unity due to handiness
	//float dotNH = dot(normal, halfVec);
	float dotNH = max(0, dot(normal, halfVec));
	half specTerm = pow(dotNH, shininess);
	specTerm *= max(0, dot(lightDir, normal));
	return specTerm * Shadow;
}


float3 SampleNormal(in float2 uv, in half3x3 tS, in SamplerState ss, in Texture2D normalMapSmapler, in float normalMapIntensity)
{
	float3 normal_map_sample = UnpackNormal(normalMapSmapler.Sample(ss, uv));
	half3 normal_uv = normal_map_sample;
	half3 wsnormal = mul(normal_uv, tS);
	wsnormal = lerp(tS[2], wsnormal, normalMapIntensity);
	return normalize(wsnormal);
	//return normal_uv;
}


/*
radianceOcclusion = min(1.0, radianceOcclusion + scatter);
	albedo = mix(albedo, m_scatter_colour.rgb, scatterColourFactor);
*/

float ScatterDiffuse(in float NdotL, float scatter)
{
	//m_scatter_colour.rgb 
	return (1.0 - pow(NdotL, 0.5)) * scatter;
}

void CubeUVMap_float	(in float3 position, in float3 normal, out float2 UVCoord)
{
	float3 absnorm = abs(normal);

	if (absnorm.y < 0.5)
	{
		UVCoord = float2(absnorm.z <= 0.5 ? position.z : position.x,
			position.y);
	}
	else
	{
		UVCoord = float2(position.x,
			absnorm.z <= 0.5 ? position.z : position.y);
		
	}	
}

void Eye_float(in half3x3 tS,
	in float3 wV,
	in float3 wP,
	in float2 uv,
	in float2 distortUV,
	in half4 ssUv,
	in float refrHeight,
	in half3 baseColor,
	in Texture2D corneaNormalMap,
	in float corneaNormalStrength,
	in Texture2D irisNormalMap,
	in float irisNormalStrength,
	in float3 concaveNormal,
	in SamplerState ss,
	in float EyeShininess,
	in float SpecularIntensity,
	in float IrisShininess,
	in float IrisSpecularIntensity,
	in float3 sphericalWorldNormal,
	in float eyeLidao,
	in float aoStrength,
	in float scattering,
	in float envContribScale,
	out half3 outColor)
{
	const half3 ctN = half3(0, 0, 1);
#ifdef SHADERGRAPH_PREVIEW

	outColor = baseColor;

#else

	half3 itN = SampleNormal(distortUV, tS, ss, irisNormalMap, irisNormalStrength);
	half3 tN = SampleNormal(uv, tS, ss, corneaNormalMap, corneaNormalStrength);

	Light mainLight = GetMainLight();
	half ShadowAtten = getMainShadow(wP);
	wV = normalize(wV);

	float3 tV = mul(tS, wV);
	float3 tD = normalize(mul(tS, mainLight.direction));
	float3 wD = mainLight.direction;
	float highlightShadow = eyeLidao;

	float NdotL = dot(itN, tD);

	NdotL = (NdotL + scattering) / (1.0 + scattering);

	float3 diffuse = max(0.01, NdotL) * mainLight.color * mainLight.distanceAttenuation * ShadowAtten;

	float3 irisSpec = evalBlinn(tD, itN, tV, highlightShadow, IrisShininess) * mainLight.color * mainLight.distanceAttenuation * ShadowAtten;
	float3 corneaSpec = evalBlinn(wD, tN, wV, highlightShadow, EyeShininess) * mainLight.color * mainLight.distanceAttenuation * ShadowAtten;

	int pixelLightCount = GetAdditionalLightsCount();
	for (int i = 0; i < pixelLightCount; ++i)
	{
		Light light = GetAdditionalLight(i, wP);
		tD = normalize(mul(tS, light.direction));
		float NdotL = dot(itN, tD);
		NdotL = -(NdotL + scattering) / (1.0 + scattering);
		diffuse += max(0.01, NdotL) * light.color * light.distanceAttenuation * light.shadowAttenuation;
		irisSpec += evalBlinn(tD, itN, tV, highlightShadow, IrisShininess) * light.color * light.distanceAttenuation * light.shadowAttenuation;
		corneaSpec += evalBlinn(light.direction, tN, wV, highlightShadow, EyeShininess) * light.color * light.distanceAttenuation * light.shadowAttenuation;
	}

	irisSpec *= refrHeight * 4;

	half3 wN = normalize(mul(itN, tS));

	diffuse += SampleSH(wN);
	baseColor *= 1 - _DidimoEyeDarken;
	diffuse *= baseColor;

	/// temper iris by the base color luminance
	const half3 LuminanceVector = { 0.299f, 0.587f, 0.114f };
	half invLum = 1 - dot(baseColor, LuminanceVector);
	irisSpec *= invLum;
	float3 totalSpec = max(float3(0.0, 0.0, 0.0), (corneaSpec * SpecularIntensity) + (irisSpec * IrisSpecularIntensity)); //

	outColor = diffuse + totalSpec;

	half ao = eyeLidao;// SampleAmbientOcclusion(ssUv.xy) *

	outColor = lerp(outColor, outColor * ao, aoStrength);

	/// reflection
	half3 reflDir = normalize(-reflect(tV, tN));
	reflDir = normalize(mul(reflDir, tS));
	half3 indirectSpec = GlossyEnvironmentReflection(reflDir, 0, 1) * ao * envContribScale;
	half f = 1.0 - abs(dot(ctN, tV));
	f *= f * f;
	half fresnel = lerp(1, f, 0.995);
	outColor += indirectSpec * fresnel;
#ifdef TEST_FRESNEL
	outColor = float3(f, f, f);
#endif
#endif
}

//#define TEST_AS_PHONG_BLINN
half evalKajiyaKay(half3 normal, half3 tangent, half3 halfVec, half roughness, half shadow)
{
	half  dotTH = dot(tangent, halfVec);
	
	half  dirAtten = smoothstep(-1.0, 0.0, dotTH);
#ifdef TEST_AS_PHONG_BLINN
	return max(0, pow(dotNH, roughness));
#else
	half  sinTH = sqrt(1 - dotTH * dotTH);

	return max(0, dirAtten * pow(sinTH, roughness)) * shadow;
#endif
}

float3 decodeNormal(float3 v)
{
	return 2.0 * (v - 0.5);
}

float3 decodeNormal2(float3 v)
{
	return normalize(2.0 * (v - 0.5));
}


/*

void evalDiffuse(in half3 tN, in half3 tD, half sssAdd, in half3 lightColor, inout half3 diffuse, inout half3 psuedoSss, inout half3 transmission)
{
	half lambert = dot(tN, tD);
	//diffuse += lightColor * max(0, lambert);
	psuedoSss += lightColor * clamp(lambert + sssAdd, 0, 1);
	half tLambert = dot(-tN, tD);   
	transmission += lightColor * max(0, tLambert * tLambert * tLambert);
}
*/


//#define DOUBLE_SIDED_LIGHTING
float doLightDot(in float3 normal, in float3 lightdirection)
{
	float dp = dot(normal, lightdirection);

#ifdef DOUBLE_SIDED_LIGHTING  
	return  abs(dp);
#else
	return max(0.0, dp);
#endif        
}

float3 calculateDiffuseColour(in float3 normal, in float scatter, float3 lightdirection, in float3 lightcol)
{
	float inv_scatter = max(0.0, 1.0 - scatter);
	float dp = clamp((doLightDot(normal, lightdirection) + scatter) * inv_scatter, 0.0, 1.0);

	float3 diffcol = lightcol;
	return diffcol * dp;
}

#define USE_FLOW_MAP
#define WORLD_SPACE_FLOW_MAP
void evalHairBrdf( in half3 lTd, in half3 lColor, in half3 tN, in half3 tT, in half3 tEtoV, 
				   in half roughness1, in half roughness2, in half specShift, in half specShift2, in half scatter,
				   inout half3 diffuse, inout half3 spec1, inout half3 spec2)
{	
	float LdotN = dot(lTd, tN);
	diffuse += calculateDiffuseColour(tN, scatter, lTd, lColor);
	//max(0, LdotN)* lColor;
	float shadow = max(0, LdotN );
	
	half3 halfVec = normalize(lTd + tEtoV); 
	float specShiftAddition = 0.0;

	half3 T1 = normalize(tT - (tN * (specShift + specShiftAddition )));
	half3 T2 = normalize(tT - (tN * (specShift2+ specShiftAddition )));
	spec1 += max(0, evalKajiyaKay(tN, T1, halfVec, roughness1, shadow ) * lColor);
	spec2 += max(0, evalKajiyaKay(tN, T2, halfVec, roughness2, shadow ) * lColor);
}

//#define USE_dFD
void calcSDFAlpha_half(in float2 uv, in float dist, in float cutoff, in float smoothing, in float antialiasfactor, in float gamma, out float res)
{
#ifdef USE_dFD
	float2 dpdx = ddx(uv);
	float2 dpdy = ddy(uv);
	float m = length(float2(length(dpdx), length(dpdy)));
#else
	float m = 0.4;

#endif
	antialiasfactor = 1.0;
	float smoothval = max(smoothing, pow(abs(m) * antialiasfactor, gamma));

	//float distanceChange = m_derivative * 0.5; //fwidth(dist)
	float antialiasedCutoff = smoothstep(cutoff - smoothval, cutoff + smoothval, dist);

	res = antialiasedCutoff;
}

void calcSDFAlpha_float(in float2 uv, in float dist, in float cutoff, in float smoothing, in float antialiasfactor, in float gamma, out float res)
{
#ifdef USE_dFD
	float2 dpdx = ddx(uv);
	float2 dpdy = ddy(uv);
	float m = length(float2(length(dpdx), length(dpdy)));
#else
	float m = 0.4;

#endif

	float smoothval = max(smoothing, pow(abs(m) * antialiasfactor, gamma));

	//float distanceChange = m_derivative * 0.5; //fwidth(dist)
	float antialiasedCutoff = smoothstep(cutoff - smoothval, cutoff + smoothval, dist);
	res = antialiasedCutoff;	
}

void MatrixRotateXYZ_float(in float3 o, out float4x4 m)
{
	float crx = cos(o.x);
	float srx = sin(o.x);
	float cry = cos(o.y);
	float sry = sin(o.y);
	float crz = cos(o.z);
	float srz = sin(o.z);
	//this may have 'flipped' y rotation - need to establish 'cannon' here. 
	//RotateY and SetRotateY are flipped respective to each other 	
	m[0][0] = crz * cry;    m[0][1] = crz * -sry * -srx + srz * crx;        m[0][2] = crz * -sry * crx + srz * srx;          m[0][3] = 0;
	m[1][0] = -srz * cry;   m[1][1] = -srz * -sry * -srx + crz * crx;       m[1][2] = -srz * -sry * crx + crz * srx;         m[1][3] = 0;
	m[2][0] = sry;          m[2][1] = cry * -srx;                           m[2][2] = cry * crx;                             m[2][3] = 0;
	m[3][0] = 0;            m[3][1] = 0;                                    m[3][2] = 0;                                     m[3][3] = 1;	
}

void MatrixRotateXYZ_half(in float3 o, out half4x4 m)
{
	float crx = cos(o.x);
	float srx = sin(o.x);
	float cry = cos(o.y);
	float sry = sin(o.y);
	float crz = cos(o.z);
	float srz = sin(o.z);
	//this may have 'flipped' y rotation - need to establish 'cannon' here. 
	//RotateY and SetRotateY are flipped respective to each other 	
	m[0][0] = crz * cry;    m[0][1] = crz * -sry * -srx + srz * crx;        m[0][2] = crz * -sry * crx + srz * srx;          m[0][3] = 0;
	m[1][0] = -srz * cry;   m[1][1] = -srz * -sry * -srx + crz * crx;       m[1][2] = -srz * -sry * crx + crz * srx;         m[1][3] = 0;
	m[2][0] = sry;          m[2][1] = cry * -srx;                           m[2][2] = cry * crx;                             m[2][3] = 0;
	m[3][0] = 0;            m[3][1] = 0;                                    m[3][2] = 0;                                     m[3][3] = 1;
}


void Hair_float( in half3x3 tS, in float3 wP, in float3 tP, in half3 tN, in half3 tT, in float3 tV, in float2 uv, 
				 in half3 baseColor, in half specExp1, in half specExp2, in half envRough, in half envSpecMul, 
				 in half specShift, in half specShift2, in half flowMultiply, in half specMultiply, in half rootTipPos, in float AO, in float SSSfactor, out half3 outColor)
{
	half3 wN = normalize(mul(tN, tS));
	half3 wT = normalize(mul(tT, tS));
	//tT = -cross(tN, tT);
	
#ifdef SHADERGRAPH_PREVIEW

	outColor = baseColor;

#else
	float3 tEtoV = normalize(tV - tP);

	baseColor = min(baseColor, half3(1.0, 1.0, 1.0));
	half3 diffuse = half3(0, 0, 0);
	half3 spec1 = half3(0, 0, 0);
	half3 spec2 = half3(0, 0, 0);

	Light mainLight = GetMainLight();
	half ShadowAtten = getMainShadow(wP);

	half3 tD = normalize(mul(tS, mainLight.direction)); //light direction in tangent space
	half rough1 = specExp1;
	half rough2 = specExp2;

	evalHairBrdf(tD, mainLight.color * mainLight.distanceAttenuation * ShadowAtten, tN, tT, tEtoV, rough1, rough2, specShift , specShift2, SSSfactor, diffuse, spec1, spec2);

	int pixelLightCount = GetAdditionalLightsCount();
	for (int i = 0; i < pixelLightCount; ++i)
	{
		Light light = GetAdditionalLight(i, wP);
		tD = normalize(mul(tS, light.direction));
		evalHairBrdf(tD, light.color * light.distanceAttenuation * light.shadowAttenuation, tN, tT, tEtoV, rough1, rough2, specShift, specShift2, SSSfactor, diffuse, spec1, spec2);
	}

	half3 indDiff = SampleSH(wN);
	diffuse += indDiff * 0.7;
	diffuse *= baseColor;

	//environmental reflection - N.B. non anisotropic!
#define HAIR_ENV_SPEC
#ifdef HAIR_ENV_SPEC


	const half3 ctN = half3(0, 0, 1);
	float3 t1 = normalize(wT * specShift);

	half3 reflDir = normalize(-reflect(tV, normalize(ctN + t1 * 0.05f) ));//
	//half3 reflDir = normalize(-reflect(tV, ctN));//
	reflDir = normalize(mul(reflDir, tS));
	half3 indirectSpec = GlossyEnvironmentReflection(reflDir,  envRough, 1.0) * envSpecMul;//wP.xyz,
	half f = clamp(1.0 - abs(dot(ctN, tV)), 0.0, 1.0);
	f *= f * f;
	half fresnel = lerp(1, f, 0.995);
 
	spec1 += indirectSpec * fresnel;

#endif

	const half3 LuminanceVector = { 0.299f, 0.587f, 0.114f };
	half lum = min(dot(baseColor , LuminanceVector), 1);
	half3 lumCol = half3(lum, lum, lum);

	spec1 *= lumCol;
	spec2 *= baseColor;

	half rootDampen = min(lerp(0, 3, uv.y), 1);

#ifdef TEST_NORMALS
	outColor = lerp(perturbedFlow, diffuse + (spec1 + spec2) * specMultiply, 0.1);
#else
	outColor = (diffuse + (spec1 + spec2) * specMultiply) * AO;
#endif
#endif

	

}

void Background_float(in half3x3 tS, in float3 wP, in float3 tN, in half3 baseColor, in half3 globalIllum, out half3 outColor)
{
#ifdef SHADERGRAPH_PREVIEW

	outColor = baseColor;

#else

	half3 diffuse = half3(0, 0, 0);

	Light mainLight = GetMainLight();

	float3 tD = normalize(mul(tS, mainLight.direction));

	// half ShadowAtten = getMainShadow(wP);

	diffuse = max(0, dot(tN, tD)) * mainLight.color * mainLight.distanceAttenuation;// * ShadowAtten;

	int pixelLightCount = GetAdditionalLightsCount();
	for (int i = 0; i < pixelLightCount; ++i)
	{
		Light light = GetAdditionalLight(i, wP);
		tD = normalize(mul(tS, light.direction));

		diffuse += max(0, dot(tN, tD)) * light.color * light.distanceAttenuation;// * light.shadowAttenuation;
	}

	half3 wN = normalize(mul(tN, tS));

	diffuse += globalIllum;

	diffuse *= baseColor;

	outColor = diffuse;

#endif
}

void Ssao_half(in half4 ssUv, out half outAo)
{
#ifdef SHADERGRAPH_PREVIEW
	outAo = 1;
#else
	outAo = SampleAmbientOcclusion(ssUv.xy);
#endif
}

#endif // DIDIMO_INCLUDED