/*------------------.
| :: Description :: |
'-------------------/

	Layer (version 0.1)

	Author: CeeJay.dk
	Modified: Crashaholic, kingtobbe, L00, Oh Deer
	License: MIT

	About:
	Blends an image with the game.
    The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
    Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

	Ideas for future improvement:
    * More blend modes
    * Texture size, placement and tiling control
    * A default Layer texture with something useful in it

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 0.1
    *
	//float4 layer = tex2D(Layer_SampleDirt1, texcoord).rgba;
*/

#include "ReShade.fxh"

#if LAYER_SINGLECHANNEL //I plan to have some option to let users set this for performance sake.
    #define TEXFORMAT R8
#else
    #define TEXFORMAT RGBA8
#endif

//TODO blend by alpha

uniform int fLayer_FrameSelecter < 
	ui_type = "combo";
	ui_items="None\0Frame01\0Frame02\0Frame03\0Frame04\0Frame05\0";
	ui_label = "Frames";
	ui_tooltip = "Select overlay frame texture.";
> = 0;


uniform float Layer_Blend <
    ui_label = "Transperancy";
    ui_tooltip = "How much to blend layer with the original image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;


/// L00 speaking here "let's add the bool interface"
uniform bool Layer_invert_Color_Please_Thankyou <
    ui_label = "Invert Color";
    ui_category = "Color options";
> = 0;

texture Frame_Texture0 <source="NullTexture.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Frame_Texture1 <source="Frames/Frame01.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Frame_Texture2 <source="Frames/Frame02.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Frame_Texture3 <source="Frames/Frame03.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Frame_Texture4 <source="Frames/Frame04.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Frame_Texture5 <source="Frames/Frame05.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };


sampler Layer_SampleFrame0 { Texture = Frame_Texture0; };
sampler Layer_SampleFrame1 { Texture = Frame_Texture1; };
sampler Layer_SampleFrame2 { Texture = Frame_Texture2; };
sampler Layer_SampleFrame3 { Texture = Frame_Texture3; };
sampler Layer_SampleFrame4 { Texture = Frame_Texture4; };
sampler Layer_SampleFrame5 { Texture = Frame_Texture5; };


float3 PS_Layer(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float4 layer;
	

	switch (fLayer_FrameSelecter)
	{
		case 0:
		layer = tex2D(Layer_SampleFrame0, texcoord).rgba;
		break;
		case 1:
		layer = tex2D(Layer_SampleFrame1, texcoord).rgba;
		break;
		case 2:
		layer = tex2D(Layer_SampleFrame2, texcoord).rgba;
		break;
		case 3:
		layer = tex2D(Layer_SampleFrame3, texcoord).rgba;
		break;
		case 4:
		layer = tex2D(Layer_SampleFrame4, texcoord).rgba;
		break;
		case 5:
		layer = tex2D(Layer_SampleFrame5, texcoord).rgba;
		break;
	}
	
	/// Inverse layer color...not sure it works
	if (Layer_invert_Color_Please_Thankyou) layer = float4(1.0 - layer.r, 1.0 - layer.g, 1.0 - layer.b, layer.a);

	color = lerp(color, layer.rgb, layer.a * Layer_Blend);

	return color;    
    //return layer.aaa;

}

technique FramesOD {
    pass
    {
        VertexShader = PostProcessVS;
		PixelShader  = PS_Layer;
    }
}