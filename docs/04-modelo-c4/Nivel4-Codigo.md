# C4 Nivel 4: Código (diseño propuesto)

Todavía no existe código, así que este diagrama es una **propuesta** para el motor de niveles. Muestra cómo se respeta la regla de dependencias: la escena depende del presentador, el presentador de los casos de uso, los casos de uso del dominio y de sus puertos, y el adaptador SQLite implementa el puerto.

```mermaid
classDiagram
    direction LR
    class LevelView {
        <<escena>>
        +setup(presenter)
        +render(view_model)
    }
    class LevelPresenter {
        <<presentador>>
        +on_answer_selected(item_id, value)
        +on_hint_requested(item_id)
    }
    class SubmitAnswer {
        <<caso_de_uso>>
        +execute(request) SubmitAnswerResponse
    }
    class FinishLevel {
        <<caso_de_uso>>
        +execute(request) FinishLevelResponse
    }
    class LevelSession {
        <<entidad>>
        -DangerMeter danger
        -int lives
        +answer(item_id, value) AnswerOutcome
        +is_finished() bool
    }
    class DangerMeter {
        <<valor>>
        -int value
        -int max
        +hit() DangerMeter
        +miss() DangerMeter
        +is_caught() bool
    }
    class StarRule {
        <<regla>>
        +stars_for(valid_correct, total, lives_lost) int
    }
    class ItemEvaluator {
        <<interfaz>>
        +evaluate(item, value) bool
    }
    class MultipleChoiceEvaluator
    class OrderingEvaluator
    class NumericEvaluator
    class ReadingUnitEvaluator
    class AttemptRepository {
        <<puerto>>
        +save_answer(attempt_id, answer)
        +close_attempt(attempt)
    }
    class SqliteAttemptRepository {
        <<adaptador>>
    }
    LevelView --> LevelPresenter
    LevelPresenter --> SubmitAnswer
    LevelPresenter --> FinishLevel
    SubmitAnswer --> LevelSession
    SubmitAnswer --> AttemptRepository
    FinishLevel --> StarRule
    FinishLevel --> AttemptRepository
    LevelSession --> DangerMeter
    LevelSession --> ItemEvaluator
    ItemEvaluator <|.. MultipleChoiceEvaluator
    ItemEvaluator <|.. OrderingEvaluator
    ItemEvaluator <|.. NumericEvaluator
    ItemEvaluator <|.. ReadingUnitEvaluator
    AttemptRepository <|.. SqliteAttemptRepository
```

| Clase | Capa | Carpeta |
| --- | --- | --- |
| `LevelView` | Vista (framework) | `scenes/level/` |
| `LevelPresenter` | Adaptador de entrada | `src/presentation/presenters/` |
| `SubmitAnswer`, `FinishLevel` | Aplicación | `src/application/use_cases/play/` |
| `AttemptRepository` | Aplicación (puerto) | `src/application/ports/` |
| `LevelSession`, `DangerMeter`, `StarRule` | Dominio | `src/domain/rules/` |
| `ItemEvaluator` y evaluadores | Dominio | `src/domain/evaluators/` |
| `SqliteAttemptRepository` | Adaptador de salida | `src/infrastructure/sqlite/` |

**Estado:** propuesta que se validará con el código del Sprint 4 y el Sprint 5.
