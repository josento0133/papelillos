import 'package:flutter/material.dart';
import 'juego_screen.dart';

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

  // Variables para controlar el intercambio
  int? _equipoSeleccionadoIndex;
  int? _jugadorSeleccionadoIndex;

  @override
  void initState() {
    super.initState();
    _formarEquiposIniciales();
  }

  void _formarEquiposIniciales() {
    List<String> jugadores = List.from(widget.nombresJugadores);
    jugadores.shuffle(); // Mezclamos al principio, luego el usuario edita

    List<List<String>> nuevosEquipos = [];
    for (int i = 0; i < jugadores.length; i += 2) {
      nuevosEquipos.add(jugadores.sublist(i, i + 2 > jugadores.length ? jugadores.length : i + 2));
    }

    setState(() {
      equipos = nuevosEquipos;
    });
  }

  // Lógica principal de intercambio
  void _manejarToqueJugador(int equipoIdx, int jugadorIdx) {
    setState(() {
      // CASO 1: No hay nadie seleccionado, seleccionamos al primero
      if (_equipoSeleccionadoIndex == null) {
        _equipoSeleccionadoIndex = equipoIdx;
        _jugadorSeleccionadoIndex = jugadorIdx;
      }
      // CASO 2: Toco al mismo jugador que ya estaba seleccionado (Deseleccionar)
      else if (_equipoSeleccionadoIndex == equipoIdx && _jugadorSeleccionadoIndex == jugadorIdx) {
        _limpiarSeleccion();
      }
      // CASO 3: Hay un jugador seleccionado y toco a otro distinto -> INTERCAMBIO
      else {
        String jugadorA = equipos[_equipoSeleccionadoIndex!][_jugadorSeleccionadoIndex!];
        String jugadorB = equipos[equipoIdx][jugadorIdx];

        // Realizamos el intercambio
        equipos[_equipoSeleccionadoIndex!][_jugadorSeleccionadoIndex!] = jugadorB;
        equipos[equipoIdx][jugadorIdx] = jugadorA;

        _limpiarSeleccion();
      }
    });
  }

  void _limpiarSeleccion() {
    _equipoSeleccionadoIndex = null;
    _jugadorSeleccionadoIndex = null;
  }

  void _iniciarJuego() {
    if (widget.palabras.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JuegoScreen(
          equipos: equipos,
          palabras: widget.palabras,
          tiempoPorRonda: widget.tiempoPorRonda,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Equipos', style: TextStyle(fontSize: 22)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Toca un nombre y luego otro para intercambiarlos",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: equipos.length,
              itemBuilder: (context, indexEquipo) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Equipo ${indexEquipo + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        SizedBox(height: 10),
                        // Usamos Wrap o Row para mostrar los jugadores
                        Wrap(
                          spacing: 10.0,
                          children: equipos[indexEquipo].asMap().entries.map((entry) {
                            int indexJugador = entry.key;
                            String nombre = entry.value;

                            // Verificamos si este jugador específico está seleccionado
                            bool esSeleccionado = _equipoSeleccionadoIndex == indexEquipo &&
                                _jugadorSeleccionadoIndex == indexJugador;

                            return ChoiceChip(
                              label: Text(
                                nombre,
                                style: TextStyle(
                                    fontSize: 20,
                                    color: esSeleccionado ? Colors.white : Colors.black
                                ),
                              ),
                              selected: esSeleccionado,
                              selectedColor: Colors.orange, // Color cuando está seleccionado
                              backgroundColor: Colors.grey[200], // Color normal
                              onSelected: (_) {
                                _manejarToqueJugador(indexEquipo, indexJugador);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              onPressed: _iniciarJuego,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 25, color: Colors.white),
                backgroundColor: Colors.lightGreen,
              ),
              child: Text('Iniciar Juego', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}