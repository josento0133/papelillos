import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse; // Necesario para parsear HTML
import 'package:html/dom.dart' as html_dom; // <--- ¡AQUÍ SE DEFINE EL PREFIJO!
// Importaciones de otras pantallas (EquiposScreen)

class PalabrasScreen extends StatefulWidget {
  final String nombre;
  final int palabrasPorJugador;
  final bool modoAleatorio;
  final bool modoTodasPalabrasAleatorias;

  PalabrasScreen({
    required this.nombre,
    required this.palabrasPorJugador,
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias,
    required List<String> palabras, // Aunque no se usa aquí, se mantiene por consistencia
  });

  @override
  _PalabrasScreenState createState() => _PalabrasScreenState();
}

class _PalabrasScreenState extends State<PalabrasScreen> {
  List<String> _palabras = [];
  final TextEditingController _palabraController = TextEditingController();
  final Color primaryBlue = Colors.blue;

  @override
  void dispose() {
    _palabraController.dispose();
    super.dispose();
  }

  // Helper para mostrar SnackBar
  void _mostrarSnackBar(String mensaje, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        duration: const Duration(milliseconds: 1500), // Muestra el SnackBar por 1.5 segundos
      ),
    );
  }

  // ----------------------------------------------------
  // MÉTODOS DE LÓGICA DE PALABRAS
  // ----------------------------------------------------

  void _agregarPalabra() {
    String nuevaPalabra = _palabraController.text.trim();
    if (nuevaPalabra.isEmpty) return;

    if (_palabras.length < widget.palabrasPorJugador) {
      setState(() {
        _palabras.add(nuevaPalabra);
        _palabraController.clear();
      });
    } else {
      _mostrarSnackBar('Ya has añadido el número máximo de palabras.', color: Colors.red);
    }
  }

  // Método para obtener una palabra aleatoria de la API
  Future<String?> _obtenerPalabraAleatoria() async {
    const String url = 'https://www.palabrasaleatorias.com/';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);

        // AHORA USAMOS EL PREFIJO 'html_dom.' para referenciar el objeto Element
        // --- CAMBIO CLAVE AQUÍ ---
        // Buscamos el div con el estilo grande (asumiendo que es el único)
        // Puede que necesites un selector más específico si hay muchos <div> en la página.
        html_dom.Element? wordElement = document.querySelector('div[style*="font-size:3em"]');
        // Si el anterior falla, prueba con este selector más general:
        // html_dom.Element? wordElement = document.querySelector('div[style]');
        if (wordElement != null) {
          String palabra = wordElement.text.trim().toLowerCase();

          if (palabra.isNotEmpty) {
            return palabra;
          }
        }

        throw Exception('No se pudo encontrar la palabra en la estructura HTML.');

      } else {
        throw Exception('Error al descargar la página. Estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en Web Scraping de Palabras: $e');
      _mostrarSnackBar('Fallo al obtener palabra. Usando reserva.', color: Colors.orange);
      return 'papelillo';
    }
  }

  // Rellena *solo una* palabra si el jugador no sabe qué poner.
  void _agregarPalabraAleatoriaSencilla() async {
    if (_palabras.length >= widget.palabrasPorJugador) {
      _mostrarSnackBar('Ya tienes todas tus palabras.');
      return;
    }

    String? palabra = await _obtenerPalabraAleatoria();

    if (palabra != null) {
      setState(() {
        _palabras.add(palabra);
      });
      _mostrarSnackBar('Palabra aleatoria añadida.');
    }
  }

  // Rellena todas las palabras automáticamente (Usado en modoTodasPalabrasAleatorias)
  void _rellenarTodasLasPalabras() async {
    try {
      _palabras.clear();
      List<String> nuevasPalabras = [];
      int palabrasFaltantes = widget.palabrasPorJugador;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Bucle para obtener todas las palabras
      while (nuevasPalabras.length < palabrasFaltantes) {
        String? palabra = await _obtenerPalabraAleatoria();

        if (palabra != null && palabra.isNotEmpty && !nuevasPalabras.contains(palabra)) {
          nuevasPalabras.add(palabra);
        } else {
          // Manejo de palabra duplicada o nula, evitamos el incremento de palabrasFaltantes
        }

        // Para evitar bloquear la UI, se puede añadir un pequeño delay, aunque la llamada async ya ayuda.
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Cerrar el indicador de carga
      Navigator.pop(context);

      setState(() {
        _palabras = nuevasPalabras;
      });

      _mostrarSnackBar('Se han añadido ${nuevasPalabras.length} palabras aleatorias.');
    } catch (e) {
      Navigator.pop(context);
      _mostrarSnackBar('Error al rellenar palabras: $e', color: Colors.red);
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

  // ----------------------------------------------------
  // WIDGET BUILD
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    double progreso = _palabras.length / widget.palabrasPorJugador;
    bool esModoManual = !widget.modoTodasPalabrasAleatorias;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Palabras de ${widget.nombre}',
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: LinearProgressIndicator(
            value: progreso,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(progreso == 1.0 ? Colors.green : Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. Campo de Entrada y Botón Añadir (Solo si es modo manual) ---
            if (esModoManual) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _palabraController,
                      decoration: InputDecoration(
                        labelText: 'Escribe tu palabra (${_palabras.length} / ${widget.palabrasPorJugador})',
                        labelStyle: TextStyle(fontSize: 18, color: primaryBlue),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryBlue, width: 2)),
                      ),
                      style: const TextStyle(fontSize: 20),
                      onSubmitted: (_) => _agregarPalabra(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _agregarPalabra,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Añadir', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón 'No me sé ninguna palabra' (Solo si modo manual y permitido el aleatorio)
              if (widget.modoAleatorio && _palabras.length < widget.palabrasPorJugador)
                ElevatedButton(
                  onPressed: _agregarPalabraAleatoriaSencilla,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Rellenar una aleatoria', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              const SizedBox(height: 10),
            ],

            // --- 2. Botón Rellenar Todas (Solo si modo Aleatorio Total) ---
            if (widget.modoTodasPalabrasAleatorias && !_puedeTerminar())
              ElevatedButton(
                onPressed: _rellenarTodasLasPalabras,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Rellenar mis palabras', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),

            // --- 3. Lista de Palabras (Se oculta si el modo es Aleatorio Total y no se han rellenado) ---
            if (esModoManual || _palabras.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _palabras.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _palabras[index],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _borrarPalabra(index),
                      ),
                    );
                  },
                ),
              )
            else
            // Mensaje cuando el modo es aleatorio total y aún no se han rellenado
              Expanded(
                child: Center(
                  child: Text(
                    'Presiona "Rellenar mis palabras" para empezar.',
                    style: TextStyle(fontSize: 18, color: primaryBlue),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // --- 4. Botón Confirmar ---
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _puedeTerminar() ? _terminar : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _puedeTerminar() ? 'Confirmar Palabras' : 'Faltan ${widget.palabrasPorJugador - _palabras.length} palabras',
                    style: const TextStyle(fontSize: 23, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}