import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// --- Listas de frases (Sin cambios) ---
List<String> frasesPalabraFallida = [
  "¡INÚTIL!", "¿En serio?", "Que espabile el otro", "Has descrito como una mierda",
  "En la siguiente fallaras tambien", "Menos mal que no cobras"
];
List<String> frasesTodasPalabrasAdivinadas = [
  "¡Eres un máquina!, ¿O no?", "No te creas tanto, chalao.", "¡Bien hecho, idiota!",
  "¡Que palabras más faciles!", "Hacian falta mas palabras...", "En la siguiente ronda vas a perder"
];
List<String> frasesTiempoAgotado = [
  "¿Te tengo que poner media hora o qué?", "¿Que adivine algo el otro no?", "Venga que hay sueño",
  "¿Tas quedao dormido?", "Has descrito bien o que?", "Deja palabras pa los demas",
  "¿De quien ha sido la culpa? Tuya me imagino"
];

class JuegoScreen extends StatefulWidget {
  final List<List<String>> equipos;
  final List<String> palabras;
  final int tiempoPorRonda;

  JuegoScreen({
    required this.equipos,
    required this.palabras,
    required this.tiempoPorRonda,
  });

  @override
  _JuegoScreenState createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  int equipoActual = 0;
  String palabraActual = '';
  bool botonPasarUsado = false;
  int tiempoRestante = 0;
  late Timer _timer;
  List<String> palabrasRestantes = [];
  int rondaActual = 1;
  int palabrasAdivinadas = 0;
  bool turnoIniciado = false;
  Random _random = Random();
  late AudioPlayer player;
  List<int> puntuaciones = [];
  bool juegoPausado = false;
  bool enCuentaRegresiva = false; // Para saber si estamos contando 3, 2, 1
  int conteoInicial = 3; // El número que se muestra
  Timer? _timerCuentaAtras; // Timer específico para la cuenta atrás
  List<String> palabrasAdivinadasRecuperables = []; // NUEVO: Almacena las palabras adivinadas para recuperarlas
  int pasesRestantes = 1; // O el número que decidas

  final Map<String, String> sonidos = {
    'palabraFallida': 'error.mp3',
    'adivinada': 'adivinada.mp3',
    'finTiempo': 'finTiempo.mp3',
    'todaspalabras': 'todaspalabras.mp3',
    'pasar': 'pasar.mp3',
    'reloj': 'reloj.mp3',
  };

  @override
  void initState() {
    super.initState();
    _reiniciarPalabras();
    tiempoRestante = widget.tiempoPorRonda;
    player = AudioPlayer();
    _precargarSonidos();
    puntuaciones = List.filled(widget.equipos.length, 0);
  }

  Future<void> _precargarSonidos() async {
    for (var sonido in sonidos.values) {
      await player.setSource(AssetSource(sonido));
    }
  }

  void _reproducirSonido(String tipo) async {
    // MEJORA: stop() antes de play() evita solapamientos extraños si pulsas muy rápido
    await player.stop();
    await player.play(AssetSource(sonidos[tipo]!));
  }

  void _reiniciarPalabras() {
    palabrasRestantes = List.from(widget.palabras);
  }

  void _seleccionarPalabraAleatoria() {
    if (palabrasRestantes.isNotEmpty) {
      setState(() {
        // MEJORA: Evita repetir la misma palabra si se pulsa "Pasar"
        if (palabrasRestantes.length > 1 && palabraActual.isNotEmpty) {
          String nuevaPalabra;
          do {
            int index = _random.nextInt(palabrasRestantes.length);
            nuevaPalabra = palabrasRestantes[index];
          } while (nuevaPalabra == palabraActual);
          palabraActual = nuevaPalabra;
        } else {
          int index = _random.nextInt(palabrasRestantes.length);
          palabraActual = palabrasRestantes[index];
        }
      });
    }
  }

  void _pasarPalabra() {
    if (juegoPausado || pasesRestantes <= 0) return; // <--- NUEVA CONDICIÓN
    if (palabrasRestantes.isNotEmpty) {
      // MEJORA: Pequeña penalización o límite opcional podría ir aquí
      _seleccionarPalabraAleatoria();
      _reproducirSonido('pasar');
      setState(() {
        pasesRestantes--; // <--- DECREMENTA
        botonPasarUsado = true;
      });
    }
  }

