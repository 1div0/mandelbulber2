/**
 * Mandelbulber v2, a 3D fractal generator       ,=#MKNmMMKmmßMNWy,
 *                                             ,B" ]L,,p%%%,,,§;, "K
 * Copyright (C) 2018 Mandelbulber Team        §R-==%w["'~5]m%=L.=~5N
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
 * calculation of distance to primitive objects for opencl
 */

#ifdef USE_PRIMITIVES
float PrimitivePlane(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	float dist = point.z;
	return primitive->data.plane.empty ? fabs(dist) : dist;
}

float PrimitiveBox(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	point = modRepeat(point, primitive->data.box.repeat);

	if (primitive->data.box.empty)
	{
		float boxDist = -1e6f;
		boxDist = max(fabs(point.x) - primitive->object.size.x * 0.5f, boxDist);
		boxDist = max(fabs(point.y) - primitive->object.size.y * 0.5f, boxDist);
		boxDist = max(fabs(point.z) - primitive->object.size.z * 0.5f, boxDist);
		return fabs(boxDist);
	}
	else
	{
		float3 boxTemp;
		boxTemp.x = max(fabs(point.x) - primitive->object.size.x * 0.5f, 0.0f);
		boxTemp.y = max(fabs(point.y) - primitive->object.size.y * 0.5f, 0.0f);
		boxTemp.z = max(fabs(point.z) - primitive->object.size.z * 0.5f, 0.0f);
		return length(boxTemp) - primitive->data.box.rounding;
	}
}

float PrimitiveSphere(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	point = modRepeat(point, primitive->data.sphere.repeat);
	float dist = length(point) - primitive->data.sphere.radius;
	return primitive->data.sphere.empty ? fabs(dist) : dist;
}

float PrimitiveRectangle(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	float3 boxTemp;
	boxTemp.x = max(fabs(point.x) - primitive->data.rectangle.width * 0.5f, 0.0f);
	boxTemp.y = max(fabs(point.y) - primitive->data.rectangle.height * 0.5f, 0.0f);
	boxTemp.z = fabs(point.z);
	return length(boxTemp);
}

float PrimitiveCylinder(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	point = modRepeat(point, primitive->data.cylinder.repeat);
	float2 cylTemp = (float2){point.x, point.y};
	float dist = length(cylTemp) - primitive->data.cylinder.radius;
	if (!primitive->data.cylinder.caps) dist = fabs(dist);
	dist = max(fabs(point.z) - primitive->data.cylinder.height * 0.5f, dist);
	return primitive->data.cylinder.empty ? fabs(dist) : dist;
}

float PrimitiveCircle(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	float2 circleTemp = (float2){point.x, point.y};
	float distTemp = length(circleTemp) - primitive->data.circle.radius;
	distTemp = max(fabs(point.z), distTemp);
	return distTemp;
}

float PrimitiveCone(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	point = modRepeat(point, primitive->data.cone.repeat);
	point.z -= primitive->data.cone.height;
	float q = sqrt(point.x * point.x + point.y * point.y);
	float2 vect = (float2){q, point.z};
	float dist = dot(primitive->data.cone.wallNormal, vect);
	if (!primitive->data.cone.caps) dist = fabs(dist);
	dist = max(-point.z - primitive->data.cone.height, dist);
	return primitive->data.cone.empty ? fabs(dist) : dist;
}

