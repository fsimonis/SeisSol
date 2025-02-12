#include "utils/args.h"
#include "utils/logger.h"

#include <netcdf.h>

#include <omp.h>

#include <algorithm>
#include <cstring>
#include <map>
#include <utility>
#include <vector>

typedef int t_vertex[3];

// Index of the vertices of a tetraedra in a cube
// even/odd, index of the tetrahedra, index of vertex, offset of the vertices in x/y/z
static const t_vertex TET_VERTICES[2][5][4] = {
		{
				{{0, 0, 0}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1}},
				{{1, 0, 0}, {0, 1, 0}, {1, 1, 1}, {1, 1, 0}},
				{{1, 0, 0}, {1, 1, 1}, {0, 0, 1}, {1, 0, 1}},
				{{0, 1, 0}, {0, 1, 1}, {0, 0, 1}, {1, 1, 1}},
				{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 1}}
		},
		{
				{{0, 0, 0}, {0, 1, 0}, {0, 1, 1}, {1, 1, 0}},
				{{0, 0, 0}, {1, 1, 0}, {1, 0, 1}, {1, 0, 0}},
				{{0, 0, 0}, {1, 0, 1}, {0, 1, 1}, {0, 0, 1}},
				{{1, 1, 0}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}},
				{{0, 0, 0}, {1, 1, 0}, {0, 1, 1}, {1, 0, 1}}
		}
};

struct Vertex
{
	t_vertex v;

	bool operator<(const Vertex& other) const {
		return (v[0] < other.v[0])
			|| ((v[0] == other.v[0]) && (v[1] < other.v[1]))
			|| ((v[0] == other.v[0]) && (v[1] == other.v[1]) && (v[2] < other.v[2]));
	}
};

static const int TET_SIDE_NEIGHBORS[2][5*4] = {
		{3, 3, 3, 0,
				1, 3, 0, 2,
				2, 2, 2, 1,
				0, 1, 3, 1,
				3, 0, 0, 2},
		{2, 3, 0, 1,
				1, 3, 3, 2,
				2, 1, 1, 0,
				0, 3, 2, 1,
				2, 0, 0, 1}
};

static const int TET_SIDE_ORIENTATIONS[2][5*4] = {
		{2, 0, 2, 0,
				0, 0, 0, 0,
				0, 0, 0, 1,
				0, 0, 0, 1,
				0, 0, 0, 0},
		{0, 1, 0, 0,
				0, 1, 0, 2,
				0, 0, 0, 2,
				0, 0, 0, 0,
				0, 0, 0, 0}
};

// Process has done i out of n rounds,
// and we want a bar of width w and resolution r.
// TODO put this i an library
static inline void loadBar(int x, int n, int r = 100, int w = 50)
{
	r = std::min(r, n);

    // Only update r times.
    if ( x % (n/r) != 0 ) return;

    // Calculuate the ratio of complete-to-incomplete.
    float ratio = x/(float)n;
    int   c     = ratio * w;

    // Show the percentage complete.
    std::cout << std::setw(3) << (int)(ratio*100) << "% [";

    // Show the load bar.
    for (int x=0; x<c; x++)
       std::cout << '=';

    for (int x=c; x<w; x++)
       std::cout << ' ';

    std::cout << ']';

    if (x != n)
        // go to the beginning of the line
    	std::cout << '\r';
    else
    	std::cout << '\n';

    std::cout << std::flush;
}

static const char* dim2str(unsigned int dim)
{
	switch (dim) {
	case 0:
		return "x";
	case 1:
		return "y";
	case 2:
		return "z";
	default:
		;
	}

	logError() << "Invalid dimension";
	return "invalid"; // Never reached
}

template<typename A, typename B>
std::pair<B,A> flip_pair(const std::pair<A,B> &p)
{
    return std::pair<B,A>(p.second, p.first);
}

void checkNcError(int error)
{
	if (error != NC_NOERR)
		logError() << "Error while writing netCDF file:" << nc_strerror(error);
}

