import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/services/firestore_service.dart';
import 'package:straights_psyroll/shared/services/location_service.dart';
import 'package:straights_psyroll/shared/services/nfc_service.dart';
import 'package:straights_psyroll/shared/services/device_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockLocationService extends Mock implements LocationService {}

class MockNFCService extends Mock implements NFCService {}

class MockDeviceService extends Mock implements DeviceService {}

class MockRef extends Mock implements Ref {}

class FakeAttendanceModel extends Fake implements AttendanceModel {}

class FakePosition extends Fake implements Position {
  @override
  double get latitude => 25.276987;
  @override
  double get longitude => 55.296249;
  @override
  double get accuracy => 10.0;
  @override
  double get altitude => 0.0;
  @override
  double get altitudeAccuracy => 0.0;
  @override
  double get heading => 0.0;
  @override
  double get headingAccuracy => 0.0;
  @override
  double get speed => 0.0;
  @override
  double get speedAccuracy => 0.0;
  @override
  DateTime get timestamp => DateTime.now();
  @override
  bool get isMocked => true;
}
