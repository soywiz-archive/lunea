/* Copyright (c) Mark J. Kilgard, 1994, 1995, 1996, 1998. */

/* This program is freely distributable without licensing fees  and is
   provided without guarantee or warrantee expressed or  implied. This
   program is -not- in the public domain. */

// convert to D by shinichiro.h

import opengl;
import openglu;

extern (C):

/**
 GLUT API revision history:

 GLUT_API_VERSION is updated to reflect incompatible GLUT
 API changes (interface changes, semantic changes, deletions,
 or additions).

 GLUT_API_VERSION=1  First public release of GLUT.  11/29/94

 GLUT_API_VERSION=2  Added support for OpenGL/GLX multisampling,
 extension.  Supports new input devices like tablet, dial and button
 box, and Spaceball.  Easy to query OpenGL extensions.

 GLUT_API_VERSION=3  glutMenuStatus added.

 GLUT_API_VERSION=4  glutInitDisplayString, glutWarpPointer,
 glutBitmapLength, glutStrokeLength, glutWindowStatusFunc, dynamic
 video resize subAPI, glutPostWindowRedisplay, glutKeyboardUpFunc,
 glutSpecialUpFunc, glutIgnoreKeyRepeat, glutSetKeyRepeat,
 glutJoystickFunc, glutForceJoystickFunc (NOT FINALIZED!).
**/
const uint GLUT_API_VERSION = 3;

/**
 GLUT implementation revision history:

 GLUT_XLIB_IMPLEMENTATION is updated to reflect both GLUT
 API revisions and implementation revisions (ie, bug fixes).

 GLUT_XLIB_IMPLEMENTATION=1  mjk's first public release of
 GLUT Xlib-based implementation.  11/29/94

 GLUT_XLIB_IMPLEMENTATION=2  mjk's second public release of
 GLUT Xlib-based implementation providing GLUT version 2
 interfaces.

 GLUT_XLIB_IMPLEMENTATION=3  mjk's GLUT 2.2 images. 4/17/95

 GLUT_XLIB_IMPLEMENTATION=4  mjk's GLUT 2.3 images. 6/?/95

 GLUT_XLIB_IMPLEMENTATION=5  mjk's GLUT 3.0 images. 10/?/95

 GLUT_XLIB_IMPLEMENTATION=7  mjk's GLUT 3.1+ with glutWarpPoitner.  7/24/96

 GLUT_XLIB_IMPLEMENTATION=8  mjk's GLUT 3.1+ with glutWarpPoitner
 and video resize.  1/3/97

 GLUT_XLIB_IMPLEMENTATION=9 mjk's GLUT 3.4 release with early GLUT 4 routines.

 GLUT_XLIB_IMPLEMENTATION=11 Mesa 2.5's GLUT 3.6 release.

 GLUT_XLIB_IMPLEMENTATION=12 mjk's GLUT 3.6 release with early GLUT 4 routines + signal handling.

 GLUT_XLIB_IMPLEMENTATION=13 mjk's GLUT 3.7 beta with GameGLUT support.

 GLUT_XLIB_IMPLEMENTATION=14 mjk's GLUT 3.7 beta with f90gl friend interface.

 GLUT_XLIB_IMPLEMENTATION=15 mjk's GLUT 3.7 beta sync'ed with Mesa <GL/glut.h>
**/
const uint GLUT_XLIB_IMPLEMENTATION = 15;

/* Display mode bit masks. */
const uint GLUT_RGB	=		0;
const uint GLUT_RGBA	=		GLUT_RGB;
const uint GLUT_INDEX		=	1;
const uint GLUT_SINGLE		=	0;
const uint GLUT_DOUBLE		=	2;
const uint GLUT_ACCUM		=	4;
const uint GLUT_ALPHA		=	8;
const uint GLUT_DEPTH		=	16;
const uint GLUT_STENCIL		=	32;
const uint GLUT_MULTISAMPLE	=	128;
const uint GLUT_STEREO		=	256;
const uint GLUT_LUMINANCE	=		512;

/* Mouse buttons. */
const uint GLUT_LEFT_BUTTON	=	0;
const uint GLUT_MIDDLE_BUTTON	=	1;
const uint GLUT_RIGHT_BUTTON	=	2;

