import 'package:flutter/material.dart';

/// Material Symbols-style icons referenced by name in home_sections.json.
const configIcons = <String, IconData>{
  'quiz': Icons.quiz_rounded,
  'menu_book': Icons.menu_book_rounded,
  'description': Icons.description_rounded,
  'campaign': Icons.campaign_rounded,
  'edit_note': Icons.edit_note_rounded,
  'emoji_events': Icons.emoji_events_rounded,
  'smart_display': Icons.smart_display_rounded,
  'child_care': Icons.child_care_rounded,
  'construction': Icons.construction_rounded,
  'newspaper': Icons.newspaper_rounded,
  'school': Icons.school_rounded,
  'science': Icons.science_rounded,
  'calculate': Icons.calculate_rounded,
  'translate': Icons.translate_rounded,
  'public': Icons.public_rounded,
  'eco': Icons.eco_rounded,
  'groups': Icons.groups_rounded,
  'auto_stories': Icons.auto_stories_rounded,
};

IconData configIcon(String? name) => configIcons[name] ?? Icons.folder_rounded;

const subjectIcons = <String, IconData>{
  'kannada': Icons.translate_rounded,
  'english': Icons.abc_rounded,
  'hindi': Icons.translate_rounded,
  'maths': Icons.calculate_rounded,
  'science': Icons.science_rounded,
  'social': Icons.public_rounded,
  'evs': Icons.eco_rounded,
};
