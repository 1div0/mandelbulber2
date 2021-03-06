/**
 * Mandelbulber v2, a 3D fractal generator  _%}}i*<.        ____                _______
 * Copyright (C) 2020 Mandelbulber Team   _>]|=||i=i<,     / __ \___  ___ ___  / ___/ /
 *                                        \><||i|=>>%)    / /_/ / _ \/ -_) _ \/ /__/ /__
 * This file is part of Mandelbulber.     )<=i=]=|=i<>    \____/ .__/\__/_//_/\___/____/
 * The project is licensed under GPLv3,   -<>>=|><|||`        /_/
 * see also COPYING file in this folder.    ~+{i%+++
 *
 * RiemannSphereMsltoe Version1
 * @reference
 * http://www.fractalforums.com/new-theories-and-research/
 * revisiting-the-riemann-sphere-%28again%29/

 * This file has been autogenerated by tools/populateUiInformation.php
 * from the file "fractal_riemann_sphere_msltoe_v1.cpp" in the folder formula/definition
 * D O    N O T    E D I T    T H I S    F I L E !
 */

REAL4 RiemannSphereMsltoeV1Iteration(REAL4 z, __constant sFractalCl *fractal, sExtendedAuxCl *aux)
{
	REAL r = aux->r;
	// if (r < 1e-21f) r = 1e-21f;
	z *= fractal->transformCommon.scale / r;
	REAL q = 1.0f / (1.0f - z.z);
	REAL4 t3;
	t3.x = z.x * q;
	t3.y = z.y * q;

	t3.z = (r - 1.5f) * (1.0f + t3.x * t3.x + t3.y * t3.y);

	if (fractal->transformCommon.rotationEnabled)
		t3 = Matrix33MulFloat4(fractal->transformCommon.rotationMatrix, t3);

	t3.x = t3.x - floor(t3.x + 0.5f);
	t3.y = t3.y - floor(t3.y + 0.5f);
	t3.w = z.w;

	z = t3 * fractal->transformCommon.constantMultiplier441;

	z += fractal->transformCommon.additionConstant000;

	if (fractal->analyticDE.enabled)
	{
		aux->DE *= 4.0f * fractal->transformCommon.scale * length(z) / r;
		aux->DE = aux->DE * fractal->analyticDE.scale1 + fractal->analyticDE.offset1;
	}
	return z;
}