class ErrorMessages {
  static String systemNotResponsiveError =
      'System not responsive. Please reach out to Schnell IT team @ +91 98940 79954/+91 96290 40186 or luminator@schnellenergy.com';
  static String tryAgainError = 'Something went wrong. Please try Again!';
  static String serverTimeOutError = "Server Timeout. Please try Again!";
  static String offlineErrorTitle = "You seem Offline!";
  static String offlineErrorMessage = 'Please check your connection.';
  static String invalidScanedDeviceError = "Please scan a valid device";
  static String invalidQRError = 'Invalid QR. Please try again.!';
  static String invalidDeviceError = 'Invalid device. Please try again.!';
  static String invalidThreePhaseEbError =
      'Please enter a valid Three Phase EB Meter number.';
  static String invalidSinglePhaseEbError =
      'Please enter a valid Single Phase EB Meter number.';
  static String mismatchedDeviceError = "Mismatched Device/Asset type";
  static String deviceNotFoundError =
      'No device/ asset found. Kindly scan a different QR code or search for it.';
  static String locationDeniedError = 'Location permissions are denied';
  static String locationPermanentlyDeniedError =
      'Location permissions are permanently denied';
  static String gpsNotEnabledError =
      "GPS Service is not enabled, turn on GPS location";
  static String playStoreLaunchError = "Unable to launch the Play Store.";
  static String lampIdGenerationWarning =
      'Upon your selection, the lamp ID will be automatically generated. If you have a Lamp QR code, click on "Lamp" QR button to start/initiate your installation process.';
  static String deviceInstalledSomeWhereWarning =
      "Device installed on another location?";
  static String lampWithoutQRWarning =
      "Do you want to proceed the lamp without QR?";
  static String deviceMismatchError = "Mismatched Device/Asset type";
  static String installPoleVaultAlert = "Install Pole Vault app to continue.";
  static String searchCharLimitWarningTitle =
      "Please provide min. 3 characters to search.";
  static String searchCharLimitWarningMessage = 'Try once again';
  static String networkErrorTitle = 'Network error occurred';
  static String networkErrorMessage = 'trying to lookup coordinates';
  static String wardRequiredAlertMessage =
      'Please select a ward to proceed further..';
  static String regionRequiredAlertMessage =
      'Please select a region to proceed further..';
  static String locationDisabledWarning = 'Location services are disabled.';
  static String regionFetchingError = 'Error while fetching region';
  static String zoneFetchingError = 'Error while fetching zone';
  static String wardFetchingError = 'Error while fetching ward';
  static String customerNotFoundError = 'No Customer is found with this name';
  static String regionNotFoundError = 'No Region is found with this name';
  static String zoneNotFoundError = 'No zone is found with this name';
  static String wardNotFoundError = 'No ward is found with this name';
  static String emailValidationError = "Please enter a valid email";
  static String passwordValidationError = 'Please enter a valid Password';
  static String ticketSuccessAlert = "Ticket updated successfully!";
  static String updateTicketServiceError =
      'internal server error on updateTicketService';
  static String commentsSuccessAlert = "comments updated successfully";
  static String updateTicketServiceTryAgainError =
      'Something went wrong. Please try Again! - updateTicketService';
  static String deviceDispatchSuccessAlert =
      'Device has been successfully Dispatched..!';
  static String sessionExpiredError = 'Session Expired. Please Login again!';
  static String enableLocationAlert =
      'Please enable location permission from Setting';
  static String enableNotificationPermission =
      'Please allow notification permission from Setting';
  static String dataRequestedSuccessfully =
      'Data requested successfully!Please wait for a while to receive the data';
  static String unableToRequestData =
      'Unable to request data from the Panel at the moment.Kindly try again';

  static String updateAlert({required String latestVersion}) {
    return "Kindly upgrade to latest version $latestVersion from PlayStore to continue using the app!";
  }

  static String removeLampWithLuminodeWarning({
    required String lampName,
    required String deviceLabel,
    required String poleName,
    required String ward,
  }) {
    return "The Lamp $lampName is installed with $deviceLabel on Pole $poleName at Ward $ward. Due to this removal, associated Luminode $deviceLabel also be removed. Do you still want to remove? ";
  }

  static String removeLampWarning({
    required String lampName,
    required String poleName,
    required String ward,
  }) {
    return "The Lamp $lampName is installed on Pole $poleName at Ward $ward. Do you still want to remove?";
  }

  static String assetNotInstalledError({
    required String lampName,
  }) {
    return "Asset $lampName not installed properly";
  }

  static String deviceFoundInstalledWantToProceedWarning(
      {required String deviceName,
      String lampName = '',
      String region = '',
      String zone = '',
      String ward = ''}) {
    if (region.isEmpty) {
      return "The device has been installed without proper association to a project, region, or ward. Please contact the system administrator to resolve this issue before proceeding further.";
    } else {
      return "Device $deviceName ${lampName.isNotEmpty ? '$lampName ' : ''}is found to be INSTALLED at${region.isNotEmpty ? ' $region' : ''}${zone.isNotEmpty ? ' $zone' : ''}${ward.isNotEmpty ? ' $ward' : ''}.How do you want to proceed?";
    }
  }

