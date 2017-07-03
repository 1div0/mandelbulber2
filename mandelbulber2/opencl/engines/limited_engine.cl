/**
 * Mandelbulber v2, a 3D fractal generator       ,=#MKNmMMKmmßMNWy,
 *                                             ,B" ]L,,p%%%,,,§;, "K
 * Copyright (C) 2017 Mandelbulber Team        §R-==%w["'~5]m%=L.=~5N
 *                                        ,=mm=§M ]=4 yJKA"/-Nsaj  "Bw,==,,
 * This file is part of Mandelbulber.    §R.r= jw",M  Km .mM  FW ",§=ß., ,TN
 *                                     ,4R =%["w[N=7]J '"5=],""]]M,w,-; T=]M
 * Mandelbulber is free software:     §R.ß~-Q/M=,=5"v"]=Qf,'§"M= =,M.§ Rz]M"Kw
 * you can redistribute it and/or     §w "xDY.J ' -"m=====WeC=\ ""%""y=%"]"" §
 * modify it under the terms of the    "§M=M =D=4"N #"%==A%p M§ M6  R' #"=~.4M
 * GNU General Public License as        §W =, ][T"]C  §  § '§ e===~ U  !§[Z ]N
 * published by the                    4M",,Jm=,"=e~  §  §  j]]""N  BmM"py=ßM
 * Free Software Foundation,          ]§ T,M=& 'YmMMpM9MMM%=w=,,=MT]M m§;'§,
 * either version 3 of the License,    TWw [.j"5=~N[=§%=%W,T ]R,"=="Y[LFT ]N
 * or (at your option)                   TW=,-#"%=;[  =Q:["V""  ],,M.m == ]N
 * any later version.                      J§"mr"] ,=,," =="""J]= M"M"]==ß"
 *                                          §= "=C=4 §"eM "=B:m|4"]#F,§~
 * Mandelbulber is distributed in            "9w=,,]w em%wJ '"~" ,=,,ß"
 * the hope that it will be useful,                 . "K=  ,=RMMMßM"""
 * but WITHOUT ANY WARRANTY;                            .'''
 * without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with Mandelbulber. If not, see <http://www.gnu.org/licenses/>.
 *
 * ###########################################################################
 *
 * Authors: Krzysztof Marczak (buddhi1980@gmail.com)
 *
 * Fast kernel for rendering opencl with missing effects
 */

int GetInteger(int byte, __global char *array)
{
	__global int *intPointer = (__global int *)&array[byte];
	return *intPointer;
}

