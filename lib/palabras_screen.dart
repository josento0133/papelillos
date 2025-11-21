import 'package:flutter/material.dart';
import 'equipos_screen.dart'; // Asegúrate de importar EquiposScreen
import 'package:http/http.dart' as http; // Importa el paquete http
import 'dart:convert'; // Asegúrate de importar esto


class PalabrasScreen extends StatefulWidget {
  final String nombre;
  final int palabrasPorJugador;
  final List<String> palabras;
  final bool modoAleatorio; // Agregar el parámetro modoAleatorio
  final bool modoTodasPalabrasAleatorias; // Agregar el parámetro modoTodasPalabrasAleatorias

  PalabrasScreen({
    required this.nombre,
    required this.palabrasPorJugador,
    required this.palabras,
    required this.modoAleatorio, // Asegúrate de requerir este parámetro
    required this.modoTodasPalabrasAleatorias, // Asegúrate de requerir este parámetro
  });

  @override
  _PalabrasScreenState createState() => _PalabrasScreenState();
}

class _PalabrasScreenState extends State<PalabrasScreen> {
  List<String> _palabras = [];
  final TextEditingController _palabraController = TextEditingController();

  // Método para agregar palabra normalmente
  void _agregarPalabra() {
    String nuevaPalabra = _palabraController.text.trim();
    if (nuevaPalabra.isNotEmpty) {
      if (_palabras.length < widget.palabrasPorJugador) {
        setState(() {
          _palabras.add(nuevaPalabra);
          _palabraController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ya has añadido el número máximo de palabras.')),
        );
      }
    }
  }

  // Método para agregar palabras aleatorias
  Future<void> _agregarPalabraAleatoria() async {
    String palabraAleatoria = await obtenerPalabraAleatoria();

    setState(() {
      if (_palabras.length < widget.palabrasPorJugador) {
        _palabras.add(palabraAleatoria);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ya has añadido el número máximo de palabras.')),
        );
      }
    });
  }

  // Método para obtener una palabra aleatoria de la API
  Future<String> obtenerPalabraAleatoria() async {
    final response = await http.get(Uri.parse('https://random-word-api.herokuapp.com/word?lang=es&number=1t'));

    if (response.statusCode == 200) {
      // Analiza la respuesta JSON
      List<dynamic> palabras = json.decode(response.body);

      // Devuelve la primera palabra de la lista
      return palabras.first;
    } else {
      throw Exception('Error al obtener la palabra aleatoria');
    }
  }

  void _rellenarPalabras() async {
    try {
      // Limpiar las palabras actuales para el jugador
      _palabras.clear();

      // Mostrar indicador de carga mientras se obtienen las palabras
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      List<String> nuevasPalabras = [];

      for (int i = 0; i < widget.palabrasPorJugador; i++) {
        String palabra = await obtenerPalabraAleatoria();
        nuevasPalabras.add(palabra);
      }

      // Cerrar el indicador de carga después de obtener las palabras
      Navigator.pop(context);

      // Actualizar el estado con las nuevas palabras
      setState(() {
        _palabras = nuevasPalabras;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se han añadido ${nuevasPalabras.length} palabras aleatorias.')),
      );
    } catch (e) {
      // Cerrar el indicador de carga en caso de error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener palabras aleatorias: $e')),
      );
    }
  }





  bool _puedeTerminar() {
    return _palabras.length == widget.palabrasPorJugador;
  }

  void _terminar() {
    Navigator.pop(context, _palabras);
  }

