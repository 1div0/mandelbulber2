/**
 * Mandelbulber v2, a 3D fractal generator       ,=#MKNmMMKmmßMNWy,
 *                                             ,B" ]L,,p%%%,,,§;, "K
 * Copyright (C) 2014-18 Mandelbulber Team     §R-==%w["'~5]m%=L.=~5N
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
 * Compute - function fractal computation
 */

#include "compute_fractal.hpp"

#include "common_math.h"
#include "fractal.h"
#include "fractal_formulas.hpp"
#include "material.h"
#include "nine_fractals.hpp"

using namespace fractal;

template <fractal::enumCalculationMode Mode>
void Compute(const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out)
{
	fractalFormulaFcn fractalFormulaFunction;

	// repeat, move and rotate
	CVector3 pointTransformed = (in.point - in.common.fractalPosition).mod(in.common.repeat);
	pointTransformed = in.common.mRotFractalRotation.RotateVector(pointTransformed);

	CVector4 z = CVector4(pointTransformed, 0.0);

	double minimumR = 0.0;
	if (Mode == calcModeColouring)
	{
		minimumR = in.material->fractalColoring.initialMinimumR; // default 100.0
	}

	//double len = 0.0; // Temp: declared here for access outside orbit traps code
	//double colorLength = 0.0; // Temp: declared here for access outside orbit traps code

	if (in.forcedFormulaIndex >= 0)
	{
		z.w = fractals.GetInitialWAxis(in.forcedFormulaIndex);
	}
	else
	{
		z.w = fractals.GetInitialWAxis(0);
	}

	double r = z.Length();

	double initialWAxisColor = z.w;

	double orbitTrapTotal = 0.0;
	out->orbitTrapR = 0.0;

	enumFractalFormula formula = fractal::none;

	if (in.common.iterThreshMode)
		out->maxiter = true;
	else
		out->maxiter = false;

	int fractalIndex = 0;
	if (in.forcedFormulaIndex >= 0) fractalIndex = in.forcedFormulaIndex;

	const sFractal *defaultFractal = fractals.GetFractal(fractalIndex);

	sExtendedAux extendedAux;

	extendedAux.c = z;
	extendedAux.const_c = z;
	extendedAux.old_z = CVector4(0.0, 0.0, 0.0, 0.0);
	extendedAux.sum_z = CVector4(0.0, 0.0, 0.0, 0.0);
	extendedAux.pos_neg = 1.0;
	extendedAux.cw = 0;

	extendedAux.r = r;
	extendedAux.DE = 1.0;
	extendedAux.pseudoKleinianDE = 1.0;

	extendedAux.actualScale = fractals.GetFractal(fractalIndex)->mandelbox.scale;
	extendedAux.actualScaleA = 0.0;

	extendedAux.color = 1.0;
	extendedAux.colorHybrid = 0.0;

	extendedAux.temp100 = 100.0;
	extendedAux.addDist = 0.0;

	// main iteration loop
	int i;
	int sequence = 0;

	CVector4 lastGoodZ;
	CVector4 lastZ;
	CVector4 lastLastZ;

	// main iteration loop
	for (i = 0; i < in.maxN; i++)
	{
		lastGoodZ = lastZ;
		lastLastZ = lastZ;
		;
		lastZ = z;

		// hybrid fractal sequence
		if (in.forcedFormulaIndex >= 0)
		{
			sequence = in.forcedFormulaIndex;
		}
		else
		{
			sequence = fractals.GetSequence(i);
		}

		// foldings
		if (in.common.foldings.boxEnable)
		{
			BoxFolding(z, &in.common.foldings, extendedAux);
			r = z.Length();
		}

		if (in.common.foldings.sphericalEnable)
		{
			extendedAux.r = r;
			SphericalFolding(z, &in.common.foldings, extendedAux);
			r = z.Length();
		}

		const sFractal *fractal = fractals.GetFractal(sequence);
		formula = fractal->formula;

		// temporary vector for weight function
		CVector4 tempZ = z;

		extendedAux.r = r;
		extendedAux.i = i;

		fractalFormulaFunction = fractals.GetFractalFormulaFunction(sequence);

		if (!fractals.IsHybrid() || fractals.GetWeight(sequence) > 0.0)
		{
			// -------------- call for fractal formulas by function pointers ---------------
			if (fractalFormulaFunction)
			{
				fractalFormulaFunction(z, fractal, extendedAux);
			}
			else
			{
				double high = fractals.GetBailout(sequence) * 10.0;
				z = CVector4(high, high, high, high);
				out->distance = 10.0;
				out->iters = 1;
				out->z = z.GetXYZ();
				return;
			}
			// -----------------------------------------------------------------------------
		}

		// addition of constant
		if (fractals.IsAddCConstant(sequence))
		{
			switch (formula)
			{
				case aboxMod1:
				case amazingSurf:
					// case amazingSurfMod1:
					{
						if (fractals.IsJuliaEnabled(sequence))
						{
							CVector3 juliaC =
								fractals.GetJuliaConstant(sequence) * fractals.GetConstantMultiplier(sequence);
							z += CVector4(juliaC.y, juliaC.x, juliaC.z, 0.0);
						}
						else
						{
							z +=
								CVector4(extendedAux.const_c.y, extendedAux.const_c.x, extendedAux.const_c.z, 0.0)
								* fractals.GetConstantMultiplier(sequence);
						}
						break;
					}

				default:
				{
					if (fractals.IsJuliaEnabled(sequence))
					{
						z += CVector4(
							fractals.GetJuliaConstant(sequence) * fractals.GetConstantMultiplier(sequence), 0.0);
					}
					else
					{
						z += extendedAux.const_c * fractals.GetConstantMultiplier(sequence);
					}
					break;
				}
			}
		}

		if (fractals.IsHybrid())
		{
			z = SmoothCVector(tempZ, z, fractals.GetWeight(sequence));
		}

		// r calculation
		// r = sqrt(z.x * z.x + z.y * z.y + z.z * z.z + w * w);
		switch (fractal->formula)
		{
			case scatorPower2:					// add v2.15
			case scatorPower2Real:			// add v2.15
			case scatorPower2Imaginary: // corrected v2.14
			case testingLog:
			{
				CVector4 z2 = z * z;
				r = sqrt(z2.x + z2.y + z2.z + (z2.y * z2.z) / z2.x);
				// initial condition is normal r, becomes aux.r

				// r = sqrt(z2.x - z2.y - z2.z + (z2.y * z2.z) / (z2.x));
				break;
			}
			// scator magnitudes
			// magnitude in imaginary scator algebra

			// case pseudoKleinian:
			// case pseudoKleinianMod1:
			// case pseudoKleinianMod2:
			case pseudoKleinianStdDE:
			{
				r = sqrt(z.x * z.x + z.y * z.y);
				break;
			}

			default:
			{
				r = z.Length();
				// r = sqrt(z.x * z.x + z.y * z.y + z.z * z.z);
				break;
			}
		}

		if (z.IsNotANumber())
		{
			z = lastZ;
			r = z.Length();
			out->maxiter = true;
			break;
		}

		// escape conditions
		if (fractals.IsCheckForBailout(sequence))
		{
			if (Mode == calcModeNormal || Mode == calcModeDeltaDE1)
			{
				if (r > fractals.GetBailout(sequence))
				{
					out->maxiter = false;
					break;
				}

				if (fractals.UseAdditionalBailoutCond(sequence))
				{
					if ((z - lastZ).Length() / r < 0.1 / fractals.GetBailout(sequence))
					{
						out->maxiter = false;
						break;
					}
					if ((z - lastLastZ).Length() / r < 0.1 / fractals.GetBailout(sequence))
					{
						out->maxiter = false;
						break;
					}
				}
			}
			else if (Mode == calcModeDeltaDE2)
			{
				if (i == in.maxN) break;
			}
			else if (Mode == calcModeColouring)
			{
				CVector4 colorZ = z;
				if (!in.material->fractalColoring.color4dEnabledFalse) colorZ.w = 0.0;

				if (!in.material->fractalColoring.colorPreV215False)
				{
					double len = 0.0;
					if (extendedAux.i < in.material->fractalColoring.maxColorIter)
					{
						switch (in.material->fractalColoring.coloringAlgorithm)
						{
							case fractalColoring_Standard:
							{
								len = colorZ.Length();
								if (len < minimumR) minimumR = len;
								break;
							}
							case fractalColoring_ZDotPoint:
							{
								len = fabs(colorZ.Dot(CVector4(pointTransformed, initialWAxisColor)));
								if (len < minimumR) minimumR = len;
								break;
							}
							case fractalColoring_Sphere:
							{
								len = fabs((colorZ - CVector4(pointTransformed, initialWAxisColor)).Length()
													 - in.material->fractalColoring.sphereRadius);
								if (len < minimumR) minimumR = len;
								break;
							}
							case fractalColoring_Cross:
							{
								len = dMin(fabs(colorZ.x), fabs(colorZ.y), fabs(colorZ.z));
								if (in.material->fractalColoring.color4dEnabledFalse) len = min(len, fabs(colorZ.w));
								if (len < minimumR) minimumR = len;
								break;
							}
							case fractalColoring_Line:
							{
								len = fabs(colorZ.Dot(in.material->fractalColoring.lineDirection));
								if (len < minimumR) minimumR = len;
								break;
							}
							case fractalColoring_None:
							{
								len = r;
								if (len < minimumR) minimumR = len;
								break;
							}
						}
					}
					//if (fractal->formula == mandelbox) minimumR = 100;
					if (r > fractals.GetBailout(sequence) || (z - lastZ).Length() / r < 1e-15) break;
				}
				else
				{
					double len = 0.0;
					{
						switch (in.material->fractalColoring.coloringAlgorithm)
						{
							case fractalColoring_Standard:
							{
								len = colorZ.Length();
								break;
							}
							case fractalColoring_ZDotPoint:
							{
								len = fabs(colorZ.Dot(CVector4(pointTransformed, initialWAxisColor)));
								break;
							}
							case fractalColoring_Sphere:
							{
								len = fabs((colorZ - CVector4(pointTransformed, initialWAxisColor)).Length()
													 - in.material->fractalColoring.sphereRadius);
								break;
							}
							case fractalColoring_Cross:
							{
								len = dMin(fabs(colorZ.x), fabs(colorZ.y), fabs(colorZ.z));
								if (in.material->fractalColoring.color4dEnabledFalse) len = min(len, fabs(colorZ.w));
								break;
							}
							case fractalColoring_Line:
							{
								len = fabs(colorZ.Dot(in.material->fractalColoring.lineDirection));
								break;
							}
							case fractalColoring_None:
							{
								len = r;
								break;
							}
						}
					}
					if (fractal->formula != mandelbox // minimumR = 100 default in color calc for Mbox and standard
							|| in.material->fractalColoring.coloringAlgorithm != fractalColoring_Standard)
					{
						if (len < minimumR) minimumR = len;
						if (r > 1e15 || (z - lastZ).Length() / r < 1e-15) break; // old, is updated v2.15
					}
					else
					{
						if (r > 1e15 || (z - lastZ).Length() / r < 1e-15) break;
					}
				}
			}

			else if (Mode == calcModeOrbitTrap)
			{
				CVector4 delta = z - CVector4(in.common.fakeLightsOrbitTrap, 0.0);
				double distance = delta.Length();
				if (i >= in.common.fakeLightsMinIter && i <= in.common.fakeLightsMaxIter)
					orbitTrapTotal += (1.0 / (distance * distance));
				if (distance > fractals.GetBailout(sequence))
				{
					out->orbitTrapR = orbitTrapTotal;
					break;
				}
			}
			else if (Mode == calcModeCubeOrbitTrap)
			{
				if (i >= in.material->textureFractalizeStartIteration)
				{
					double size = in.material->textureFractalizeCubeSize;
					CVector3 zz = z.GetXYZ() - pointTransformed;
					if (zz.x > -size && zz.x < size && zz.y > -size && zz.y < size && zz.z > -size
							&& zz.z < size)
					{
						out->colorIndex = (abs(z.x - size) + abs(z.y - size) + abs(z.z - size)) * 100.0;
						out->iters = i + 1;
						out->z = z.GetXYZ();
						return;
					}
				}
				if (r > in.material->textureFractalizeCubeSize * 100.0)
				{
					out->colorIndex = 0.0;
					out->iters = i + 1;
					out->z = z.GetXYZ() / z.Length();
					return;
				}
			}
		}

		if (z.IsNotANumber()) // detection of dead computation
		{
			z = lastGoodZ;
			break;
		}
	}

	// final calculations
	if (Mode == calcModeNormal) //analytic
	{
		// if (extendedAux.DE > 0.0); //maybe?
		if (fractals.IsHybrid())
		{
			if (extendedAux.DE != 0.0)
			{
				if (fractals.GetDEFunctionType(0) == fractal::linearDEFunction)
				{
					out->distance = (r - in.common.linearDEOffset) / fabs(extendedAux.DE);
				}
				else if (fractals.GetDEFunctionType(0) == fractal::logarithmicDEFunction)
				{
					out->distance = 0.5 * r * log(r) / extendedAux.DE;
				}
				else if (fractals.GetDEFunctionType(0) == fractal::pseudoKleinianDEFunction)
				{
					double rxy = sqrt(z.x * z.x + z.y * z.y);
					out->distance =
						max(rxy - extendedAux.pseudoKleinianDE, fabs(rxy * z.z) / r) / fabs(extendedAux.DE);
				}
				else if (fractals.GetDEFunctionType(0) == fractal::josKleinianDEFunction)
				{
					if (fractals.GetFractal(0)->transformCommon.functionEnabled)
						z.y = min(z.y, fractals.GetFractal(0)->transformCommon.foldingValue - z.y);

					out->distance =
						min(z.y, fractals.GetFractal(0)->analyticDE.tweak005)
						/ max(extendedAux.pseudoKleinianDE, fractals.GetFractal(0)->analyticDE.offset1);
				}
				/*case testingDEFunction:
				{
					double logDE = ((0.5 * r * log(r)) - in.common.linearDEOffset) / extendedAux.DE;
					double linDE = (r - in.common.linearDEOffset) / fabs(extendedAux.DE);

					out->distance = "mix function"  (logDE, linDE, extendedAux.temp100 / 100)); // temp use of
				aux.

				}*/

				// out->distance = = max(fabs(z.z), max(fabs(z.y), fabs(z.x)));
				// CVector4 zz = z * z;
				// out->distance = = sqrt(max(zz.x + zz.y, max(zz.y + zz.z, zz.x + zz.z)))
				// out->distance = abs(length(z)-0.0 ) * pow(Scale, float(-n));
				// Use this to crop to a sphere:
				//  float e = clamp(length(z)-2.0, 0.0,100.0);
				//  out->distance = max(d,e);// distance estimate
				//
				// #if 1
				// 	out->distance = (sqrt(r2)-sr)/dd;//bounding volume is a sphere
				// #else
				// 	p=abs(p); out->distance = (max(p.x,max(p.y,p.z))-sc)/dd;//bounding volume is a cube
				// #endif
			}
			else
			{
				out->distance = r;
			}
		}
		else
		{
			switch (fractals.GetDEAnalyticFunction(sequence))
			{
				case analyticFunctionLogarithmic:
				{
					if (extendedAux.DE > 0)
						out->distance = 0.5 * r * log(r) / extendedAux.DE;
					else
						out->distance = r;
					break;
				}
				case analyticFunctionLinear:
				{
					out->distance = r / fabs(extendedAux.DE);
					break;
				}
				case analyticFunctionIFS:
				{
					out->distance = (r - 2.0) / fabs(extendedAux.DE);
					break;
				}
				case analyticFunctionPseudoKleinian:
				{
					if (extendedAux.DE > 0)
					{
						double rxy = sqrt(z.x * z.x + z.y * z.y);
						out->distance =
							max(rxy - extendedAux.pseudoKleinianDE, fabs(rxy * z.z) / r) / (extendedAux.DE);
					}
					else
						out->distance = r;
					break;
				}
				case analyticFunctionJosKleinian:
				{
					if (fractals.GetFractal(sequence)->transformCommon.functionEnabled)
						z.y = min(z.y, fractals.GetFractal(sequence)->transformCommon.foldingValue - z.y);

					out->distance =
						min(z.y, fractals.GetFractal(sequence)->analyticDE.tweak005)
						/ max(extendedAux.pseudoKleinianDE, fractals.GetFractal(sequence)->analyticDE.offset1);
					break;
				}

				case analyticFunctionNone: out->distance = -1.0; break;
				case analyticFunctionUndefined: out->distance = r; break;
			}
		}
	}

	// color calculation
	else if (Mode == calcModeColouring)
	{
		enumColoringFunction coloringFunction = fractals.GetColoringFunction(sequence);
		out->colorIndex = CalculateColorIndex(fractals.IsHybrid(), r, z, minimumR, extendedAux,
			in.material->fractalColoring, coloringFunction, defaultFractal);
	}
	else
	{
		out->distance = 0.0;

		// needed for JosKleinian fractal to calculate spheres in deltaDE mode
		if (fractals.GetDEFunctionType(0) == fractal::josKleinianDEFunction)
		{
			if (fractals.GetFractal(sequence)->transformCommon.functionEnabled)
				z.y = min(z.y, fractals.GetFractal(sequence)->transformCommon.foldingValue - z.y);
		}
	}

	out->iters = i + 1;
	out->z = z.GetXYZ();
}

template void Compute<calcModeNormal>(
	const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out);
template void Compute<calcModeDeltaDE1>(
	const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out);
template void Compute<calcModeDeltaDE2>(
	const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out);
template void Compute<calcModeColouring>(
	const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out);
template void Compute<calcModeOrbitTrap>(
	const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out);
template void Compute<calcModeCubeOrbitTrap>(
	const cNineFractals &fractals, const sFractalIn &in, sFractalOut *out);