float PrimitiveWater(__global sPrimitiveCl *primitive, float3 _point, float distanceFromAnother)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);

	float length = primitive->data.water.length;
	if (primitive->data.water.waveFromObjectsEnable)
	{
		point.x += length * 20.0f * exp(-distanceFromAnother / length / 5.0f)
							 * primitive->data.water.waveFromObjectsRelativeAmplitude;
	}

	float amplitude = length * primitive->data.water.relativeAmplitude;
	float objectWave = 0.0f;

	float planeDistance = point.z;
	if (planeDistance < amplitude * 10.0f)
	{
		float phase = primitive->data.water.animSpeed * primitive->data.water.animFrame * 0.f;

		if (primitive->data.water.waveFromObjectsEnable)
		{
			objectWave = sin(distanceFromAnother / length * 5.0f - phase * 2.0f)
									 * exp(-distanceFromAnother / length / 5.0f)
									 * primitive->data.water.waveFromObjectsRelativeAmplitude;
		}

		float k = 0.23f;
		float waveXTemp;
		float waveYTemp;
		float waveX = objectWave;
		float waveY = -objectWave;
		float p = 1.0f;
		float p2 = 0.05f;
		for (int i = 1; i <= primitive->data.water.iterations; i++)
		{
			float p3 = p * p2;
			float shift = phase / (i / 3.0f + 1.0f);
			waveXTemp =
				sin(i + 0.4f * (waveX)*p3 + sin(k * point.y / length * p3) + point.x / length * p3 + shift)
				/ p;
			waveYTemp = cos(i + 0.4f * (waveY)*p3 + sin(point.x / length * p3) + k * point.y / length * p3
											+ shift * 0.23f)
									/ p;
			waveX += waveXTemp;
			waveY += waveYTemp;
			p2 = p2 + (1.0f - p2) * 0.7f;
			p *= 1.872f;
		}

		planeDistance += (waveX + waveY) * amplitude;
	}
	return primitive->data.water.empty ? fabs(planeDistance) : planeDistance;
}

float PrimitiveTorus(__global sPrimitiveCl *primitive, float3 _point)
{
	float3 point = _point - primitive->object.position;
	point = Matrix33MulFloat3(primitive->object.rotationMatrix, point);
	point = modRepeat(point, primitive->data.torus.repeat);

	float2 pointXY = (float2){point.x, point.y};
	float d1 =
		LengthPow(pointXY, pow(2.0f, primitive->data.torus.radiusLPow)) - primitive->data.torus.radius;
	float2 pointDZ = (float2){d1, point.z};

	float dist = LengthPow(pointDZ, pow(2.0, primitive->data.torus.tubeRadiusLPow))
							 - primitive->data.torus.tubeRadius;
	return primitive->data.torus.empty ? fabs(dist) : dist;
}

float TotalDistanceToPrimitives(__constant sClInConstants *consts, sRenderData *renderData,
	float3 point, float fractalDistance, int *closestObjectId)
{
	int numberOfPrimitives = renderData->numberOfPrimitives;
	int closestObject = *closestObjectId;
	float dist = fractalDistance;

	float3 point2 = point - renderData->primitivesGlobalPosition->allPrimitivesPosition;
	point2 =
		Matrix33MulFloat3(renderData->primitivesGlobalPosition->mRotAllPrimitivesRotation, point2);

	for (int i = 0; i < numberOfPrimitives; i++)
	{
		__global sPrimitiveCl *primitive = &renderData->primitives[i];

		if (primitive->object.enable)
		{
			float distTemp = 0.0f;
			switch (primitive->object.objectType)
			{
				case clObjPlane:
				{
					distTemp = PrimitivePlane(primitive, point2);
					break;
				}
				case clObjBox:
				{
					distTemp = PrimitiveBox(primitive, point2);
					break;
				}
				case clObjSphere:
				{
					distTemp = PrimitiveSphere(primitive, point2);
					break;
				}
				case clObjRectangle:
				{
					distTemp = PrimitiveRectangle(primitive, point2);
					break;
				}
				case clObjCylinder:
				{
					distTemp = PrimitiveCylinder(primitive, point2);
					break;
				}
				case clObjCircle:
				{
					distTemp = PrimitiveCircle(primitive, point2);
					break;
				}
				case clObjCone:
				{
					distTemp = PrimitiveCone(primitive, point2);
					break;
				}
				case clObjWater:
				{
					distTemp = PrimitiveWater(primitive, point2, dist);
					break;
				}
				case clObjTorus:
				{
					distTemp = PrimitiveTorus(primitive, point2);
					break;
				}
				default: break;
			}

			dist = min(dist, distTemp);
		}
	}
	return dist;
}

#endif // USE_PRIMITIVES