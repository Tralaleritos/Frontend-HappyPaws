import 'package:flutter/material.dart';

import '../../../models/pet.dart'; // importa el modelo
import '../../../models/care_request.dart';
import '../../../services/request_service.dart';


class RequestFormScreen extends StatefulWidget {
  final Pet pet; // 👈 añadimos esta línea

  const RequestFormScreen({super.key, required this.pet});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}


class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Form'),
        leading: BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTimePickers(),
              const SizedBox(height: 16),
              _buildLocation(),
              const SizedBox(height: 16),
              _buildDetails(),
              const SizedBox(height: 16),
              _buildPetsSelector(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Enviar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('Fecha:'),
      subtitle: Text(_selectedDate == null
          ? 'Selecciona el dia'
          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
    );
  }

  Widget _buildTimePickers() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            title: const Text('Hora inicio:'),
            subtitle: Text(_startTime?.format(context) ?? 'Seleccion'),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: 15, minute: 0),
              );
              if (picked != null) setState(() => _startTime = picked);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ListTile(
            title: const Text('Hora fin:'),
            subtitle: Text(_endTime?.format(context) ?? 'Seleccion'),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: 18, minute: 0),
              );
              if (picked != null) setState(() => _endTime = picked);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return ListTile(
      title: const Text('Locacion:'),
      subtitle: const Text('San Miguel'),
      leading: const Icon(Icons.location_on),
    );
  }

  Widget _buildDetails() {
    return TextFormField(
      controller: _detailsController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Detalles',
        border: OutlineInputBorder(),
        hintText: 'Cuidar mascotas, alimentarlas, jugar...',
      ),
      validator: (value) =>
      value == null || value.isEmpty ? 'Please enter details' : null,
    );
  }

  Widget _buildPetsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mascotas:'),
        const SizedBox(height: 8),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(widget.pet.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white)),
          ),
          title: Text(widget.pet.name),
          subtitle: Text('${widget.pet.specie} - ${widget.pet.breed}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // futuro: seleccionar otra mascota
          },
        ),
      ],
    );
  }


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final request = CareRequest(
        caregiverName: 'Radamel', // ⚠️ <- Usa el nombre real si lo tienes
        petName: widget.pet.name,
        date: '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
        startTime: _startTime!.format(context),
        endTime: _endTime!.format(context),
        location: 'San Miguel',
        details: _detailsController.text,
      );

      await RequestService().saveRequest(request);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada con éxito')),
      );
    }
  }

}
