import 'package:flutter/material.dart';
import '../../state/home_state.dart';

/// A view that displays the raw application system logs.
class MessageView extends StatelessWidget {
  final HomeState state;
  const MessageView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.appLogger.logs.isEmpty) {
      return const Center(child: Text("No messages logged."));
    }
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(thumbVisibility: MaterialStateProperty.all(true), thumbColor: MaterialStateProperty.all(Colors.white54)),
        ),
        child: Scrollbar(
          controller: state.scrollController,
          child: SingleChildScrollView(
            controller: state.scrollController,
            child: SelectableText(
              state.appLogger.logs.join('\n'),
              style: const TextStyle(color: Color(0xFF7AE190), fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
