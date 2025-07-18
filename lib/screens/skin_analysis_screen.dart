import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/skin_analysis_view.dart';
import '../models/skin_analysis_model.dart';
import 'package:path/path.dart';

class SkinAnalysisScreen extends StatefulWidget {
  const SkinAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen> {
  ImageProvider? _imageProvider;
  Map<String, dynamic>? _analysisJson;
  Map<String, dynamic>? _gradioResult;
  File? _imageFile;
  Size? _originalImageSize;
  bool _loading = false;
  String? _error;
  SkinIssueType? _selectedIssueType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skin Analysis")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            if (_imageProvider != null &&
                (_analysisJson != null || _gradioResult != null) &&
                _originalImageSize != null)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _analysisJson != null
                          ? SkinAnalysisView(
                              analysisJson: _analysisJson!,
                              inputImage: _imageProvider!,
                              originalImageSize: _originalImageSize!,
                              selectedType: _selectedIssueType,
                            )
                          : Image(image: _imageProvider!, fit: BoxFit.contain),
                    ),
                    // Only show chips for types with location and not unknown
                    if (_analysisJson != null)
                      _buildHorizontalIssues(_analysisJson!),
                    if (_gradioResult != null)
                      _buildGradioResultWidget(_gradioResult!),
                  ],
                ),
              ),
            if (_imageProvider == null && !_loading && _error == null)
              const Expanded(
                child: Center(
                  child: Text(
                    "Pick an image to start analysis",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalIssues(Map<String, dynamic> analysisJson) {
    final patches = SkinPatch.fromJsonAll(analysisJson);
    // Only include types that are not unknown and have at least one patch with location
    final foundTypes = patches
        .where((p) =>
            p.issueType != SkinIssueType.unknown &&
            (p.rect != null || (p.polygon != null && p.polygon!.isNotEmpty)))
        .map((p) => p.issueType)
        .toSet()
        .toList();

    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: foundTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final type = foundTypes[idx];
          final name = skinIssueTypeDisplayName(type);
          final selected = _selectedIssueType == type;
          return ChoiceChip(
            label: Text(name),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedIssueType = selected ? null : type;
              });
            },
            selectedColor: Colors.blue.shade100,
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.blue : Colors.black,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradioResultWidget(Map<String, dynamic> data) {
    final List<Widget> items = [];
    if (data['data'] is List) {
      for (var element in data['data']) {
        if (element is Map) {
          element.forEach((key, value) {
            items.add(Text("$key: $value"));
          });
        } else if (element is String) {
          items.add(Text(element,
              style: const TextStyle(fontWeight: FontWeight.bold)));
        }
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        items.add(Text("$key: $value"));
      });
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Skin Problem Percentages",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...items,
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      _imageFile = File(picked.path);
      _imageProvider = FileImage(_imageFile!);
      _originalImageSize = await _getImageSize(_imageFile!);

      setState(() {
        _loading = true;
        _error = null;
        _analysisJson = null;
        _gradioResult = null;
        _selectedIssueType = null;
      });
      await _analyzeImage(_imageFile!);
    }
  }

  Future<Size> _getImageSize(File imageFile) async {
    final decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<void> _analyzeImage(File imageFile) async {
    Map<String, dynamic>? ailabData;
    Map<String, dynamic>? uploadApiResult;

    try {
      final uri = Uri.parse(
          "https://www.ailabapi.com/api/portrait/analysis/skin-analysis-pro");
      final req = http.MultipartRequest('POST', uri);
      req.headers['ailabapi-api-key'] =
          'qaZ9TlSGKuaXR1D06DbIOCW380RUrdek7iVxmHVYJs9FniA3U5cOBkPtNLrlJF2h';
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamedResp = await req.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map<String, dynamic>) {
          ailabData = decoded;
          if ((ailabData['results'] is List) &&
              ((ailabData['results'] as List?)?.isEmpty ?? true)) {
            ailabData = null;
          }
        } else if (decoded is List) {
          ailabData = {'results': decoded};
          if ((decoded).isEmpty) {
            ailabData = null;
          }
        } else {
          ailabData = null;
        }
      }
    } catch (e) {
      ailabData = null;
    }

    // Gradio Space
    try {
      final uri = Uri.parse(
          "https://www.ailabapi.com/api/portrait/analysis/skin-analysis-pro");
      final req = http.MultipartRequest('POST', uri);
      req.headers['ailabapi-api-key'] =
          'qaZ9TlSGKuaXR1D06DbIOCW380RUrdek7iVxmHVYJs9FniA3U5cOBkPtNLrlJF2h';
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamedResp = await req.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map<String, dynamic>) {
          ailabData = decoded;
          if ((ailabData['results'] is List) &&
              ((ailabData['results'] as List?)?.isEmpty ?? true)) {
            ailabData = null;
          }
        } else if (decoded is List) {
          ailabData = {'results': decoded};
          if ((decoded).isEmpty) {
            ailabData = null;
          }
        } else {
          ailabData = null;
        }
      }
    } catch (e) {
      ailabData = null;
    }

    // 2. Upload image + params to your backend using multipart POST
    try {
      final uri = Uri.parse(
          'https://aestheticai.globalspace.in/dev/aesthetic_backend/public/api/v3/uploadImageFromDoc');
      var request = http.MultipartRequest('POST', uri);

      request.fields['doctor_id'] = "70690";
      request.fields['patient_id'] = "42";
      request.fields['patient_number'] = "8600285374";

      request.files.add(
        await http.MultipartFile.fromPath(
          'images[]',
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        uploadApiResult = decoded;
      }
    } catch (e) {
      uploadApiResult = null;
    }

    setState(() {
      _analysisJson = ailabData;
      _gradioResult = uploadApiResult;
      _loading = false;
      _error = (_analysisJson == null && _gradioResult == null)
          ? "Both APIs failed or returned no detections. Try again."
          : null;
    });
  }
}
