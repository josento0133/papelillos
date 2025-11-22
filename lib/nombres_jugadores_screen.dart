import 'package:flutter/material.dart';
import 'palabras_screen.dart';
import 'equipos_screen.dart';

class NombresJugadoresScreen extends StatefulWidget {
  final bool modoAleatorio;
  final bool modoTodasPalabrasAleatorias;
  final int numeroJugadores;
  final int palabrasPorJugador;
  final List<String> palabras;
  final int tiempoPorRonda;

  NombresJugadoresScreen({
    required this.numeroJugadores,
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias,
    required this.palabrasPorJugador,
    required this.palabras,
    required this.tiempoPorRonda,
  });

  @override
  _NombresJugadoresScreenState createState() => _NombresJugadoresScreenState();
}

class _NombresJugadoresScreenState extends State<NombresJugadoresScreen> {
  late int _numeroJugadores;
  final List<String> _nombres = [];
  final TextEditingController _nombreController = TextEditingController();
  final List<List<String>> _palabrasPorJugador = [];


  // Definición del color azul principal para consistencia
  final Color primaryBlue = Colors.blue;


  void _agregarNombre() {
    String nuevoNombre = _nombreController.text.trim();

    if (nuevoNombre.isEmpty) {
      _mostrarSnackBar('Por favor, ingresa un nombre.');
      return;
    }
    if (_nombres.contains(nuevoNombre)) {
      _mostrarSnackBar('Este nombre ya ha sido ingresado.');
      return;
    }
    if (_nombres.length >= widget.numeroJugadores) {
      _mostrarSnackBar('Ya has ingresado el número máximo de jugadores (${widget.numeroJugadores}).');
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
          modoAleatorio: widget.modoAleatorio,
          modoTodasPalabrasAleatorias: widget.modoTodasPalabrasAleatorias,
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


  // Función para agregar palabra aleatoria (solo si el modo lo requiere)


  bool _puedeContinuar() {
    bool todosJugadores = _nombres.length == widget.numeroJugadores;
    bool todasLasPalabrasLlenas = widget.modoTodasPalabrasAleatorias ||
        _palabrasPorJugador.every((palabras) => palabras.length == widget.palabrasPorJugador);
    return todosJugadores && todasLasPalabrasLlenas;
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
        content: Text('¿Estás seguro de que deseas volver atrás? Perderás el progreso de nombres.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sí', style: TextStyle(color: primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    )) ?? false;
  }

  // Helper para mostrar SnackBars
  void _mostrarSnackBar(String mensaje, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        duration: const Duration(milliseconds: 1500), // Muestra el SnackBar por 1.5 segundos
      ),
    );
  }



  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    int maxJugadores = widget.numeroJugadores;
    int jugadoresIngresados = _nombres.length;

    return WillPopScope(
      onWillPop: _mostrarDialogoConfirmacion,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Nombres de los Jugadores'),
          automaticallyImplyLeading: false,
          backgroundColor: primaryBlue,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(30.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Progreso: $jugadoresIngresados / $maxJugadores',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del jugador',
                        labelStyle: TextStyle(fontSize: 20, color: primaryBlue),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryBlue, width: 2.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                      ),
                      style: TextStyle(fontSize: 20),
                      onSubmitted: (_) => _agregarNombre(),
                      enabled: jugadoresIngresados < maxJugadores,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: jugadoresIngresados < maxJugadores ? _agregarNombre : null,
                    child: Text('Añadir', style: TextStyle(fontSize: 20, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: jugadoresIngresados,
                itemBuilder: (context, index) {
                  String nombre = _nombres[index];
                  bool palabrasCompletas = _palabrasPorJugador[index].length == widget.palabrasPorJugador;

                  return ListTile(
                    leading: Icon(Icons.person, color: primaryBlue),
                    title: Text(nombre, style: TextStyle(fontSize: 20)),
                    subtitle: Text(
                      // Si es FALSE (modo manual/mixto), muestra el progreso real.
                      'Palabras añadidas: ${_palabrasPorJugador[index].length} / ${widget.palabrasPorJugador}',

                      style: TextStyle(
                        // La lógica de color solo aplica si NO es el modo aleatorio total (para evitar errores en la condición de abajo).
                        fontWeight: FontWeight.bold,
                        // --- LÓGICA DE COLOR SIMPLIFICADA (Ignora el modo automático) ---
                        color: palabrasCompletas ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón Añadir/Ver Palabras (solo si el modo no es totalmente aleatorio)
                          ElevatedButton(
                            onPressed: palabrasCompletas
                                ? null // Deshabilitado si ya están completas
                                : () => _irAPalabrasScreen(nombre, index),
                            child: Text(
                              palabrasCompletas ? 'Completado' : 'Añadir',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              backgroundColor: palabrasCompletas ? Colors.green : primaryBlue,
                              disabledBackgroundColor: Colors.green[700],
                            ),
                          ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 28),
                          onPressed: () => _borrarNombre(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _puedeContinuar() ? _continuarEquipos : null,
                  child: Text('Continuar', style: TextStyle(fontSize: 24, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}