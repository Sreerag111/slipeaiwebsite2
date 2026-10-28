enum ImageAspectRatio {
  portrait('9:16', '1008x1792', 'vertical portrait'),
  fourByFive('4:5', '1408x1760', 'portrait');

  const ImageAspectRatio(this.label, this.apiSize, this.description);

  final String label;
  final String apiSize;
  final String description;

  String get promptInstruction =>
      'Create the image in a $label $description aspect ratio. '
      'Compose the entire scene for that orientation.';
}