int main(int argc, char* argv[])
{
	// Parse command line arguments
	utils::Args args;
	args.addOption("boundary", 'b', "boundary condition (default: 1)", utils::Args::Required, false);
	args.addOption("netcdf", 'n', "for compatibility with the Python script", utils::Args::No, false);
	args.addOption("x", 'x', "number of cubes in x dimension");
	args.addOption("y", 'y', "number of cubes in y dimension");
	args.addOption("z", 'z', "number of cubes in z dimension");
	args.addOption("px", 0, "number of partitions x dimension");
	args.addOption("py", 0, "number of partitions y dimension");
	args.addOption("pz", 0, "number of partitions z dimension");
	args.addOption("output", 'o', "output file for resulting netCDF mesh");
  args.addOption("scale", 's', "size of the domain = [-s/2, s/2]^3 (default: 100)", utils::Args::Required, false);

	unsigned int numCubes[4];
	unsigned int numPartitions[4];

	// Parse/check command line arguments
	if (args.parse(argc, argv) == utils::Args::Success) {
		numCubes[0] = args.getArgument<unsigned int>("x");
		numCubes[1] = args.getArgument<unsigned int>("y");
		numCubes[2] = args.getArgument<unsigned int>("z");

		numPartitions[0] = args.getArgument<unsigned int>("px");
		numPartitions[1] = args.getArgument<unsigned int>("py");
		numPartitions[2] = args.getArgument<unsigned int>("pz");

		for (int i = 0; i < 3; i++) {
			if (numCubes[i] < 2)
				logError() << "Number of cubes in" << dim2str(i) << "dimension must be at least 2";
			if (numCubes[i] % numPartitions[i] != 0)
				logError() << "Number of cubes in" << dim2str(i)
					<< "dimension can not be distribute to" << numPartitions[i] << "partitions";
			if ((numCubes[i] / numPartitions[i]) % 2 != 0)
				logError() << "Number of cubes per partition in" << dim2str(i) << "dimension must be a multiple of 2";
		}
	} else {
		return 1;
	}

	unsigned int boundary = args.getArgument("boundary", 1u);
	if (boundary > 100)
		boundary -= 100;
	logInfo() << "Boundary condition:" << boundary;

	// Compute additional sizes
	numCubes[3] = numCubes[0] * numCubes[1] * numCubes[2];
	numPartitions[3] = numPartitions[0] * numPartitions[1] * numPartitions[2];

	unsigned int numCubesPerPart[4];
	unsigned long numElemPerPart[4];
	for (int i = 0; i < 4; i++) {
		numCubesPerPart[i] = numCubes[i] / numPartitions[i];
		numElemPerPart[i] = numCubesPerPart[i] * 5;
	}

	unsigned int numVrtxPerPart[4];
	for (int i = 0; i < 3; i++)
		numVrtxPerPart[i] = numCubesPerPart[i] + 1;
	numVrtxPerPart[3] = numVrtxPerPart[0] * numVrtxPerPart[1] * numVrtxPerPart[2];

	unsigned int numBndElements[3];
	numBndElements[0] = 2*numCubesPerPart[1]*numCubesPerPart[2];
	numBndElements[1] = 2*numCubesPerPart[0]*numCubesPerPart[2];
	numBndElements[2] = 2*numCubesPerPart[0]*numCubesPerPart[1];

	logInfo() << "Total number of cubes:" << numCubes[0] << 'x' << numCubes[1] << 'x' << numCubes[2] << '=' << numCubes[3];
	logInfo() << "Total number of partitions" << numPartitions[0] << 'x' << numPartitions[1] << 'x' << numPartitions[2]
	        << '=' << numPartitions[3];
	logInfo() << "Total number of cubes per partition:" << numCubesPerPart[0] << 'x' << numCubesPerPart[1] << 'x'
			<< numCubesPerPart[2] << '=' << numCubesPerPart[3];
	logInfo() << "Total number of elements per partition:" << numElemPerPart[0] << 'x' << numElemPerPart[1] << 'x'
			<< numElemPerPart[2] << '=' << numElemPerPart[3];
	logInfo() << "Using" << omp_get_max_threads() << "threads";

	int netcdf_writes = 2 + numPartitions[3]*8;

	// Create the netcdf file
	int ncFile;
	checkNcError(nc_create(args.getArgument<std::string>("output").c_str(), NC_NETCDF4, &ncFile));

	int ncDimDimension;
	nc_def_dim(ncFile, "dimension", 3, &ncDimDimension);

	int ncDimPart;
	nc_def_dim(ncFile, "partitions", numPartitions[3], &ncDimPart);

	int ncDimElem, ncDimElemSides, ncDimElemVertices;
	nc_def_dim(ncFile, "elements", numElemPerPart[3], &ncDimElem);
	nc_def_dim(ncFile, "element_sides", 4, &ncDimElemSides);
	nc_def_dim(ncFile, "element_vertices_dim", 4, &ncDimElemVertices);

	int ncDimVrtx;
	nc_def_dim(ncFile, "vertices", numVrtxPerPart[3], &ncDimVrtx);

	int ncDimBnd, ncDimBndElem;
	nc_def_dim(ncFile, "boundaries", 6, &ncDimBnd);
	nc_def_dim(ncFile, "boundary_elements", *std::max_element(numBndElements, numBndElements+3), &ncDimBndElem);

	// Create netcdf variables
	int ncVarElemSize;
	checkNcError(nc_def_var(ncFile, "element_size", NC_INT, 1, &ncDimPart, &ncVarElemSize));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemSize, NC_COLLECTIVE));

	int ncVarElemVertices;
	int dimsElemVertices[] = {ncDimPart, ncDimElem, ncDimElemVertices};
	checkNcError(nc_def_var(ncFile, "element_vertices", NC_INT, 3, dimsElemVertices, &ncVarElemVertices));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemVertices, NC_COLLECTIVE));

	int ncVarElemNeighbors;
	int dimsElemSides[] = {ncDimPart, ncDimElem, ncDimElemSides};
	checkNcError(nc_def_var(ncFile, "element_neighbors", NC_INT, 3, dimsElemSides, &ncVarElemNeighbors));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemNeighbors, NC_COLLECTIVE));

	int ncVarElemBoundaries;
	checkNcError(nc_def_var(ncFile, "element_boundaries", NC_INT, 3, dimsElemSides, &ncVarElemBoundaries));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemBoundaries, NC_COLLECTIVE));

	int ncVarElemNeighborSides;
	checkNcError(nc_def_var(ncFile, "element_neighbor_sides", NC_INT, 3, dimsElemSides, &ncVarElemNeighborSides));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemNeighborSides, NC_COLLECTIVE));

	int ncVarElemSideOrientations;
	checkNcError(nc_def_var(ncFile, "element_side_orientations", NC_INT, 3, dimsElemSides, &ncVarElemSideOrientations));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemSideOrientations, NC_COLLECTIVE));

	int ncVarElemNeighborRanks;
	checkNcError(nc_def_var(ncFile, "element_neighbor_ranks", NC_INT, 3, dimsElemSides, &ncVarElemNeighborRanks));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemNeighborRanks, NC_COLLECTIVE));

	int ncVarElemMPIIndices;
	checkNcError(nc_def_var(ncFile, "element_mpi_indices", NC_INT, 3, dimsElemSides, &ncVarElemMPIIndices));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemMPIIndices, NC_COLLECTIVE));

	int ncVarElemGroup;
	checkNcError(nc_def_var(ncFile, "element_group", NC_INT, 2, dimsElemSides, &ncVarElemGroup));
//	checkNcError(nc_var_par_access(ncFile, ncVarElemGroup, NC_COLLECTIVE));

	int ncVarVrtxSize;
	checkNcError(nc_def_var(ncFile, "vertex_size", NC_INT, 1, &ncDimPart, &ncVarVrtxSize));
