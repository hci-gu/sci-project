class DfuProgress {
  final String phase;
  final int current;
  final int total;
  final String? message;

  const DfuProgress({
    required this.phase,
    this.current = 0,
    this.total = 0,
    this.message,
  });

  double get progress => total > 0 ? current / total : 0.0;

  Map<String, dynamic> toMap() => {
        'type': 'dfu_progress',
        'phase': phase,
        'current': current,
        'total': total,
        'message': message,
      };
}