/* Mouse button  state. */
const uint GLUT_DOWN	=		0;
const uint GLUT_UP		=		1;

/* function keys */
const uint GLUT_KEY_F1		=	1;
const uint GLUT_KEY_F2		=	2;
const uint GLUT_KEY_F3		=	3;
const uint GLUT_KEY_F4		=	4;
const uint GLUT_KEY_F5		=	5;
const uint GLUT_KEY_F6		=	6;
const uint GLUT_KEY_F7		=	7;
const uint GLUT_KEY_F8		=	8;
const uint GLUT_KEY_F9		=	9;
const uint GLUT_KEY_F10		=	10;
const uint GLUT_KEY_F11		=	11;
const uint GLUT_KEY_F12		=	12;
/* directional keys */
const uint GLUT_KEY_LEFT		=	100;
const uint GLUT_KEY_UP		=	101;
const uint GLUT_KEY_RIGHT	=		102;
const uint GLUT_KEY_DOWN	=		103;
const uint GLUT_KEY_PAGE_UP	=	104;
const uint GLUT_KEY_PAGE_DOWN	=	105;
const uint GLUT_KEY_HOME		=	106;
const uint GLUT_KEY_END		=	107;
const uint GLUT_KEY_INSERT	=		108;

/* Entry/exit  state. */
const uint GLUT_LEFT		=	0;
const uint GLUT_ENTERED		=	1;

/* Menu usage  state. */
const uint GLUT_MENU_NOT_IN_USE	=	0;
const uint GLUT_MENU_IN_USE	=	1;

/* Visibility  state. */
const uint GLUT_NOT_VISIBLE	=	0;
const uint GLUT_VISIBLE		=	1;

/* Window status  state. */
const uint GLUT_HIDDEN		=	0;
const uint GLUT_FULLY_RETAINED	=	1;
const uint GLUT_PARTIALLY_RETAINED	=	2;
const uint GLUT_FULLY_COVERED	=	3;

/* Color index component selection values. */
const uint GLUT_RED		=	0;
const uint GLUT_GREEN	=		1;
const uint GLUT_BLUE	=		2;

/* Layers for use. */
const uint GLUT_NORMAL	=		0;
const uint GLUT_OVERLAY	=		1;

/+

#if defined(_WIN32)
/* Stroke font constants (use these in GLUT program). */
#define GLUT_STROKE_ROMAN		((void*)0)
#define GLUT_STROKE_MONO_ROMAN		((void*)1)

/* Bitmap font constants (use these in GLUT program). */
#define GLUT_BITMAP_9_BY_15		((void*)2)
#define GLUT_BITMAP_8_BY_13		((void*)3)
#define GLUT_BITMAP_TIMES_ROMAN_10	((void*)4)
#define GLUT_BITMAP_TIMES_ROMAN_24	((void*)5)
#if (GLUT_API_VERSION >= 3)
#define GLUT_BITMAP_HELVETICA_10	((void*)6)
#define GLUT_BITMAP_HELVETICA_12	((void*)7)
#define GLUT_BITMAP_HELVETICA_18	((void*)8)
#endif
#else
/* Stroke font opaque addresses (use constants instead in source code). */
GLUTAPI void *glutStrokeRoman;
GLUTAPI void *glutStrokeMonoRoman;

/* Stroke font constants (use these in GLUT program). */
#define GLUT_STROKE_ROMAN		(&glutStrokeRoman)
#define GLUT_STROKE_MONO_ROMAN		(&glutStrokeMonoRoman)

/* Bitmap font opaque addresses (use constants instead in source code). */
GLUTAPI void *glutBitmap9By15;
GLUTAPI void *glutBitmap8By13;
GLUTAPI void *glutBitmapTimesRoman10;
GLUTAPI void *glutBitmapTimesRoman24;
GLUTAPI void *glutBitmapHelvetica10;
GLUTAPI void *glutBitmapHelvetica12;
GLUTAPI void *glutBitmapHelvetica18;