//	checkNcError(nc_var_par_access(ncFile, ncVarVrtxSize, NC_COLLECTIVE));

	int ncVarVrtxCoords;
	int dimsVrtxCoords[] = {ncDimPart, ncDimVrtx, ncDimDimension};
	checkNcError(nc_def_var(ncFile, "vertex_coordinates", NC_DOUBLE, 3, dimsVrtxCoords, &ncVarVrtxCoords));
//	checkNcError(nc_var_par_access(ncFile, ncVarVrtxCoords, NC_COLLECTIVE));

	int ncVarBndSize;
	checkNcError(nc_def_var(ncFile, "boundary_size", NC_INT, 1, &ncDimPart, &ncVarBndSize));
//	checkNcError(nc_var_par_access(ncFile, ncVarBndSize, NC_COLLECTIVE));

	int ncVarBndElemSize;
	int dimsBndElemSize[] = {ncDimPart, ncDimBnd};
	checkNcError(nc_def_var(ncFile, "boundary_element_size", NC_INT, 2, dimsBndElemSize, &ncVarBndElemSize));
//	checkNcError(nc_var_par_access(ncFile, ncVarBndElemSize, NC_COLLECTIVE));

	int ncVarBndElemRank;
	checkNcError(nc_def_var(ncFile, "boundary_element_rank", NC_INT, 2, dimsBndElemSize, &ncVarBndElemRank));
//	checkNcError(nc_var_par_access(ncFile, ncVarBndElemRank, NC_COLLECTIVE));

	int ncVarBndElemLocalIds;
	int dimsBndElemLocalIds[] = {ncDimPart, ncDimBnd, ncDimBndElem};
	checkNcError(nc_def_var(ncFile, "boundary_element_localids", NC_INT, 3, dimsBndElemLocalIds, &ncVarBndElemLocalIds));
