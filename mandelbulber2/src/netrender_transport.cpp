/**
 * Mandelbulber v2, a 3D fractal generator       ,=#MKNmMMKmmßMNWy,
 *                                             ,B" ]L,,p%%%,,,§;, "K
 * Copyright (C) 2019 Mandelbulber Team        §R-==%w["'~5]m%=L.=~5N
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
 * Authors: Krzysztof Marczak (buddhi1980@gmail.com), Sebastian Jennen (jenzebas@gmail.com)
 *
 * Netrender Transport class - transport specific Networking class for command and payload
 * communication
 */

#include <QDataStream>

#include "netrender_transport.hpp"
#include "lzo_compression.h"
#include "write_log.hpp"

bool cNetRenderTransport::SendData(QTcpSocket *socket, sMessage msg, qint32 id)
{
	// ############## NetRender Message format #######################
	// FIELD: | command  | id       | size     | payload  | checksum |
	// SIZE:  | qint32   | qint32   | qint32   | 0 - size | quint16  |
	// STATE: | required | required | required | optional | optional |
	// ###############################################################
	// Note: If size is 0, payload and checksum are omitted.
	// ###############################################################

	if (!socket) return false;
	if (socket->state() != QAbstractSocket::ConnectedState) return false;

	QByteArray byteArray;
	QDataStream socketWriteStream(&byteArray, QIODevice::ReadWrite);

	msg.payload = lzoCompress(msg.payload);
	msg.size = msg.payload.size();
	msg.id = id;

	WriteLog(QString("NetRender - send data, command %1, bytes %2, id %3")
						 .arg(msg.command)
						 .arg(msg.size)
						 .arg(msg.id),
		3);

	// append header
	socketWriteStream << msg.command << msg.id << msg.size;

	// append payload
	if (msg.size > 0)
	{
		socketWriteStream.writeRawData(msg.payload.data(), msg.size);
		// append checksum
		qint16 checksum = qChecksum(msg.payload.data(), msg.size);
		socketWriteStream << checksum;
	}

	// write to socket
	if (socket->isOpen() && socket->state() == QAbstractSocket::ConnectedState)
	{
		socket->write(byteArray);
	}
	else
	{
		qCritical() << "CNetRender::SendData(QTcpSocket *socket, sMessage msg): socket closed!";
	}

	return true;
}

bool cNetRenderTransport::ReceiveData(QTcpSocket *socket, sMessage *msg)
{
	QDataStream socketReadStream(socket);

	// read in the header
	if (msg->command == netRender_NONE)
	{
		if (socket->bytesAvailable() < sMessage::headerSize())
		{
			return false;
		}
		// header data is available
		socketReadStream >> msg->command;
		socketReadStream >> msg->id;
		socketReadStream >> msg->size;
		WriteLog(QString("NetRender - ReceiveData(), command %1, bytes %2, id %3")
							 .arg(msg->command)
							 .arg(msg->size)
							 .arg(msg->id),
			3);
	}

	// if the message does not contain a payload it is ready to be processed
	if (msg->size <= 0) return true;

	// if there is still incomplete message then return false
	if (socket->bytesAvailable() < (sMessage::crcSize() + msg->size)) return false;

	// full payload available, read to buffer
	std::vector<char> buffer(msg->size);
	socketReadStream.readRawData(buffer.data(), msg->size);
	msg->payload.append(buffer.data(), msg->size);

	// run crc check on the payload
	quint16 crcCalculated = qChecksum(buffer.data(), msg->size);
	quint16 crcReceived;
	socketReadStream >> crcReceived;
	if (crcCalculated != crcReceived)
	{
		WriteLog("NetRender - ReceiveData() : crc error", 2);
		return false;
	}

	msg->payload = lzoUncompress(msg->payload);
	msg->size = msg->payload.size();
	return true;
}

void cNetRenderTransport::ResetMessage(sMessage *msg)
{
	if (msg == nullptr)
	{
		qCritical() << "CNetRender::ResetMessage(sMessage *msg): message is nullptr!";
	}
	else
	{
		msg->command = netRender_NONE;
		msg->id = 0;
		msg->size = 0;
		if (!msg->payload.isEmpty()) msg->payload.clear();
	}
}

bool cNetRenderTransport::CompareMajorVersion(qint32 version1, qint32 version2)
{
	qint32 majorVersion1 = version1 / 10;
	qint32 majorVersion2 = version2 / 10;
	return majorVersion1 == majorVersion2;
}
