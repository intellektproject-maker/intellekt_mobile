class UsefulLink {
  final int linkId;
  final String title;
  final String url;

  const UsefulLink({
    required this.linkId,
    required this.title,
    required this.url,
  });

  factory UsefulLink.fromJson(Map<String, dynamic> json) {
    return UsefulLink(
      linkId: _parseInt(json['link_id']),
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