//	checkNcError(nc_var_par_access(ncFile, ncVarBndElemLocalIds, NC_COLLECTIVE));

	int writes_done = 0;
	loadBar(writes_done, netcdf_writes);

	// Elements
	int *elemSize = new int[numPartitions[3]];
	std::fill(elemSize, elemSize+numPartitions[3], numElemPerPart[3]);
	checkNcError(nc_put_var_int(ncFile, ncVarElemSize, elemSize));
	delete [] elemSize;
	writes_done++; loadBar(writes_done, netcdf_writes);

	std::vector<Vertex> vertices;
	vertices.resize(numElemPerPart[3]*4);
	#pragma omp parallel for
	for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
		for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
			for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
				unsigned int c = ((zz*numCubesPerPart[1] + yy)*numCubesPerPart[0] + xx) * 20;
				int odd = (zz+yy+xx) % 2;

				for (unsigned int i = 0; i < 5; i++) {
					for (unsigned int j = 0; j < 4; j++) {
						Vertex v;
						v.v[0] = TET_VERTICES[odd][i][j][0] + xx;
						v.v[1] = TET_VERTICES[odd][i][j][1] + yy;
						v.v[2] = TET_VERTICES[odd][i][j][2] + zz;
						vertices[c] = v;
						c++;
					}
				}
			}
		}
	}

	int *elemVertices = new int[numElemPerPart[3]*4];
	std::map<Vertex, int> vertexMap;
	for (unsigned int i = 0; i < vertices.size(); i++) {
		std::map<Vertex, int>::iterator it = vertexMap.find(vertices[i]);
		if (it != vertexMap.end()) {
			elemVertices[i] = it->second;
		} else {
			int n = vertexMap.size();
			vertexMap[vertices[i]] = n;
			elemVertices[i] = n;
		}
	}

	for (unsigned int i = 0; i < numPartitions[3]; i++) {
		size_t start[3] = {i, 0, 0};
		size_t count[3] = {1, numElemPerPart[3], 4};
		checkNcError(nc_put_vara_int(ncFile, ncVarElemVertices, start, count, elemVertices));
		writes_done++; loadBar(writes_done, netcdf_writes);
	}
	delete [] elemVertices;

	int *elemNeighbors = new int[numElemPerPart[3]*4];
	const int TET_NEIGHBORS[2][5*4] = {
			{-numCubesPerPart[1]*numCubesPerPart[0]*5+2, -numCubesPerPart[0]*5, -4, 4,
					4, -numCubesPerPart[1]*numCubesPerPart[0]*5+3, 5, numCubesPerPart[0]*5+1,
					4, 7, -numCubesPerPart[0]*5+3, numCubesPerPart[1]*numCubesPerPart[0]*5+1,
					-2, numCubesPerPart[0]*5+2, 4, numCubesPerPart[1]*numCubesPerPart[0]*5,
					0, 1, 2, 3},
			{-4, -numCubesPerPart[1]*numCubesPerPart[0]*5+3, 4, numCubesPerPart[0]*5,
					4, -numCubesPerPart[1]*numCubesPerPart[0]*5+2, -numCubesPerPart[0]*5+1, 5,
					4, -numCubesPerPart[0]*5+3, -3, numCubesPerPart[1]*numCubesPerPart[0]*5,
					8, 4, numCubesPerPart[0]*5+2, numCubesPerPart[1]*numCubesPerPart[0]*5+1,
					0, 1, 2, 3}
	};

	#pragma omp parallel for
	for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
		for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
			for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
				unsigned int c = ((zz*numCubesPerPart[1] + yy)*numCubesPerPart[0] + xx) * 20;
				int odd = (zz+yy+xx) % 2;

				memcpy(&elemNeighbors[c], TET_NEIGHBORS[odd], sizeof(int)*20);
				int offset = ((zz*numCubesPerPart[1] + yy)*numCubesPerPart[0] + xx)*5;
				for (int i = 0; i < 20; i++)
					elemNeighbors[c+i] += offset;

				if (xx == 0) {
					if (odd) {
						if (boundary == 6 && numPartitions[0] == 1) {
							elemNeighbors[c] += numCubesPerPart[0]*5;
							elemNeighbors[c+10] += numCubesPerPart[0]*5;
						} else {
							elemNeighbors[c] = numElemPerPart[3];
							elemNeighbors[c+10] = numElemPerPart[3];
						}
					} else {
						if (boundary == 6 && numPartitions[0] == 1) {
							elemNeighbors[c+2] += numCubesPerPart[0]*5;
							elemNeighbors[c+12] += numCubesPerPart[0]*5;
						} else {
							elemNeighbors[c+2] = numElemPerPart[3];
							elemNeighbors[c+12] = numElemPerPart[3];
						}
					}
				} else if (xx == numCubesPerPart[0]-1) {
					if (odd) {
						if (boundary == 6 && numPartitions[0] == 1) {
							elemNeighbors[c+7] -= numCubesPerPart[0]*5;
							elemNeighbors[c+12] -= numCubesPerPart[0]*5;
						} else {
							elemNeighbors[c+7] = numElemPerPart[3];
							elemNeighbors[c+12] = numElemPerPart[3];
						}
					} else {
						if (boundary == 6 && numPartitions[0] == 1) {
							elemNeighbors[c+6] -= numCubesPerPart[0]*5;
							elemNeighbors[c+9] -= numCubesPerPart[0]*5;
						} else {
							elemNeighbors[c+6] = numElemPerPart[3];
							elemNeighbors[c+9] = numElemPerPart[3];
						}
					}
				}
				if (yy == 0) {
					if (odd) {
						if (boundary == 6 && numPartitions[1] == 1) {
							elemNeighbors[c+6] += numCubesPerPart[0]*numCubesPerPart[1]*5;
							elemNeighbors[c+9] += numCubesPerPart[0]*numCubesPerPart[1]*5;
						} else {
							elemNeighbors[c+6] = numElemPerPart[3];
							elemNeighbors[c+9] = numElemPerPart[3];
						}
					} else {
						if (boundary == 6 && numPartitions[1] == 1) {
							elemNeighbors[c+1] += numCubesPerPart[0]*numCubesPerPart[1]*5;
							elemNeighbors[c+10] += numCubesPerPart[0]*numCubesPerPart[1]*5;
						} else {
							elemNeighbors[c+1] = numElemPerPart[3];
							elemNeighbors[c+10] = numElemPerPart[3];
						}
					}
				} else if (yy == numCubesPerPart[1]-1) {
					if (odd) {
						if (boundary == 6 && numPartitions[1] == 1) {
							elemNeighbors[c+3] -= numCubesPerPart[0]*numCubesPerPart[1]*5;
							elemNeighbors[c+14] -= numCubesPerPart[0]*numCubesPerPart[1]*5;
						} else {
							elemNeighbors[c+3] = numElemPerPart[3];
							elemNeighbors[c+14] = numElemPerPart[3];
						}
					} else {
						if (boundary == 6 && numPartitions[1] == 1) {
							elemNeighbors[c+7] -= numCubesPerPart[0]*numCubesPerPart[1]*5;
							elemNeighbors[c+13] -= numCubesPerPart[0]*numCubesPerPart[1]*5;
						} else {
							elemNeighbors[c+7] = numElemPerPart[3];
							elemNeighbors[c+13] = numElemPerPart[3];
						}
					}
				}
				if (zz == 0) {
					if (odd) {
						if (boundary == 6 && numPartitions[2] == 1) {
							elemNeighbors[c+1] += numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
							elemNeighbors[c+5] += numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
						} else {
							elemNeighbors[c+1] = numElemPerPart[3];
							elemNeighbors[c+5] = numElemPerPart[3];
						}
					} else {
						if (boundary == 6 && numPartitions[2] == 1) {
							elemNeighbors[c] += numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
							elemNeighbors[c+5] += numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
						} else {
							elemNeighbors[c] = numElemPerPart[3];
							elemNeighbors[c+5] = numElemPerPart[3];
						}
					}
				} else if (zz == numCubesPerPart[2]-1) {
					if (odd) {
						if (boundary == 6 && numPartitions[2] == 1) {
							elemNeighbors[c+11] -= numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
							elemNeighbors[c+15] -= numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
						} else {
							elemNeighbors[c+11] = numElemPerPart[3];
							elemNeighbors[c+15] = numElemPerPart[3];
						}
					} else {
						if (boundary == 6 && numPartitions[2] == 1) {
							elemNeighbors[c+11] -= numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
							elemNeighbors[c+15] -= numCubesPerPart[0]*numCubesPerPart[1]*numCubesPerPart[2]*5;
						} else {
							elemNeighbors[c+11] = numElemPerPart[3];
							elemNeighbors[c+15] = numElemPerPart[3];
						}
					}
				}
			}
		}
	}

	for (unsigned int i = 0; i < numPartitions[3]; i++) {
		size_t start[3] = {i, 0, 0};
		size_t count[3] = {1, numElemPerPart[3], 4};
		checkNcError(nc_put_vara_int(ncFile, ncVarElemNeighbors, start, count, elemNeighbors));
		writes_done++; loadBar(writes_done, netcdf_writes);
	}
	delete [] elemNeighbors;

	int *elemBoundaries = new int[numElemPerPart[3]*4];
	for (unsigned int z = 0; z < numPartitions[2]; z++) {
		for (unsigned int y = 0; y < numPartitions[1]; y++) {
			for (unsigned int x = 0; x < numPartitions[0]; x++) {
				memset(elemBoundaries, 0, sizeof(int)*numElemPerPart[3]*4);

				if (x == 0) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy) % 2;
							if (odd) {
								elemBoundaries[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20] = boundary;
								elemBoundaries[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 10] = boundary;
							} else {
								elemBoundaries[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 2] = boundary;
								elemBoundaries[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 12] = boundary;
							}
						}
					}
				}
				if (x == numPartitions[0]-1) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy+1) % 2;
							if (odd) {
								elemBoundaries[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 7] = boundary;
								elemBoundaries[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 12] = boundary;
							} else {
								elemBoundaries[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 6] = boundary;
								elemBoundaries[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 9] = boundary;
							}
						}
					}
				}
				if (y == 0) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx) % 2;
							if (odd) {
								elemBoundaries[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 6] = boundary;
								elemBoundaries[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 9] = boundary;
							} else {
								elemBoundaries[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 1] = boundary;
								elemBoundaries[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 10] = boundary;
							}
						}
					}
				}
				if (y == numPartitions[1]-1) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx+1) % 2;
							if (odd) {
								elemBoundaries[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 3] = boundary;
								elemBoundaries[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 14] = boundary;
							} else {
								elemBoundaries[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 7] = boundary;
								elemBoundaries[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 13] = boundary;
							}
						}
					}
				}
				if (z == 0) {
					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (yy+xx) % 2;
							if (odd) {
								elemBoundaries[(yy*numCubesPerPart[0]+xx) * 20 + 1] = boundary;
								elemBoundaries[(yy*numCubesPerPart[0]+xx) * 20 + 5] = boundary;
							} else {
								elemBoundaries[(yy*numCubesPerPart[0]+xx) * 20] = boundary;
								elemBoundaries[(yy*numCubesPerPart[0]+xx) * 20 + 5] = boundary;
							}
						}
					}
				}
				if (z == numPartitions[2]-1) {
					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (yy+xx+1) % 2;
//							if (odd) {
								elemBoundaries[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = boundary;
								elemBoundaries[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = boundary;
//							} else {
//								elemBoundaries[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = boundary;
//								elemBoundaries[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = boundary;
//							}
						}
					}
				}

				size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, 0, 0};
				size_t count[3] = {1, numElemPerPart[3], 4};
				checkNcError(nc_put_vara_int(ncFile, ncVarElemBoundaries, start, count, elemBoundaries));
				writes_done++; loadBar(writes_done, netcdf_writes);
			}
		}
	}
	delete [] elemBoundaries;

	int *elemNeighborSides = new int[numElemPerPart[3]*4];
	int *elemNeighborSidesDef = new int[numElemPerPart[3]*4];
	#pragma omp parallel for
	for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
		for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
			for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
				int odd = (zz+yy+xx) % 2;
				unsigned int c = ((zz*numCubesPerPart[1] + yy)*numCubesPerPart[0] + xx) * 20;
				memcpy(&elemNeighborSidesDef[c], TET_SIDE_NEIGHBORS[odd], sizeof(int)*20);
			}
		}
	}

	for (unsigned int z = 0; z < numPartitions[2]; z++) {
		for (unsigned int y = 0; y < numPartitions[1]; y++) {
			for (unsigned int x = 0; x < numPartitions[0]; x++) {
				memcpy(elemNeighborSides, elemNeighborSidesDef, sizeof(int)*numElemPerPart[3]*4);

				if (boundary != 6 && x == 0) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy) % 2;
							if (odd) {
								elemNeighborSides[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20] = 0;
								elemNeighborSides[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 10] = 0;
							} else {
								elemNeighborSides[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 2] = 0;
								elemNeighborSides[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 12] = 0;
							}
						}
					}
				}
				if (boundary != 6 && x == numPartitions[0]-1) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy+1) % 2;
							if (odd) {
								elemNeighborSides[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 7] = 0;
								elemNeighborSides[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 12] = 0;
							} else {
								elemNeighborSides[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 6] = 0;
								elemNeighborSides[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 9] = 0;
							}
						}
					}
				}
				if (boundary != 6 && y == 0) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx) % 2;
							if (odd) {
								elemNeighborSides[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 6] = 0;
								elemNeighborSides[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 9] = 0;
							} else {
								elemNeighborSides[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 1] = 0;
								elemNeighborSides[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 10] = 0;
							}
						}
					}
				}
				if (boundary != 6 && y == numPartitions[1]-1) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx+1) % 2;
							if (odd) {
								elemNeighborSides[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 3] = 0;
								elemNeighborSides[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 14] = 0;
							} else {
								elemNeighborSides[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 7] = 0;
								elemNeighborSides[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 13] = 0;
							}
						}
					}
				}
				if (boundary != 6 && z == 0) {
					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (yy+xx) % 2;
							if (odd) {
								elemNeighborSides[(yy*numCubesPerPart[0]+xx) * 20 + 1] = 0;
								elemNeighborSides[(yy*numCubesPerPart[0]+xx) * 20 + 5] = 0;
							} else {
								elemNeighborSides[(yy*numCubesPerPart[0]+xx) * 20] = 0;
								elemNeighborSides[(yy*numCubesPerPart[0]+xx) * 20 + 5] = 0;
							}
						}
					}
				}
				if (boundary != 6 && z == numPartitions[2]-1) {
					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (yy+xx+1) % 2;
//							if (odd) {
								elemNeighborSides[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = 0;
								elemNeighborSides[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = 0;
//							} else {
//								elemSideNeighbors[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = 0;
//								elemSideNeighbors[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = 0;
//							}
						}
					}
				}

				size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, 0, 0};
				size_t count[3] = {1, numElemPerPart[3], 4};
				checkNcError(nc_put_vara_int(ncFile, ncVarElemNeighborSides, start, count, elemNeighborSides));
				writes_done++; loadBar(writes_done, netcdf_writes);
			}
		}
	}
	delete [] elemNeighborSides;
	delete [] elemNeighborSidesDef;

	int *elemSideOrientations = new int[numElemPerPart[3]*4];
	int *elemSideOrientationsDef = new int[numElemPerPart[3]*4];
	#pragma omp parallel for
	for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
		for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
			for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
				int odd = (zz+yy+xx) % 2;
				unsigned int c = ((zz*numCubesPerPart[1] + yy)*numCubesPerPart[0] + xx) * 20;
				memcpy(&elemSideOrientationsDef[c], TET_SIDE_ORIENTATIONS[odd], sizeof(int)*20);
			}
		}
	}

	for (unsigned int z = 0; z < numPartitions[2]; z++) {
		for (unsigned int y = 0; y < numPartitions[1]; y++) {
			for (unsigned int x = 0; x < numPartitions[0]; x++) {
				memcpy(elemSideOrientations, elemSideOrientationsDef, sizeof(int)*numElemPerPart[3]*4);

				if (boundary != 6 && x == 0) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy) % 2;
							if (odd) {
								elemSideOrientations[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20] = 0;
								elemSideOrientations[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 10] = 0;
							} else {
								elemSideOrientations[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 2] = 0;
								elemSideOrientations[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 12] = 0;
							}
						}
					}
				}
				if (boundary != 6 && x == numPartitions[0]-1) {
					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy+1) % 2;
							if (odd) {
								elemSideOrientations[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 7] = 0;
								elemSideOrientations[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 12] = 0;
							} else {
								elemSideOrientations[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 6] = 0;
								elemSideOrientations[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 9] = 0;
							}
						}
					}
				}
				// There are zero anyway
