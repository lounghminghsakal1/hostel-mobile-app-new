import 'dart:async';

enum SessionEvent { expired }

/// Lets the network layer tell the auth layer "the session is over"
/// without the two depending on each other.
class SessionEvents {
  final _controller = StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get stream => _controller.stream;

  void emit(SessionEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}
