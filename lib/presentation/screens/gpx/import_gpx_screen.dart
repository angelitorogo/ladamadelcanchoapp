import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/parse_gpx_file.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/preview-track-screen.dart';

class ImportGpxScreen extends StatefulWidget {
  static const name = 'import-gpx-screen';

  const ImportGpxScreen({super.key});

  @override
  State<ImportGpxScreen> createState() => _ImportGpxScreenState();
}

class _ImportGpxScreenState extends State<ImportGpxScreen> {
  String? selectedFileName;
  bool archivoOk = false;
  FilePickerResult? result;
  List<LocationPoint>? points;

  Future<void> _pickGpxFile() async {
    result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecciona un archivo GPX',
      type: FileType.any,
    );

    

    if (result != null && result!.files.isNotEmpty) {
      String? ext = result!.files.single.name.split('.').last;
       final File gpxFile = File(result!.files.single.path!);
       points = await parseGpxFileToPoints(gpxFile);

      if( ext != 'gpx') {
        setState(() {
          selectedFileName = 'archivo NO permitido';
          archivoOk = false;
        });
      } else {
        setState(() {
          selectedFileName = result!.files.single.name;
          archivoOk = true;
        });
      }
      

      // Aquí podrías también guardar la ruta completa si la necesitás:
      // result.files.single.path
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar GPX')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
          
              
          
              ElevatedButton.icon(
                onPressed: _pickGpxFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar archivo GPX'),
              ),
              const SizedBox(height: 40),
          
          
              if(archivoOk) 
          
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedFileName != null)
                  Text(
                    selectedFileName!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                  onPressed: () async {

                    //comprobar si hay o no internet
                    final hasInternet = await checkAndWarnIfNoInternet(context);

                    if(hasInternet && context.mounted) {

                      await context.pushNamed(
                        TrackPreviewScreen.name, // o TrackPreviewScreen.name
                        extra: {
                          'trackFile': File(result!.files.single.path!), // puedes cambiar por un File real si lo necesitas
                          'points': points,
                        },
                      );


                    }


                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Importar archivo'),
                ),
                
                
          
                ],
              )
          
              
          
                
          
          
          
            ],
          ),
        ),
      ),
    );
  }
}