//				if (boundary != 6 && y == 0) {
//					#pragma omp parallel for
//					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
//						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (zz+xx) % 2;
//							if (odd) {
//								elemSideOrientations[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 6] = 0;
//								elemSideOrientations[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 9] = 0;
//							} else {
//								elemSideOrientations[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 1] = 0;
//								elemSideOrientations[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 10] = 0;
//							}
//						}
//					}
//				}
//				if (boundary != 6 && y == numPartitions[1]-1) {
//					#pragma omp parallel for
//					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
//						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (zz+xx+1) % 2;
//							if (odd) {
//								elemSideOrientations[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 3] = 0;
//								elemSideOrientations[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 14] = 0;
//							} else {
//								elemSideOrientations[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 7] = 0;
//								elemSideOrientations[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 13] = 0;
//							}
//						}
//					}
//				}
				if (boundary != 6 && z == 0) {
					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (yy+xx) % 2;
							if (odd) {
								elemSideOrientations[(yy*numCubesPerPart[0]+xx) * 20 + 1] = 0;
								elemSideOrientations[(yy*numCubesPerPart[0]+xx) * 20 + 5] = 0;
							} else {
								elemSideOrientations[(yy*numCubesPerPart[0]+xx) * 20] = 0;
								elemSideOrientations[(yy*numCubesPerPart[0]+xx) * 20 + 5] = 0;
							}
						}
					}
				}
				if (boundary != 6 && z == numPartitions[2]-1) {
					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (yy+xx+1) % 2;
//							if (odd) {
								elemSideOrientations[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = 0;
								elemSideOrientations[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = 0;
//							} else {
//								elemSideOrientations[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = 0;
//								elemSideOrientations[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = 0;
//							}
						}
					}
				}

				size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, 0, 0};
				size_t count[3] = {1, numElemPerPart[3], 4};
				checkNcError(nc_put_vara_int(ncFile, ncVarElemSideOrientations, start, count, elemSideOrientations));
				writes_done++; loadBar(writes_done, netcdf_writes);
			}
		}
	}
	delete [] elemSideOrientations;
	delete [] elemSideOrientationsDef;

	int *elemNeighborRanks = new int[numElemPerPart[3]*4];

	for (unsigned int z = 0; z < numPartitions[2]; z++) {
		for (unsigned int y = 0; y < numPartitions[1]; y++) {
			for (unsigned int x = 0; x < numPartitions[0]; x++) {
				int myrank = (z*numPartitions[1] + y)*numPartitions[0] + x;

				std::fill(elemNeighborRanks, elemNeighborRanks+numElemPerPart[3]*4, myrank);

				if ((boundary == 6 && numPartitions[0] > 1) || x != 0) {
					int rank = (z*numPartitions[1] + y)*numPartitions[0] + (x-1+numPartitions[0])%numPartitions[0];

					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy) % 2;
							if (odd) {
								elemNeighborRanks[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20] = rank;
								elemNeighborRanks[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 10] = rank;
							} else {
								elemNeighborRanks[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 2] = rank;
								elemNeighborRanks[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 12] = rank;
							}
						}
					}
				}
				if ((boundary == 6 && numPartitions[0] > 1) || x != numPartitions[0]-1) {
					int rank = (z*numPartitions[1] + y)*numPartitions[0] + (x+1)%numPartitions[0];

					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy+1) % 2;
							if (odd) {
								elemNeighborRanks[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 7] = rank;
								elemNeighborRanks[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 12] = rank;
							} else {
								elemNeighborRanks[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 6] = rank;
								elemNeighborRanks[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 9] = rank;
							}
						}
					}
				}
				if ((boundary == 6 && numPartitions[1] > 1) || y != 0) {
					int rank = (z*numPartitions[1] + (y-1+numPartitions[1])%numPartitions[1])*numPartitions[0] + x;

					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx) % 2;
							if (odd) {
								elemNeighborRanks[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 6] = rank;
								elemNeighborRanks[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 9] = rank;
							} else {
								elemNeighborRanks[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 1] = rank;
								elemNeighborRanks[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 10] = rank;
							}
						}
					}
				}
				if ((boundary == 6 && numPartitions[1] > 1) || y != numPartitions[1]-1) {
					int rank = (z*numPartitions[1] + (y+1)%numPartitions[1])*numPartitions[0] + x;

					#pragma omp parallel for
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx+1) % 2;
							if (odd) {
								elemNeighborRanks[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 3] = rank;
								elemNeighborRanks[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 14] = rank;
							} else {
								elemNeighborRanks[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 7] = rank;
								elemNeighborRanks[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 13] = rank;
							}
						}
					}
				}
				if ((boundary == 6 && numPartitions[2] > 1) || z != 0) {
					int rank = (((z-1+numPartitions[2])%numPartitions[2])*numPartitions[1] + y)*numPartitions[0] + x;

					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (yy+xx) % 2;
							if (odd) {
								elemNeighborRanks[(yy*numCubesPerPart[0]+xx) * 20 + 1] = rank;
								elemNeighborRanks[(yy*numCubesPerPart[0]+xx) * 20 + 5] = rank;
							} else {
								elemNeighborRanks[(yy*numCubesPerPart[0]+xx) * 20] = rank;
								elemNeighborRanks[(yy*numCubesPerPart[0]+xx) * 20 + 5] = rank;
							}
						}
					}
				}
				if ((boundary == 6 && numPartitions[2] > 1) || z != numPartitions[2]-1) {
					int rank = (((z+1)%numPartitions[2])*numPartitions[1] + y)*numPartitions[0] + x;

					#pragma omp parallel for
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (yy+xx+1) % 2;
//							if (odd) {
								elemNeighborRanks[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = rank;
								elemNeighborRanks[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = rank;
//							} else {
//								elemNeighborRanks[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = rank;
//								elemNeighborRanks[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = rank;
//							}
						}
					}
				}

				size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, 0, 0};
				size_t count[3] = {1, numElemPerPart[3], 4};
				checkNcError(nc_put_vara_int(ncFile, ncVarElemNeighborRanks, start, count, elemNeighborRanks));
				writes_done++; loadBar(writes_done, netcdf_writes);
			}
		}
	}
	delete [] elemNeighborRanks;

	int *elemMPIIndices = new int[numElemPerPart[3]*4];
	int *bndLocalIds = new int[*std::max_element(numBndElements, numBndElements+3)];

	for (unsigned int z = 0; z < numPartitions[2]; z++) {
		for (unsigned int y = 0; y < numPartitions[1]; y++) {
			for (unsigned int x = 0; x < numPartitions[0]; x++) {
				memset(elemMPIIndices, 0, sizeof(int)*numElemPerPart[3]*4);

				int bndSize = 0;

				if ((boundary == 6 && numPartitions[2] > 1) || z != 0) {
					int nextMPIIndex = 0;
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (yy+xx) % 2;
							if (odd) {
								bndLocalIds[nextMPIIndex] = (yy*numCubesPerPart[0]+xx) * 5 + 1;
								elemMPIIndices[(yy*numCubesPerPart[0]+xx) * 20 + 5] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (yy*numCubesPerPart[0]+xx) * 5;
								elemMPIIndices[(yy*numCubesPerPart[0]+xx) * 20 + 1] = nextMPIIndex++;
							} else {
								bndLocalIds[nextMPIIndex] = (yy*numCubesPerPart[0]+xx) * 5;
								elemMPIIndices[(yy*numCubesPerPart[0]+xx) * 20] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (yy*numCubesPerPart[0]+xx) * 5 + 1;
								elemMPIIndices[(yy*numCubesPerPart[0]+xx) * 20 + 5] = nextMPIIndex++;
							}
						}
					}

					size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, bndSize, 0};
					size_t count[3] = {1, 1, nextMPIIndex};
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemSize, start, &nextMPIIndex));
					int rank = (((z-1+numPartitions[2])%numPartitions[2])*numPartitions[1] + y)*numPartitions[0] + x;
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemRank, start, &rank));
					checkNcError(nc_put_vara_int(ncFile, ncVarBndElemLocalIds, start, count, bndLocalIds));

					bndSize++;
				}
				if ((boundary == 6 && numPartitions[1] > 1) || y != 0) {
					int nextMPIIndex = 0;
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx) % 2;
							if (odd) {
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 5 + 1;
								elemMPIIndices[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 6] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 5 + 2;
								elemMPIIndices[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 9] = nextMPIIndex++;
							} else {
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 5;
								elemMPIIndices[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 1] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 5 + 2;
								elemMPIIndices[(zz*numCubesPerPart[1]*numCubesPerPart[0]+xx) * 20 + 10] = nextMPIIndex++;
							}
						}
					}

					size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, bndSize, 0};
					size_t count[3] = {1, 1, nextMPIIndex};
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemSize, start, &nextMPIIndex));
					int rank = (z*numPartitions[1] + (y-1+numPartitions[1])%numPartitions[1])*numPartitions[0] + x;
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemRank, start, &rank));
					checkNcError(nc_put_vara_int(ncFile, ncVarBndElemLocalIds, start, count, bndLocalIds));

					bndSize++;
				}
				if ((boundary == 6 && numPartitions[0] > 1) || x != 0) {
					int nextMPIIndex = 0;
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy) % 2;
							if (odd) {
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 5;
								elemMPIIndices[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 5 + 2;
								elemMPIIndices[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 10] = nextMPIIndex++;
							} else {
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 5;
								elemMPIIndices[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 2] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 5 + 3;
								elemMPIIndices[(zz*numCubesPerPart[1]+yy)*numCubesPerPart[0] * 20 + 12] = nextMPIIndex++;
							}
						}
					}

					size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, bndSize, 0};
					size_t count[3] = {1, 1, nextMPIIndex};
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemSize, start, &nextMPIIndex));
					int rank = (z*numPartitions[1] + y)*numPartitions[0] + (x-1+numPartitions[0])%numPartitions[0];
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemRank, start, &rank));
					checkNcError(nc_put_vara_int(ncFile, ncVarBndElemLocalIds, start, count, bndLocalIds));

					bndSize++;
				}
				if ((boundary == 6 && numPartitions[0] > 1) || x != numPartitions[0]-1) {
					int nextMPIIndex = 0;
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
							int odd = (zz+yy+1) % 2;
							if (odd) {
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 5 + 1;
								elemMPIIndices[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 7] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 5 + 3;
								elemMPIIndices[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 12] = nextMPIIndex++;
							} else {
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 5 + 1;
								elemMPIIndices[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 6] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 5 + 2;
								elemMPIIndices[((zz*numCubesPerPart[1]+yy)*numCubesPerPart[0]+numCubesPerPart[0]-1) * 20 + 9] = nextMPIIndex++;
							}
						}
					}

					size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, bndSize, 0};
					size_t count[3] = {1, 1, nextMPIIndex};
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemSize, start, &nextMPIIndex));
					int rank = (z*numPartitions[1] + y)*numPartitions[0] + (x+1)%numPartitions[0];
					rank = (rank + numPartitions[3]) % numPartitions[3];
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemRank, start, &rank));
					checkNcError(nc_put_vara_int(ncFile, ncVarBndElemLocalIds, start, count, bndLocalIds));

					bndSize++;
				}
				if ((boundary == 6 && numPartitions[1] > 1) || y != numPartitions[1]-1) {
					int nextMPIIndex = 0;
					for (unsigned int zz = 0; zz < numCubesPerPart[2]; zz++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
							int odd = (zz+xx+1) % 2;
							if (odd) {
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 5;
								elemMPIIndices[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 3] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 5 + 3;
								elemMPIIndices[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 14] = nextMPIIndex++;
							} else {
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 5 + 1;
								elemMPIIndices[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 7] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = ((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 5 + 3;
								elemMPIIndices[((zz*numCubesPerPart[1]+numCubesPerPart[1]-1)*numCubesPerPart[0]+xx) * 20 + 13] = nextMPIIndex++;
							}
						}
					}

					size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, bndSize, 0};
					size_t count[3] = {1, 1, nextMPIIndex};
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemSize, start, &nextMPIIndex));
					int rank = (z*numPartitions[1] + (y+1)%numPartitions[1])*numPartitions[0] + x;
					rank = (rank + numPartitions[3]) % numPartitions[3];
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemRank, start, &rank));
					checkNcError(nc_put_vara_int(ncFile, ncVarBndElemLocalIds, start, count, bndLocalIds));

					bndSize++;
				}
				if ((boundary == 6 && numPartitions[2] > 1) || z != numPartitions[2]-1) {
					int nextMPIIndex = 0;
					for (unsigned int yy = 0; yy < numCubesPerPart[1]; yy++) {
						for (unsigned int xx = 0; xx < numCubesPerPart[0]; xx++) {
//							int odd = (yy+xx+1) % 2;
//							if (odd) {
								bndLocalIds[nextMPIIndex] = (((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 5 + 2;
								elemMPIIndices[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = nextMPIIndex++;
								bndLocalIds[nextMPIIndex] = (((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 5 + 3;
								elemMPIIndices[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = nextMPIIndex++;
//							} else {
//								bndLocalIds[nextMPIIndex] = (((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 5 + 2;
//								elemMPIIndices[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 11] = nextMPIIndex++;
//								bndLocalIds[nextMPIIndex] = (((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 5 + 3;
//								elemMPIIndices[(((numCubesPerPart[2]-1)*numCubesPerPart[1]+yy)*numCubesPerPart[0]+xx) * 20 + 15] = nextMPIIndex++;
//							}
						}
					}

					size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, bndSize, 0};
					size_t count[3] = {1, 1, nextMPIIndex};
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemSize, start, &nextMPIIndex));
					int rank = (((z+1)%numPartitions[2])*numPartitions[1] + y)*numPartitions[0] + x;
					rank = (rank + numPartitions[3]) % numPartitions[3];
					checkNcError(nc_put_var1_int(ncFile, ncVarBndElemRank, start, &rank));
					checkNcError(nc_put_vara_int(ncFile, ncVarBndElemLocalIds, start, count, bndLocalIds));

					bndSize++;
				}

				size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, 0, 0};
				size_t count[3] = {1, numElemPerPart[3], 4};
				checkNcError(nc_put_vara_int(ncFile, ncVarElemMPIIndices, start, count, elemMPIIndices));

				checkNcError(nc_put_var1_int(ncFile, ncVarBndSize, &start[0], &bndSize));
				writes_done++; loadBar(writes_done, netcdf_writes);
			}
		}
	}
	delete [] elemMPIIndices;
	delete [] bndLocalIds;

	// Vertices
	std::map<int, Vertex> uniqueVertices;
	transform(vertexMap.begin(), vertexMap.end(),
			inserter(uniqueVertices, uniqueVertices.begin()),
			flip_pair<Vertex,int>);

	int *vrtxSize = new int[numPartitions[3]];
	std::fill(vrtxSize, vrtxSize+numPartitions[3], uniqueVertices.size());
	checkNcError(nc_put_var_int(ncFile, ncVarVrtxSize, vrtxSize));
	delete [] vrtxSize;
	writes_done++; loadBar(writes_done, netcdf_writes);

	double *vrtxCoords = new double[uniqueVertices.size()*3];
  
  
  double scale = args.getArgument<double>("scale", 100.0);
  double halfWidth = scale / 2.0;

	for (unsigned int z = 0; z < numPartitions[2]; z++) {
		for (unsigned int y = 0; y < numPartitions[1]; y++) {
			for (unsigned int x = 0; x < numPartitions[0]; x++) {

				#pragma omp parallel for
				for (unsigned int i = 0; i < uniqueVertices.size(); i++) {
					vrtxCoords[i*3] = static_cast<double>(uniqueVertices.at(i).v[0] + x*numCubesPerPart[0])/static_cast<double>(numCubes[0])*scale - halfWidth;
					vrtxCoords[i*3+1] = static_cast<double>(uniqueVertices.at(i).v[1] + y*numCubesPerPart[1])/static_cast<double>(numCubes[1])*scale - halfWidth;
					vrtxCoords[i*3+2] = static_cast<double>(uniqueVertices.at(i).v[2] + z*numCubesPerPart[2])/static_cast<double>(numCubes[2])*scale - halfWidth;
				}

				size_t start[3] = {(z*numPartitions[1] + y)*numPartitions[0] + x, 0, 0};
				size_t count[3] = {1, uniqueVertices.size(), 3};
				checkNcError(nc_put_vara_double(ncFile, ncVarVrtxCoords, start, count, vrtxCoords));
				writes_done++; loadBar(writes_done, netcdf_writes);
			}
		}
	}

	delete [] vrtxCoords;
  
  // Set material zone to 1
  int *elemGroup = new int[numPartitions[3] * numElemPerPart[3]];
	std::fill(elemGroup, elemGroup + numPartitions[3] * numElemPerPart[3], 1);
  size_t start[2] = { 0, 0 };
  size_t count[2] = { numPartitions[3], numElemPerPart[3] };
	checkNcError(nc_put_vara_int(ncFile, ncVarElemGroup, start, count, elemGroup));
	delete[] elemGroup;

	checkNcError(nc_close(ncFile));

	logInfo() << "Finished";
}
