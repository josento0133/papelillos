import 'package:flutter/material.dart';
import 'palabras_screen.dart';
import 'equipos_screen.dart';
import 'dart:convert'; // Para el manejo de JSON
import 'package:http/http.dart' as http; // Paquete para hacer solicitudes HTTP

class NombresJugadoresScreen extends StatefulWidget {
  final bool modoAleatorio; // Parámetro para el modo de juego
  final bool modoTodasPalabrasAleatorias; // Parámetro para el modo de palabras aleatorias
  final int numeroJugadores;
  final int palabrasPorJugador;
  final List<String> palabras;
  final int tiempoPorRonda;

  NombresJugadoresScreen({
    required this.numeroJugadores,
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias, // Agregado
    required this.palabrasPorJugador,
    required this.palabras,
    required this.tiempoPorRonda,
  });

  @override
  _NombresJugadoresScreenState createState() => _NombresJugadoresScreenState();
}

class _NombresJugadoresScreenState extends State<NombresJugadoresScreen> {
  final List<String> _nombres = [];
  final TextEditingController _nombreController = TextEditingController();
  final List<List<String>> _palabrasPorJugador = [];

  void _agregarNombre() {
    String nuevoNombre = _nombreController.text.trim();

    if (nuevoNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa un nombre.')),
      );
      return;
    }
    if (_nombres.contains(nuevoNombre)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Este nombre ya ha sido ingresado.')),
      );
      return;
    }
    if (_nombres.length >= widget.numeroJugadores) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya has ingresado el número máximo de jugadores.')),
      );
      return;
    }

    setState(() {
      _nombres.add(nuevoNombre);
      _palabrasPorJugador.add([]);
      _nombreController.clear();
    });
  }

  void _borrarNombre(int index) {
    setState(() {
      _nombres.removeAt(index);
      _palabrasPorJugador.removeAt(index);
    });
  }

  void _irAPalabrasScreen(String nombreJugador, int index) async {
    List<String>? palabras = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PalabrasScreen(
          nombre: nombreJugador,
          palabras: widget.palabras,
          palabrasPorJugador: widget.palabrasPorJugador,
          modoAleatorio: widget.modoAleatorio, // Pasar el modo aleatorio
          modoTodasPalabrasAleatorias: widget.modoTodasPalabrasAleatorias, // Pásalo correctamente

        ),
      ),
    );

    if (palabras != null) {
      setState(() {
        _palabrasPorJugador[index] = palabras;
      });
    }
  }

  // Método para obtener una palabra aleatoria de la API
  Future<String?> _obtenerPalabraAleatoria() async {
    try {
      final response = await http.get(Uri.parse('https://api.example.com/palabras'));
      if (response.statusCode == 200) {
        // Aquí debes ajustar según la estructura de tu respuesta JSON
        final data = json.decode(response.body);
        return data['palabra']; // Ajusta según el campo correcto
      } else {
        throw Exception('Error al obtener palabra aleatoria');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener palabra aleatoria.')),
      );
      return null;
    }
  }

  void _agregarPalabraAleatoria(int index) async {
    String? palabra = await _obtenerPalabraAleatoria();
    if (palabra != null) {
      setState(() {
        _palabrasPorJugador[index].add(palabra);
      });
    }
  }

  bool _puedeContinuar() {
    return _nombres.length == widget.numeroJugadores &&
        _palabrasPorJugador.every((palabras) => palabras.length == widget.palabrasPorJugador);
  }

  void _continuarEquipos() {
    List<String> todasLasPalabras = _palabrasPorJugador.expand((x) => x).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquiposScreen(
          nombresJugadores: _nombres,
          palabras: todasLasPalabras,
          tiempoPorRonda: widget.tiempoPorRonda,
        ),
      ),
    );
  }

  Future<bool> _mostrarDialogoConfirmacion() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmación'),
        content: Text('¿Estás seguro de que deseas volver atrás?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirmar
            child: Text('Sí'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancelar
            child: Text('No'),
          ),
        ],
      ),
    )) ?? false; // Devuelve false si el diálogo se cierra sin seleccionar
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _mostrarDialogoConfirmacion, // Mostrar el diálogo de confirmación
      child: Scaffold(
        appBar: AppBar(
          title: Text('Nombres de los Jugadores'),
          automaticallyImplyLeading: false, // Esto oculta la flecha de retroceso
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del jugador',
                        labelStyle: TextStyle(fontSize: 20, color:Colors.lightBlueAccent),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _agregarNombre,
                    child: Text('Añadir', style: TextStyle(fontSize: 20, color:Colors.lightBlueAccent)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _nombres.length,
                itemBuilder: (context, index) {
                  String nombre = _nombres[index];

                  return ListTile(
                    title: Text(nombre, style: TextStyle(fontSize: 20, color:Colors.lightBlueAccent)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 30),
                          onPressed: () => _borrarNombre(index),
                        ),
                         // Condicional para mostrar el botón solo si el modo no está activado
                          ElevatedButton(
                            onPressed: _palabrasPorJugador[index].isNotEmpty
                                ? null
                                : () => _irAPalabrasScreen(nombre, index),
                            child: Text(
                              _palabrasPorJugador[index].isNotEmpty ? 'Palabras añadidas' : 'Añadir palabras',
                              style: TextStyle(fontSize: 15, color:Colors.lightBlueAccent),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _puedeContinuar() ? _continuarEquipos : null,
                child: Text('Continuar', style: TextStyle(fontSize: 30, color:Colors.lightBlueAccent)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
