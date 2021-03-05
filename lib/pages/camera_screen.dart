
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lahar/pages/preview_screen.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget{

  @override
  _CameraScreenState createState() => _CameraScreenState();

}

class _CameraScreenState extends State<CameraScreen>{

  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  String imgPath;


  Future _initCameraController(CameraDescription cameraDescription) async{
    if(cameraController != null){
      await cameraController.dispose();
    }
    cameraController = CameraController(cameraDescription, ResolutionPreset.high);
    
    cameraController.addListener(() {
   if(mounted){
     setState(() { });
   }
    });

    if(cameraController.value.hasError){
      print('Camera error ${cameraController.value.errorDescription}');
    }

    try{
      await cameraController.initialize();
    }on CameraException catch (e){
      _showCameraException(e);
    }
if(mounted){
  setState(() { });
}
  }


  Widget _cameraPreviewWidget(){
    if(cameraController == null || !cameraController.value.isInitialized){
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: CameraPreview(cameraController),
    );
  }
  Widget _cameraControlWidget(BuildContext context){
return Expanded(
  child: Align(
alignment: Alignment.center,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        FloatingActionButton(
          child: Icon(
            Icons.camera,
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          onPressed: (){
            _onCapturePressed(context);
          },
        )
      ],
    )
  ),
);
    
}
  Widget _cameraToggleRowWidget(){
    if(cameras == null || cameras.isEmpty){
      return Spacer();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;
    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlatButton.icon(
            onPressed: _onSwitchCamera,
            icon: Icon(
              _getCameraLensIcon(lensDirection),
              color: Colors.white,
              size: 24,
            ),
            label: Text(
              '${lensDirection.toString().substring(lensDirection.toString().indexOf('.')+1).toUpperCase()}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            )
        ),
      ),
    );
  }

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    availableCameras().then((availableCameras){
      cameras = availableCameras;
      if(cameras.length>0){
        setState(() {
          selectedCameraIndex = 0;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v){ });
      }else{
        print('No camera available');
      }
    }).catchError((err){
      print('Error : ${err.code}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: _cameraPreviewWidget(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      _cameraToggleRowWidget(),
                      _cameraControlWidget(context),
                      Spacer(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error : ${e.code}\n Error message : ${e.description}';
    print(errorText);
  }

  void _onCapturePressed(context) async{
    try{
      final path =
          join((await getTemporaryDirectory()).path,
    '${DateTime.now()}.png');

      await cameraController.takePicture(path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            imgPath: path,
          )
        )
      );

    }catch(e){
            _showCameraException(e);
    }


  }

  void _onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    _initCameraController(selectedCamera);
  }

  IconData _getCameraLensIcon(CameraLensDirection lensDirection) {
    switch(lensDirection){
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return CupertinoIcons.photo_camera;
      default:
        return Icons.device_unknown;

    }
  }
}