  void _iniciarTurno() {
    setState(() {
      turnoIniciado = true;
      botonPasarUsado = false;
      pasesRestantes = 1; // <--- AÑADE ESTO
    });
    _seleccionarPalabraAleatoria();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (juegoPausado) return; // <--- SI ESTÁ PAUSADO, NO HACE NADA
      setState(() {
        if (tiempoRestante > 0) {
          tiempoRestante--;
          if (tiempoRestante == 7) {
            _reproducirSonido('reloj');
          }
        } else {
          String fraseAleatoria = frasesTiempoAgotado[_random.nextInt(frasesTiempoAgotado.length)];
          _finalizarTurno("¡TIEMPO!", fraseAleatoria);
          _reproducirSonido('finTiempo');
        }
      });
    });
  }

  void _pararTimer() {
    if (_timer.isActive) _timer.cancel();
    botonPasarUsado = false;
  }

  void _finalizarTurno(String titulo, String mensaje) {
    _pararTimer();
    _mostrarVentanaEmergente(titulo, mensaje);
    _cambiarEquipo();
  }

  void _cambiarEquipo() {
    setState(() {
      equipoActual = (equipoActual + 1) % widget.equipos.length;
      tiempoRestante = widget.tiempoPorRonda;
      turnoIniciado = false;
    });
  }
  void _iniciarCuentaAtras() {
    if (turnoIniciado || enCuentaRegresiva) return;

    setState(() {
      enCuentaRegresiva = true;
      conteoInicial = 3;
    });

    _timerCuentaAtras = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (conteoInicial > 1) {
          conteoInicial--;
        } else {
          timer.cancel();
          enCuentaRegresiva = false;
          _iniciarTurno(); // Inicia el turno de juego real
        }
      });
    });
  }
  void _recuperarPalabrasAdivinadas() {
    if (palabrasAdivinadasRecuperables.isEmpty) return;

    // Usamos una copia para las selecciones temporales
    List<String> palabrasOriginales = List.from(palabrasAdivinadasRecuperables);
    List<String> palabrasSeleccionadas = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('Selecciona Palabras para Recuperar'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400, // Altura fija para la lista
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: palabrasOriginales.length,
                  itemBuilder: (context, index) {
                    final palabra = palabrasOriginales[index];
                    final isSelected = palabrasSeleccionadas.contains(palabra);

                    return CheckboxListTile(
                      title: Text(palabra),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            palabrasSeleccionadas.add(palabra);
                          } else {
                            palabrasSeleccionadas.remove(palabra);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  // Deshabilitado si no hay nada seleccionado
                  onPressed: palabrasSeleccionadas.isEmpty ? null : () {
                    setState(() {
                      // 1. Añade las palabras seleccionadas a la lista de juego
                      palabrasRestantes.addAll(palabrasSeleccionadas);
                      palabrasRestantes.shuffle();

                      // 2. Elimina las palabras seleccionadas de la lista de recuperables
                      for (var palabra in palabrasSeleccionadas) {
                        palabrasAdivinadasRecuperables.remove(palabra);
                      }

                      // 3. No paramos el turno, el juego continúa
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Recuperar (${palabrasSeleccionadas.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _adivinarPalabra() {
    if (juegoPausado) return;
    setState(() {
      palabrasAdivinadas++;
      _reproducirSonido('adivinada');

      if (palabrasRestantes.isNotEmpty) {
        // Mueve la palabra a la lista de recuperables, junto con el equipo que la adivinó
        // Guardamos un objeto/mapa simple con la palabra y la puntuación
        palabrasAdivinadasRecuperables.add(
            palabraActual
        ); // <--- Solo la palabra es suficiente para este caso de uso

        palabrasRestantes.remove(palabraActual);
        puntuaciones[equipoActual]++;
      }

      if (palabrasRestantes.isEmpty) {
        _reproducirSonido('todaspalabras');
        rondaActual++;
        String fraseAleatoria = frasesTodasPalabrasAdivinadas[_random.nextInt(frasesTodasPalabrasAdivinadas.length)];
        _finalizarTurno("NO HAY MÁS PALABRAS", fraseAleatoria);
        _reiniciarPalabras();
      } else {
        _seleccionarPalabraAleatoria();
      }
    });
  }

  Future<void> _mostrarDialogoEditarPuntuacion(int indexEquipo, String nombreEquipo) async {
    TextEditingController controller = TextEditingController(text: puntuaciones[indexEquipo].toString());

    // Almacenará el nuevo valor
    int nuevoPuntaje = puntuaciones[indexEquipo];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modificar Puntuación de $nombreEquipo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Puntuación actual: ${puntuaciones[indexEquipo]}'),
              SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nuevo Puntaje Total',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.score),
                ),
                onChanged: (value) {
                  // Intentamos parsear el valor a entero
                  nuevoPuntaje = int.tryParse(value) ?? puntuaciones[indexEquipo];
                },
              ),
              SizedBox(height: 15),
              // Botones para ajustes rápidos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      int ajuste = nuevoPuntaje - 1;
                      setState(() {
                        controller.text = ajuste.toString();
                        nuevoPuntaje = ajuste;
                      });
                    },
                    child: Text('-1', style: TextStyle(fontSize: 20)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      int ajuste = nuevoPuntaje + 1;
                      setState(() {
                        controller.text = ajuste.toString();
                        nuevoPuntaje = ajuste;
                      });
                    },
                    child: Text('+1', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Aplicamos el nuevo puntaje y forzamos el rebuild de la pantalla de juego
                setState(() {
                  puntuaciones[indexEquipo] = nuevoPuntaje;
                });
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _palabraFallida() async {
    String fraseAleatoria = frasesPalabraFallida[_random.nextInt(frasesPalabraFallida.length)];
    _reproducirSonido('palabraFallida');
    _finalizarTurno("PALABRA FALLADA", fraseAleatoria);
  }
  Future<void> _mostrarDialogoEditarPalabras() async {
    List<String> palabrasEnEdicion = List.from(palabrasRestantes);
    List<bool> palabrasReveladas = List.filled(palabrasEnEdicion.length, false);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {

            return AlertDialog(
              title: Text('Editar Palabras Restantes (${palabrasEnEdicion.length})'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: palabrasEnEdicion.length,
                  itemBuilder: (context, index) {

                    if (index >= palabrasEnEdicion.length) return SizedBox.shrink();

                    bool revelada = palabrasReveladas.length > index ? palabrasReveladas[index] : false;

                    // --- NUEVA LÓGICA PARA EL TEXTO OCULTO ---
                    String palabraOculta = palabrasEnEdicion[index];
                    String textoParaMostrar;

                    if (palabraOculta.isEmpty) {
                      textoParaMostrar = '[Vacío]';
                    } else {
                      // Muestra la primera letra en mayúscula seguida de asteriscos
                      String primeraLetra = palabraOculta[0].toUpperCase();
                      // Genera N-1 asteriscos
                      String asteriscos = '*' * (palabraOculta.length - 1);
                      textoParaMostrar = primeraLetra + asteriscos;
                    }
                    // ------------------------------------------

                    TextEditingController controller = TextEditingController(text: palabrasEnEdicion[index]);
                    controller.selection = TextSelection.fromPosition(TextPosition(offset: palabrasEnEdicion[index].length));

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: revelada
                          ? TextField(
                        controller: controller,
                        onChanged: (newValue) {
                          palabrasEnEdicion[index] = newValue;
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility_off, color: Colors.grey),
                                onPressed: () {
                                  setStateDialog(() {
                                    palabrasReveladas[index] = false;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setStateDialog(() {
                                    palabrasEnEdicion.removeAt(index);
                                    palabrasReveladas.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                          : Row( // Muestra el texto oculto con la primera letra
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              textoParaMostrar, // <--- TEXTO MODIFICADO
                              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)
                          ),
                          IconButton(
                            icon: Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () {
                              setStateDialog(() {
                                palabrasReveladas[index] = true;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      palabrasRestantes = palabrasEnEdicion.where((p) => p.isNotEmpty).toList();
                      palabrasRestantes.shuffle();
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Guardar Cambios'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!palabrasRestantes.contains(palabraActual) || palabrasRestantes.isEmpty) {
      if (turnoIniciado) _seleccionarPalabraAleatoria();
    }
  }

  Future<void> _mostrarVentanaEmergente(String titulo, String mensaje) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Continuar', style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    bool? salir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¿Quieres Volver?'),
          content: Text('Se PERDERÁ el turno actual.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Sí, salir'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return salir ?? false;
  }

  @override
  void dispose() {
    if(turnoIniciado && _timer.isActive) _timer.cancel();
    if(_timerCuentaAtras != null && _timerCuentaAtras!.isActive) _timerCuentaAtras!.cancel(); // <--- LÍNEA AÑADIDA
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DENTRO del método build(BuildContext context) { ...
// ...

// <<<<<<< ESTE CÓDIGO DEBE ESTAR ARRIBA DE TODO TU LISTADO DE WIDGETS >>>>>>>

    final VoidCallback pasarAction = pasesRestantes > 0
        ? () => _pasarPalabra()
        : () {};

    final Color pasarColor = pasesRestantes > 0
        ? Colors.orangeAccent
        : Colors.grey;

    final String pasarText = 'Pasar (${pasesRestantes})';

// ...
    String equipoActualNombres = widget.equipos[equipoActual].join(' y ');

    // --- SOLUCIÓN: DECLARACIÓN MOVIDA FUERA DE LA LISTA DE ACTIONS ---
    final VoidCallback? editarAction = (!turnoIniciado && !enCuentaRegresiva) || (turnoIniciado && juegoPausado)
        ? _mostrarDialogoEditarPalabras
        : null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Juego en Curso'),
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra también el título de la AppBar
          actions: [
            if (palabrasAdivinadasRecuperables.isNotEmpty) // Solo se muestra si hay palabras para recuperar
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'Recuperar ${palabrasAdivinadasRecuperables.length} palabras',
                onPressed: _recuperarPalabrasAdivinadas,
              ),
            // Botón de Editar Palabras
            IconButton(
              icon: Icon(Icons.edit, color: editarAction != null ? Colors.blue : Colors.grey),
              tooltip: 'Editar palabras restantes',
              onPressed: editarAction,
            ),
            if (turnoIniciado && !enCuentaRegresiva) // Solo mostramos pausa si el tiempo corre
              IconButton(
                icon: Icon(juegoPausado ? Icons.play_arrow : Icons.pause, size: 35),
                onPressed: () {
                  setState(() {
                    juegoPausado = !juegoPausado;
                  });
                },
              ),
            SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: SizedBox(
            width: double.infinity, // <--- ESTO ES LA CLAVE: Fuerza a ocupar todo el ancho
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // <--- Fuerza el centrado horizontal
                children: [
                  // --- Cabecera ---
                  Text(
                    'Ronda $rondaActual',
                    style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),

                  // --- Puntuaciones (Con nombres reales) ---
                  // --- Puntuaciones (Nombres reales) ---
                  if (!turnoIniciado && !enCuentaRegresiva)
                  Wrap(
                    spacing: 15, runSpacing: 5, alignment: WrapAlignment.center,
                    children: widget.equipos.asMap().entries.map((entry) {
                      int indexEquipo = entry.key;
                      String nombreEquipo = entry.value.join(' y ');

                      return Row( // Usamos Row para agrupar el texto y el icono
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$nombreEquipo: ${puntuaciones[indexEquipo]}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.blue[900], fontWeight: FontWeight.bold),
                          ),
                          // Icono de edición
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: Colors.grey[700]),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _mostrarDialogoEditarPuntuacion(indexEquipo, nombreEquipo),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                  Spacer(flex: 1),

                  Text(
                    'Turno de:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    equipoActualNombres,
                    style: TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  Spacer(flex: 1),

                  if (!turnoIniciado && !enCuentaRegresiva) // Ocultar botón si ya está contando
                    ElevatedButton(
                      onPressed: _iniciarCuentaAtras, // <--- CAMBIO AQUÍ
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        backgroundColor: Colors.lightGreen,
                        elevation: 5,
                      ),
                      child: Text('¡EMPEZAR!', style: TextStyle(fontSize: 28, color: Colors.white)),
                    ),
                  // Añade esto dentro del Column, donde mejor te parezca (por ejemplo, donde sale la palabra)

                  if (enCuentaRegresiva)
                    Center(
                      child: Text(
                        '$conteoInicial',
                        style: TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange
                        ),
                      ),
                    ),

                  if (turnoIniciado) ...[
                    Text(
                      'Palabra:',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    juegoPausado
                        ? Column(
                      children: [
                        Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
                        Text(
                          "PAUSADO",
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        Text("Palabra oculta", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    )
                        : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        palabraActual,
                        style: TextStyle(fontSize: 55, color: Colors.black, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    Spacer(flex: 1),

                    Text(
                      '$tiempoRestante',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: tiempoRestante < 10 ? 60 : 40,
                          fontWeight: FontWeight.bold,
                          color: tiempoRestante < 10 ? Colors.red : Colors.blue
                      ),
                    ),
                    Text(
                      'segundos',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),

                    Spacer(flex: 2),
                    if (juegoPausado)
                      Text("JUEGO PAUSADO", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange))
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _botonJuego('Mal', Colors.redAccent, () => _palabraFallida()),

                          // Usa las variables definidas arriba
                          _botonJuego(pasarText, pasarColor, pasarAction),

                          _botonJuego('Bien', Colors.green, _adivinarPalabra),
                        ],
                      ),
// ...
                  ],
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MEJORA: Widget auxiliar para no repetir código en los botones
  Widget _botonJuego(String texto, Color color, VoidCallback accion) {
    return ElevatedButton(
      onPressed: accion,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(texto, style: TextStyle(fontSize: 22, color: Colors.white)),
    );
  }
}