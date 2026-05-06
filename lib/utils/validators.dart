class Validators {
  static String? validateEventName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event name is required';
    }
    if (value.trim().length < 3) {
      return 'Event name must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Event name must be less than 100 characters';
    }
    return null;
  }

  static String? validateVenue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Venue is required';
    }
    if (value.trim().length < 2) {
      return 'Venue must be at least 2 characters';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  static String? validateCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Capacity is required';
    }
    final int? capacity = int.tryParse(value.trim());
    if (capacity == null) {
      return 'Please enter a valid number';
    }
    if (capacity < 1) {
      return 'Capacity must be at least 1';
    }
    if (capacity > 100000) {
      return 'Capacity cannot exceed 100,000';
    }
    return null;
  }

  static String? validateParticipantId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Participant ID is required';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static bool isValidParticipantIdFormat(String id) {
    final regex = RegExp(r'^STU-\d{3,}$');
    return regex.hasMatch(id.trim().toUpperCase());
  }
}
