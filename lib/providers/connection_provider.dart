import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/connection_model.dart';
import '../models/user.dart';

class ConnectionProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<ConnectionModel> _connectionRequests = [];
  List<ConnectionModel> _sentRequests = [];
  List<ConnectionModel> _connections = [];
  List<User> _suggestedConnections = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ConnectionModel> get connectionRequests => _connectionRequests;
  List<ConnectionModel> get sentRequests => _sentRequests;
  List<ConnectionModel> get connections => _connections;
  List<User> get suggestedConnections => _suggestedConnections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch connection requests
  Future<void> fetchConnectionRequests(String userId) async {
    _setLoading(true);
    try {
      _connectionRequests = await _databaseService.getConnectionRequests(userId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Error fetching connection requests: $e');
    }
  }

  // Fetch sent connection requests
  Future<void> fetchSentRequests(String userId) async {
    _setLoading(true);
    try {
      _sentRequests = await _databaseService.getSentConnectionRequests(userId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Error fetching sent requests: $e');
    }
  }

  // Fetch established connections
  Future<void> fetchConnections(String userId) async {
    _setLoading(true);
    try {
      _connections = await _databaseService.getUserConnections(userId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Error fetching connections: $e');
    }
  }

  // Fetch suggested connections
  Future<void> fetchSuggestedConnections(String userId) async {
    _setLoading(true);
    try {
      _suggestedConnections = await _databaseService.getSuggestedConnections(userId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Error fetching suggested connections: $e');
    }
  }

  // Send connection request
  Future<bool> sendConnectionRequest(String userId, String receiverId) async {
    _setLoading(true);
    try {
      await _databaseService.sendConnectionRequest(userId, receiverId);
      await fetchSentRequests(userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Error sending connection request: $e');
      return false;
    }
  }

  // Respond to connection request
  Future<bool> respondToRequest(String userId, String requestId, String response) async {
    _setLoading(true);
    try {
      await _databaseService.respondToConnectionRequest(userId, requestId, response);
      await fetchConnectionRequests(userId);
      await fetchConnections(userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Error responding to request: $e');
      return false;
    }
  }

  // Remove connection
  Future<bool> removeConnection(String userId, String connectionId) async {
    _setLoading(true);
    try {
      await _databaseService.removeConnection(userId, connectionId);
      await fetchConnections(userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Error removing connection: $e');
      return false;
    }
  }

  // Check connection status between two users
  Future<String> checkConnectionStatus(String userId, String otherUserId) async {
    try {
      return await _databaseService.checkConnectionStatus(userId, otherUserId);
    } catch (e) {
      _setError('Error checking connection status: $e');
      return 'error';
    }
  }
} 