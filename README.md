# front_personal_budget

Фронтенд-часть Personal Budget: Flutter-клиент для учета доходов, расходов и
текущего баланса через REST API бэкенда BudgetServer.

Доска проекта: [YouGile](https://zavozik.yougile.com/board/4i11p9qwg9yu)

## Возможности

- Экраны входа и регистрации.
- Хранение JWT-сессии в browser `localStorage`.
- Автоматическая подстановка access token в защищенные API-запросы.
- Refresh token retry flow для ответов `401`.
- Список транзакций с расчетом баланса на клиенте.
- Добавление, редактирование и удаление доходов/расходов.
- Поддержка Flutter Web с PWA manifest.

## Архитектура

Приложение организовано по feature-based структуре.

- `lib/main.dart` создает Riverpod `ProviderScope`.
- `lib/app.dart` настраивает `MaterialApp.router`.
- `lib/core/router/app_router.dart` описывает GoRouter маршруты и auth
  redirects.
- `lib/core/api/` содержит Dio API client и auth interceptor.
- `lib/core/providers/` содержит общие Riverpod providers.
- `lib/core/repositories/` содержит repository-классы для работы с API.
- `lib/core/services/token_storage.dart` хранит access и refresh tokens.
- `lib/core/models/` содержит клиентские DTO для auth, users и transactions.
- `lib/features/auth/` содержит UI и controllers для входа и регистрации.
- `lib/features/transactions/` содержит экраны и providers для транзакций.

Состояние управляется через Riverpod. Навигация построена на GoRouter. Сетевые
запросы идут через Dio, а `API_BASE_URL` задается на этапе сборки и по
умолчанию равен `http://localhost:8080`.

## Стек

- Flutter и Dart
- Riverpod
- GoRouter
- Dio
- Material UI

## Локальный запуск

Установите зависимости:

```bash
flutter pub get
```

Запустите приложение против локального бэкенда на `http://localhost:8080`:

```bash
flutter run -d chrome
```

Для другого адреса API передайте `API_BASE_URL`:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## Проверки

```bash
flutter analyze
flutter test
```
