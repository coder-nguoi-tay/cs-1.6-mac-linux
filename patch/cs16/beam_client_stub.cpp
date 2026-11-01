// beam_client_stub.cpp — stub definitions for CBeam methods that exist only in
// the (server-side) ReGameDLL_CS code. The client dll references them through
// inline CBaseEntity::BodyTarget chains (cs_weapons.cpp) but never actually
// uses beams on the client side, so return a zero vector.
// @author codernguoitay @since 2026-11-01
#include "port.h"
#include "wrect.h"
#include "cl_dll.h"
#include "cl_util.h"
#include "hud.h"
#include "extdll.h"
#include "util.h"
#include "cbase.h"
#include "effects.h"

static Vector g_stubBeamVec;

// @return const Vector& zero vector stub
const Vector &CBeam::GetStartPos( void )
{
	return g_stubBeamVec;
}

// @return const Vector& zero vector stub
const Vector &CBeam::GetEndPos( void )
{
	return g_stubBeamVec;
}
