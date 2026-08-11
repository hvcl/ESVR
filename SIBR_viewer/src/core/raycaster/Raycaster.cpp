/*
 * Lightweight compatibility implementation for the Gaussian viewer build.
 * The viewer does not create a raycaster, so keeping Embree would only add an
 * unused binary dependency. Intersection methods deliberately report no hit.
 */

#include "Raycaster.hpp"

#include <limits>

namespace sibr
{
	const Raycaster::geomId Raycaster::InvalidGeomId = std::numeric_limits<Raycaster::geomId>::max();

	Raycaster::~Raycaster() = default;

	bool Raycaster::init() { return false; }

	Raycaster::geomId Raycaster::addMesh(const sibr::Mesh&) { return InvalidGeomId; }
	Raycaster::geomId Raycaster::addDynamicMesh(const sibr::Mesh&) { return InvalidGeomId; }
	Raycaster::geomId Raycaster::addGenericMesh(const sibr::Mesh&, int) { return InvalidGeomId; }

	void Raycaster::xformRtcMeshOnly(sibr::Mesh&, geomId, sibr::Matrix4f&, sibr::Vector3f&, float&) {}

	RayHit Raycaster::intersect(const Ray& ray, float)
	{
		return RayHit(ray, RayHit::InfinityDist, { 0.0f, 0.0f }, Vector3f::Zero(),
			{ InvalidGeomId, InvalidGeomId, InvalidGeomId });
	}

	std::array<RayHit, 8> Raycaster::intersect8(const std::array<Ray, 8>& rays, const std::vector<int>&, float minDist)
	{
		std::array<RayHit, 8> hits;
		for (size_t i = 0; i < hits.size(); ++i) {
			hits[i] = intersect(rays[i], minDist);
		}
		return hits;
	}

	bool Raycaster::hitSomething(const Ray&, float) { return false; }

	std::array<bool, 8> Raycaster::hitSomething8(const std::array<Ray, 8>&, float)
	{
		return { false, false, false, false, false, false, false, false };
	}

	void Raycaster::clearGeometry() {}

	sibr::Vector3f Raycaster::smoothNormal(const sibr::Mesh& mesh, const RayHit& hit)
	{
		const auto& tri = mesh.triangles()[hit.primitive().triID];
		const auto uvw = hit.interpolateUV();
		return (uvw[0] * mesh.normals()[tri[0]] + uvw[1] * mesh.normals()[tri[1]] + uvw[2] * mesh.normals()[tri[2]]).normalized();
	}

	sibr::Vector3f Raycaster::smoothColor(const sibr::Mesh& mesh, const RayHit& hit)
	{
		const auto& tri = mesh.triangles()[hit.primitive().triID];
		const auto uvw = hit.interpolateUV();
		return uvw[0] * mesh.colors()[tri[0]] + uvw[1] * mesh.colors()[tri[1]] + uvw[2] * mesh.colors()[tri[2]];
	}

	sibr::Vector2f Raycaster::smoothUV(const sibr::Mesh& mesh, const RayHit& hit)
	{
		const auto& tri = mesh.triangles()[hit.primitive().triID];
		const auto uvw = hit.interpolateUV();
		return uvw[0] * mesh.texCoords()[tri[0]] + uvw[1] * mesh.texCoords()[tri[1]] + uvw[2] * mesh.texCoords()[tri[2]];
	}
}