/* Bitmap font constants (use these in GLUT program). */
#define GLUT_BITMAP_9_BY_15		(&glutBitmap9By15)
#define GLUT_BITMAP_8_BY_13		(&glutBitmap8By13)
#define GLUT_BITMAP_TIMES_ROMAN_10	(&glutBitmapTimesRoman10)
#define GLUT_BITMAP_TIMES_ROMAN_24	(&glutBitmapTimesRoman24)
#if (GLUT_API_VERSION >= 3)
#define GLUT_BITMAP_HELVETICA_10	(&glutBitmapHelvetica10)
#define GLUT_BITMAP_HELVETICA_12	(&glutBitmapHelvetica12)
#define GLUT_BITMAP_HELVETICA_18	(&glutBitmapHelvetica18)
#endif
#endif

+/
// abeyance end.

/* glutGet parameters. */
const uint GLUT_WINDOW_X	=		100;
const uint GLUT_WINDOW_Y	=		101;
const uint GLUT_WINDOW_WIDTH	=	102;
const uint GLUT_WINDOW_HEIGHT	=	103;
const uint GLUT_WINDOW_BUFFER_SIZE	=	104;
const uint GLUT_WINDOW_STENCIL_SIZE	= 105;
const uint GLUT_WINDOW_DEPTH_SIZE	=	106;
const uint GLUT_WINDOW_RED_SIZE	=	107;
const uint GLUT_WINDOW_GREEN_SIZE	=	108;
const uint GLUT_WINDOW_BLUE_SIZE	=	109;
const uint GLUT_WINDOW_ALPHA_SIZE	=	110;
const uint GLUT_WINDOW_ACCUM_RED_SIZE	= 111;
const uint GLUT_WINDOW_ACCUM_GREEN_SIZE	 = 112;
const uint GLUT_WINDOW_ACCUM_BLUE_SIZE	= 113;
const uint GLUT_WINDOW_ACCUM_ALPHA_SIZE	= 114;
const uint GLUT_WINDOW_DOUBLEBUFFER	= 115;
const uint GLUT_WINDOW_RGBA	=	116;
const uint GLUT_WINDOW_PARENT	=	117;
const uint GLUT_WINDOW_NUM_CHILDREN =	118;
const uint GLUT_WINDOW_COLORMAP_SIZE =	119;
const uint GLUT_WINDOW_NUM_SAMPLES	=	120;
const uint GLUT_WINDOW_STEREO	=	121;
const uint GLUT_WINDOW_CURSOR	=	122;
const uint GLUT_SCREEN_WIDTH	=	200;
const uint GLUT_SCREEN_HEIGHT	=	201;
const uint GLUT_SCREEN_WIDTH_MM	=	202;
const uint GLUT_SCREEN_HEIGHT_MM	=	203;
const uint GLUT_MENU_NUM_ITEMS	=	300;
const uint GLUT_DISPLAY_MODE_POSSIBLE =	400;
const uint GLUT_INIT_WINDOW_X	=	500;
const uint GLUT_INIT_WINDOW_Y	=	501;
const uint GLUT_INIT_WINDOW_WIDTH	=	502;
const uint GLUT_INIT_WINDOW_HEIGHT	=	503;
const uint GLUT_INIT_DISPLAY_MODE	=	504;
const uint GLUT_ELAPSED_TIME	=	700;
const uint GLUT_WINDOW_FORMAT_ID	=	123;

/* glutDeviceGet parameters. */
const uint GLUT_HAS_KEYBOARD	=	600;
const uint GLUT_HAS_MOUSE		=	601;
const uint GLUT_HAS_SPACEBALL	=	602;
const uint GLUT_HAS_DIAL_AND_BUTTON_BOX =	603;
const uint GLUT_HAS_TABLET		=	604;
const uint GLUT_NUM_MOUSE_BUTTONS	=	605;
const uint GLUT_NUM_SPACEBALL_BUTTONS =	606;
const uint GLUT_NUM_BUTTON_BOX_BUTTONS =	607;
const uint GLUT_NUM_DIALS		=	608;
const uint GLUT_NUM_TABLET_BUTTONS =		609;

const uint GLUT_DEVICE_IGNORE_KEY_REPEAT  =  610;
const uint GLUT_DEVICE_KEY_REPEAT        =  611;
const uint GLUT_HAS_JOYSTICK	=	612;
const uint GLUT_OWNS_JOYSTICK	=	613;
const uint GLUT_JOYSTICK_BUTTONS	=	614;
const uint GLUT_JOYSTICK_AXES	=	615;
const uint GLUT_JOYSTICK_POLL_RATE	=	616;

