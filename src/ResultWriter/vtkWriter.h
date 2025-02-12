/**
 * @file
 * This file is part of SeisSol.
 *
 * @author Atanas Atanasov (atanasoa AT in.tum.de, http://www5.in.tum.de/wiki/index.php/Atanas_Atanasov)
 *
 * @section LICENSE
 * Copyright (c) 2013, SeisSol Group
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
 */

#ifndef VTKWRITER_H_
#define VTKWRITER_H_

#include <string>
#include "vertex_hashmap.h"
#include <stdio.h>
#include <fstream>
#include <vector>

class vtkWriter{
private:
        bool _dirCreated;

	int _number_of_cells;
	int _vertex_counter;
        double* dArraySca;
        float* fArraySca;
        bool bMagnitudeWritten[13];
        int m_offset;
        int m_iCurrent;
        int m_var_id;
        bool m_bBinary;
        bool m_bFloat64;
	std::string _fileName;
	const static std::string HEADER;
	VertexHashmap _map;
	std::ofstream _out;
	std::vector<double> _v_x;

	std::vector<double> _v_y;

	std::vector<double> _v_z;
public:
	vtkWriter(int rank,int iteration, const char* basename, int binaryoutput);
	~vtkWriter();
	void insert_vertex(double x,double y,double z);
	void write_vertices();
	void start_cell_data(int var_id);
	void end_cell_data();
	void plot_cell_data(double value);
	void plot_cells();
	void open();
	void close();
};

#endif /* VTKWRITER_H_ */
