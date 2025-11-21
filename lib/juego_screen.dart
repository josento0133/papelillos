import 'dart:async';
import 'dart:math'; // Importa el paquete para generar números aleatorios
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// Lista de frases posibles cuando se falla una palabra
List<String> frasesPalabraFallida = [
  "¡INÚTIL!",
  "¿En serio?",
  "Que espabile el otro",
  "Has descrito como una mierda",
  "En la siguiente fallaras tambien",
  "Menos mal que no cobras"
];

// Lista de frases posibles cuando se adivinan todas las palabras
List<String> frasesTodasPalabrasAdivinadas = [
  "¡Eres un máquina!, ¿O no?",
  "No te creas tanto, chalao.",
  "¡Bien hecho, idiota!",
  "¡Que palabras más faciles!",
  "Hacian falta mas palabras...",
  "En la siguiente ronda vas a perder"
];

// Lista de frases posibles para cuando se acaba el tiempo
List<String> frasesTiempoAgotado = [
  "¿Te tengo que poner media hora o qué?",
  "¿Que adivine algo el otro no?",
  "Venga que hay sueño",
  "¿Tas quedao dormido?",
  "Has descrito bien o que?",
  "Deja palabras pa los demas",
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
  bool botonPasarUsado = false; // Bandera para controlar el uso del botón
  int tiempoRestante = 0;
  late Timer _timer;
  List<String> palabrasRestantes = [];
  int rondaActual = 1; // Comienza en la ronda 1
  int palabrasAdivinadas = 0;
  bool turnoIniciado = false;
  Random _random = Random(); // Instancia de Random
  late AudioPlayer player;
  // Añadimos una lista para almacenar la puntuación de cada equipo
  List<int> puntuaciones = [];
  // Mapa para almacenar los sonidos
  final Map<String, String> sonidos = {
    'palabraFallida': 'error.mp3',
    'adivinada': 'adivinada.mp3', // Agrega más sonidos aquí
    'finTiempo': 'finTiempo.mp3',
    'todaspalabras': 'todaspalabras.mp3',
    'pasar': 'pasar.mp3',
    'reloj': 'reloj.mp3',
    // Añade otros sonidos según sea necesario
  };

  @override
  void initState() {
    super.initState();
    _reiniciarPalabras();
    tiempoRestante = widget.tiempoPorRonda;
    player = AudioPlayer(); // Inicializa el AudioPlayer
    _precargarSonidos(); // Precarga todos los sonidos

    // Inicializamos las puntuaciones para cada equipo en 0
    puntuaciones = List.filled(widget.equipos.length, 0);
  }
  // Método para precargar sonidos
  Future<void> _precargarSonidos() async {
    for (var sonido in sonidos.values) {
      await player.setSource(AssetSource(sonido)); // Precarga cada sonido
    }
  }
  // Método para reproducir un sonido
  void _reproducirSonido(String tipo) {
    player.play(AssetSource(sonidos[tipo]!)); // Reproduce el sonido correspondiente
  }


  void _reiniciarPalabras() {
    palabrasRestantes = List.from(widget.palabras);
  }

  void _seleccionarPalabraAleatoria() {
    print('Palabras restantes antes: $palabrasRestantes');
    if (palabrasRestantes.isNotEmpty) {
      setState(() {
        // Selecciona una palabra aleatoria
        int index = _random.nextInt(palabrasRestantes.length);
        palabraActual = palabrasRestantes[index];
        print('Nueva palabra seleccionada: $palabraActual');
      });
    }
  }
  void _pasarPalabra() {
    print('Intentando pasar palabra...');
    if (palabrasRestantes.isNotEmpty) {
      setState(() {
        try {
          _seleccionarPalabraAleatoria();
          _reproducirSonido('pasar');
          botonPasarUsado = true;
          print('Palabra pasada correctamente: $palabraActual');
        } catch (e) {
          print('Error en _pasarPalabra: $e');
        }
      });
    } else {
      print('No hay palabras disponibles para pasar.');
    }
  }

  void _iniciarTurno() {
    setState(() {
      turnoIniciado = true;
      botonPasarUsado = false; // Restablece la bandera al iniciar turno
    });
    _seleccionarPalabraAleatoria(); // Mueve la selección de palabra aquí
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (tiempoRestante > 0) {
          tiempoRestante--;
          // Reproducir sonido cuando queden 7 segundos
          if (tiempoRestante == 7) {
            _reproducirSonido('reloj'); // Reproduce el sonido del reloj
          }
        } else {
          // Selecciona una frase aleatoria de la lista
          String fraseAleatoria = frasesTiempoAgotado[Random().nextInt(frasesTiempoAgotado.length)];
          _finalizarTurno("¡TIEMPO!", fraseAleatoria);
          _reproducirSonido('finTiempo'); // Reproduce el sonido de tiempo agotado
        }
      });
    });
  }

  void _pararTimer() {
    _timer.cancel();
    botonPasarUsado = false;
  }

  void _finalizarTurno(String titulo, String mensaje) {
    _pararTimer();
    _mostrarVentanaEmergente(titulo, mensaje);
    _cambiarEquipo();
    botonPasarUsado = false;
  }

  void _cambiarEquipo() {
    setState(() {
      equipoActual = (equipoActual + 1) % widget.equipos.length;
      tiempoRestante = widget.tiempoPorRonda;
      turnoIniciado = false;
    });
  }

  void _adivinarPalabra() {
    setState(() {
      palabrasAdivinadas++;
      _reproducirSonido('adivinada'); // Reproduce el sonido al adivinar
      // Elimina la palabra actual de la lista solo si se adivina correctamente
      if (palabrasRestantes.isNotEmpty) {
        palabrasRestantes.remove(palabraActual);
        // Incrementa la puntuación del equipo actual
        puntuaciones[equipoActual]++;
      }

      if (palabrasRestantes.isEmpty) {
        // Aumenta la ronda actual al adivinar todas las palabras
        _reproducirSonido('todaspalabras');
        rondaActual++;
        // Selecciona una frase aleatoria de la lista
        String fraseAleatoria = frasesTodasPalabrasAdivinadas[Random().nextInt(frasesTodasPalabrasAdivinadas.length)];
        _finalizarTurno("NO HAY MÁS PALABRAS", fraseAleatoria);
        botonPasarUsado = false;
        _reiniciarPalabras(); // Reinicia las palabras para la nueva ronda
      } else {
        _seleccionarPalabraAleatoria();
      }
    });
  }


  Future<void> _palabraFallida() async {
    // Selecciona una frase aleatoria de la lista
    botonPasarUsado = false;
    String fraseAleatoria = frasesPalabraFallida[Random().nextInt(frasesPalabraFallida.length)];

    _reproducirSonido('palabraFallida'); // Reproduce el sonido para palabra fallida

    // No eliminamos la palabra de la lista cuando falla
    _finalizarTurno("PALABRA FALLADA", fraseAleatoria);
  }


  Future<void> _mostrarVentanaEmergente(String titulo, String mensaje) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            titulo,
            textAlign: TextAlign.center, // Centrar el título
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black), // Aumenta el tamaño del título
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SizedBox(height: 20),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), // Aumenta el tamaño del mensaje
                  // Centrar el mensaje
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Continuar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarConfirmacionSalir() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¿Quieres Volver?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Se PERDERÁ el turno, ¿Seguro?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Sí'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pop(); // Regresa a la pantalla anterior
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pararTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String equipoActualNombres = widget.equipos[equipoActual].join(' y '); // Nombres del equipo actual

    return WillPopScope(
      onWillPop: () async {
        _mostrarConfirmacionSalir(); // Muestra el diálogo de confirmación
        return false; // Previene el cierre de la pantalla hasta que el usuario confirme
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Juego en Curso'),
          automaticallyImplyLeading: false, // Esto oculta la flecha de retroceso
        ),

        body: Center( // Aquí se centra todo el contenido
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Alineación desde la parte superior
            crossAxisAlignment: CrossAxisAlignment.center, // Alineación centrada horizontalmente
            children: [
              // Sección que muestra la ronda actual
              Text(
                'Ronda $rondaActual', // Aquí se muestra la ronda actual
                style: TextStyle(fontSize: 24,color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 50),
              // Sección que muestra los nombres y puntuaciones de los otros equipos
              ...widget.equipos.asMap().entries.map((entry) {
                int index = entry.key;
                List<String> equipo = entry.value;
                String nombreEquipo = equipo.join(' y ');
                return Text(
                  '$nombreEquipo: ${puntuaciones[index]}',
                  style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                );
              }).toList(),
              SizedBox(height: 50), // Espaciado entre la lista y el nombre del equipo actual
              Text(
                'Equipo Actual',
                style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center, // Alineación del texto
              ),

              // Sección del botón "Estoy listo" y el nombre del equipo actual
              Text(
                '$equipoActualNombres',
                style: TextStyle(fontSize: 33, color: Colors.blue, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center, // Alineación del texto
              ),
              // Mostramos la puntuación del equipo actual debajo del nombre

              SizedBox(height: 60),
              if (!turnoIniciado)

                ElevatedButton(
                  onPressed: () {
                    _iniciarTurno();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Tamaño del botón
                    textStyle: TextStyle(fontSize: 30, color: Colors.white), // Tamaño y color del texto
                    backgroundColor: Colors.lightGreen, // Color rojo
                  ),

                  child: Text('Estoy listo', style: TextStyle(fontSize: 30)),
                ),

              // Separación entre el botón y la parte de juego
              SizedBox(height: 10),

              // Sección que muestra el contador, la palabra y los botones "Bien" y "Mal"
              if (turnoIniciado) ...[
                Text(
                  'Palabra a adivinar:',
                  style: TextStyle(fontSize: 25, color: Colors.blue),
                  textAlign: TextAlign.center, // Alineación del texto
                ),
                SizedBox(height: 50),
                Text(
                  '$palabraActual',
                  style: TextStyle(fontSize: 45, color: Colors.black, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, // Alineación del texto
                ),
                SizedBox(height: 80),
                Text(
                  'Tiempo restante: $tiempoRestante segundos',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue),
                  // Tamaño del texto para el contador
                  textAlign: TextAlign.center, // Alineación del texto
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _palabraFallida(); // Llama a la función
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25), // Tamaño del botón
                        textStyle: TextStyle(fontSize: 30, color: Colors.white), // Tamaño y color del texto
                        backgroundColor: Colors.redAccent, // Color de fondo
                      ),
                      child: Text('Mal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _pasarPalabra();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25), // Tamaño del botón
                        textStyle: TextStyle(fontSize: 30, color: Colors.white), // Tamaño del texto y color del texto
                        backgroundColor:  Colors.orangeAccent, // Cambia el color según el estado
                      ),
                      child: Text('Pasar'),
                    ),
                    ElevatedButton(
                      onPressed: _adivinarPalabra,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25), // Tamaño del botón
                        textStyle: TextStyle(fontSize: 30, color: Colors.white), // Tamaño del texto y color del texto
                        backgroundColor: Colors.lightGreen, // Azul eterno (puedes ajustar el valor hexadecimal)
                      ),
                      child: Text('Bien'),
                    ),

                  ],
                ),

              ],
            ],
          ),
        ),
      ),
    );
  }
}
