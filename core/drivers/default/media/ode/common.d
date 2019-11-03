/*************************************************************************
 *                                                                       *
 * Open Dynamics Engine, Copyright (C) 2001,2002 Russell L. Smith.       *
 * All rights reserved.  Email: russ@q12.org   Web: www.q12.org          *
 *                                                                       *
 * This library is free software; you can redistribute it and/or         *
 * modify it under the terms of EITHER:                                  *
 *   (1) The GNU Lesser General Public License as published by the Free  *
 *       Software Foundation; either version 2.1 of the License, or (at  *
 *       your option) any later version. The text of the GNU Lesser      *
 *       General Public License is included with this library in the     *
 *       file LICENSE.TXT.                                               *
 *   (2) The BSD-style license that is included with this library in     *
 *       the file LICENSE-BSD.TXT.                                       *
 *                                                                       *
 * This library is distributed in the hope that it will be useful,       *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the files    *
 * LICENSE.TXT and LICENSE-BSD.TXT for more details.                     *
 *                                                                       *
 *************************************************************************/
module ode.common;

private import std.c.math;
private import std.c.stdlib;
import ode.config;
import ode.error;

extern(C):

/* configuration stuff */

/* the efficient alignment. most platforms align data structures to some
 * number of bytes, but this is not always the most efficient alignment.
 * for example, many x86 compilers align to 4 bytes, but on a pentium it
 * is important to align doubles to 8 byte boundaries (for speed), and
 * the 4 floats in a SIMD register to 16 byte boundaries. many other
 * platforms have similar behavior. setting a larger alignment can waste
 * a (very) small amount of memory. NOTE: this number must be a power of
 * two. this is set to 16 by default.
 */
const int EFFICIENT_ALIGNMENT = 16;


/* constants */

/* pi and 1/sqrt(2) are defined here if necessary because they don't get
 * defined in <math.h> on some platforms (like MS-Windows)
 */

const real M_PI = 3.1415926535897932384626433832795029;
const real M_SQRT1_2 = 0.7071067811865475244008443621048490;

/* debugging:
 *   IASSERT  is an internal assertion, i.e. a consistency check. if it fails
 *            we want to know where.
 *   UASSERT  is a user assertion, i.e. if it fails a nice error message
 *            should be printed for the user.
 *   AASSERT  is an arguments assertion, i.e. if it fails "bad argument(s)"
 *            is printed.
 *   DEBUGMSG just prints out a message
 */

int dIASSERT(int a) { return 0; }
int dUASSERT(int a, char* msg) { return 0; }
int dDEBUGMSG(char* msg) { return 0; }
int dAASSERT(int a) { return 0; }

/* floating point data type, vector, matrix and quaternion types */

alias double dReal;


/* round an integer up to a multiple of 4, except that 0 and 1 are unmodified
 * (used to compute matrix leading dimensions)
 */
int dPAD(int a) { return ((a > 1) ? (((a-1)|3)+1) : a); }

/* these types are mainly just used in headers */
alias dReal dVector3[4];
alias dReal dVector4[4];
alias dReal dMatrix3[4*3];
alias dReal dMatrix4[4*4];
alias dReal dMatrix6[8*6];
alias dReal dQuaternion[4];


/* precision dependent scalar math functions */

dReal REAL(dReal x) { return x; }
dReal dRecip(dReal x) { return (1.0/(x)); }
dReal dSqrt(dReal x) { return sqrtl(x); }
dReal dRecipSqrt(dReal x) { return (1.0/sqrtl(x)); }
dReal dSin(dReal x) { return sinl(x); }
dReal dCos(dReal x) { return cosl(x); }
dReal dFabs(dReal x) { return fabsl(x); }
dReal dAtan2(dReal y, dReal x) { return atan2l((y),(x)); }
dReal dFMod(dReal a, dReal b) { return (fmodl((a),(b))); }
dReal dCopySign(dReal a, dReal b) { return (copysignl((a),(b))); }

/* utility */


/* round something up to be a multiple of the EFFICIENT_ALIGNMENT */

int dEFFICIENT_SIZE(int x) { return (((x-1)|(EFFICIENT_ALIGNMENT-1))+1); }


/* alloca aligned to the EFFICIENT_ALIGNMENT. note that this can waste
 * up to 15 bytes per allocation, depending on what alloca() returns.
 */

char*  dALLOCA16(int n) 
{ return (cast(char*)dEFFICIENT_SIZE((cast(size_t)(alloca(n+(EFFICIENT_ALIGNMENT-1)))))); }


/* internal object types (all prefixed with `dx') */

struct dxWorld;		/* dynamics world */
struct dxSpace;		/* collision space */
struct dxBody;		/* rigid body (dynamics object) */
struct dxGeom;		/* geometry (collision object) */
struct dxJoint;
struct dxJointNode;
struct dxJointGroup;

alias dxWorld *dWorldID;
alias dxSpace *dSpaceID;
alias dxBody *dBodyID;
alias dxGeom *dGeomID;
alias dxJoint *dJointID;
alias dxJointGroup *dJointGroupID;


