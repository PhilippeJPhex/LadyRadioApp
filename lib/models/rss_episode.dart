import 'package:xml/xml.dart';

class RssEpisode {
  final String title;
  final String description;
  final String pubDate;
  final String audioUrl;
  final String imageUrl;
  final String duration;
  String? programId;

  RssEpisode({
    required this.title,
    required this.description,
    required this.pubDate,
    required this.audioUrl,
    required this.imageUrl,
    required this.duration,
    this.programId,
  });

  factory RssEpisode.fromXml(XmlElement xmlNode) {
    // Helper to get text from node, gracefully handling missing nodes
    String getText(String elementName) {
      final elements = xmlNode.findElements(elementName);
      return elements.isNotEmpty ? elements.first.innerText : '';
    }

    // Attempt to extract duration (often in itunes:duration)
    final itunesDuration = xmlNode.findElements('itunes:duration');
    String durationStr = itunesDuration.isNotEmpty ? itunesDuration.first.innerText : '00:00';

    // Attempt to extract image (from itunes:image or fallback)
    final itunesImage = xmlNode.findElements('itunes:image');
    String imageUrl = '';
    if (itunesImage.isNotEmpty) {
      imageUrl = itunesImage.first.getAttribute('href') ?? '';
    }
    
    // Attempt to extract audio url from enclosure
    final enclosure = xmlNode.findElements('enclosure');
    String audioUrl = '';
    if (enclosure.isNotEmpty) {
      audioUrl = enclosure.first.getAttribute('url') ?? '';
    }

    return RssEpisode(
      title: getText('title'),
      description: getText('description'),
      pubDate: getText('pubDate'),
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      duration: durationStr,
    );
  }
}
