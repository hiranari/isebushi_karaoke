/// Cache service interface
/// Handles caching of computation results and audio data
abstract class ICacheService {
  /// Get cached value by key
  /// 
  /// Returns the cached value or null if not found
  Future<T?> get<T>(String key);
  
  /// Set cached value by key
  /// 
  /// Stores the value with optional expiration
  Future<void> set<T>(String key, T value, {Duration? expiration});
  
  /// Remove cached value by key
  Future<void> remove(String key);
  
  /// Clear all cached values
  Future<void> clear();
  
  /// Check if key exists in cache
  bool exists(String key);
}
