import 'dart:io';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
class FileUtils {

  String rootDir = '/storage/emulated/0/Android/media';


  static Future<String> createFolderInAppDocDir(String folderName) async {

    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =  Directory('${_appDocDir.path}/$folderName/');

    if(await _appDocDirFolder.exists()){ //if folder already exists return path
      return _appDocDirFolder.path;
    }else{//if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder=await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  Future<Directory?> _getAppMediaDir() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final String appPackage = packageInfo.packageName;
    final String appName = packageInfo.appName;
    final String appMediaDirPath = '$rootDir/$appPackage/$appName';

    return Directory(appMediaDirPath);
  }

  Future<String> getMediaDirectoryPath({
    required String mediaDirName,
  }) async {
    Directory? _dir;
    try {
      _dir = await _getAppMediaDir();
    } catch (e) {
      _dir = await getTemporaryDirectory();
    }
    final String dirPath = '${_dir!.path}/$mediaDirName';
    await _checkAndCreateDirectory(dirPath);
    return dirPath;
  }


  Future<void> _checkAndCreateDirectory(String dirPath) async {
    if (!Directory(dirPath).existsSync()) {
      await Directory(dirPath).create(recursive: true);
    }
  }

  Future<String> _getDestinationDirectory({required String folderName}) async {

    String contentDir = folderName;
    return await getMediaDirectoryPath(mediaDirName: contentDir);

  }
  static String trimString(
      {required String originText, required int maxLength}) {
    if (originText.length > maxLength) {
      return originText.substring(0, maxLength);
    }

    return originText;
  }


  String _generateMediaFileName({
    required String originFileName,
    required String filePath,
  }) {
    final String fileName = trimString(originText: originFileName, maxLength: 60);

    final String extension =  '.jpg';
    final String generatedFilePath = '$fileName$extension';

    return generatedFilePath;
  }

  String _generateVideoFileName({
    required String originFileName,
    required String filePath,
  }) {
    final String fileName = trimString(originText: originFileName, maxLength: 60);

    final String extension =  '.mp4';
    final String generatedFilePath = '$fileName$extension';

    return generatedFilePath;
  }

  Future<String> mediaFilesForMobile(
      {required String sourceFilePath,
        required String msgFileName,}
      ) async {
    final String destinationDirPath = await _getDestinationDirectory(folderName: 'rampSure_images');

    final String _mediaGeneratedFileName = _generateMediaFileName(
      filePath: sourceFilePath,
      originFileName: msgFileName,
    );

    final String destinationFilePath =
        destinationDirPath + '/$_mediaGeneratedFileName';

    final File updatedFile = File(sourceFilePath).copySync(destinationFilePath);
    await ImageGallerySaver.saveFile(updatedFile.path);

    return updatedFile.path;
  }

  Future<String> videoFileSave(
      {required String sourceFilePath,
        required String msgFileName,}
      ) async {
    final String destinationDirPath = await _getDestinationDirectory(folderName:' rampSure_videos');

    final String _mediaGeneratedFileName = _generateVideoFileName(
      filePath: sourceFilePath,
      originFileName: msgFileName,
    );

    final String destinationFilePath =
        destinationDirPath + '/$_mediaGeneratedFileName';

    final File updatedFile = File(sourceFilePath).copySync(destinationFilePath);
    await ImageGallerySaver.saveFile(updatedFile.path);

    return updatedFile.path;
  }

}