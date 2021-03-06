/**
 * Mandelbulber v2, a 3D fractal generator  _%}}i*<.        ____                _______
 * Copyright (C) 2020 Mandelbulber Team   _>]|=||i=i<,     / __ \___  ___ ___  / ___/ /
 *                                        \><||i|=>>%)    / /_/ / _ \/ -_) _ \/ /__/ /__
 * This file is part of Mandelbulber.     )<=i=]=|=i<>    \____/ .__/\__/_//_/\___/____/
 * The project is licensed under GPLv3,   -<>>=|><|||`        /_/
 * see also COPYING file in this folder.    ~+{i%+++
 *
 * based of darkbeams recfold transform from Mandelbulb3D.

 * This file has been autogenerated by tools/populateUiInformation.php
 * from the file "fractal_transf_abs_rec_fold_xy.cpp" in the folder formula/definition
 * D O    N O T    E D I T    T H I S    F I L E !
 */

REAL4 TransfAbsRecFoldXYIteration(REAL4 z, __constant sFractalCl *fractal, sExtendedAuxCl *aux)
{
	REAL foldX = fractal->transformCommon.offset1;
	REAL foldY = fractal->transformCommon.offsetA1;

	REAL t;
	z.x = fabs(z.x);
	z.y = fabs(z.y);
	if (fractal->transformCommon.functionEnabledAFalse)
	{
		t = z.x;
		z.x = z.y;
		z.y = t;
	}
	t = z.x;
	z.x = z.x + z.y - fractal->transformCommon.offset0;
	z.y = t - z.y - fractal->transformCommon.offsetA0;
	if (fractal->transformCommon.functionEnabledBxFalse) z.x = -fabs(z.x);
	if (fractal->transformCommon.functionEnabledBx) z.y = -fabs(z.y);

	t = z.x;
	z.x = z.x + z.y;
	z.y = t - z.y;
	z.x *= 0.5f;
	z.y *= 0.5f;
	if (fractal->transformCommon.functionEnabledAx) z.x = foldX - fabs(z.x + foldX);
	if (fractal->transformCommon.functionEnabledAxFalse) z.y = foldY - fabs(z.y + foldY);

	if (fractal->analyticDE.enabledFalse)
		aux->DE = aux->DE * fractal->analyticDE.scale1 + fractal->analyticDE.offset0;
	return z;
}