/**
 * Mandelbulber v2, a 3D fractal generator  _%}}i*<.        ____                _______
 * Copyright (C) 2020 Mandelbulber Team   _>]|=||i=i<,     / __ \___  ___ ___  / ___/ /
 *                                        \><||i|=>>%)    / /_/ / _ \/ -_) _ \/ /__/ /__
 * This file is part of Mandelbulber.     )<=i=]=|=i<>    \____/ .__/\__/_//_/\___/____/
 * The project is licensed under GPLv3,   -<>>=|><|||`        /_/
 * see also COPYING file in this folder.    ~+{i%+++
 *
 * KochIteration
 * Based on Knighty's Kaleidoscopic IFS 3D Fractals, described here:
 * http://www.fractalforums.com/3d-fractal-generation/kaleidoscopic-%28escape-time-ifs%29/

 * This file has been autogenerated by tools/populateUiInformation.php
 * from the function "KochIteration" in the file fractal_formulas.cpp
 * D O    N O T    E D I T    T H I S    F I L E !
 */

REAL4 KochIteration(REAL4 z, __constant sFractalCl *fractal, sExtendedAuxCl *aux)
{
	z.x = fabs(z.x);
	z.y = fabs(z.y);
	if (z.y > z.x)
	{
		REAL temp = z.x;
		z.x = z.y;
		z.y = temp;
	}

	REAL YOff = FRAC_1_3 * fractal->transformCommon.scale1;
	z.y = YOff - fabs(z.y - YOff);

	z.x += FRAC_1_3;
	if (z.z > z.x)
	{
		REAL temp = z.x;
		z.x = z.z;
		z.z = temp;
	}
	z.x -= FRAC_1_3;

	z.x -= FRAC_1_3;
	if (z.z > z.x)
	{
		REAL temp = z.x;
		z.x = z.z;
		z.z = temp;
	}
	z.x += FRAC_1_3;

	REAL4 Offset = fractal->transformCommon.offset100;
	z = mad(fractal->transformCommon.scale3, (z - Offset), Offset);
	aux->DE = aux->DE * fractal->transformCommon.scale3;

	// rotation
	if (fractal->transformCommon.functionEnabledRFalse
			&& aux->i >= fractal->transformCommon.startIterationsR
			&& aux->i < fractal->transformCommon.stopIterationsR)
	{
		z = Matrix33MulFloat4(fractal->transformCommon.rotationMatrix, z);
	}
	aux->dist = fabs(length(z) - length(Offset));
	aux->dist = native_divide(aux->dist, aux->DE);
	return z;
}
