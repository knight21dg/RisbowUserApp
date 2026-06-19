/// Mirrors the JSON schema the server sends.
/// Every UI element is described by type + props + optional children.
class SduiNode {
  final String type;
  final Map<String, dynamic> props;
  final List<SduiNode>? children;

  const SduiNode({
    required this.type,
    this.props = const {},
    this.children,
  });

  factory SduiNode.fromJson(Map<String, dynamic> json) => SduiNode(
        type: json['type'] as String,
        props: Map<String, dynamic>.from(json['props'] as Map? ?? {}),
        children: (json['children'] as List<dynamic>?)
            ?.map((e) => SduiNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'props': props,
        if (children != null) 'children': children!.map((e) => e.toJson()).toList(),
      };
}

/// A full page = ordered list of sections.
class SduiPage {
  final String schemaVersion;
  final String pageTitle;
  final List<SduiNode> sections;

  const SduiPage({
    this.schemaVersion = '1.0',
    this.pageTitle = '',
    this.sections = const [],
  });

  factory SduiPage.fromJson(Map<String, dynamic> json) => SduiPage(
        schemaVersion: json['schema_version'] as String? ?? '1.0',
        pageTitle: json['page_title'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => SduiNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
