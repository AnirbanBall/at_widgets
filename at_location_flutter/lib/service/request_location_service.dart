import 'package:at_commons/at_commons.dart';
import 'package:at_location_flutter/location_modal/location_notification.dart';
import 'package:at_location_flutter/utils/constants/init_location_service.dart';

import 'at_location_notification_listener.dart';
import 'key_stream_service.dart';

class RequestLocationService {
  static final RequestLocationService _singleton =
      RequestLocationService._internal();
  RequestLocationService._internal();

  factory RequestLocationService() {
    return _singleton;
  }

  Future<bool> sendRequestLocationEvent(String atsign) async {
    try {
      AtKey atKey = newAtKey(60000,
          "requestlocation-${DateTime.now().microsecondsSinceEpoch}", atsign);

      LocationNotificationModel locationNotificationModel =
          LocationNotificationModel()
            ..atsignCreator = atsign
            ..key = atKey.key
            ..isRequest = true
            ..receiver =
                AtLocationNotificationListener().atClientInstance.currentAtSign;

      var result = await AtLocationNotificationListener().atClientInstance.put(
          atKey,
          LocationNotificationModel.convertLocationNotificationToJson(
              locationNotificationModel));
      print('requestLocationNotification:$result');

      if (result) {
        KeyStreamService().addDataToList(locationNotificationModel);
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  requestLocationAcknowledgment(
      LocationNotificationModel locationNotificationModel, bool isAccepted,
      {int minutes, bool isSharing}) async {
    try {
      String atkeyMicrosecondId = locationNotificationModel.key
          .split('requestlocation-')[1]
          .split('@')[0];
      AtKey atKey;

      atKey = newAtKey(
        60000,
        "requestlocationacknowledged-$atkeyMicrosecondId",
        locationNotificationModel.receiver,
      );

      locationNotificationModel
        ..isAccepted = isAccepted
        ..isExited = !isAccepted
        ..lat = isAccepted ? 12 : 0
        ..long = isAccepted ? 12 : 0;

      if (isSharing != null) locationNotificationModel.isSharing = isSharing;

      if (isAccepted && (minutes != null)) {
        locationNotificationModel.from = DateTime.now();
        locationNotificationModel.to =
            DateTime.now().add(Duration(minutes: minutes));
      }

      var result = await AtLocationNotificationListener().atClientInstance.put(
          atKey,
          LocationNotificationModel.convertLocationNotificationToJson(
              locationNotificationModel));
      print('requestLocationAcknowledgment $result');
      if ((result) && (!isSharing)) {
        KeyStreamService().removeData(atKey.key);
      }

      return result;
    } catch (e) {
      return false;
    }
  }

  updateWithRequestLocationAcknowledge(
    LocationNotificationModel locationNotificationModel,
  ) async {
    try {
      String atkeyMicrosecondId = locationNotificationModel.key
          .split('requestlocation-')[1]
          .split('@')[0];

      List<String> response =
          await AtLocationNotificationListener().atClientInstance.getKeys(
                regex: 'requestlocation-$atkeyMicrosecondId',
              );

      AtKey key = getAtKey(response[0]);

      if (locationNotificationModel.isAccepted) {
        key.metadata.ttl = locationNotificationModel.to
                .difference(locationNotificationModel.from)
                .inMinutes *
            60000;
        key.metadata.ttr = locationNotificationModel.to
                .difference(locationNotificationModel.from)
                .inMinutes *
            60000;
        key.metadata.expiresAt = locationNotificationModel.to;
      }

      locationNotificationModel.isAcknowledgment = true;

      var notification =
          LocationNotificationModel.convertLocationNotificationToJson(
              locationNotificationModel);
      var result;
      result = await AtLocationNotificationListener()
          .atClientInstance
          .put(key, notification);

      if (result)
        KeyStreamService()
            .mapUpdatedLocationDataToWidget(locationNotificationModel);

      print('update result - $result');

      return result;
    } catch (e) {
      return false;
    }
  }

  removePerson(LocationNotificationModel locationNotificationModel) async {
    var result;
    if (locationNotificationModel.atsignCreator !=
        AtLocationNotificationListener().atClientInstance.currentAtSign) {
      locationNotificationModel.isAccepted = false;
      locationNotificationModel.isExited = true;
      result =
          await updateWithRequestLocationAcknowledge(locationNotificationModel);
    } else {
      result =
          await requestLocationAcknowledgment(locationNotificationModel, false);
    }
    return result;
  }

  sendDeleteAck(LocationNotificationModel locationNotificationModel) async {
    String atkeyMicrosecondId = locationNotificationModel.key
        .split('requestlocation-')[1]
        .split('@')[0];
    AtKey atKey;
    atKey = newAtKey(
      60000,
      "deleterequestlocation-$atkeyMicrosecondId",
      locationNotificationModel.receiver,
    );

    var result = await AtLocationNotificationListener().atClientInstance.put(
        atKey,
        LocationNotificationModel.convertLocationNotificationToJson(
            locationNotificationModel));
    print('requestLocationAcknowledgment $result');
  }

  deleteKey() async {}

  AtKey newAtKey(int ttr, String key, String sharedWith,
      {int ttl, DateTime expiresAt}) {
    AtKey atKey = AtKey()
      ..metadata = Metadata()
      ..metadata.ttr = ttr
      ..metadata.ccd = true
      ..key = key
      ..sharedWith = sharedWith
      ..sharedBy =
          AtLocationNotificationListener().atClientInstance.currentAtSign;
    if (ttl != null) atKey.metadata.ttl = ttl;
    if (expiresAt != null) atKey.metadata.expiresAt = expiresAt;

    return atKey;
  }
}