/* glutLayerGet parameters. */
const uint GLUT_OVERLAY_POSSIBLE      =     800;
const uint GLUT_LAYER_IN_USE	=	801;
const uint GLUT_HAS_OVERLAY	=	802;
const uint GLUT_TRANSPARENT_INDEX	=	803;
const uint GLUT_NORMAL_DAMAGED	=	804;
const uint GLUT_OVERLAY_DAMAGED	=	805;

/* glutVideoResizeGet parameters. */
const uint GLUT_VIDEO_RESIZE_POSSIBLE =	900;
const uint GLUT_VIDEO_RESIZE_IN_USE =	901;
const uint GLUT_VIDEO_RESIZE_X_DELTA =	902;
const uint GLUT_VIDEO_RESIZE_Y_DELTA =	903;
const uint GLUT_VIDEO_RESIZE_WIDTH_DELTA =	904;
const uint GLUT_VIDEO_RESIZE_HEIGHT_DELTA =	905;
const uint GLUT_VIDEO_RESIZE_X	=	906;
const uint GLUT_VIDEO_RESIZE_Y	=	907;
const uint GLUT_VIDEO_RESIZE_WIDTH	=	908;
const uint GLUT_VIDEO_RESIZE_HEIGHT	= 909;

/* glutUseLayer parameters. */
/*
const uint GLUT_NORMAL		=	0;
const uint GLUT_OVERLAY		=	1;
*/

/* glutGetModifiers return mask. */
const uint GLUT_ACTIVE_SHIFT      =         1;
const uint GLUT_ACTIVE_CTRL       =         2;
const uint GLUT_ACTIVE_ALT        =         4;

/* glutSetCursor parameters. */
/* Basic arrows. */
const uint GLUT_CURSOR_RIGHT_ARROW	=	0;
const uint GLUT_CURSOR_LEFT_ARROW	=	1;
/* Symbolic cursor shapes. */
const uint GLUT_CURSOR_INFO	=	2;
const uint GLUT_CURSOR_DESTROY	=	3;
const uint GLUT_CURSOR_HELP	=	4;
const uint GLUT_CURSOR_CYCLE	=	5;
const uint GLUT_CURSOR_SPRAY	=	6;
const uint GLUT_CURSOR_WAIT	=	7;
const uint GLUT_CURSOR_TEXT	=	8;
const uint GLUT_CURSOR_CROSSHAIR	=	9;
/* Directional cursors. */
const uint GLUT_CURSOR_UP_DOWN	=	10;
const uint GLUT_CURSOR_LEFT_RIGHT	=	11;
/* Sizing cursors. */
const uint GLUT_CURSOR_TOP_SIDE	=	12;
const uint GLUT_CURSOR_BOTTOM_SIDE	=	13;
const uint GLUT_CURSOR_LEFT_SIDE	=	14;
const uint GLUT_CURSOR_RIGHT_SIDE	=	15;
const uint GLUT_CURSOR_TOP_LEFT_CORNER =	16;
const uint GLUT_CURSOR_TOP_RIGHT_CORNER =	17;
const uint GLUT_CURSOR_BOTTOM_RIGHT_CORNER =	18;
const uint GLUT_CURSOR_BOTTOM_LEFT_CORNER =	19;
/* Inherit from parent window. */
const uint GLUT_CURSOR_INHERIT	 =	100;
/* Blank cursor. */
const uint GLUT_CURSOR_NONE	=	101;
/* Fullscreen crosshair (if available). */
const uint GLUT_CURSOR_FULL_CROSSHAIR	= 102;

/* GLUT initialization sub-API. */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutInit(int *argcp, char **argv);

/+
#if defined(_WIN32) && !defined(GLUT_DISABLE_ATEXIT_HACK)
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ __glutInitWithExit(int *argcp, char **argv, void (__cdecl *exitfunc)(int));
#ifndef GLUT_BUILDING_LIB
static void /*GLUTAPIENTRY*/ glutInit_ATEXIT_HACK(int *argcp, char **argv) { __glutInitWithExit(argcp, argv, exit); }
#define glutInit glutInit_ATEXIT_HACK
#endif
#endif
+/

/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutInitDisplayMode(uint mode);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutInitDisplayString(char *string);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutInitWindowPosition(int x, int y);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutInitWindowSize(int width, int height);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutMainLoop();

