/*
	MADE BY MATSILAGI, NOT OFFICIAL, PLEASE DON'T BOTHER MARTY IF IT BACKFIRES, EXPLODES YOUR GPU OR ARTIFACTS IT.
*/

/*
	changelog:

	2.0.0:	added frame count parameter
			added versioning system
			removed common textures - should only be declared if needed
			flipped reversed depth buffer switch by default as most games use this format

*/

/*=============================================================================
	Version checks
=============================================================================*/

#if !defined(__RESHADE__) || __RESHADE__ < 40000
	#error "ReShade 4.4+ is required to use this header file"
#endif

/*=============================================================================
	Define defaults
=============================================================================*/

uniform float2 WH_PRECISION <
    	ui_type = "drag";
        ui_label = "Weapon Precesion / Cutoff";
    	ui_min = 0.00; ui_max = 1.00;
    	ui_tooltip = "Adjust Weapon Depth and Cutoff Point";
 	   ui_category = "Blending";
> = float2(0.0, 0.5);

//depth buffer
#ifdef RESHADE_POINT_FILTER
	#define RESHADEFILTERMODE POINT
#else
	#define RESHADEFILTERMODE LINEAR
#endif
#ifdef RESHADE_DEPTH_POINT_FILTER
	#define RESHADEDEPTHFILTERMODE POINT
#else
	#define RESHADEDEPTHFILTERMODE LINEAR
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
	#define RESHADE_DEPTH_INPUT_Y_SCALE 1
#endif
#ifndef RESHADE_DEPTH_INPUT_X_SCALE
	#define RESHADE_DEPTH_INPUT_X_SCALE 1
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET_SCALE
	#define RESHADE_DEPTH_INPUT_Y_OFFSET_SCALE 0
#endif
#ifndef RESHADE_DEPTH_INPUT_X_OFFSET_SCALE
	#define RESHADE_DEPTH_INPUT_X_OFFSET_SCALE 0
#endif
#ifndef RESHADE_DEPTH_MULTIPLIER
	#define RESHADE_DEPTH_MULTIPLIER 1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
	#define RESHADE_DEPTH_INPUT_IS_REVERSED 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_MIRRORED
	#define RESHADE_DEPTH_INPUT_IS_MIRRORED 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	#define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
	#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif

/*=============================================================================
	Uniforms
=============================================================================*/

namespace qUINT
{
    uniform float FRAME_TIME < source = "frametime"; >;
	uniform int FRAME_COUNT < source = "framecount"; >;

    static const float2 ASPECT_RATIO 	= float2(1.0, BUFFER_WIDTH * BUFFER_RCP_HEIGHT);
	static const float2 PIXEL_SIZE 		= float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	static const float2 SCREEN_SIZE 	= float2(BUFFER_WIDTH, BUFFER_HEIGHT);

	// Global textures and samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;

	sampler sBackBufferTex 	{ Texture = BackBufferTex; 	MinFilter = RESHADEFILTERMODE; MagFilter = RESHADEFILTERMODE; MipFilter = RESHADEFILTERMODE;};
	sampler sDepthBufferTex { Texture = DepthBufferTex; MinFilter = RESHADEDEPTHFILTERMODE; MagFilter = RESHADEDEPTHFILTERMODE; MipFilter = RESHADEDEPTHFILTERMODE;};
	
	//reusable textures for the shaders
    texture2D CommonTex0 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; };
    texture2D CommonTex1 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; };

    sampler2D sCommonTex0	{ Texture = CommonTex0;	};
    sampler2D sCommonTex1	{ Texture = CommonTex1;	};

    // Helper functions
	float linear_depth(float2 uv)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		uv.y = 1.0 - uv.y;
#endif

#if RESHADE_DEPTH_INPUT_IS_MIRRORED
		uv.x = 1.0 - uv.x;
#endif

		// Apply the Depth Buffer Scale if modified
		uv.x /= RESHADE_DEPTH_INPUT_X_SCALE;
    	uv.y /= RESHADE_DEPTH_INPUT_Y_SCALE;

		// Apply Depth Buffer Location Offset if modified
		uv.x -= (RESHADE_DEPTH_INPUT_X_OFFSET_SCALE/2.000000001);
    	uv.y += (RESHADE_DEPTH_INPUT_Y_OFFSET_SCALE/2.000000001);


		float depth = tex2Dlod(sDepthBufferTex, float4(uv, 0, 0)).x;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		float testval = WH_PRECISION.x / 1000.0;
    	float testval2 = WH_PRECISION.y;
    	float test3 = 1-testval/depth;
    	float outval = step(depth, testval2); //WORKING
    	float fade = lerp(depth,test3,outval);

		return saturate(fade);
	}
}

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 vpos : SV_Position, out float2 uv : TEXCOORD)
{
	uv.x = (id == 2) ? 2.0 : 0.0;
	uv.y = (id == 1) ? 2.0 : 0.0;
	vpos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}