//------------------ MAIN RENDER FUNCTION --------------------
kernel void fractal3D(
	__global sClPixel *out, __global char *inBuff, __constant sClInConstants *consts)
{
	// get actual pixel
	const int id = get_global_id(0);
	const int cl_offset = get_global_offset(0);
	const int imageX = id % consts->params.imageWidth;
	const int imageYTemp = id / consts->params.imageWidth;
	const int buffIndex = (id - cl_offset);

	const int imageY = clamp(imageYTemp, 0, consts->params.imageHeight - 1);

	float2 screenPoint = (float2){convert_float(imageX), convert_float(imageY)};
	float width = convert_float(consts->params.imageWidth);
	float height = convert_float(consts->params.imageHeight);
	float resolution = 1.0f / height;

	//-------- decode data file ----------------
	// main offset for materials
	int materialsMainOffset = GetInteger(0, inBuff);
	int AOVectorsMainOffset = GetInteger(1 * sizeof(int), inBuff);
	int lightsMainOffset = GetInteger(2 * sizeof(int), inBuff);

	//--- main material

	// number of materials
	int numberOfMaterials = GetInteger(materialsMainOffset, inBuff);

	// materials 0 offset:
	const int materialAddressOffset = materialsMainOffset + 1 * sizeof(int);
	int material0Offset = GetInteger(materialAddressOffset, inBuff);

	// material header
	int materialClOffset = GetInteger(material0Offset, inBuff);
	int paletteItemsOffset = GetInteger(material0Offset + sizeof(int), inBuff);
	int paletteSize = GetInteger(material0Offset + sizeof(int) * 2, inBuff);
	int paletteLength = GetInteger(material0Offset + sizeof(int) * 3, inBuff);

	// material data
	__global sMaterialCl *material = (__global sMaterialCl *)&inBuff[materialClOffset];

	// palette data
	__global float4 *palette = (__global float4 *)&inBuff[paletteItemsOffset];

	//--- AO vectors

	// AO vectors count
	int AOVectorsCount = GetInteger(AOVectorsMainOffset, inBuff);
	int AOVectorsOffset = GetInteger(AOVectorsMainOffset + 1 * sizeof(int), inBuff);

	__global sVectorsAroundCl *__attribute__((aligned(16))) AOVectors =
		(__global sVectorsAroundCl *)&inBuff[AOVectorsOffset];

	//--- Lights

	// AO vectors count
	int numberOfLights = GetInteger(lightsMainOffset, inBuff);
	int lightssOffset = GetInteger(lightsMainOffset + 1 * sizeof(int), inBuff);

	__global sLightCl *__attribute__((aligned(16))) lights =
		(__global sLightCl *)&inBuff[lightssOffset];

	//--------- end of data file ----------------------------------

	// auxiliary vectors
	const float3 one = (float3){1.0f, 0.0f, 0.0f};
	const float3 ones = 1.0f;

	// main rotation matrix
	matrix33 rot;
	rot.m1 = (float3){1.0f, 0.0f, 0.0f};
	rot.m2 = (float3){0.0f, 1.0f, 0.0f};
	rot.m3 = (float3){0.0f, 0.0f, 1.0f};

	rot = RotateZ(rot, consts->params.viewAngle.x);
	rot = RotateX(rot, consts->params.viewAngle.y);
	rot = RotateY(rot, consts->params.viewAngle.z);

	// starting point for ray-marching
	float3 start = consts->params.camera;

	// view vector
	float aspectRatio = width / height;
	float x2, z2;
	x2 = (screenPoint.x / width - 0.5f) * aspectRatio;
	z2 = -(screenPoint.y / height - 0.5f);
	float3 viewVector = (float3){x2 * consts->params.fov, 1.0f, z2 * consts->params.fov};
	float3 viewVectorNotRotated = viewVector;
	viewVector = Matrix33MulFloat3(rot, viewVector);

	bool found = false;
	int count;

	float3 point;
	float scan, distThresh, distance;

	scan = 1e-10f;

	sClCalcParams calcParam;
	calcParam.N = consts->params.N;
	distThresh = 1e-6f;

	formulaOut outF;
	float step = 0.0f;

	// ray-marching
	for (count = 0; count < MAX_RAYMARCHING && scan < consts->params.viewDistanceMax; count++)
	{
		point = start + viewVector * scan;
		distThresh = length(point - consts->params.camera) * resolution * consts->params.fov;
		distThresh = max(1e-6, distThresh);
		calcParam.distThresh = distThresh;
		calcParam.detailSize = distThresh;
		outF = CalculateDistance(consts, point, &calcParam);
		distance = outF.distance;

		if (distance < distThresh * 0.95f)
		{
			found = true;
			break;
		}

		step = (distance - 0.5f * distThresh) * consts->params.DEFactor;
		scan += step / length(viewVector);
	}

	point = start + viewVector * scan;

	// final binary searching
	if (found)
	{
		step *= 0.5f;
		for (int i = 0; i < 5; i++)
		{
			if (distance < distThresh && distance > distThresh * 0.95f)
			{
				break;
			}
			else
			{
				if (distance > distThresh)
				{
					point += viewVector * step;
				}
				else if (distance < distThresh * 0.95f)
				{
					point -= viewVector * step;
				}
			}
			outF = CalculateDistance(consts, point, &calcParam);
			distance = outF.distance;
			step *= 0.5f;
		}
	}

	// shaders

	float3 color;

	float lightAlpha = consts->params.mainLightAlpha / 180.0f * M_PI_F;
	float lightBeta = consts->params.mainLightBeta / 180.0f * M_PI_F;
	float3 lightVector = (float3){cos(lightAlpha - 0.5f * M_PI_F) * cos(lightBeta),
		sin(lightAlpha - 0.5f * M_PI_F) * cos(lightBeta), sin(lightBeta)};

	if (consts->params.mainLightPositionAsRelative) lightVector = Matrix33MulFloat3(rot, lightVector);

	distThresh = length(point - consts->params.camera) * resolution * consts->params.fov;
	distThresh = max(1e-6, distThresh);

	sShaderInputDataCl shaderInputData;
	shaderInputData.point = point;
	shaderInputData.viewVector = viewVector;
	shaderInputData.viewVectorNotRotated = viewVectorNotRotated;
	shaderInputData.lightVect = lightVector;
	shaderInputData.distThresh = distThresh;
	shaderInputData.lastDist = distance;
	shaderInputData.delta = calcParam.detailSize;
	shaderInputData.depth = scan;
	shaderInputData.invertMode = false;
	shaderInputData.material = material;
	shaderInputData.palette = palette;
	shaderInputData.paletteSize = paletteLength;
	shaderInputData.AOVectors = AOVectors;
	shaderInputData.AOVectorsCount = AOVectorsCount;
	shaderInputData.lights = lights;
	shaderInputData.numberOfLights = numberOfLights;
	shaderInputData.stepCount = count;

	float3 surfaceColor = 0.0f;
	float3 specular = 0.0f;

	if (found)
	{
		color = ObjectShader(consts, &shaderInputData, &calcParam, &surfaceColor, &specular);
	}
	else
	{
		color = BackgroundShader(consts, &shaderInputData);
		scan = 1e20;
	}

	float4 color4 = (float4){color.s0, color.s1, color.s2, 0.0f};
	float opacityOut;
	color4 = VolumetricShader(consts, &shaderInputData, &calcParam, color4, &opacityOut);

	sClPixel pixel;

	pixel.R = color4.s0;
	pixel.G = color4.s1;
	pixel.B = color4.s2;
	pixel.zBuffer = scan;
	pixel.colR = surfaceColor.s0 * 256.0f;
	pixel.colG = surfaceColor.s1 * 256.0f;
	pixel.colB = surfaceColor.s2 * 256.0f;
	pixel.opacity = opacityOut * 65535;
	pixel.alpha = 65535;

	out[buffIndex] = pixel;
}
