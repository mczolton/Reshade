/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-sa/4.0/.
*/

// Chromatic Aberration PS
// inspired by Marty McFly YACA shader

  ////////////////////
 /////// MENU ///////
////////////////////

uniform int Aberration <
	ui_label = "Aberration scale in pixels";
	ui_type = "drag";
	ui_min = 1; ui_max = 48;
> = 6;

uniform bool Automatic <
	ui_label = "Automatic sample count";
	ui_tooltip = "Amount of samples will be adjusted automatically";
> = true;

uniform int SampleCount <
	ui_label = "Samples";
	ui_tooltip = "Amount of samples (only even numbers are accepted, odd numbers will be clamped)";
	ui_type = "drag";
	ui_min = 6; ui_max = 32;
> = 8;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Special Hue generator by JMF
float3 Spectrum(float Hue)
{
	float3 HueColor = abs(Hue * 4.0 - float3(1.0, 2.0, 1.0));
	HueColor = saturate(1.5 - HueColor);
	HueColor.xz += saturate(Hue * 4.0 - 3.5);
	HueColor.z = 1.0 - HueColor.z;
	return HueColor;
}

float3 ChromaticAberrationPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Grab Aspect Ratio
	float Aspect = ReShade::AspectRatio;
	// Grab Pixel V size
	float Pixel = ReShade::PixelSize.y;

	// Adjust number of samples
	int Samples;
	if (Automatic)
	{
		// Ceil odd numbers to even
		Samples = ceil(Aberration * 0.5) * 2;
		Samples += 2;
		// Minimum 6 samples for right color split
		Samples = max(Samples, 6);
	}
	else
	{
		// Clamp odd numbers to even
		Samples = floor(SampleCount * 0.5) * 2;
	}
	// Clamp maximum sample count
	Samples = min(Samples, 48);

	// Convert UVs to radial coordinates with correct Aspect Ratio
	float2 RadialCoord = texcoord * 2.0 - 1.0;
	RadialCoord.x *= Aspect;

	// Generate radial mask from center (0) to the corner of the screen (1)
//	float Mask = length(RadialCoord) / length(float2(Aspect, 1.0));
	float Mask = length(RadialCoord) * rsqrt(Aspect * Aspect + 1.0);

	// Reset values for each pixel sample
	float3 BluredImage = float3(0.0, 0.0, 0.0);
	float OffsetBase = Mask * Aberration * Pixel * 2.0;
	
	// Each loop represents one pass
	for(int P = 0; P < Samples && P <= 48; P++)
	{
		// Calculate current sample
		float CurrentSample = float(P) / float(Samples);

		float Offset = OffsetBase * CurrentSample + 1.0;

		// Scale UVs at center
		float2 Position = RadialCoord / Offset;
		// Convert aspect ratio back to square
		Position.x /= Aspect;
		// Convert radial coordinates to UV
		Position = Position * 0.5 + 0.5;

		// Multiply texture sample by HUE color
		BluredImage += Spectrum(CurrentSample) * tex2Dlod(ReShade::BackBuffer, float4(Position, 0, 0)).rgb;
	}
	BluredImage = BluredImage / Samples * 2.0;
	return BluredImage;
}

technique ChromaticAberration
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPS;
	}
}