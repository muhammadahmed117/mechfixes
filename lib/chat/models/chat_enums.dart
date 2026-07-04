enum ChatSenderRole { customer, mechanic, system }

enum ChatMessageType { text, voice, location, system }

enum LocationRequestStatus { none, pending, granted, denied }

enum ChatSystemEvent {
  locationRequest,
  locationGranted,
  locationDenied,
  locationDeclined,
}

extension ChatSenderRoleX on ChatSenderRole {
  String get firestoreValue {
    switch (this) {
      case ChatSenderRole.customer:
        return 'customer';
      case ChatSenderRole.mechanic:
        return 'mechanic';
      case ChatSenderRole.system:
        return 'system';
    }
  }

  static ChatSenderRole fromFirestore(String? value) {
    switch (value) {
      case 'mechanic':
        return ChatSenderRole.mechanic;
      case 'system':
        return ChatSenderRole.system;
      default:
        return ChatSenderRole.customer;
    }
  }
}

extension ChatMessageTypeX on ChatMessageType {
  String get firestoreValue {
    switch (this) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.voice:
        return 'voice';
      case ChatMessageType.location:
        return 'location';
      case ChatMessageType.system:
        return 'system';
    }
  }

  static ChatMessageType fromFirestore(String? value) {
    switch (value) {
      case 'voice':
        return ChatMessageType.voice;
      case 'location':
        return ChatMessageType.location;
      case 'system':
        return ChatMessageType.system;
      default:
        return ChatMessageType.text;
    }
  }
}

extension LocationRequestStatusX on LocationRequestStatus {
  String get firestoreValue {
    switch (this) {
      case LocationRequestStatus.none:
        return 'none';
      case LocationRequestStatus.pending:
        return 'pending';
      case LocationRequestStatus.granted:
        return 'granted';
      case LocationRequestStatus.denied:
        return 'denied';
    }
  }

  static LocationRequestStatus fromFirestore(String? value) {
    switch (value) {
      case 'pending':
        return LocationRequestStatus.pending;
      case 'granted':
        return LocationRequestStatus.granted;
      case 'denied':
        return LocationRequestStatus.denied;
      default:
        return LocationRequestStatus.none;
    }
  }
}

extension ChatSystemEventX on ChatSystemEvent {
  String get firestoreValue {
    switch (this) {
      case ChatSystemEvent.locationRequest:
        return 'location_request';
      case ChatSystemEvent.locationGranted:
        return 'location_granted';
      case ChatSystemEvent.locationDenied:
        return 'location_denied';
      case ChatSystemEvent.locationDeclined:
        return 'location_declined';
    }
  }

  static ChatSystemEvent? fromFirestore(String? value) {
    switch (value) {
      case 'location_request':
        return ChatSystemEvent.locationRequest;
      case 'location_granted':
        return ChatSystemEvent.locationGranted;
      case 'location_denied':
        return ChatSystemEvent.locationDenied;
      case 'location_declined':
        return ChatSystemEvent.locationDeclined;
      default:
        return null;
    }
  }
}
