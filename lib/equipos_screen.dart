import 'package:flutter/material.dart';
import 'juego_screen.dart'; // Asegúrate de importar tu pantalla de juego

class EquiposScreen extends StatefulWidget {
  final List<String> nombresJugadores;
  final List<String> palabras;
  final int tiempoPorRonda;

  EquiposScreen({
    required this.nombresJugadores,
    required this.palabras,
    required this.tiempoPorRonda,
  });

  @override
  _EquiposScreenState createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  List<List<String>> equipos = [];

  @override
  void initState() {
    super.initState();
    _formarEquipos(); // Llama a la función para formar los equipos al iniciar la pantalla
  }

  // Función para formar equipos aleatoriamente
  void _formarEquipos() {
    List<String> jugadores = List.from(widget.nombresJugadores);
    jugadores.shuffle();

    List<List<String>> nuevosEquipos = [];
    for (int i = 0; i < jugadores.length; i += 2) {
      nuevosEquipos.add(jugadores.sublist(i, i + 2 > jugadores.length ? jugadores.length : i + 2));
    }

    setState(() {
      equipos = nuevosEquipos;
    });
  }

  // Botón para re-aleatorizar los equipos
  void _reAleatorizarEquipos() {
    _formarEquipos();
  }

  // Función para navegar a la pantalla de juego
  void _iniciarJuego() {
    if (widget.palabras.isEmpty) {
      // Manejar el caso donde no hay palabras
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay palabras disponibles.')),
      );
      return;
    }
    print('Iniciando juego...'); // Verificar que se llame esta función
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JuegoScreen(
          equipos: equipos, // Pasamos los equipos
          palabras: widget.palabras, // Pasamos las palabras
          tiempoPorRonda: widget.tiempoPorRonda, // Pasamos el tiempo por ronda
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Equipos Aleatorios',
          style: TextStyle(fontSize: 22), // Aumenta el tamaño del texto en la AppBar
        ),
        automaticallyImplyLeading: false, // Esto oculta la flecha de retroceso
      ),
      body: Column(
        children: [
          SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: equipos.length,
              itemBuilder: (context, index) {
                List<String> equipo = equipos[index];
                return ListTile(
                  title: Text(
                    'Equipo ${index + 1}: ${equipo.join(' y ')}',
                    style: TextStyle(fontSize: 23, color:Colors.blue,fontWeight: FontWeight.bold), // Aumenta el tamaño del texto de la lista
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Añade espacio entre los botones
            child: ElevatedButton(
              onPressed: _reAleatorizarEquipos,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Tamaño del botón
                textStyle: TextStyle(fontSize: 25, color: Colors.white), // Tamaño y color del texto
                backgroundColor: Colors.lightBlue, // Color azul
              ),
              child: Text('Re-aleatorizar equipos'),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0), // Añade espacio en la parte inferior
            child: ElevatedButton(
              onPressed: _iniciarJuego,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Tamaño del botón
                textStyle: TextStyle(fontSize: 25, color: Colors.white), // Tamaño y color del texto
                backgroundColor: Colors.lightGreen, // Color azul
              ),
              child: Text('Iniciar Juego'),
            ),
          ),

          SizedBox(height: 50),
        ],
      ),
    );
  }
}
