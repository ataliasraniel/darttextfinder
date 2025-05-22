// Add this export at the top of the file
import 'dart:io';

import 'package:path/path.dart' as path;

// Add this new function to the library
/// Finds all text strings in Flutter dart files within a directory
/// and organizes them by file
Map<String, List<String>> findAllTextStringsWithFiles(String directoryPath) {
  final directory = Directory(directoryPath);
  final Map<String, List<String>> textStringsByFile = {};

  if (!directory.existsSync()) {
    throw ArgumentError('Directory not found: $directoryPath');
  }

  final entities = directory.listSync(recursive: true);

  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final fileContent = entity.readAsStringSync();
      final fileName = path.basename(entity.path);
      final textStrings = <String>{};

      extractTextStrings(fileContent, textStrings);

      if (textStrings.isNotEmpty) {
        textStringsByFile[fileName] = textStrings.toList()..sort();
      }
    }
  }

  return textStringsByFile;
}

/// Extracts text strings from a Dart file content
void extractTextStrings(String content, Set<String> textStrings) {
  // First, remove comment lines and import statements
  final List<String> lines = content.split('\n');
  final List<String> filteredLines = [];

  for (var line in lines) {
    final trimmedLine = line.trim();
    if (!trimmedLine.startsWith('//') && !trimmedLine.startsWith('import ')) {
      filteredLines.add(line);
    }
  }

  final filteredContent = filteredLines.join('\n');

  // Regular expression to match strings in single or double quotes
  final doubleQuoteRegex = RegExp(r'"(?:[^"\\]|\\.)*"');
  final singleQuoteRegex = RegExp(r"'(?:[^'\\]|\\.)*'");

  // Find all matches for double-quoted strings
  final doubleQuoteMatches = doubleQuoteRegex.allMatches(filteredContent);
  for (var match in doubleQuoteMatches) {
    final text = match.group(0)!;
    // Remove the quotes and add to the set if it's not empty
    final cleanText = text.substring(1, text.length - 1);
    if (cleanText.isNotEmpty && !isCodeOrComment(cleanText)) {
      textStrings.add(cleanText);
    }
  }

  // Find all matches for single-quoted strings
  final singleQuoteMatches = singleQuoteRegex.allMatches(filteredContent);
  for (var match in singleQuoteMatches) {
    final text = match.group(0)!;
    // Remove the quotes and add to the set if it's not empty
    final cleanText = text.substring(1, text.length - 1);
    if (cleanText.isNotEmpty && !isCodeOrComment(cleanText)) {
      textStrings.add(cleanText);
    }
  }
}

/// Checks if a string is likely code or a comment rather than UI text
bool isCodeOrComment(String text) {
  // Immediately return true for common code patterns
  if (text.startsWith(r'$') || text.contains('/')) {
    return true;
  }

  // Check if the text contains emoji characters
  if (containsEmoji(text)) {
    return true;
  }

  // Filter out common code patterns that aren't UI text
  final codePatterns = [
    RegExp(r'^[a-zA-Z0-9_]+$'), // Variable names
    RegExp(r'^https?://'), // URLs
    RegExp(r'^[\d.]+$'), // Numbers
    RegExp(r'^#[0-9a-fA-F]{3,8}$'), // Color codes
    RegExp(r'^[{}[\](),:;]$'), // Single punctuation
    RegExp(r'^//'), // Comment start
    RegExp(r'^import\s+'), // Import statements
    RegExp(r'^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+'), // Object properties
    RegExp(r'^\$\{.*\}$'), // String interpolation
    RegExp(r'^\.'), // Starts with dot (like .pdf)
    RegExp(r'^\.\./'), // Relative paths
    RegExp(r'.*\.(pdf|png|xlsx|dart)$'), // Any file with common extensions
  ];

  for (var pattern in codePatterns) {
    if (pattern.hasMatch(text)) {
      return true;
    }
  }

  // Also check for common code keywords
  final codeKeywords = [
    'return',
    'if',
    'else',
    'for',
    'while',
    'switch',
    'case',
    'break',
    'continue',
    'class',
    'void',
    'int',
    'double',
    'String',
    'List',
    'Map',
    'Set',
    'bool',
    'true',
    'false',
    'null',
    'this',
    'super',
    'new',
    'final',
    'const',
    'static',
    'get',
    'set',
    'async',
    'await',
    'Future',
    'Stream',
    '_',
    '-',
    'var',
  ];

  if (codeKeywords.contains(text)) {
    return true;
  }

  return false;
}

/// Checks if a string contains emoji characters
bool containsEmoji(String text) {
  // A simpler approach using a single regex with the unicode property
  final emojiRegex = RegExp(r'(\p{Emoji})', unicode: true);

  if (emojiRegex.hasMatch(text)) {
    return true;
  }

  // Also check for specific characters that might not be caught
  if (text.contains('•') || text.contains('…')) {
    return true;
  }

  return false;
}
