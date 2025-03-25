import 'package:flutter/material.dart';
import 'package:app/constants.dart';

class Menus {
  final String? svgSrc, title, route;
  final int? numOfFiles, percentage;
  final Color? color;

  Menus({
    this.svgSrc,
    this.title,
    this.numOfFiles,
    this.percentage,
    this.color,
    this.route, // Rota associada ao menu
  });
}

List options = [
  Menus(
    title: "Requests",
    numOfFiles: 0,
    svgSrc: "assets/icons/Documents.svg",
    color: primaryColor,
    percentage: 35,
    route: "/request",
  ),
  Menus(
    title: "Confirmed Reservations",
    numOfFiles: 0,
    svgSrc: "assets/icons/google_drive.svg",
    color: Color(0xFFFFA113),
    percentage: 35,
    route: "/confirmedReservations",
  ),
  Menus(
    title: "Allocations",
    numOfFiles: 0,
    svgSrc: "assets/icons/one_drive.svg",
    color: Color(0xFFA4CDFF),
    percentage: 10,
    route: "/allocations",
  ),
  Menus(
    title: "Finance",
    numOfFiles: 0,
    svgSrc: "assets/icons/drop_box.svg",
    color: Color(0xFF007EE5),
    percentage: 78,
    route: "/finance",
  ),
];
