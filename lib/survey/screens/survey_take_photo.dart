import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../background_connectivity_monitoring.dart';
import '../survey_controller.dart';
import '../../ticket_notification/ticket_controller.dart';
import '../../ticket_notification/ticket_model.dart';

class CaptureThreeImagesScreen extends ConsumerStatefulWidget {
  final List<XFile?> capturedImages;
  final bool isForTicket;
  final bool isForTicketUpdate;
  final Ticket? ticketToUpdate;
  final String? comment;
  final String? usermail;
  final String? username;
  const CaptureThreeImagesScreen({
    super.key,
    this.capturedImages = const [],
    this.isForTicket = false,
    this.isForTicketUpdate = false,
    this.ticketToUpdate,
    this.comment,
    this.usermail,
    this.username,
  });
  @override
  ConsumerState<CaptureThreeImagesScreen> createState() =>
      _CaptureThreeImagesScreenState();
}

class _CaptureThreeImagesScreenState
    extends ConsumerState<CaptureThreeImagesScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  late final List<XFile?> _capturedImages;
  final Set<int> _capturedIndexes = <int>{};

  int _nextImageIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _capturedImages =
        widget.capturedImages.isNotEmpty && widget.capturedImages.length == 3
            ? List<XFile?>.from(widget.capturedImages)
            : List<XFile?>.filled(3, null);
    log("capturedImages: ${_capturedImages.length}");
    _nextImageIndex = _capturedImages.indexWhere((img) => img == null) == -1
        ? _capturedImages.length
        : _capturedImages.indexWhere((img) => img == null);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final controller =
          CameraController(_cameras.first, ResolutionPreset.medium);

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (e) {
      log("Camera init error: $e");
    }
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) return;

    if (_nextImageIndex >= 3) return;

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImages[_nextImageIndex] = photo;
        _capturedIndexes.add(_nextImageIndex);
        _nextImageIndex++;
      });
      if (widget.isForTicket) {
        ref.read(ticketController).setCapturedImages(_capturedImages);
      }
    } catch (e) {
      log("Capture error: $e");
    }
  }

  void _retakeImage(int index) async {
    _capturedIndexes.add(index);
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImages[index] = photo;
      });
      if (widget.isForTicket) {
        ref.read(ticketController).setCapturedImages(_capturedImages);
      }
    } catch (e) {
      log("Retake error: $e");
    }
  }

  Future<void> _releaseCamera({bool fromDispose = false}) async {
    final controller = _cameraController;
    if (controller == null) return;

    try {
      // Don’t call setState() if the widget is being disposed.
      if (!fromDispose && mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      } else {
        _isCameraInitialized = false;
      }

      // Stop stream safely (ignore if not running)
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream().catchError((_) {});
      }

      // Dispose safely — no await if called from dispose
      if (!fromDispose) {
        await controller.dispose();
      } else {
        // Dispose synchronously during dispose to avoid async race
        controller.dispose();
      }
    } catch (e) {
      log("Camera release error: $e");
    } finally {
      _cameraController = null;
    }
  }

  Widget _buildImageGrid(int index) {
    final image = _capturedImages[index];
    return GestureDetector(
      onTap: () {
        if (image == null) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Dialog(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.black12,
        ),
        child: Stack(
          children: [
            image != null
                ? Positioned.fill(
                    child: Image.file(File(image.path), fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                        key: ValueKey('capture image'),
                        Icons.camera_alt,
                        size: 36,
                        color: Colors.grey),
                  ),
            if (image != null)
              Positioned(
                bottom: 3,
                right: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                  onPressed: () => _retakeImage(index),
                  child: const Icon(
                      key: const ValueKey('retake image'),
                      Icons.replay_outlined,
                      size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // @override
  // void deactivate() {
  //   // Extra safety: release camera when widget is removed from tree
  //   _releaseCamera();
  //   super.deactivate();
  // }

  @override
  void dispose() {
    _releaseCamera(fromDispose: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clickEventIsFor =
        widget.isForTicket ? '' : ref.watch(surveyController).clickEventIsFor;
    final isButtonEnabled = widget.isForTicket
        ? true
        : ref.watch(surveyController).isButtonEnabled;

    return WillPopScope(
      onWillPop: () => Future.value(widget.isForTicket ? true : false),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: widget.isForTicket
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).cardColor,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                : null,
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.19),
            elevation: 0.0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontSize: 18.0,
            ),
            title: Text(
              widget.isForTicket
                  ? (widget.isForTicketUpdate
                      ? "UPDATE TICKET PHOTOS"
                      : "TICKET PHOTOS")
                  : "TAKE PICTURE",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          body: _isCameraInitialized && _cameraController != null
              ? ConnectivityBanner(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: CameraPreview(_cameraController!),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(
                            3,
                            (index) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _buildImageGrid(index),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Center(
                            child: Semantics(
                              label: 'capture_image_button',
                              button: true,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor:
                                      const Color.fromARGB(248, 54, 89, 109),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  fixedSize: const Size(64, 64),
                                ),
                                onPressed:
                                    _nextImageIndex < 3 ? _captureImage : null,
                                child: const Icon(Icons.camera_alt, size: 35),
                              ),
                            ),
                          ),
                          const SizedBox(width: 50),
                          Semantics(
                            label: 'upload_image_button',
                            button: true,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                backgroundColor:
                                    const Color.fromARGB(248, 54, 89, 109),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                fixedSize: const Size(54, 54),
                              ),
                              onPressed: _capturedImages
                                      .every((img) => img != null)
                                  ? (widget.isForTicket
                                      ? (_isSubmitting
                                          ? null
                                          : () async {
                                              setState(() {
                                                _isSubmitting = true;
                                              });
                                              await _releaseCamera();
                                              if (!mounted || !context.mounted) return;
                                              ref
                                                  .read(ticketController)
                                                  .setCapturedImages(
                                                      _capturedImages);
                                              if (widget.isForTicketUpdate &&
                                                  widget.ticketToUpdate != null) {
                                                await ref
                                                    .read(ticketController)
                                                    .updateTicketWithImages(
                                                      context,
                                                      ref,
                                                      widget.ticketToUpdate!,
                                                      widget.comment ?? '',
                                                      _capturedImages,
                                                    );
                                              } else {
                                                await ref
                                                    .read(ticketController)
                                                    .createTicketWithImages(
                                                      context,
                                                      ref,
                                                      _capturedImages,
                                                      widget.usermail ?? '',
                                                      widget.username ?? '',
                                                    );
                                              }
                                              if (mounted) {
                                                setState(() {
                                                  _isSubmitting = false;
                                                });
                                              }
                                            })
                                      : (isButtonEnabled
                                          ? () async {
                                              ref
                                                  .read(surveyController)
                                                  .disableButton();
                                              // Release camera immediately since we won’t need it anymore
                                              await _releaseCamera();
                                              await ref
                                                  .read(surveyController)
                                                  .insertCapturedImages(
                                                      context,
                                                      ref,
                                                      _capturedImages,
                                                      _capturedIndexes
                                                          .toList());
                                              if (clickEventIsFor ==
                                                  'poleSurvey') {
                                                ref
                                                    .read(surveyController)
                                                    .insertPoleSurveyDetails(
                                                        context, ref);
                                              } else if (clickEventIsFor ==
                                                  'spSurvey') {
                                                ref
                                                    .read(surveyController)
                                                    .insertSpSurveyDetails(
                                                        context, ref);
                                              } else if (clickEventIsFor ==
                                                  'transSurvey') {
                                                ref
                                                    .read(surveyController)
                                                    .insertTransSurveyDetails(
                                                        context, ref);
                                              }
                                            }
                                          : null))
                                  : null,
                              child: const Icon(
                                  semanticLabel: 'Upload Image',
                                  Icons.send,
                                  size: 35),
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
