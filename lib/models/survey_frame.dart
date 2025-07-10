import 'package:latlong2/latlong.dart';

class SurveyFrame {
final Duration timestamp;
final LatLng? position;
final double? roughness;
final double? rut;
final double? crack;
final double? area;
final double? refRough;
final double? refRut;
final double? refCrack;
final double? refArea;

SurveyFrame({
required this.timestamp,
required this.position,
this.roughness,
this.rut,
this.crack,
this.area,
this.refRough,
this.refRut,
this.refCrack,
this.refArea,
});
}