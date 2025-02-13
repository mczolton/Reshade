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

uniform int fLayer_DirtSelecter < 
	ui_type = "combo";
	ui_items="None\0Dirt01\0Dirt02\0Dirt03\0Dirt04\0";
	ui_label = "Dirt";
	ui_tooltip = "Select overlay dirt texture.";
> = 0;

uniform float Layer_Blend <
    ui_label = "Layer Blend";
    ui_tooltip = "How much to blend layer with the original image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform bool Layer_invert_Color <
    ui_label = "Invert Color";
    ui_category = "Color options";
> = 0;


texture Dirt_Texture0 <source="NullTexture.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Dirt_Texture1 <source="Dirt/Dirt01.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Dirt_Texture2 <source="Dirt/Dirt02.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Dirt_Texture3 <source="Dirt/Dirt03.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture Dirt_Texture4 <source="Dirt/Dirt04.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };

sampler Layer_SampleDirt0 { Texture = Dirt_Texture0; };
sampler Layer_SampleDirt1 { Texture = Dirt_Texture1; };
sampler Layer_SampleDirt2 { Texture = Dirt_Texture2; };
sampler Layer_SampleDirt3 { Texture = Dirt_Texture3; };
sampler Layer_SampleDirt4 { Texture = Dirt_Texture4; };


float3 PS_Layer(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float4 layer;
	

	switch (fLayer_DirtSelecter)
	{
		case 0:
		layer = tex2D(Layer_SampleDirt0, texcoord).rgba;
		break;
		case 1:
		layer = tex2D(Layer_SampleDirt1, texcoord).rgba;
		break;
		case 2:
		layer = tex2D(Layer_SampleDirt2, texcoord).rgba;
		break;
		case 3:
		layer = tex2D(Layer_SampleDirt3, texcoord).rgba;
		break;
		case 4:
		layer = tex2D(Layer_SampleDirt4, texcoord).rgba;
		break;
	}
	
	if (Layer_invert_Color) layer = float4(1.0 - layer.r, 1.0 - layer.g, 1.0 - layer.b, layer.a);
	
	color = lerp(color, layer.rgb, layer.a * Layer_Blend);

    return color;    
    //return layer.aaa;
}

technique DirtOD {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer;
    }
}