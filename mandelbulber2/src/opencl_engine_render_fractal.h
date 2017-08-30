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
 * Authors: Krzysztof Marczak (buddhi1980@gmail.com), Robert Pancoast (RobertPancoast77@gmail.com),
 *  Sebastian Jennen (jenzebas@gmail.com)
 *
 * cOpenClEngineRenderFractal - prepares and executes fractal rendering on opencl
 */

#ifndef MANDELBULBER2_SRC_OPENCL_ENGINE_RENDER_FRACTAL_H_
#define MANDELBULBER2_SRC_OPENCL_ENGINE_RENDER_FRACTAL_H_

#include "fractal_enums.h"
#include "opencl_engine.h"
#include "opencl_include_header_wrapper.hpp"
#include "statistics.h"

// custom includes
#ifdef USE_OPENCL
#include "opencl/input_data_structures.h"
#endif // USE_OPENCL

#if defined(_MSC_VER)
#pragma warning(pop)
#endif // _MSC_VER

class cImage;
class cFractalContainer;
class cOpenClDynamicData;
struct sParamRender;
class cNineFractals;
struct sRenderData;

class cOpenClEngineRenderFractal : public cOpenClEngine
{
	Q_OBJECT

public:
	enum enumClRenderEngineMode
	{
		clRenderEngineTypeFast,
		clRenderEngineTypeLimited,
		clRenderEngineTypeFull
	};

	cOpenClEngineRenderFractal(cOpenClHardware *hardware);
	~cOpenClEngineRenderFractal();

#ifdef USE_OPENCL
	bool LoadSourcesAndCompile(const cParameterContainer *params) override;
	void SetParameters(const cParameterContainer *paramContainer,
		const cFractalContainer *fractalContainer, sParamRender *paramRender, cNineFractals *fractals,
		sRenderData *renderData);
	bool PreAllocateBuffers(const cParameterContainer *params) override;
	bool AssignParametersToKernel();
	bool WriteBuffersToQueue();
	bool ProcessQueue(int jobX, int jobY, int pixelsLeftX, int pixelsLeftY);
	bool ReadBuffersFromQueue();
	bool Render(cImage *image, bool *stopRequest, sRenderData *renderData);
	void MarkCurrentPendingTile(cImage *image, QRect corners);

private:
	QString GetKernelName() override;

	static QString toCamelCase(const QString &s);

	sClInConstants *constantInBuffer;
	cl::Buffer *inCLConstBuffer;

	QByteArray inBuffer;
	cl::Buffer *inCLBuffer;

	sClPixel *rgbBuffer;
	cl::Buffer *outCL;

	cOpenClDynamicData *dynamicData;

	QStringList listOfUsedFormulas;
	bool autoRefreshMode;
	bool monteCarlo;

#endif

signals:
	void updateProgressAndStatus(const QString &text, const QString &progressText, double progress);
	void updateStatistics(cStatistics);
};

#endif /* MANDELBULBER2_SRC_OPENCL_ENGINE_RENDER_FRACTAL_H_ */
