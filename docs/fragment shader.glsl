#ifdef GL_ES
precision mediump float;
#endif

// Colour of the box
uniform vec4 u_Color;

// Enable/disable lighting
uniform bool u_isLighting;

// Texture information
uniform sampler2D u_Sampler;
uniform bool u_UseTextures;
uniform float u_TextureRepeat; // Number of times to tile the texture

// Lighting information
uniform vec3 u_AmbientColor;// Global light colour
uniform float u_Ambient; // Amount of ambient light
uniform float u_DiffuseMult; // Nifty value we can use to make a surface appear brighter than it would be naturally

const int numLights = 5;
uniform vec3 u_LightSources[numLights]; // Info of individual lightsource. Either position or direction (x, y, z)
uniform vec2 u_LightIntensity[numLights]; // Intensity of light. For spot light contains drop off factor
uniform bool u_LightType[numLights]; // Whether light source is spot or directional
uniform bool u_LightEnabled[numLights]; // Whether light source is enabled or not
uniform vec3 u_LightColor[numLights]; // Colour of the light

// Fog
uniform vec3 u_Eye;
uniform vec3 u_FogColor;
const vec2 fogDist = vec2(80, 150);
uniform bool u_ApplyFog;

// Varyings
varying vec3 v_Normal;
varying vec3 v_Position;
varying vec2 v_TexCoord;

void main() {
    // Final colour to be used, only modified if fog is enabled
    vec3 finalRGBColor;

    // Fragment colour (texture or colour)
    vec4 pixelColor;
    if (u_UseTextures) {
        pixelColor = texture2D(u_Sampler, v_TexCoord * u_TextureRepeat);
    } else {
        pixelColor = u_Color;
    }

    // We can change the ambient lighting to alter the base brightness
    vec3 ambient = u_Ambient * pixelColor.rgb;

    // Disable diffuse lighting if flag set
    if (!u_isLighting) {
        // Only ambient lighting
        finalRGBColor = u_Ambient * pixelColor.rgb;
    } else {
        // Diffuse lighting
        vec3 diffuse;
        for (int i = 0; i < numLights; i++) {
            // Only include lights that are turned on
            if (!u_LightEnabled[i]) {
                continue;
            }

            // Retrieve values from array
            float lightIntensity = u_LightIntensity[i].x;
            vec3 lightColor = u_LightColor[i];

            vec3 lightDirection;
            if (u_LightType[i]) {
                // Spot/positional lighting

                vec3 lightPosition = vec3(u_LightSources[i]);
                lightDirection = normalize(u_LightSources[i] - v_Position);

                // Get the light distance and divide it by the dropoff
                float lightDistance = length(u_LightSources[i] - v_Position) / u_LightIntensity[i].y;
                lightIntensity /= pow(1.0 + lightDistance, 2.0); // Use an inverse square law to provide additional dropoff as well as angle

                // Calculate the light direction and make it 1.0 in length
                // Dot product of light direction and normal
                float nDotL = max(dot(lightDirection, v_Normal), 0.0);
                diffuse += lightColor  * pixelColor.rgb * nDotL * lightIntensity;
            } else {
                // Support directional lighting, although we don't use this in the final version because it looks bad

                lightDirection = normalize(u_LightSources[i]);
                float nDotL = max(dot(lightDirection, v_Normal), 0.0);
                diffuse += nDotL * lightColor * pixelColor.rgb * lightIntensity;
            }
        }

        // Set the final colour by combining the diffuse and ambient lighting
        finalRGBColor = diffuse * u_DiffuseMult + ambient;
    }

    if (u_ApplyFog) {
        // Fog (adapted from book
        float Distance = distance(v_Position, u_Eye);
        float fogFactor = clamp((fogDist.y - Distance) / (fogDist.y - fogDist.x), 0.0, 1.0);
        finalRGBColor = mix(u_FogColor, finalRGBColor, fogFactor);
    }

    // Set the colour of the fragment
    gl_FragColor = vec4(finalRGBColor, pixelColor.a);
}