/* GLUT window sub-API. */
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutCreateWindow(char *title);

/+
#if defined(_WIN32) && !defined(GLUT_DISABLE_ATEXIT_HACK)
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ __glutCreateWindowWithExit(char *title, void (__cdecl *exitfunc)(int));
#ifndef GLUT_BUILDING_LIB
static int /*GLUTAPIENTRY*/ glutCreateWindow_ATEXIT_HACK(char *title) { return __glutCreateWindowWithExit(title, exit); }
#define glutCreateWindow glutCreateWindow_ATEXIT_HACK
#endif
#endif
+/

/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutCreateSubWindow(int win, int x, int y, int width, int height);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutDestroyWindow(int win);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPostRedisplay();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPostWindowRedisplay(int win);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSwapBuffers();
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutGetWindow();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetWindow(int win);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetWindowTitle(char *title);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetIconTitle(char *title);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPositionWindow(int x, int y);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutReshapeWindow(int width, int height);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPopWindow();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPushWindow();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutIconifyWindow();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutShowWindow();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutHideWindow();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutFullScreen();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetCursor(int cursor);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWarpPointer(int x, int y);

/* GLUT overlay sub-API. */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutEstablishOverlay();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutRemoveOverlay();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutUseLayer(GLenum layer);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPostOverlayRedisplay();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPostWindowOverlayRedisplay(int win);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutShowOverlay();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutHideOverlay();

/* GLUT menu sub-API. */
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutCreateMenu(void (/*GLUTCALLBACK*/ *func)(int));
/+
#if defined(_WIN32) && !defined(GLUT_DISABLE_ATEXIT_HACK)
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ __glutCreateMenuWithExit(void (/*GLUTCALLBACK*/ *func)(int), void (__cdecl *exitfunc)(int));
#ifndef GLUT_BUILDING_LIB
static int /*GLUTAPIENTRY*/ glutCreateMenu_ATEXIT_HACK(void (/*GLUTCALLBACK*/ *func)(int)) { return __glutCreateMenuWithExit(func, exit); }
#define glutCreateMenu glutCreateMenu_ATEXIT_HACK
#endif
#endif
+/

/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutDestroyMenu(int menu);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutGetMenu();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetMenu(int menu);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutAddMenuEntry(char *label, int value);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutAddSubMenu(char *label, int submenu);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutChangeToMenuEntry(int item, char *label, int value);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutChangeToSubMenu(int item, char *label, int submenu);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutRemoveMenuItem(int item);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutAttachMenu(int button);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutDetachMenu(int button);

