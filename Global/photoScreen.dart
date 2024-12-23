import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/take_away_orders/take_away_providers/photoProvider.dart';

class PhotosScreen extends StatelessWidget {
  final String customId;

  const PhotosScreen({Key? key, required this.customId}) : super(key: key);

  Future<void> _fetchPhotos(BuildContext context, String customId) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    photoProvider.clearPhotos(); // Clear any existing data
    await photoProvider.fetchPhotos(customId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _fetchPhotos(context, customId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return _PhotoGrid();
        }
      },
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);

    if (photoProvider.photos.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No photos found')),
      );
    }

    return Scaffold(
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: photoProvider.photos.length,
        itemBuilder: (ctx, index) {
          final photoId = photoProvider.photos[index]['photo_id'];
          final cachedImage = photoProvider.photoCache[photoId];

          return GestureDetector(
            onTap: () async {
              final imageBytes = await photoProvider.fetchPhotoById(photoId);
              if (imageBytes != null) {
                _showFullScreenImage(context, imageBytes);
              }
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 3,
              child: cachedImage != null
                  ? Image.memory(
                      cachedImage,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                10.0), // Optional: Adds rounded corners to the dialog
          ),
          child: SizedBox(
            width: 900, // Set the width of the dialog box
            height: 600, // Set the height of the dialog box
            child: Stack(
              children: [
                Center(
                  child: FractionallySizedBox(
                    alignment: Alignment.center,
                    widthFactor: 0.9, // 80% of the dialog width
                    heightFactor: 0.8, // 60% of the dialog height
                    child: Image.memory(imageBytes),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class PhotosScreen extends StatelessWidget {
//   final String customId;

//   const PhotosScreen({Key? key, required this.customId}) : super(key: key);

//   Future<void> _fetchPhotos(BuildContext context, String customId) async {
//     final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
//     photoProvider.clearPhotos(); // Clear any existing data
//     await photoProvider.fetchPhotos(customId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: _fetchPhotos(context, customId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         } else if (snapshot.hasError) {
//           return Scaffold(
//             body: Center(child: Text('Error: ${snapshot.error}')),
//           );
//         } else {
//           return _PhotoGrid(); // Updated Grid UI
//         }
//       },
//     );
//   }
// }

// class _PhotoGrid extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final photoProvider = Provider.of<PhotoProvider>(context);

//     if (photoProvider.photos.isEmpty) {
//       return const Scaffold(
//         body: Center(child: Text('No photos found')),
//       );
//     }

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             children: [
//               Wrap(
//                 spacing: 20, // Horizontal space between photos
//                 runSpacing: 20, // Vertical space between rows
//                 children: List.generate(photoProvider.photos.length, (index) {
//                   final photoId = photoProvider.photos[index]['photo_id'];
//                   final cachedImage = photoProvider.photoCache[photoId];

//                   return GestureDetector(
//                     onTap: () async {
//                       final imageBytes =
//                           await photoProvider.fetchPhotoById(photoId);
//                       if (imageBytes != null) {
//                         _showFullScreenImage(context, imageBytes);
//                       }
//                     },
//                     child: Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(10),
//                         image: cachedImage != null
//                             ? DecorationImage(
//                                 image: MemoryImage(cachedImage),
//                                 fit: BoxFit.cover,
//                               )
//                             : null,
//                       ),
//                       child: cachedImage == null
//                           ? const Center(
//                               child: CircularProgressIndicator(),
//                             )
//                           : null,
//                     ),
//                   );
//                 }),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           insetPadding: EdgeInsets.all(0),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: SizedBox(
//             width: 900,
//             height: 600,
//             child: Stack(
//               children: [
//                 Center(
//                   child: FractionallySizedBox(
//                     alignment: Alignment.center,
//                     widthFactor: 0.9,
//                     heightFactor: 0.8,
//                     child: Image.memory(imageBytes),
//                   ),
//                 ),
//                 Positioned(
//                   top: 10,
//                   right: 10,
//                   child: IconButton(
//                     icon: const Icon(Icons.close, size: 30),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//}
