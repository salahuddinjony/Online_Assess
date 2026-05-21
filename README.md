# SpendArc

Personal finance tracker built for the Taghyeer Technologies Senior Flutter Developer assessment.

## Architecture

- **Clean Architecture** with `presentation` → `domain` → `data` layers
- **Dependency injection** via `get_it`
- **Error handling** with `Either<Failure, T>` (`dartz`)
- **State management** with `flutter_bloc`

## Features (assessment modules)

| Module | Implementation |
|--------|----------------|
| Clean Architecture | Use cases, repository interfaces, `get_it`, `Either` failures |
| Custom animations | `BudgetArcMeter` (CustomPainter), `SpendingLineChart`, `SpringSwipeTile`, `ParticleBurstOverlay` |
| BLoC | Optimistic add/delete with rollback; `TransactionListCoordinator` stream to `DashboardBloc`; subscription cancelled in `close()` |
| Offline-first | Hive local store, write queue, background sync with `compute()` isolate diff |
| Testing | 5 unit + 2 widget tests |

## Run

```bash
flutter pub get
flutter run
flutter test
```

## Project structure

```
lib/
  core/           # failures, use cases, widgets, theme
  features/
    transactions/ # domain, data, presentation (bloc)
    dashboard/    # summary bloc fed by transaction stream
  injection_container.dart
  app.dart
  main.dart
```
