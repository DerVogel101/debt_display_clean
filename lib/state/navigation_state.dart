import 'package:flutter/foundation.dart';

import '../ui/app_shared.dart';

class NavigationState extends ChangeNotifier {
  AppDestination _selectedDestination = AppDestination.home;

  AppDestination get selectedDestination => _selectedDestination;

  void selectDestination(AppDestination destination) {
    if (_selectedDestination == destination) {
      return;
    }
    _selectedDestination = destination;
    notifyListeners();
  }
}
