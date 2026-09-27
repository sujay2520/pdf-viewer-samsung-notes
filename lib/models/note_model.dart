import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'annotation_model.dart';

enum NotePageTemplate {
  blank,
  ruled,
  grid,
  dotGrid,
  cornell,
}

extension NotePageTemplateExtension on NotePageTemplate {
  String get displayName {
    switch (this) {
      case NotePageTemplate.blank:
        return 'Blank';
      case NotePageTemplate.ruled:
        return 'Ruled / Lined';
      case NotePageTemplate.grid:
        return 'Grid / Graph';
      case NotePageTemplate.dotGrid:
        return 'Dot Grid';
      case NotePageTemplate.cornell:
        return 'Cornell Notes';
    }
  }

  IconData get icon {
    switch (this) {
      case NotePageTemplate.blank:
        return Icons.crop_portrait;
      case NotePageTemplate.ruled:
        return Icons.view_headline;
      case NotePageTemplate.grid:
        return Icons.grid_on;
      case NotePageTemplate.dotGrid:
        return Icons.grain;
      case NotePageTemplate.cornell:
        return Icons.vertical_split;
    }
  }
}

class NotePage {
  final String id;
  int pageNumber;
  NotePageTemplate template;
  bool isDark;
  String textContent;
  PageAnnotations annotations;

  NotePage({
    String? id,
    required this.pageNumber,
    this.template = NotePageTemplate.ruled,
    this.isDark = false,
    this.textContent = '',
    PageAnnotations? annotations,
  })  : id = id ?? const Uuid().v4(),
        annotations = annotations ?? PageAnnotations(pageNumber: pageNumber);

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageNumber': pageNumber,
        'template': template.name,
        'isDark': isDark,
        'textContent': textContent,
        'annotations': annotations.toJson(),
      };

  factory NotePage.fromJson(Map<String, dynamic> json) => NotePage(
        id: json['id'] as String,
        pageNumber: json['pageNumber'] as int,
        template: NotePageTemplate.values.byName(json['template'] as String? ?? 'ruled'),
        isDark: json['isDark'] as bool? ?? false,
        textContent: json['textContent'] as String? ?? '',
        annotations: json['annotations'] != null
            ? PageAnnotations.fromJson(json['annotations'] as Map<String, dynamic>)
            : PageAnnotations(pageNumber: json['pageNumber'] as int),
      );
}

class NoteDocument {
  final String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  bool isFavorite;
  String folder;
  List<NotePage> pages;
  String? pdfSourcePath;

  NoteDocument({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
    this.folder = 'General',
    List<NotePage>? pages,
    this.pdfSourcePath,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        pages = pages ?? [NotePage(pageNumber: 1)];

  NotePage get firstPage => pages.isNotEmpty ? pages.first : NotePage(pageNumber: 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isFavorite': isFavorite,
        'folder': folder,
        'pages': pages.map((p) => p.toJson()).toList(),
        'pdfSourcePath': pdfSourcePath,
      };

  factory NoteDocument.fromJson(Map<String, dynamic> json) => NoteDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isFavorite: json['isFavorite'] as bool? ?? false,
        folder: json['folder'] as String? ?? 'General',
        pages: (json['pages'] as List?)
                ?.map((p) => NotePage.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [NotePage(pageNumber: 1)],
        pdfSourcePath: json['pdfSourcePath'] as String?,
      );
}
