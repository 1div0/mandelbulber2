/**
 * Mandelbulber v2, a 3D fractal generator  _%}}i*<.        ____                _______
 * Copyright (C) 2020 Mandelbulber Team   _>]|=||i=i<,     / __ \___  ___ ___  / ___/ /
 *                                        \><||i|=>>%)    / /_/ / _ \/ -_) _ \/ /__/ /__
 * This file is part of Mandelbulber.     )<=i=]=|=i<>    \____/ .__/\__/_//_/\___/____/
 * The project is licensed under GPLv3,   -<>>=|><|||`        /_/
 * see also COPYING file in this folder.    ~+{i%+++
 *
 * FoldCutCube
 * based on formula coded by Darkbeam in fragmentarium:

 * This file has been autogenerated by tools/populateUiInformation.php
 * from the function "FoldCutCubeIteration" in the file fractal_formulas.cpp
 * D O    N O T    E D I T    T H I S    F I L E !
 */

REAL4 FoldCutCubeIteration(REAL4 z, __constant sFractalCl *fractal, sExtendedAuxCl *aux)
{

	if (!fractal->transformCommon.functionEnabledDFalse
			&& aux->i < fractal->transformCommon.stopIterations1)
	{
		REAL4 zc = fabs(z);
		if (zc.y > zc.x)
		{
			REAL temp = zc.x;
			zc.x = zc.y;
			zc.y = temp;
		}
		if (zc.z > zc.x)
		{
			REAL temp = zc.x;
			zc.x = zc.z;
			zc.z = temp;
		}
		if (zc.y > zc.x)
		{
			REAL temp = zc.x;
			zc.x = zc.y;
			zc.y = temp;
		}
		aux->dist = 1.0f - zc.x;
		/*z = fabs(z);
		if (z.y > z.x) { REAL temp = z.x; z.x = z.y; z.y = temp; }
		if (z.z > z.x) { REAL temp = z.x; z.x = z.z; z.z = temp; }
		if (z.y > z.x) { REAL temp = z.x; z.x = z.y; z.y = temp; }
		aux->dist = 1.0f - z.x;*/
	}

	z *= fractal->transformCommon.scale015;
	aux->DE *= fractal->transformCommon.scale015;
	// rotation
	if (fractal->transformCommon.functionEnabledRFalse
			&& aux->i >= fractal->transformCommon.startIterationsR
			&& aux->i < fractal->transformCommon.stopIterationsR)
	{
		z = Matrix33MulFloat4(fractal->transformCommon.rotationMatrix, z);
	}
	z = fabs(z);

	// folds
	if (fractal->transformCommon.functionEnabledFalse)
	{
		// diagonal
		if (fractal->transformCommon.functionEnabledCxFalse)
			if (z.y > z.x)
			{
				REAL temp = z.x;
				z.x = z.y;
				z.y = temp;
			}
		// polyfold
		if (fractal->transformCommon.functionEnabledPFalse)
		{
			z.x = fabs(z.x);
			int poly = fractal->transformCommon.int6;
			REAL psi = fabs(fmod(atan(native_divide(z.y, z.x)) + native_divide(M_PI_F, poly),
												native_divide(M_PI_F, (0.5f * poly)))
											- native_divide(M_PI_F, poly));
			REAL len = native_sqrt(mad(z.x, z.x, z.y * z.y));
			z.x = native_cos(psi) * len;
			z.y = native_sin(psi) * len;
		}
		if (fractal->transformCommon.functionEnabledSFalse)
		{
			REAL rr = dot(z, z);
			// z += fractal->mandelbox.offset;
			if (rr < fractal->transformCommon.minR0)
			{
				REAL tglad_factor1 =
					native_divide(fractal->transformCommon.maxR2d1, fractal->transformCommon.minR0);
				z *= tglad_factor1;
				aux->DE *= tglad_factor1;
			}
			else if (rr < fractal->transformCommon.maxR2d1)
			{
				REAL tglad_factor2 = native_divide(fractal->transformCommon.maxR2d1, rr);
				z *= tglad_factor2;
				aux->DE *= tglad_factor2;
			}
			// z -= fractal->mandelbox.offset;
		}
	}

	z -= fractal->transformCommon.offset111;
	if (z.y > z.x)
	{
		REAL temp = z.x;
		z.x = z.y;
		z.y = temp;
	}
	if (z.z > z.x)
	{
		REAL temp = z.x;
		z.x = z.z;
		z.z = temp;
	}
	if (z.y > z.x)
	{
		REAL temp = z.x;
		z.x = z.y;
		z.y = temp;
	}

	z -= fractal->transformCommon.offset100;

	if (z.y > z.x)
	{
		REAL temp = z.x;
		z.x = z.y;
		z.y = temp;
	}
	if (z.z > z.x)
	{
		REAL temp = z.x;
		z.x = z.z;
		z.z = temp;
	}
	if (z.y > z.x)
	{
		REAL temp = z.x;
		z.x = z.y;
		z.y = temp;
	}

	if (!fractal->transformCommon.functionEnabledDFalse)
	{
		int x1 = aux->i + 1;
		aux->dist =
			fabs(min(native_divide(fractal->transformCommon.offset05, REAL(x1)) - aux->dist,
				native_divide(z.x, aux->DE)));
	}
	else
		aux->dist = min(aux->dist, native_divide(z.x, aux->DE));

	if (fractal->transformCommon.rotation2EnabledFalse)
		z = Matrix33MulFloat4(fractal->transformCommon.rotationMatrix2, z);

	// DE tweak
	if (fractal->analyticDE.enabledFalse) aux->dist = aux->dist * fractal->analyticDE.scale1;
	return z;
}
