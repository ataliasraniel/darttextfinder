import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:darttextfinder/darttextfinder.dart' as darttextfinder;

void main(List<String> arguments) {
  final parser =
      ArgParser()
        ..addOption(
          'dir',
          abbr: 'd',
          help: 'Directory to search',
          defaultsTo: '/search/app',
        )
        ..addOption(
          'output',
          abbr: 'o',
          help: 'Output file path',
          defaultsTo: 'extracted_texts.json',
        )
        ..addFlag(
          'ignore-comments',
          abbr: 'i',
          help: 'Ignore comment lines',
          defaultsTo: true,
        )
        ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);

  try {
    final results = parser.parse(arguments);
    
    if (results['help']) {
      printUsage(parser);
      return;
    }

    final searchDir = results['dir'];
    final outputFile = results['output'];
    
    print('Searching for text strings in: $searchDir');
    print('Output will be saved to: $outputFile');
    
    // Use the library's function to get text strings by file
    final textStringsByFile = darttextfinder.findAllTextStringsWithFiles(searchDir);
    saveToJsonFile(textStringsByFile, outputFile);
    
    // Calculate total strings
    int totalStrings = 0;
    textStringsByFile.forEach((_, strings) => totalStrings += strings.length);
    
    print('Found $totalStrings text strings across ${textStringsByFile.length} files.');
    print('Results saved to $outputFile');
  } catch (e) {
    print('Error: $e');
    printUsage(parser);
  }
}

void printUsage(ArgParser parser) {
  print('Usage: dart darttextfinder.dart [options]');
  print(parser.usage);
}

void saveToJsonFile(Map<String, List<String>> textStringsByFile, String filePath) {
  final file = File(filePath);
  
  // Create the data structure
  final Map<String, Map<String, dynamic>> fileTextsMap = {};
  int totalStrings = 0;
  
  textStringsByFile.forEach((fileName, strings) {
    fileTextsMap[fileName] = {
      'textQuantity': strings.length,
      'textStrings': strings,
    };
    totalStrings += strings.length;
  });
  
  // Create the final JSON structure
  final Map<String, dynamic> jsonOutput = {
    'totalStrings': totalStrings,
    'data': fileTextsMap,
  };
  
  // Convert to JSON and write to file
  final jsonString = jsonEncode(jsonOutput);
  file.writeAsStringSync(jsonString);
}
