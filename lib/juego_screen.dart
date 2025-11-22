import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// --- Listas de frases ---
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
  bool enCuentaRegresiva = false;
  int conteoInicial = 3;
  Timer? _timerCuentaAtras;
  List<String> palabrasAdivinadasRecuperables = [];
  int pasesRestantes = 1;

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
    await player.stop();
    await player.play(AssetSource(sonidos[tipo]!));
  }

  void _reiniciarPalabras() {
    palabrasRestantes = List.from(widget.palabras);
  }

  void _seleccionarPalabraAleatoria() {
    if (palabrasRestantes.isNotEmpty) {
      setState(() {
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
    if (juegoPausado || pasesRestantes <= 0) return;
    if (palabrasRestantes.isNotEmpty) {
      _seleccionarPalabraAleatoria();
      _reproducirSonido('pasar');
      setState(() {
        pasesRestantes--;
        botonPasarUsado = true;
      });
    }
  }

  void _iniciarTurno() {
    setState(() {
      turnoIniciado = true;
      botonPasarUsado = false;
      pasesRestantes = 1;
    });
    _seleccionarPalabraAleatoria();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (juegoPausado) return;
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
          _iniciarTurno();
        }
      });
    });
  }

  void _recuperarPalabrasAdivinadas() {
    if (palabrasAdivinadasRecuperables.isEmpty) return;

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
                height: 400,
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
                  onPressed: palabrasSeleccionadas.isEmpty ? null : () {
                    setState(() {
                      palabrasRestantes.addAll(palabrasSeleccionadas);
                      palabrasRestantes.shuffle();

                      for (var palabra in palabrasSeleccionadas) {
                        palabrasAdivinadasRecuperables.remove(palabra);
                      }
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
        palabrasAdivinadasRecuperables.add(palabraActual);
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
    int nuevoPuntaje = puntuaciones[indexEquipo];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modificar Puntuación de $nombreEquipo'),
          content: SingleChildScrollView(
            child: Column(
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
                    nuevoPuntaje = int.tryParse(value) ?? puntuaciones[indexEquipo];
                  },
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        int ajuste = nuevoPuntaje - 1;
                        controller.text = ajuste.toString();
                        nuevoPuntaje = ajuste;
                      },
                      child: Text('-1', style: TextStyle(fontSize: 20)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        int ajuste = nuevoPuntaje + 1;
                        controller.text = ajuste.toString();
                        nuevoPuntaje = ajuste;
                      },
                      child: Text('+1', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ],
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
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: palabrasEnEdicion.length,
                  itemBuilder: (context, index) {
                    if (index >= palabrasEnEdicion.length) return SizedBox.shrink();

                    bool revelada = palabrasReveladas.length > index ? palabrasReveladas[index] : false;
                    String palabraOculta = palabrasEnEdicion[index];
                    String textoParaMostrar;

                    if (palabraOculta.isEmpty) {
                      textoParaMostrar = '[Vacío]';
                    } else {
                      String primeraLetra = palabraOculta[0].toUpperCase();
                      String asteriscos = '*' * (palabraOculta.length - 1);
                      textoParaMostrar = primeraLetra + asteriscos;
                    }

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
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                                textoParaMostrar,
                                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)
                            ),
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
    if(_timerCuentaAtras != null && _timerCuentaAtras!.isActive) _timerCuentaAtras!.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback pasarAction = pasesRestantes > 0 ? () => _pasarPalabra() : () {};
    final Color pasarColor = pasesRestantes > 0 ? Colors.orangeAccent : Colors.grey;
    final String pasarText = 'Pasar (${pasesRestantes})';
    String equipoActualNombres = widget.equipos[equipoActual].join(' y ');

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
          centerTitle: true,
          actions: [
            if (palabrasAdivinadasRecuperables.isNotEmpty)
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'Recuperar ${palabrasAdivinadasRecuperables.length} palabras',
                onPressed: _recuperarPalabrasAdivinadas,
              ),
            IconButton(
              icon: Icon(Icons.edit, color: editarAction != null ? Colors.blue : Colors.grey),
              tooltip: 'Editar palabras restantes',
              onPressed: editarAction,
            ),
            if (turnoIniciado && !enCuentaRegresiva)
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- Cabecera ---
                          Text(
                            'Ronda $rondaActual',
                            style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),

                          // --- Puntuaciones ---
                          if (!turnoIniciado && !enCuentaRegresiva)
                            Wrap(
                              spacing: 15,
                              runSpacing: 5,
                              alignment: WrapAlignment.center,
                              children: widget.equipos.asMap().entries.map((entry) {
                                int indexEquipo = entry.key;
                                String nombreEquipo = entry.value.join(' y ');

                                return IntrinsicWidth(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '$nombreEquipo: ${puntuaciones[indexEquipo]}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18, color: Colors.blue[900], fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 18, color: Colors.grey[700]),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        onPressed: () => _mostrarDialogoEditarPuntuacion(indexEquipo, nombreEquipo),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                          SizedBox(height: 20),

                          Text(
                            'Turno de:',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            equipoActualNombres,
                            style: TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),

                          SizedBox(height: 20),

                          // --- Botón EMPEZAR ---
                          if (!turnoIniciado && !enCuentaRegresiva)
                            ElevatedButton(
                              onPressed: _iniciarCuentaAtras,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                backgroundColor: Colors.lightGreen,
                                elevation: 5,
                              ),
                              child: Text('¡EMPEZAR!', style: TextStyle(fontSize: 28, color: Colors.white)),
                            ),

                          // --- Cuenta Regresiva ---
                          if (enCuentaRegresiva)
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$conteoInicial',
                                  style: TextStyle(
                                      fontSize: 100,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange
                                  ),
                                ),
                              ),
                            ),

                          // --- Pantalla de Juego ---
                          if (turnoIniciado) ...[
                            Text(
                              'Palabra:',
                              style: TextStyle(fontSize: 20, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),

                            // Palabra o Pausado
                            Flexible(
                              flex: 2,
                              child: Center(
                                child: juegoPausado
                                    ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
                                    SizedBox(height: 10),
                                    Text(
                                      "PAUSADO",
                                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                    Text("Palabra oculta", style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  ],
                                )
                                    : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      palabraActual,
                                      style: TextStyle(fontSize: 55, color: Colors.black, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Tiempo
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

                            SizedBox(height: 20),

                            // Botones de juego
                            if (juegoPausado)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: Text(
                                  "JUEGO PAUSADO",
                                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orange),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              Flexible(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: _botonJuego('Mal', Colors.redAccent, () => _palabraFallida()),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: _botonJuego(pasarText, pasarColor, pasarAction),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: _botonJuego('Bien', Colors.green, _adivinarPalabra),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _botonJuego(String texto, Color color, VoidCallback accion) {
    return ElevatedButton(
      onPressed: accion,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          texto,
          style: TextStyle(fontSize: 20, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}