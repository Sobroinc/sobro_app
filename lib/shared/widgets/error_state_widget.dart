import 'package:flutter/material.dart';

/// Reusable error state widget with retry button.
/// Eliminates duplication of error display across screens.
class ErrorStateWidget extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.error,
    this.onRetry,
    this.retryText = 'Повторить',
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _formatError(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Format error message to be user-friendly.
  String _formatError(String? error) {
    if (error == null) return 'Произошла ошибка';

    // Hide technical details from users
    if (error.contains('SocketException') ||
        error.contains('Connection refused')) {
      return 'Ошибка подключения к серверу. Проверьте интернет.';
    }
    if (error.contains('TimeoutException')) {
      return 'Превышено время ожидания. Попробуйте позже.';
    }
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Сессия истекла. Войдите снова.';
    }
    if (error.contains('403') || error.contains('Forbidden')) {
      return 'Доступ запрещен.';
    }
    if (error.contains('404')) {
      return 'Данные не найдены.';
    }
    if (error.contains('500') || error.contains('Internal Server')) {
      return 'Ошибка сервера. Попробуйте позже.';
    }

    // Return original error if it's short enough
    if (error.length < 100) return error;

    return 'Произошла ошибка. Попробуйте позже.';
  }
}
