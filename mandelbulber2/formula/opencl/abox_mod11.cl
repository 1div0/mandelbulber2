/**
 * Mandelbulber v2, a 3D fractal generator  _%}}i*<.        ____                _______
 * Copyright (C) 2017 Mandelbulber Team   _>]|=||i=i<,     / __ \___  ___ ___  / ___/ /
 *                                        \><||i|=>>%)    / /_/ / _ \/ -_) _ \/ /__/ /__
 * This file is part of Mandelbulber.     )<=i=]=|=i<>    \____/ .__/\__/_//_/\___/____/
 * The project is licensed under GPLv3,   -<>>=|><|||`        /_/
 * see also COPYING file in this folder.    ~+{i%+++
 *
 * ABoxMod11,
 * The Mandelbox fractal known as AmazingBox or ABox, invented by Tom Lowe in 2010
 * Variations from DarkBeam, Buddhi, Eiffie and mclarekin
 * based on DarkBeam's Mandelbulb3D code
 * @reference
 * http://www.fractalforums.com/ifs-iterated-function-systems/amazing-fractal/msg12467/#msg12467
 */

/* ### This file has been autogenerated. Remove this line, to prevent override. ### */

#ifndef DOUBLE_PRECISION
float4 AboxMod11Iteration(float4 z, __constant sFractalCl *fractal, sExtendedAuxCl *aux)
{
	float4 c = aux->const_c;

	// tglad fold
	if (aux->i >= fractal->transformCommon.startIterationsB
			&& aux->i < fractal->transformCommon.stopIterationsB)
	{
		float4 oldZ = z;
		z.x = fabs(z.x + fractal->transformCommon.additionConstant111.x)
					- fabs(z.x - fractal->transformCommon.additionConstant111.x) - z.x;
		z.y = fabs(z.y + fractal->transformCommon.additionConstant111.y)
					- fabs(z.y - fractal->transformCommon.additionConstant111.y) - z.y;
		z.z = fabs(z.z + fractal->transformCommon.additionConstant111.z)
					- fabs(z.z - fractal->transformCommon.additionConstant111.z) - z.z;

		if (z.x != oldZ.x) aux->color += fractal->mandelbox.color.factor4D.x;
		if (z.y != oldZ.y) aux->color += fractal->mandelbox.color.factor4D.y;
		if (z.z != oldZ.z) aux->color += fractal->mandelbox.color.factor4D.z;
	}
	if (fractal->transformCommon.functionEnabledFalse
			&& aux->i >= fractal->transformCommon.startIterationsD
			&& aux->i < fractal->transformCommon.stopIterationsD1)
	{
		float4 limit = fractal->transformCommon.additionConstant111;
		float4 length = 2.0f * limit;
		float4 tgladS = native_recip(length);
		float4 Add;
		if (fabs(z.x) < limit.x) Add.x = z.x * z.x * tgladS.x;
		if (fabs(z.y) < limit.y) Add.y = z.y * z.y * tgladS.y;
		if (fabs(z.z) < limit.z) Add.z = z.z * z.z * tgladS.z;
		if (fabs(z.x) > limit.x && fabs(z.x) < length.x)
			Add.x = (length.x - fabs(z.x)) * (length.x - fabs(z.x)) * tgladS.x;
		if (fabs(z.y) > limit.y && fabs(z.y) < length.y)
			Add.y = (length.y - fabs(z.y)) * (length.y - fabs(z.y)) * tgladS.y;
		if (fabs(z.z) > limit.z && fabs(z.z) < length.z)
			Add.z = (length.z - fabs(z.z)) * (length.z - fabs(z.z)) * tgladS.z;
		Add *= fractal->transformCommon.scale3D000;
		z.x = (z.x - (copysign((Add.x), z.x)));
		z.y = (z.y - (copysign((Add.y), z.y)));
		z.z = (z.z - (copysign((Add.z), z.z)));
	}
	// swap
	if (fractal->transformCommon.functionEnabledSwFalse)
	{
		z = (float4){z.z, z.y, z.x, z.w};
	}

	// spherical fold
	if (aux->i >= fractal->transformCommon.startIterationsS
			&& aux->i < fractal->transformCommon.stopIterationsS)
	{
		float para = 0.0f;
		float paraAddP0 = 0.0f;
		if (fractal->transformCommon.functionEnabledyFalse)
		{
			// para += paraAddP0 + fractal->transformCommon.minR2p25;
			if (fractal->Cpara.enabledLinear)
			{
				para = fractal->Cpara.para00; // parameter value at iter 0
				float temp0 = para;
				float tempA = fractal->Cpara.paraA;
				float tempB = fractal->Cpara.paraB;
				float tempC = fractal->Cpara.paraC;
				float lengthAB = fractal->Cpara.iterB - fractal->Cpara.iterA;
				float lengthBC = fractal->Cpara.iterC - fractal->Cpara.iterB;
				float grade1 = native_divide((tempA - temp0), fractal->Cpara.iterA);
				float grade2 = native_divide((tempB - tempA), lengthAB);
				float grade3 = native_divide((tempC - tempB), lengthBC);

				// slopes
				if (aux->i < fractal->Cpara.iterA)
				{
					para = temp0 + (aux->i * grade1);
				}
				if (aux->i < fractal->Cpara.iterB && aux->i >= fractal->Cpara.iterA)
				{
					para = mad(grade2, (aux->i - fractal->Cpara.iterA), tempA);
				}
				if (aux->i >= fractal->Cpara.iterB)
				{
					para = mad(grade3, (aux->i - fractal->Cpara.iterB), tempB);
				}

				// Curvi part on "true"
				if (fractal->Cpara.enabledCurves)
				{
					float paraAdd = 0.0f;
					float paraIt;
					if (lengthAB > 2.0f * fractal->Cpara.iterA) // stop  error, todo fix.
					{
						float curve1 = native_divide((grade2 - grade1), (4.0f * fractal->Cpara.iterA));
						float tempL = lengthAB - fractal->Cpara.iterA;
						float curve2 = native_divide((grade3 - grade2), (4.0f * tempL));
						if (aux->i < 2 * fractal->Cpara.iterA)
						{
							paraIt = tempA - fabs(tempA - aux->i);
							paraAdd = paraIt * paraIt * curve1;
						}
						if (aux->i >= 2 * fractal->Cpara.iterA && aux->i < fractal->Cpara.iterB + tempL)
						{
							paraIt = tempB - fabs(tempB * aux->i);
							paraAdd = paraIt * paraIt * curve2;
						}
						para += paraAdd;
					}
				}
			}
			paraAddP0 = 0.0f;
			if (fractal->Cpara.enabledParabFalse)
			{ // parabolic = paraOffset + iter *slope + (iter *iter *scale)
				paraAddP0 = fractal->Cpara.parabOffset0 + (aux->i * fractal->Cpara.parabSlope)
										+ (aux->i * aux->i * 0.001f * fractal->Cpara.parabScale);
			}
		}
		para += paraAddP0 + fractal->transformCommon.minR2p25;
		// spherical fold
		float rr = dot(z, z);

		z += fractal->mandelbox.offset;

		// if (r2 < 1e-21f) r2 = 1e-21f;
		if (rr < para)
		{
			float tglad_factor1 = native_divide(fractal->transformCommon.maxR2d1, para);
			z *= tglad_factor1;
			aux->DE *= tglad_factor1;
			aux->color += fractal->mandelbox.color.factorSp1;
		}
		else if (rr < fractal->transformCommon.maxR2d1)
		{
			float tglad_factor2 = native_divide(fractal->transformCommon.maxR2d1, rr);
			z *= tglad_factor2;
			aux->DE *= tglad_factor2;
			aux->color += fractal->mandelbox.color.factorSp2;
		}
		z -= fractal->mandelbox.offset;
	}
	// scale, incl DarkBeams Scale vary
	if (aux->i >= fractal->transformCommon.startIterationsA
			&& aux->i < fractal->transformCommon.stopIterationsA)
	{
		aux->actualScale = mad((fabs(aux->actualScale) - 1.0f), fractal->mandelboxVary4D.scaleVary,
			fractal->mandelbox.scale);

		z *= aux->actualScale;
		aux->DE = mad(aux->DE, fabs(aux->actualScale), 1.0f);

		//aux->actualScale = mad((fabs(aux->actualScale) - 1.0f), fractal->mandelboxVary4D.scaleVary,
		//	fractal->mandelbox.scale);



	}
	// offset
	z += fractal->transformCommon.additionConstant000;
	// addCpixel
	if (fractal->transformCommon.addCpixelEnabledFalse
			&& aux->i >= fractal->transformCommon.startIterationsE
			&& aux->i < fractal->transformCommon.stopIterationsE)
	{
		float4 tempC = c;
		if (fractal->transformCommon.alternateEnabledFalse) // alternate
		{
			tempC = aux->c;
			switch (fractal->mandelbulbMulti.orderOfXYZ)
			{
				case multi_OrderOfXYZCl_xyz:
				default: tempC = (float4){tempC.x, tempC.y, tempC.z, tempC.w}; break;
				case multi_OrderOfXYZCl_xzy: tempC = (float4){tempC.x, tempC.z, tempC.y, tempC.w}; break;
				case multi_OrderOfXYZCl_yxz: tempC = (float4){tempC.y, tempC.x, tempC.z, tempC.w}; break;
				case multi_OrderOfXYZCl_yzx: tempC = (float4){tempC.y, tempC.z, tempC.x, tempC.w}; break;
				case multi_OrderOfXYZCl_zxy: tempC = (float4){tempC.z, tempC.x, tempC.y, tempC.w}; break;
				case multi_OrderOfXYZCl_zyx: tempC = (float4){tempC.z, tempC.y, tempC.x, tempC.w}; break;
			}
			aux->c = tempC;
		}
		else
		{
			switch (fractal->mandelbulbMulti.orderOfXYZ)
			{
				case multi_OrderOfXYZCl_xyz:
				default: tempC = (float4){c.x, c.y, c.z, c.w}; break;
				case multi_OrderOfXYZCl_xzy: tempC = (float4){c.x, c.z, c.y, c.w}; break;
				case multi_OrderOfXYZCl_yxz: tempC = (float4){c.y, c.x, c.z, c.w}; break;
				case multi_OrderOfXYZCl_yzx: tempC = (float4){c.y, c.z, c.x, c.w}; break;
				case multi_OrderOfXYZCl_zxy: tempC = (float4){c.z, c.x, c.y, c.w}; break;
				case multi_OrderOfXYZCl_zyx: tempC = (float4){c.z, c.y, c.x, c.w}; break;
			}
		}
		z += tempC * fractal->transformCommon.constantMultiplier111;
	}
	// rotation
	if (fractal->transformCommon.rotationEnabled
			&& aux->i >= fractal->transformCommon.startIterationsR
			&& aux->i < fractal->transformCommon.stopIterationsR)
	{
		z = Matrix33MulFloat4(fractal->transformCommon.rotationMatrix, z);
	}
	// tweak scale
	if (aux->i >= fractal->transformCommon.startIterationsC
			&& aux->i < fractal->transformCommon.stopIterationsC1)
	{
		z *= fractal->transformCommon.scaleG1;
		aux->DE = mad(aux->DE, fabs(fractal->transformCommon.scaleG1), 1.0f);
	}

	// color
	aux->foldFactor = fractal->foldColor.compFold; // fold group weight
	aux->minRFactor = fractal->foldColor.compMinR; // orbit trap weight

	float scaleColor = fractal->foldColor.colorMin + fabs(aux->actualScale);
	// scaleColor += fabs(fractal->mandelbox.scale);
	aux->scaleFactor = scaleColor * fractal->foldColor.compScale;
	return z;
}
#else
double4 AboxMod11Iteration(double4 z, __constant sFractalCl *fractal, sExtendedAuxCl *aux)
{
	double4 c = aux->const_c;

	// tglad fold
	if (aux->i >= fractal->transformCommon.startIterationsB
			&& aux->i < fractal->transformCommon.stopIterationsB)
	{
		double4 oldZ = z;
		z.x = fabs(z.x + fractal->transformCommon.additionConstant111.x)
					- fabs(z.x - fractal->transformCommon.additionConstant111.x) - z.x;
		z.y = fabs(z.y + fractal->transformCommon.additionConstant111.y)
					- fabs(z.y - fractal->transformCommon.additionConstant111.y) - z.y;
		z.z = fabs(z.z + fractal->transformCommon.additionConstant111.z)
					- fabs(z.z - fractal->transformCommon.additionConstant111.z) - z.z;

		if (z.x != oldZ.x) aux->color += fractal->mandelbox.color.factor4D.x;
		if (z.y != oldZ.y) aux->color += fractal->mandelbox.color.factor4D.y;
		if (z.z != oldZ.z) aux->color += fractal->mandelbox.color.factor4D.z;
	}
	if (fractal->transformCommon.functionEnabledFalse
			&& aux->i >= fractal->transformCommon.startIterationsD
			&& aux->i < fractal->transformCommon.stopIterationsD1)
	{
		double4 limit = fractal->transformCommon.additionConstant111;
		double4 length = 2.0 * limit;
		double4 tgladS = 1.0 / length;
		double4 Add;
		if (fabs(z.x) < limit.x) Add.x = z.x * z.x * tgladS.x;
		if (fabs(z.y) < limit.y) Add.y = z.y * z.y * tgladS.y;
		if (fabs(z.z) < limit.z) Add.z = z.z * z.z * tgladS.z;
		if (fabs(z.x) > limit.x && fabs(z.x) < length.x)
			Add.x = (length.x - fabs(z.x)) * (length.x - fabs(z.x)) * tgladS.x;
		if (fabs(z.y) > limit.y && fabs(z.y) < length.y)
			Add.y = (length.y - fabs(z.y)) * (length.y - fabs(z.y)) * tgladS.y;
		if (fabs(z.z) > limit.z && fabs(z.z) < length.z)
			Add.z = (length.z - fabs(z.z)) * (length.z - fabs(z.z)) * tgladS.z;
		Add *= fractal->transformCommon.scale3D000;
		z.x = (z.x - (copysign((Add.x), z.x)));
		z.y = (z.y - (copysign((Add.y), z.y)));
		z.z = (z.z - (copysign((Add.z), z.z)));
	}
	// swap
	if (fractal->transformCommon.functionEnabledSwFalse)
	{
		z = (double4){z.z, z.y, z.x, z.w};
	}

	// spherical fold
	if (aux->i >= fractal->transformCommon.startIterationsS
			&& aux->i < fractal->transformCommon.stopIterationsS)
	{
		double para = 0.0;
		double paraAddP0 = 0.0;
		if (fractal->transformCommon.functionEnabledyFalse)
		{
			// para += paraAddP0 + fractal->transformCommon.minR2p25;
			if (fractal->Cpara.enabledLinear)
			{
				para = fractal->Cpara.para00; // parameter value at iter 0
				double temp0 = para;
				double tempA = fractal->Cpara.paraA;
				double tempB = fractal->Cpara.paraB;
				double tempC = fractal->Cpara.paraC;
				double lengthAB = fractal->Cpara.iterB - fractal->Cpara.iterA;
				double lengthBC = fractal->Cpara.iterC - fractal->Cpara.iterB;
				double grade1 = native_divide((tempA - temp0), fractal->Cpara.iterA);
				double grade2 = native_divide((tempB - tempA), lengthAB);
				double grade3 = native_divide((tempC - tempB), lengthBC);

				// slopes
				if (aux->i < fractal->Cpara.iterA)
				{
					para = temp0 + (aux->i * grade1);
				}
				if (aux->i < fractal->Cpara.iterB && aux->i >= fractal->Cpara.iterA)
				{
					para = mad(grade2, (aux->i - fractal->Cpara.iterA), tempA);
				}
				if (aux->i >= fractal->Cpara.iterB)
				{
					para = mad(grade3, (aux->i - fractal->Cpara.iterB), tempB);
				}

				// Curvi part on "true"
				if (fractal->Cpara.enabledCurves)
				{
					double paraAdd = 0.0;
					double paraIt;
					if (lengthAB > 2.0 * fractal->Cpara.iterA) // stop  error, todo fix.
					{
						double curve1 = native_divide((grade2 - grade1), (4.0 * fractal->Cpara.iterA));
						double tempL = lengthAB - fractal->Cpara.iterA;
						double curve2 = native_divide((grade3 - grade2), (4.0 * tempL));
						if (aux->i < 2 * fractal->Cpara.iterA)
						{
							paraIt = tempA - fabs(tempA - aux->i);
							paraAdd = paraIt * paraIt * curve1;
						}
						if (aux->i >= 2 * fractal->Cpara.iterA && aux->i < fractal->Cpara.iterB + tempL)
						{
							paraIt = tempB - fabs(tempB * aux->i);
							paraAdd = paraIt * paraIt * curve2;
						}
						para += paraAdd;
					}
				}
			}
			paraAddP0 = 0.0;
			if (fractal->Cpara.enabledParabFalse)
			{ // parabolic = paraOffset + iter *slope + (iter *iter *scale)
				paraAddP0 = fractal->Cpara.parabOffset0 + (aux->i * fractal->Cpara.parabSlope)
										+ (aux->i * aux->i * 0.001 * fractal->Cpara.parabScale);
			}
		}
		para += paraAddP0 + fractal->transformCommon.minR2p25;
		// spherical fold
		double rr = dot(z, z);

		z += fractal->mandelbox.offset;

		// if (r2 < 1e-21) r2 = 1e-21;
		if (rr < para)
		{
			double tglad_factor1 = native_divide(fractal->transformCommon.maxR2d1, para);
			z *= tglad_factor1;
			aux->DE *= tglad_factor1;
			aux->color += fractal->mandelbox.color.factorSp1;
		}
		else if (rr < fractal->transformCommon.maxR2d1)
		{
			double tglad_factor2 = native_divide(fractal->transformCommon.maxR2d1, rr);
			z *= tglad_factor2;
			aux->DE *= tglad_factor2;
			aux->color += fractal->mandelbox.color.factorSp2;
		}
		z -= fractal->mandelbox.offset;
	}
	// scale, incl DarkBeams Scale vary
	if (aux->i >= fractal->transformCommon.startIterationsA
			&& aux->i < fractal->transformCommon.stopIterationsA)
	{
		aux->actualScale = mad(
			(fabs(aux->actualScale) - 1.0), fractal->mandelboxVary4D.scaleVary, fractal->mandelbox.scale);

		z *= aux->actualScale;
		aux->DE = aux->DE * fabs(aux->actualScale) + 1.0;
;
	}
	// offset
	z += fractal->transformCommon.additionConstant000;
	// addCpixel
	if (fractal->transformCommon.addCpixelEnabledFalse
			&& aux->i >= fractal->transformCommon.startIterationsE
			&& aux->i < fractal->transformCommon.stopIterationsE)
	{
		double4 tempC = c;
		if (fractal->transformCommon.alternateEnabledFalse) // alternate
		{
			tempC = aux->c;
			switch (fractal->mandelbulbMulti.orderOfXYZ)
			{
				case multi_OrderOfXYZCl_xyz:
				default: tempC = (double4){tempC.x, tempC.y, tempC.z, tempC.w}; break;
				case multi_OrderOfXYZCl_xzy: tempC = (double4){tempC.x, tempC.z, tempC.y, tempC.w}; break;
				case multi_OrderOfXYZCl_yxz: tempC = (double4){tempC.y, tempC.x, tempC.z, tempC.w}; break;
				case multi_OrderOfXYZCl_yzx: tempC = (double4){tempC.y, tempC.z, tempC.x, tempC.w}; break;
				case multi_OrderOfXYZCl_zxy: tempC = (double4){tempC.z, tempC.x, tempC.y, tempC.w}; break;
				case multi_OrderOfXYZCl_zyx: tempC = (double4){tempC.z, tempC.y, tempC.x, tempC.w}; break;
			}
			aux->c = tempC;
		}
		else
		{
			switch (fractal->mandelbulbMulti.orderOfXYZ)
			{
				case multi_OrderOfXYZCl_xyz:
				default: tempC = (double4){c.x, c.y, c.z, c.w}; break;
				case multi_OrderOfXYZCl_xzy: tempC = (double4){c.x, c.z, c.y, c.w}; break;
				case multi_OrderOfXYZCl_yxz: tempC = (double4){c.y, c.x, c.z, c.w}; break;
				case multi_OrderOfXYZCl_yzx: tempC = (double4){c.y, c.z, c.x, c.w}; break;
				case multi_OrderOfXYZCl_zxy: tempC = (double4){c.z, c.x, c.y, c.w}; break;
				case multi_OrderOfXYZCl_zyx: tempC = (double4){c.z, c.y, c.x, c.w}; break;
			}
		}
		z += tempC * fractal->transformCommon.constantMultiplier111;
	}
	// rotation
	if (fractal->transformCommon.rotationEnabled
			&& aux->i >= fractal->transformCommon.startIterationsR
			&& aux->i < fractal->transformCommon.stopIterationsR)
	{
		z = Matrix33MulFloat4(fractal->transformCommon.rotationMatrix, z);
	}
	// tweak scale
	if (aux->i >= fractal->transformCommon.startIterationsC
			&& aux->i < fractal->transformCommon.stopIterationsC1)
	{
		z *= fractal->transformCommon.scaleG1;
		aux->DE = aux->DE * fabs(fractal->transformCommon.scaleG1) + 1.0;
	}

	// color
	aux->foldFactor = fractal->foldColor.compFold; // fold group weight
	aux->minRFactor = fractal->foldColor.compMinR; // orbit trap weight

	double scaleColor = fractal->foldColor.colorMin + fabs(aux->actualScale);
	// scaleColor += fabs(fractal->mandelbox.scale);
	aux->scaleFactor = scaleColor * fractal->foldColor.compScale;
	return z;
}
#endif