  void _borrarPalabra(int index) {
    setState(() {
      _palabras.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Palabras de ${widget.nombre}',
          style: TextStyle(fontSize: 20), // Aumenta el tamaño del texto en la AppBar
        ),
        automaticallyImplyLeading: false, // Esto oculta la flecha de retroceso
      ),

      body: Column(
        children: [
          if (!widget.modoTodasPalabrasAleatorias)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _palabraController,
              decoration: InputDecoration(
                labelText: 'Añadir Palabra',
                labelStyle: TextStyle(fontSize: 20, color: Colors.lightBlueAccent), // Tamaño del texto de la etiqueta
              ),
              style: TextStyle(fontSize: 20), // Tamaño del texto del campo de entrada
            ),
          ),
          SizedBox(height: 10),
          // Si no está activado el modo "todas palabras aleatorias", mostrar el botón de "Añadir"
          if (!widget.modoTodasPalabrasAleatorias)
            ElevatedButton(
              onPressed: _agregarPalabra,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Tamaño del botón
                textStyle: TextStyle(fontSize: 20, color: Colors.white), // Tamaño y color del texto
                backgroundColor: Colors.lightBlueAccent, // Azul eterno
              ),
              child: Text('Añadir'),
            ),
          SizedBox(height: 30),
          // Si no está activado el modo "todas palabras aleatorias", mostrar el botón "No me se ninguna palabra"
          if (!widget.modoTodasPalabrasAleatorias && widget.modoAleatorio)
            ElevatedButton(
              onPressed: _agregarPalabraAleatoria,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 20, color: Colors.white),
                backgroundColor: Colors.lightBlueAccent,
              ),
              child: Text('No me se ninguna palabra'),
            ),
          // Si el modo "todas palabras aleatorias" está activado, mostrar el botón para rellenar todas las palabras
          if (widget.modoTodasPalabrasAleatorias)
            ElevatedButton(
              onPressed: _rellenarPalabras,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 20, color: Colors.white),
                backgroundColor: Colors.lightBlueAccent,
              ),
              child: Text('Rellenar mis palabras'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _palabras.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _palabras[index],
                    style: TextStyle(
                      fontSize: 20,
                      color: widget.modoTodasPalabrasAleatorias ? Colors.transparent : Colors.black, // Hace el texto invisible si el modo está activado
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _borrarPalabra(index),
                  ),
                );
              },
            ),
          ),

          ElevatedButton(
            onPressed: _puedeTerminar() ? _terminar : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Tamaño del botón
              textStyle: TextStyle(fontSize: 23, color: Colors.white), // Tamaño y color del texto
              backgroundColor: Colors.lightBlueAccent, // Azul eterno
            ),
            child: Text('Confirmar Palabras'),
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }
}


class AgregarPalabrasScreen extends StatefulWidget {
  final List<String> nombresJugadores;
  final int palabrasPorJugador;
  final bool modoAleatorio;
  final bool modoTodasPalabrasAleatorias; // Recibe este parámetro

  AgregarPalabrasScreen({
    required this.nombresJugadores,
    required this.palabrasPorJugador,
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias, // Recibe este parámetro
  });

  @override
  _AgregarPalabrasScreenState createState() => _AgregarPalabrasScreenState();
}

class _AgregarPalabrasScreenState extends State<AgregarPalabrasScreen> {
  List<List<String>> palabrasPorJugador = [];

  Future<void> _agregarPalabrasJugador(int index) async {
    List<String> palabrasDelJugador = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PalabrasScreen(
          nombre: widget.nombresJugadores[index],
          palabrasPorJugador: widget.palabrasPorJugador,
          palabras: [],
          modoAleatorio: widget.modoAleatorio, // Aquí pasas el parámetro
          modoTodasPalabrasAleatorias: widget.modoTodasPalabrasAleatorias, // Asegúrate de pasar este parámetro
        ),
      ),
    );

    if (palabrasDelJugador.isNotEmpty) {
      palabrasPorJugador.add(palabrasDelJugador);

      if (index == widget.nombresJugadores.length - 1) {
        _navegarAEquipos();
      }
    }
  }

  void _navegarAEquipos() {
    List<String> todasLasPalabras = palabrasPorJugador.expand((x) => x).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquiposScreen(
          nombresJugadores: widget.nombresJugadores,
          palabras: todasLasPalabras,
          tiempoPorRonda: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agregar Palabras',
          style: TextStyle(fontSize: 20), // Aumenta el tamaño del texto en la AppBar
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.nombresJugadores.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    widget.nombresJugadores[index],
                    style: TextStyle(fontSize: 20), // Aumenta el tamaño del texto de la lista
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _agregarPalabrasJugador(index),
                    child: Text(
                      'Agregar Palabras',
                      style: TextStyle(fontSize: 20), // Tamaño del texto del botón
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
