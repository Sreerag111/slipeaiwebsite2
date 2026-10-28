import '../services/image_preset_service.dart';

export '../services/image_preset_service.dart';

class ImagePreset {
  const ImagePreset({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.prompt,
    this.order,
  });

  final String id;
  final String title;
  final String imagePath;
  final String prompt;
  final int? order;

  /// Load the configured asset first, then try its PNG/JPG counterpart.
  List<String> get imageAssetCandidates {
    final dot = imagePath.lastIndexOf('.');
    final stem = dot < 0 ? imagePath : imagePath.substring(0, dot);
    return imagePath.toLowerCase().endsWith('.jpg')
        ? ['$stem.jpg', '$stem.png']
        : ['$stem.png', '$stem.jpg'];
  }
}

/// Dynamically loaded presets (from Firestore), falling back to [defaultImagePresets].
List<ImagePreset> get imagePresets => ImagePresetService.instance.presets;

/// Preset thumbnails are bundled locally; only the user's selected photo is
/// sent to the existing image-edit flow when they choose a preset.
const defaultImagePresets = <ImagePreset>[
  // 1. nineties_camera
  ImagePreset(
    id: 'nineties_camera',
    title: "90's Camera",
    imagePath: 'assets/images/create_image_categories/nineties_camera.png',
    order: 1,
    prompt:
        '''Transform the uploaded photo into an authentic, distressed late-1990s compact film-camera photograph.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, face shape, eyes, natural facial features, skin tone, and recognizable appearance.
AESTHETIC & STYLE: Add raw, candid late-1990s direct on-camera flash illumination with fast light falloff into a dark moody background. Authentic 35mm ISO 800 silver-halide film grain with tactile organic texture. Warm Kodak nostalgic color grading with rich amber and honey tones, creamy skin tones, and lifted matte charcoal blacks. A delicate network of fine hairline scratches, light dust specks, subtle paper crease lines, and a soft, narrow amber light leak kissing the border. Authentic vintage 1990s flash snapshot.''',
  ),
  // 2. golden_effect
  ImagePreset(
    id: 'golden_effect',
    title: "Golden Effect",
    imagePath: 'assets/images/create_image_categories/golden_effect.png',
    order: 2,
    prompt:
        '''Transform the uploaded photo into an ultra-realistic cinematic golden-hour close-up portrait.
IDENTITY PRESERVATION: Preserve the person's exact face, facial features, eye shape, smile, skin tone, and recognizable likeness. Frame the portrait from the upper chest to the top of the head.
HEAD COVERING & OUTFIT: Wrap the hair and upper head in a sophisticated black fabric scarf adorned with intricate metallic-gold ornamental patterns and visible realistic woven fabric folds.
LIGHTING & ATMOSPHERE: Drench the portrait in warm, radiant low-angle golden-hour sunlight creating glowing golden highlights across the face, natural catchlights in the eyes, and rich soft shadows. One hand gently and naturally touches the head scarf. 8k cinematic portrait photography, shallow depth of field, warm ambient sunset glow.''',
  ),
  // 3. three_d_figure
  ImagePreset(
    id: 'three_d_figure',
    title: "3D Figure",
    imagePath: 'assets/images/create_image_categories/three_d_figure.png',
    order: 3,
    prompt:
        '''Transform the person in the uploaded photo into a premium photorealistic 3D collectible vinyl figure inside a luxury dark retail blister box.
IDENTITY & FIGURE: Preserve the person's recognizable facial likeness, eye shape, smile, and hairstyle, sculpted into a realistic 3D vinyl collectible figure. The figure stands full-body inside the central molded transparent plastic blister cavity of a large vertical collector box.
PACKAGING: Rigid dark cardboard retail box with glossy black and champagne-gold accents, transparent blister plastic cover with realistic commercial studio reflections, and molded compartments for miniature accessories. Top panel features elegant typography "3D ME: COLLECTIBLE FIGURE". Professional commercial toy product photography.''',
  ),
  // 4. me_and_my_dog
  ImagePreset(
    id: 'me_and_my_dog',
    title: "Me & My Dog",
    imagePath: 'assets/images/create_image_categories/me_and_my_dog.png',
    order: 4,
    prompt:
        '''Transform the uploaded photo into a heartwarming, ultra-realistic outdoor golden-hour portrait of the person with a loyal golden retriever dog.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial structure, skin tone, hairstyle, and recognizable appearance.
SCENE: The person is sitting comfortably beside or gently hugging a beautiful healthy golden retriever with soft fluffy golden fur and kind expressive eyes. Set in a sun-drenched grassy park during warm late-afternoon golden hour, with soft backlit sunlight haloing their hair, gentle rim lighting, natural lens flare, and a beautifully blurred green nature background. Candid, joyful lifestyle photography, 8k resolution.''',
  ),
  // 5. aesthetic_scrapbook
  ImagePreset(
    id: 'aesthetic_scrapbook',
    title: "Aesthetic Scrapbook",
    imagePath: 'assets/images/create_image_categories/aesthetic_scrapbook.png',
    order: 5,
    prompt:
        '''Transform the uploaded photo into a high-end luxury vintage travel scrapbook collage.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, features, and recognizable appearance.
COMPOSITION: Present the subject through a multi-frame editorial arrangement of printed photographs physically overlapping on a warm cream-colored textured paper canvas. Include artistic Polaroid-style frames, subtle washi tape accents, handwritten notes, botanical dried flower details, soft film grain, and warm Mediterranean vacation aesthetic with golden sunlight. Sophisticated lifestyle magazine layout, tactile paper textures, elegant and nostalgic.''',
  ),
  // 6. y2k_style
  ImagePreset(
    id: 'y2k_style',
    title: "Y2K Style",
    imagePath: 'assets/images/create_image_categories/y2k_style.png',
    order: 6,
    prompt:
        '''Transform the uploaded photo into an authentic late-1990s to early-2000s (Y2K) aesthetic cyber-fashion photoshoot.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial features, eye shape, and recognizable appearance.
OUTFIT & STYLING: Dress the person in iconic Y2K fashion: metallic silver accents, chunky tinted sunglasses, sporty track jacket, futuristic cargo pants, and bold millennial accessories.
AESTHETIC: Nostalgic early-2000s CD-ROM holographic shimmer, wide-angle lens perspective, vibrant cyan and magenta tinting, glossy chrome textures, and punchy direct digital camera flash. Authentic retro Y2K magazine aesthetic.''',
  ),
  // 7. twin_me
  ImagePreset(
    id: 'twin_me',
    title: "Twin Me",
    imagePath: 'assets/images/create_image_categories/twin_me.png',
    order: 7,
    prompt:
        '''Create a stunning, photorealistic creative portrait featuring the uploaded person side-by-side with their identical twin.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial features, face shape, eyes, skin tone, and natural appearance 100% identically for both figures.
COMPOSITION: Both identical twins appear in the same frame, standing shoulder-to-shoulder with complementary stylish modern outfits and natural interactive poses (one looking confident toward the camera, the other with a subtle smile). Professional studio lighting, seamless realistic interaction, authentic depth of field, sharp photographic details.''',
  ),
  // 8. cowboy
  ImagePreset(
    id: 'cowboy',
    title: "Cowboy",
    imagePath: 'assets/images/create_image_categories/cowboy.png',
    order: 8,
    prompt:
        '''Transform the uploaded photo into a premium cinematic Western cowboy portrait.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial structure, eyes, eyebrows, nose, lips, jawline, skin tone, and recognizable appearance.
COWBOY OUTFIT: Dress the person in an authentic, stylish Western cowboy outfit: a quality leather cowboy hat, rugged Western shirt, fitted leather vest, jeans, and classic leather belt with a buckle.
SCENE & LIGHTING: A majestic, realistic horse stands calmly beside the person. Set in a breathtaking cinematic Western desert landscape at golden-hour sunset, with dramatic rim lighting, distant mountains, dusty trails, and atmospheric film grain.''',
  ),
  // 9. barbie_me
  ImagePreset(
    id: 'barbie_me',
    title: "Barbie Me",
    imagePath: 'assets/images/create_image_categories/barbie_me.png',
    order: 9,
    prompt:
        '''Transform the person in the uploaded photo into a premium photorealistic fashion doll inside a luxury pink retail toy box.
IDENTITY & DOLL: Preserve the person's recognizable facial likeness, face shape, eye shape, smile, and hairstyle, sculpted into a collectible fashion doll appearance with smooth vinyl finish.
PACKAGING: The doll stands full-body on the left side inside a transparent plastic blister box with soft rose-gold and pastel pink packaging. The right side features molded compartments displaying miniature toy accessories: sunglasses, handbag, laptop, high heels, and perfume bottle. Elegant script logo treatment "Doll Version of Me" at the top. Clean commercial toy product photography.''',
  ),
  // 10. mafia
  ImagePreset(
    id: 'mafia',
    title: "Mafia",
    imagePath: 'assets/images/create_image_categories/mafia.png',
    order: 10,
    prompt:
        '''Transform the person in the uploaded photo into the main protagonist of a 1940s–1950s cinematic Mafia crime film.
IDENTITY PRESERVATION: Preserve the uploaded person's exact facial identity, facial features, eyes, jawline, hairstyle, skin tone, and recognizable likeness.
OUTFIT & POSE: Show the person walking confidently toward the camera down a rain-soaked vintage city street at night. Dress them in a tailored dark charcoal three-piece suit, patterned tie, polished leather shoes, and a long black overcoat flowing behind them.
ATMOSPHERE: Dramatic film-noir atmosphere: wet cobblestone reflections, vintage glowing street lamps, classic 1940s cars parked along the curb, light rain, and atmospheric mist.''',
  ),
  // 11. gangster_look
  ImagePreset(
    id: 'gangster_look',
    title: "Gangster",
    imagePath: 'assets/images/create_image_categories/gangster_look.png',
    order: 11,
    prompt:
        '''Transform the person in the uploaded photo into a powerful, sophisticated modern gangster boss portrait.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial features, eyes, hairstyle, skin tone, and recognizable likeness.
SCENE & OUTFIT: The person is seated in a tufted dark leather armchair inside a private luxury lounge with wood-paneled walls and dim ambient lighting. Dressed in a sharply tailored designer dark suit with an unbuttoned collar, subtle gold chain, and luxury wristwatch. Moody cinematic chiaroscuro lighting, soft amber backlighting, shallow depth of field, and a commanding, confident expression.''',
  ),
  // 12. ai_photoshoot
  ImagePreset(
    id: 'ai_photoshoot',
    title: "Photoshoot",
    imagePath: 'assets/images/create_image_categories/photoshoot.png',
    order: 12,
    prompt:
        '''Transform the uploaded photo into a high-end luxury fashion-editorial studio photoshoot.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial features, skin tone, hairstyle, and recognizable natural appearance.
OUTFIT & LIGHTING: Style the person in modern haute-couture designer clothing with clean lines and premium fabric textures. Professional high-fashion studio lighting setup with soft key light, gentle fill, and subtle rim light defining their silhouette against a clean minimalist studio backdrop. Posed naturally like a top fashion magazine cover (Vogue/GQ style), razor-sharp 8k details, and cinematic color grading.''',
  ),
  // 13. aesthetic_collage
  ImagePreset(
    id: 'aesthetic_collage',
    title: "Aesthetic Collage",
    imagePath: 'assets/images/create_image_categories/aesthetic_collage.png',
    order: 13,
    prompt:
        '''Transform the uploaded photo into an aesthetic multi-frame lifestyle fashion collage.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, skin tone, hairstyle, and recognizable likeness.
COMPOSITION: An elegant arrangement of 4-5 complementary photographs of the subject with diverse framing (main portrait, artistic half-body shot, detailed close-up) artfully layered with soft shadows, delicate white margins, warm film colors, and natural sunlight against a minimalist warm beige editorial background. High-end Pinterest/Instagram moodboard aesthetic.''',
  ),
  // 14. cartoon_look
  ImagePreset(
    id: 'cartoon_look',
    title: "Cartoon Look",
    imagePath: 'assets/images/create_image_categories/cartoon_look.png',
    order: 14,
    prompt:
        '''Transform the person in the uploaded photo into a gorgeous 3D animated character in the style of modern Pixar/Disney animation.
IDENTITY & STYLIZATION: Preserve the person's recognizable facial likeness, hairstyle, eye color, facial hair, smile, and signature expression while translating their features into smooth, stylized 3D animation aesthetics. Big expressive eyes with detailed catchlights, soft subsurface scattering skin shaders, stylized hair geometry, warm natural lighting, and a charming animated world background. Vibrant, high-production 3D animation render.''',
  ),
  // 15. polaroid_frame
  ImagePreset(
    id: 'polaroid_frame',
    title: "Polaroid Frame",
    imagePath: 'assets/images/create_image_categories/polaroid_frame.png',
    order: 15,
    prompt:
        '''Transform the uploaded photo into an authentic vintage white Polaroid instant photograph.
IDENTITY PRESERVATION: Preserve the original photo and the person's exact identity, face, expression, skin tone, and clothing completely unchanged.
POLAROID FRAME: Frame the entire photo inside an iconic physical white Polaroid border with the classic wide bottom margin. Add realistic physical paper texture, subtle corner handling wear, gentle surface gloss reflections, soft natural shadows cast beneath the print, and authentic vintage instant-film color grading. Authentic physical photograph lying on a clean surface.''',
  ),
  // 16. hip_hop
  ImagePreset(
    id: 'hip_hop',
    title: "Hip-Hop",
    imagePath: 'assets/images/create_image_categories/hip_hop.png',
    order: 16,
    prompt:
        '''Transform the uploaded photo into a high-energy cinematic hip-hop streetwear portrait.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial structure, eyes, hairstyle, skin tone, and recognizable appearance.
STREETWEAR: Replace the clothing with modern luxury streetwear: oversized designer bomber jacket, baggy cargo pants, fresh sneakers, layered silver/gold chain, and a stylish watch.
NEON ATMOSPHERE: Set in a vibrant urban city street at night illuminated by neon purple, electric blue, and magenta lights with wet asphalt reflections, subtle atmospheric haze, and dynamic music-video rim lighting.''',
  ),
  // 17. me_with_my_bike
  ImagePreset(
    id: 'me_with_my_bike',
    title: "Me & My Bike",
    imagePath: 'assets/images/create_image_categories/me_with_my_bike.png',
    order: 17,
    prompt:
        '''Transform the person in the uploaded photo into an ultra-realistic cinematic motorcycle photoshoot.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, face shape, eyes, hairstyle, skin tone, and recognizable likeness.
SUPERBIKE: The person stands confidently beside a gorgeous, sleek matte-black high-performance sports superbike (Yamaha R1 / Ducati Panigale style) with aggressive aerodynamic fairings, polished exhaust, and wide sport tires.
LOCATION & LIGHTING: Positioned on an open coastal mountain highway overlook during a breathtaking golden-hour sunset, with dramatic rim lighting tracing the rider and motorcycle, city lights shimmering in the distant bay below, and cinematic warm skies.''',
  ),
  // 18. personality_sketch
  ImagePreset(
    id: 'personality_sketch',
    title: "Personality Sketch",
    imagePath: 'assets/images/create_image_categories/personality_sketch.png',
    order: 18,
    prompt:
        '''Transform the uploaded photo into a breathtaking handcrafted graphite pencil and charcoal artist sketch.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial proportions, eyes, nose, lips, hair, and recognizable likeness through precise artistic pencil hatching, cross-hatching, and smooth charcoal blending.
ARTISTIC DETAILS: Realistic paper grain texture with delicate visible sketch guidelines, varied pencil pressure strokes, soft smudging for depth, and clean white highlights. Authentic sketchbook artwork drawn by a master portrait artist.''',
  ),
  // 19. korean_streetwear
  ImagePreset(
    id: 'korean_streetwear',
    title: "Korean Streetwear",
    imagePath: 'assets/images/create_image_categories/korean_streetwear.png',
    order: 19,
    prompt:
        '''Transform the uploaded photo into a trendy Seoul K-fashion editorial portrait.
IDENTITY PRESERVATION: Preserve the person's exact facial identity, facial features, hairstyle, skin tone, and natural appearance.
K-FASHION: Dress the person in high-end Korean streetwear: an oversized minimalist trench coat or boxy blazer, layered hoodie or turtleneck, tailored wide-leg trousers, minimalist leather sneakers, and subtle silver jewelry.
SETTING: Set in a stylish modern Seoul alleyway or minimalist concrete architectural setting with soft overcast daylight, clean color palette (charcoal, cream, sage, black), and effortless aesthetic modeling pose.''',
  ),
  // 20. me_and_my_toy
  ImagePreset(
    id: 'me_and_my_toy',
    title: "Me & My Toy",
    imagePath: 'assets/images/create_image_categories/me_and_my_toy.png',
    order: 20,
    prompt:
        '''Transform the uploaded photo into a charming, creative tilt-shift miniature toy photography scene.
IDENTITY & MINIATURIZATION: Preserve the person's recognizable facial likeness, hair, and clothing, reimagined as an adorable miniature collectible figurine placed inside a macro real-world environment.
MACRO PHOTOGRAPHY: Strong tilt-shift depth of field with blurred foreground and background, macro lens perspective, smooth vinyl and painted plastic materials with realistic specular highlights, and warm soft table-top lighting. High-end designer toy photography.''',
  ),
  // 21. black_and_white
  ImagePreset(
    id: 'black_and_white',
    title: "Black & White",
    imagePath: 'assets/images/create_image_categories/black_and_white.png',
    order: 21,
    prompt:
        '''Transform the uploaded photo into a museum-grade black-and-white fine-art portrait.
IDENTITY PRESERVATION: Preserve the person's exact identity, face, facial features, skin tone gradation, hairstyle, and expression.
MONOCHROME AESTHETIC: Render the entire scene in rich, high-contrast monochrome with deep velvety blacks, luminous silvery midtones, and crisp clean highlights. Dramatic Rembrandt studio lighting sculpting the facial contours, realistic skin texture, shallow depth of field, and subtle analog film grain. Timeless, powerful, luxury fashion magazine black-and-white photography.''',
  ),
];
