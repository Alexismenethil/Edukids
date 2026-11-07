@abstract class_name PinHasher
extends RefCounted
## Puerto: hash con sal de los PIN (RNF-08). El PIN nunca se guarda en texto claro.


## Sal aleatoria nueva, en hexadecimal.
@abstract func new_salt() -> String


## Hash del PIN con la sal dada, listo para guardar.
@abstract func hash_pin(digits: String, salt: String) -> String


## ¿El PIN escrito corresponde a la credencial guardada?
@abstract func verify(digits: String, credential: PinCredential) -> bool
