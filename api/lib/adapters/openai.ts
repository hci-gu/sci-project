import dotenv from 'dotenv'
dotenv.config()
import OpenAI from 'openai'
const openai = new OpenAI()

const generatePrompt = (calories: number) => `
(${new Date().toISOString()}) 
Abstract Cubist Night scene from 'Cycle of Balance' triptych (moose version).
Aspect 3:5, deep-navy.
Flat-vector painterly style with subtle paper-grain texture.
Palette: indigo #1C2436, plum #3D2A3B, ember gold #E4B661,
accent moss #B7C48E, and ivory #F9F4E6.
Lighting soft and low, rim glow along moose silhouette;
facets subdued and cool with faint gold edges.
Background: seven-node constellation network subtly echoing antler geometry,
each node representing one of the last 7 days energy;
connected by faint golden lines, brightest node (today) near moose's head.
Moose in side profile facing right, posture relaxed, head lowered,
antlers spreading outward. Front-left hoof resting lightly near a large
translucent moss orb ({BUBBLE_SIZE}% canvas width).
Body formed by angular shard facets blending into the dark background.
Metrics visuals:
- {PLANKTON_COUNT} faint gold motes behind left antler;
- eye halo {ANEMONE_BRIGHTNESS}% brightness;
- nebula veil overlay at {FOG_DENSITY}% opacity, ~56 px grid.
Top-left text (ALL CAPS):
'{WEEKDAY}'
'{DATE}'
geometric sans, flush-left.
Bottom-centre caption: '{CAPTION}' Ivory text.
Gentle vignette; 1-2 px light-gold rim-light along antlers and shoulders.
No icons or shadows.
`

const generateImage = async (prompt: string) => {
  const response = await openai.responses.create({
    model: 'gpt-5',
    input: prompt,
    tools: [{ type: 'image_generation' }],
  })

  // return base64 image data
  const imageData = response.output
    .filter((output: any) => output.type === 'image_generation_call')
    .map((output: any) => output.result as string | null)

  if (imageData.length === 0) {
    throw new Error('No image data returned from OpenAI')
  }

  const base64 = imageData[0]
  if (!base64) {
    throw new Error('Image result is null or empty')
  }

  return Buffer.from(base64, 'base64')
}

export default {
  generateImage,
  generatePrompt,
}
