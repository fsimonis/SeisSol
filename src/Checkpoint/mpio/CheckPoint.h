/**
 * @file
 * This file is part of SeisSol.
 *
 * @author Sebastian Rettenberger (sebastian.rettenberger AT tum.de, http://www5.in.tum.de/wiki/index.php/Sebastian_Rettenberger)
 *
 * @section LICENSE
 * Copyright (c) 2015, SeisSol Group
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @section DESCRIPTION
 * Main class for MPI-IO checkpoints
 */

#ifndef CHECKPOINT_MPIO_CHECK_POINT_H
#define CHECKPOINT_MPIO_CHECK_POINT_H

#include <mpi.h>

#include <cassert>

#include "utils/env.h"

#include "Checkpoint/CheckPoint.h"
#include "Initializer/preProcessorMacros.fpp"

namespace seissol
{

namespace checkpoint
{

namespace mpio
{

class CheckPoint : virtual public seissol::checkpoint::CheckPoint
{
private:
	/** Checkpoint identifier (written to the beginning of the file) */
	const unsigned long m_identifier;

	/** The size of an element (in bytes) */
	const unsigned int m_elemSize;

	/** Identifiers of the files */
	MPI_File m_mpiFiles[2];

	/** Number of bytes reserved for the header */
	unsigned long m_headerSize;

	/** The MPI data type for the header */
	MPI_Datatype m_headerType;

	/** The MPI data type for the file header */
	MPI_Datatype m_fileHeaderType;

	/** The MPI data type of the file data */
	MPI_Datatype m_fileDataType;

public:
	CheckPoint(unsigned long identifier, unsigned int elemSize)
		: m_identifier(identifier),
		  m_elemSize(elemSize),
		  m_headerSize(0), m_headerType(MPI_DATATYPE_NULL),
		  m_fileHeaderType(MPI_DATATYPE_NULL), m_fileDataType(MPI_DATATYPE_NULL)
	{
	}

	virtual ~CheckPoint() {}

	void setFilename(const char* filename)
	{
		initFilename(filename, "scp");
	}

	void initLate()
	{
		seissol::checkpoint::CheckPoint::initLate();

		for (unsigned int i = 0; i < 2; i++) {
			checkMPIErr(MPI_File_open(comm(), const_cast<char*>(dataFile(i).c_str()),
					MPI_MODE_WRONLY | MPI_MODE_CREATE, MPI_INFO_NULL, &m_mpiFiles[i]));

			// Sync file (required for performance measure)
			// TODO preallocate file first
			checkMPIErr(MPI_File_sync(m_mpiFiles[i]));
		}
	}

	void close()
	{
		for (unsigned int i = 0; i < 2; i++)
			MPI_File_close(&m_mpiFiles[i]);
		MPI_Type_free(&m_headerType);
		MPI_Type_free(&m_fileDataType);
		if (rank() == 0)
			MPI_Type_free(&m_fileHeaderType);
	}

protected:
	/**
	 * Submit the header data type
	 *
	 * @param type The MPI data type
	 */
	void setHeaderType(MPI_Datatype type)
	{
		m_headerType = type;
		MPI_Type_commit(&m_headerType);
	}

