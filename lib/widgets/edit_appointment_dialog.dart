import 'package:flutter/material.dart';
import '../models/appointment.dart';

class EditAppointmentDialog extends StatefulWidget {
  final Appointment appointment;
  final Function(Appointment) onSave;

  const EditAppointmentDialog({
    super.key,
    required this.appointment,
    required this.onSave,
  });

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.appointment.dateTime;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le rendez-vous'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: widget.appointment.doctor.image.startsWith('assets/')
                    ? AssetImage(widget.appointment.doctor.image)
                    : null,
                onBackgroundImageError: (_, __) => null,
                child: widget.appointment.doctor.image.startsWith('assets/')
                    ? null
                    : const Icon(Icons.person),
              ),
              title: Text(widget.appointment.doctor.name),
              subtitle: Text(widget.appointment.doctor.specialty),
            ),
            const SizedBox(height: 16),
            const Text(
              'Date et heure du rendez-vous:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} à ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedAppointment = Appointment(
              id: widget.appointment.id,
              doctor: widget.appointment.doctor,
              dateTime: _selectedDateTime,
            );
            widget.onSave(updatedAppointment);
            Navigator.of(context).pop();
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}