/* GLUT window callback sub-API. */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutDisplayFunc(void (/*GLUTCALLBACK*/ *func)());
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutReshapeFunc(void (/*GLUTCALLBACK*/ *func)(int width, int height));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutKeyboardFunc(void (/*GLUTCALLBACK*/ *func)(ubyte key, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutMouseFunc(void (/*GLUTCALLBACK*/ *func)(int button, int state, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutMotionFunc(void (/*GLUTCALLBACK*/ *func)(int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutPassiveMotionFunc(void (/*GLUTCALLBACK*/ *func)(int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutEntryFunc(void (/*GLUTCALLBACK*/ *func)(int state));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutVisibilityFunc(void (/*GLUTCALLBACK*/ *func)(int state));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutIdleFunc(void (/*GLUTCALLBACK*/ *func)());
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutTimerFunc(uint millis, void (/*GLUTCALLBACK*/ *func)(int value), int value);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutMenuStateFunc(void (/*GLUTCALLBACK*/ *func)(int state));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSpecialFunc(void (/*GLUTCALLBACK*/ *func)(int key, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSpaceballMotionFunc(void (/*GLUTCALLBACK*/ *func)(int x, int y, int z));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSpaceballRotateFunc(void (/*GLUTCALLBACK*/ *func)(int x, int y, int z));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSpaceballButtonFunc(void (/*GLUTCALLBACK*/ *func)(int button, int state));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutButtonBoxFunc(void (/*GLUTCALLBACK*/ *func)(int button, int state));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutDialsFunc(void (/*GLUTCALLBACK*/ *func)(int dial, int value));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutTabletMotionFunc(void (/*GLUTCALLBACK*/ *func)(int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutTabletButtonFunc(void (/*GLUTCALLBACK*/ *func)(int button, int state, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutMenuStatusFunc(void (/*GLUTCALLBACK*/ *func)(int status, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutOverlayDisplayFunc(void (/*GLUTCALLBACK*/ *func)());
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWindowStatusFunc(void (/*GLUTCALLBACK*/ *func)(int state));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutKeyboardUpFunc(void (/*GLUTCALLBACK*/ *func)(ubyte key, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSpecialUpFunc(void (/*GLUTCALLBACK*/ *func)(int key, int x, int y));
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutJoystickFunc(void (/*GLUTCALLBACK*/ *func)(uint buttonMask, int x, int y, int z), int pollInterval);

/* GLUT color index sub-API. */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetColor(int, GLfloat red, GLfloat green, GLfloat blue);
/*GLUTAPI*/ GLfloat /*GLUTAPIENTRY*/ glutGetColor(int ndx, int component);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutCopyColormap(int win);

/* GLUT state retrieval sub-API. */
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutGet(GLenum type);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutDeviceGet(GLenum type);
/* GLUT extension support sub-API */
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutExtensionSupported(char *name);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutGetModifiers();
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutLayerGet(GLenum type);

/* GLUT font sub-API */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutBitmapCharacter(void *font, int character);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutBitmapWidth(void *font, int character);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutStrokeCharacter(void *font, int character);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutStrokeWidth(void *font, int character);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutBitmapLength(void *font, ubyte *string);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutStrokeLength(void *font, ubyte *string);

/* GLUT pre-built models sub-API */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireSphere(GLdouble radius, GLint slices, GLint stacks);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidSphere(GLdouble radius, GLint slices, GLint stacks);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireCone(GLdouble base, GLdouble height, GLint slices, GLint stacks);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidCone(GLdouble base, GLdouble height, GLint slices, GLint stacks);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireCube(GLdouble size);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidCube(GLdouble size);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireTorus(GLdouble innerRadius, GLdouble outerRadius, GLint sides, GLint rings);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidTorus(GLdouble innerRadius, GLdouble outerRadius, GLint sides, GLint rings);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireDodecahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidDodecahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireTeapot(GLdouble size);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidTeapot(GLdouble size);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireOctahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidOctahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireTetrahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidTetrahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutWireIcosahedron();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSolidIcosahedron();

/* GLUT video resize sub-API. */
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutVideoResizeGet(GLenum param);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetupVideoResizing();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutStopVideoResizing();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutVideoResize(int x, int y, int width, int height);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutVideoPan(int x, int y, int width, int height);

/* GLUT debugging sub-API. */
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutReportErrors();

/* GLUT device control sub-API. */
/* glutSetKeyRepeat modes. */
const uint GLUT_KEY_REPEAT_OFF	=	0;
const uint GLUT_KEY_REPEAT_ON	=	1;
const uint GLUT_KEY_REPEAT_DEFAULT	=	2;

/* Joystick button masks. */
const uint GLUT_JOYSTICK_BUTTON_A	=	1;
const uint GLUT_JOYSTICK_BUTTON_B	=	2;
const uint GLUT_JOYSTICK_BUTTON_C	=	4;
const uint GLUT_JOYSTICK_BUTTON_D	=	8;

/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutIgnoreKeyRepeat(int ignore);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutSetKeyRepeat(int repeatMode);
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutForceJoystickFunc();

/* GLUT game mode sub-API. */
/* glutGameModeGet. */
const uint GLUT_GAME_MODE_ACTIVE          = 0;
const uint GLUT_GAME_MODE_POSSIBLE        = 1;
const uint GLUT_GAME_MODE_WIDTH           = 2;
const uint GLUT_GAME_MODE_HEIGHT          = 3;
const uint GLUT_GAME_MODE_PIXEL_DEPTH     = 4;
const uint GLUT_GAME_MODE_REFRESH_RATE    = 5;
const uint GLUT_GAME_MODE_DISPLAY_CHANGED = 6;

/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutGameModeString(char *string);
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutEnterGameMode();
/*GLUTAPI*/ void /*GLUTAPIENTRY*/ glutLeaveGameMode();
/*GLUTAPI*/ int /*GLUTAPIENTRY*/ glutGameModeGet(GLenum mode);