	/**
	 * Create the file view
	 *
	 * @param headerSize The size of the header in bytes
	 * @param numElem The number of elements in the local part
	 */
	void defineFileView(unsigned long headerSize, unsigned long numElem)
	{
		// Check header size
		MPI_Aint size;
		MPI_Type_extent(m_headerType, &size);
		if (size != headerSize)
			logError() << "Size of C struct and MPI data type do not match.";

		unsigned long align = utils::Env::get<unsigned long>("SEISSOL_CHECKPOINT_ALIGNMENT", 0);
		if (align > 0) {
			unsigned int blocks = (headerSize + align - 1) / align;
			m_headerSize = blocks * align;
		} else
			m_headerSize = headerSize;

		// Get total size of the file
		unsigned long totalSize = numTotalElems() * m_elemSize;

		// Create element type
		MPI_Datatype elemType;
		MPI_Type_contiguous(m_elemSize, MPI_BYTE, &elemType);

		// Create data file type
		int blockLength[] = {numElem, 1};
		MPI_Aint displ[] = {m_headerSize + fileOffset() * m_elemSize, totalSize};
		MPI_Datatype types[] = {elemType, MPI_UB};
		MPI_Type_create_struct(2, blockLength, displ, types, &m_fileDataType);
		MPI_Type_commit(&m_fileDataType);

		MPI_Type_free(&elemType);
		
		// Create the header file type
		if (rank() == 0) {
			int blockLength[] = {headerSize, 1};
			MPI_Aint displ[] = {0, m_headerSize};
			MPI_Datatype types[] = {MPI_BYTE, MPI_UB};
			MPI_Type_create_struct(2, blockLength, displ, types, &m_fileHeaderType);

			MPI_Type_commit(&m_fileHeaderType);
		} else
			// Only first rank write the header
			m_fileHeaderType = m_fileDataType;
	}

	bool exists()
	{
		if (!seissol::checkpoint::CheckPoint::exists())
			return false;

		MPI_File file = open();
		if (file == MPI_FILE_NULL)
			return false;

		bool hasCheckpoint = validate(file);
		MPI_File_close(&file);

		return hasCheckpoint;
	}

	/**
	 * Finalize checkpoint writing:
	 * Flush the file, update symbolic link, ...
	 */
	void finalizeCheckpoint()
	{
		EPIK_USER_REG(r_flush, "checkpoint_flush");
		SCOREP_USER_REGION_DEFINE(r_flush);
		EPIK_USER_START(r_flush);
		SCOREP_USER_REGION_BEGIN(r_flush, "checkpoint_flush", SCOREP_USER_REGION_TYPE_COMMON);

		checkMPIErr(MPI_File_sync(m_mpiFiles[odd()]));

		EPIK_USER_END(r_flush);
		SCOREP_USER_REGION_END(r_flush);
	}

	/**
	 * Open a check point file
	 *
	 * @return The MPI file handle
	 */
	MPI_File open()
	{
		MPI_File fh;

		int result = MPI_File_open(comm(), const_cast<char*>(linkFile()),
				MPI_MODE_RDONLY, MPI_INFO_NULL, &fh);
		if (result != 0) {
			logWarning() << "Could not open checkpoint file";
			return MPI_FILE_NULL;
		}

		return fh;
	}

	/**
	 * Set header file view
	 *
	 * @return The MPI error code
	 */
	int setHeaderView(MPI_File file) const
	{
		return MPI_File_set_view(file, 0, MPI_BYTE, m_fileHeaderType, "native", MPI_INFO_NULL);
	}

	/**
	 * Set data file view
	 *
	 * @return The MPI error code
	 */
	int setDataView(MPI_File file) const
	{
		return MPI_File_set_view(file, 0, MPI_BYTE, m_fileDataType, "native", MPI_INFO_NULL);
	}

	/**
	 * @return The current MPI file
	 */
	MPI_File file() const
	{
		return m_mpiFiles[odd()];
	}

	/**
	 * @return The size of the header in bytes
	 */
	unsigned long headerSize() const
	{
		return m_headerSize;
	}

	MPI_Datatype headerType() const
	{
		return m_headerType;
	}

	/**
	 * @return The identifier of the file
	 */
	unsigned long identifier() const
	{
		return m_identifier;
	}

	/**
	 * Validate an existing check point file
	 */
	virtual bool validate(MPI_File file) const = 0;

protected:
	static void checkMPIErr(int ret)
	{
		if (ret != 0) {
			char errString[MPI_MAX_ERROR_STRING+1];
			int length;
			MPI_Error_string(ret, errString, &length);
			assert(length < MPI_MAX_ERROR_STRING+1);

			errString[length] = '\0';
			logError() << "Error in the MPI checkpoint module:" << errString;
		}
	}
};

}

}

}

#endif // CHECKPOINT_MPIO_CHECK_POINT_H