/* error numbers */

enum {
  d_ERR_UNKNOWN = 0,		/* unknown error */
  d_ERR_IASSERT,		/* internal assertion failed */
  d_ERR_UASSERT,		/* user assertion failed */
  d_ERR_LCP			/* user assertion failed */
};


/* joint type numbers */

enum {
  dJointTypeNone = 0,		/* or "unknown" */
  dJointTypeBall,
  dJointTypeHinge,
  dJointTypeSlider,
  dJointTypeContact,
  dJointTypeUniversal,
  dJointTypeHinge2,
  dJointTypeFixed,
  dJointTypeNull,
  dJointTypeAMotor
};


/* an alternative way of setting joint parameters, using joint parameter
 * structures and member constants. we don't actually do this yet.
 */

/*
typedef struct dLimot {
  int mode;
  dReal lostop, histop;
  dReal vel, fmax;
  dReal fudge_factor;
  dReal bounce, soft;
  dReal suspension_erp, suspension_cfm;
} dLimot;

enum {
  dLimotLoStop		= 0x0001,
  dLimotHiStop		= 0x0002,
  dLimotVel		= 0x0004,
  dLimotFMax		= 0x0008,
  dLimotFudgeFactor	= 0x0010,
  dLimotBounce		= 0x0020,
  dLimotSoft		= 0x0040
};
*/


/* standard joint parameter names. why are these here? - because we don't want
 * to include all the joint function definitions in joint.cpp. hmmmm.
 * MSVC complains if we call D_ALL_PARAM_NAMES_X with a blank second argument,
 * which is why we have the D_ALL_PARAM_NAMES macro as well. please copy and
 * paste between these two.
 */
enum {
  /* parameters for limits and motors */
  dParamLoStop = 0,
  dParamHiStop,
  dParamVel,
  dParamFMax,
  dParamFudgeFactor,
  dParamBounce,
  dParamCFM,
  dParamStopERP,
  dParamStopCFM,
  /* parameters for suspension */
  dParamSuspensionERP,
  dParamSuspensionCFM,
};

enum {
  /* parameters for limits and motors */
  dParamLoStop2 = 0x100,
  dParamHiStop2,
  dParamVel2,
  dParamFMax2,
  dParamFudgeFactor2,
  dParamBounce2,
  dParamCFM2,
  dParamStopERP2,
  dParamStopCFM2,
  /* parameters for suspension */
  dParamSuspensionERP2,
  dParamSuspensionCFM2,
};

enum {
  /* parameters for limits and motors */
  dParamLoStop3 = 0x200,
  dParamHiStop3,
  dParamVel3,
  dParamFMax3,
  dParamFudgeFactor3,
  dParamBounce3,
  dParamCFM3,
  dParamStopERP3,
  dParamStopCFM3,
  /* parameters for suspension */
  dParamSuspensionERP3,
  dParamSuspensionCFM3,
};

/+
#define D_ALL_PARAM_NAMES(start) \
  /* parameters for limits and motors */ \
  dParamLoStop = start, \
  dParamHiStop, \
  dParamVel, \
  dParamFMax, \
  dParamFudgeFactor, \
  dParamBounce, \
  dParamCFM, \
  dParamStopERP, \
  dParamStopCFM, \
  /* parameters for suspension */ \
  dParamSuspensionERP, \
  dParamSuspensionCFM,

#define D_ALL_PARAM_NAMES_X(start,x) \
  /* parameters for limits and motors */ \
  dParamLoStop ## x = start, \
  dParamHiStop ## x, \
  dParamVel ## x, \
  dParamFMax ## x, \
  dParamFudgeFactor ## x, \
  dParamBounce ## x, \
  dParamCFM ## x, \
  dParamStopERP ## x, \
  dParamStopCFM ## x, \
  /* parameters for suspension */ \
  dParamSuspensionERP ## x, \
  dParamSuspensionCFM ## x,

enum {
  D_ALL_PARAM_NAMES(0)
  D_ALL_PARAM_NAMES_X(0x100,2)
  D_ALL_PARAM_NAMES_X(0x200,3)

  /* add a multiple of this constant to the basic parameter numbers to get
   * the parameters for the second, third etc axes.
   */
  dParamGroup=0x100
};
+/

/* angular motor mode numbers */

enum{
  dAMotorUser = 0,
  dAMotorEuler = 1
};


/* joint force feedback information */

struct dJointFeedback {
  dVector3 f1;		/* force applied to body 1 */
  dVector3 t1;		/* torque applied to body 1 */
  dVector3 f2;		/* force applied to body 2 */
  dVector3 t2;		/* torque applied to body 2 */
};


/* private functions that must be implemented by the collision library:
 * (1) indicate that a geom has moved, (2) get the next geom in a body list.
 * these functions are called whenever the position of geoms connected to a
 * body have changed, e.g. with dBodySetPosition(), dBodySetRotation(), or
 * when the ODE step function updates the body state.
 */

void dGeomMoved (dGeomID);
dGeomID dGeomGetBodyNext (dGeomID);