  static String deviceInstallWithOtherWarning({
    required String deviceName,
    required String lampName,
    required String firstDeviceRegionName,
    required String region,
  }) {
    if (region.isEmpty) {
      return "The device has been installed without proper association to a project, region, or ward. Please contact the system administrator to resolve this issue before proceeding further.";
    } else {
      return "Device $deviceName $lampName is found to be INSTALLED with $firstDeviceRegionName $region.How do you want to proceed?";
    }
  }

  static String deviceFoundInstalledWarning(
      {required String deviceName,
      String deviceRegion = '',
      String deviceZone = '',
      String deviceWard = ''}) {
    if (deviceRegion.isEmpty || deviceZone.isEmpty || deviceWard.isEmpty) {
      return "The device has been installed without proper association to a project, region, or ward. Please contact the system administrator to resolve this issue before proceeding further.";
    } else {
      return "Device $deviceName is found to be INSTALLED at${deviceRegion.isNotEmpty ? ' $deviceRegion' : ''}${deviceZone.isNotEmpty ? ' $deviceZone' : ''}${deviceWard.isNotEmpty ? ' $deviceWard' : ''}.";
    }
  }

  static String deviceFoundInstalledWithWarning(
      {required String deviceName,
      String deviceRegion = '',
      String deviceZone = '',
      String deviceWard = ''}) {
    if (deviceRegion.isEmpty) {
      return "The device has been installed without proper association to a project, region, or ward. Please contact the system administrator to resolve this issue before proceeding further.";
    } else {
      return "Device $deviceName is found to be INSTALLED with${deviceRegion.isNotEmpty ? ' $deviceRegion' : ''}${deviceZone.isNotEmpty ? ' $deviceZone' : ''}${deviceWard.isNotEmpty ? ' $deviceWard' : ''}.";
    }
  }

  static String deviceInstalledAlert({
    required String deviceName,
    required String deviceWard,
  }) {
    return "Device $deviceName installed at $deviceWard";
  }

  static String deviceScrappedError({required String deviceName}) {
    return "Device $deviceName is SCRAPPED.  Kindly try with another device.";
  }

  static String gwNotDespatchedError({required String deviceName}) {
    return "GW $deviceName is not despatched as part of a CCMS/Hub. Hence cannot be installed as such. However, it can be used to replace a GW installed with a CCMS Panel or Hub.";
  }

  static String semcNotDespatchedError({required String deviceName}) {
    return "SEMC $deviceName is not despatched as part of a SMSLC. Hence cannot be installed as such. However, it can be used to replace a SEMC installed with a SMSLC Panel.";
  }

  static String deviceNotInstallableWarning({required String deviceName}) {
    return "Device $deviceName is not in an INSTALLABLE State. Do you want to continue?";
  }

  static String deviceNotInstallableError({required String deviceName}) {
    return 'Device $deviceName is not in an INSTALLABLE State';
  }

  static String deviceNotInstallableTryWithSEMCError(
      {required String deviceName}) {
    return "Device $deviceName is not INSTALLABLE : Firmware version information is missing.Please try powering up the SEMC to verify / update the firmware.";
  }

  static String deviceNotInstallableTryWithGWError(
      {required String deviceName}) {
    return "Device $deviceName is not INSTALLABLE : Firmware version information is missing.Please try powering up the GW to verify / update the firmware.";
  }

  static String deviceNotInstallableTryWithILMError(
      {required String deviceName}) {
    return "Device $deviceName is not INSTALLABLE : Firmware version information is missing.Please try connecting the ILM to a Lamp and power-up to verify and update the firmware.";
  }

  static String deviceRemovedError({required String deviceName}) {
    return "Device/Asset $deviceName was removed.";
  }

  static String cantReplaceAssetWarning({
    required String firstAssetName,
    required String secondAssetName,
  }) {
    return "Cannot replace an Asset $firstAssetName with itself $secondAssetName! Please retry with a different one!";
  }

  static String cantReplaceDeviceWarning({
    required String firstDeviceName,
    required String secondDeviceName,
  }) {
    return "Cannot replace a Device $firstDeviceName with itself $secondDeviceName! Please retry with a different one!";
  }

  static String lampInstallationAlert({
    required String lampName,
    required String lampWard,
  }) {
    return "Asset $lampName installed at $lampWard";
  }

  static String lampFoundScanAnotherAlert({
    required String lampName,
    required String lampWard,
  }) {
    return 'Asset $lampName installed at $lampWard. Please scan another device';
  }

  static String lampInstalledonPoleAlert({
    required String lampName,
    required String poleName,
  }) {
    return "Lamp $lampName successfully Installed!";
  }

  static String deviceReplaceSuccessAlert({
    String firstLampName = "",
    required String firstDeviceName,
    String secondLampName = "",
    required String secondDeviceName,
  }) {
    return "Device${firstLampName.isNotEmpty ? ' $firstLampName' : ''} $firstDeviceName replaced with${secondLampName.isNotEmpty ? ' $secondLampName' : ''} $secondDeviceName successfully!";
  }

  static String deviceRemoveSuccessAlert({
    required String deviceName,
  }) {
    return "Device $deviceName removed successfully!";
  }

  static String lampWattageMismatchWarning({
    required int intLmpWattage,
    required String recommWattages,
  }) {
    return 'Lamp wattage ($intLmpWattage)W is not same as recommended wattage($recommWattages)W. Do you still want to proceed?';
  }
}
