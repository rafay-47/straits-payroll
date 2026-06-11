/// Stub file for non-web platforms
/// Provides placeholder implementations so code compiles on Android/iOS

// Stub classes for dart:html that don't exist on native platforms
class Blob {
  int size = 0;
  Blob([dynamic parts, dynamic type]);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class CssStyleDeclaration {
  String display = '';
}

class HttpRequest {
  String? responseType;
  int? status;
  dynamic response;
  
  void open(String method, String url, {bool? async}) {}
  void send([dynamic data]) {}
  
  // Event streams (these won't be used, just need to exist)
  Stream<Event> get onLoad => Stream.empty();
  Stream<Event> get onError => Stream.empty();
  Stream<Event> get onAbort => Stream.empty();
}

class AnchorElement {
  String? href;
  late CssStyleDeclaration style;
  
  AnchorElement({String? href}) {
    this.href = href;
    style = CssStyleDeclaration();
  }
  
  void setAttribute(String name, String value) {}
  void click() {}
  void remove() {}
}

class Event {}

class Document {
  Body? body;
}

class Body {
  void append(dynamic element) {}
}

class Navigator {
  Clipboard? clipboard;
}

class Clipboard {
  Future<void> write(List<dynamic> items) async {}
}

class Window {
  Navigator? navigator;
  
  Future<Response> fetch(String url, [dynamic options]) async {
    return Response();
  }
  
  void open(String url, String target) {}
}

class Response {
  bool ok = false;
  int status = 0;
  String statusText = '';
  
  Future<Blob> blob() async => Blob();
}

// This won't be used, but needs to exist for type checking
final window = Window();
final document = Document();
