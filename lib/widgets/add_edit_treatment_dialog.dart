import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/treatment.dart';

class AddEditTreatmentDialog extends StatefulWidget {
  final Treatment? treatment;
  final int patientId;
  final Function(Treatment) onSave;

  const AddEditTreatmentDialog({
    super.key,
    this.treatment,
    required this.patientId,
    required this.onSave,
  });

  @override
  State<AddEditTreatmentDialog> createState() => _AddEditTreatmentDialogState();
}

class _AddEditTreatmentDialogState extends State<AddEditTreatmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _totalQuantityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  List<ConsumptionTime> _consumptionTimes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.treatment != null) {
      _medicationNameController.text = widget.treatment!.medicationName;
      _dosageController.text = widget.treatment!.dosage;
      _frequencyController.text = widget.treatment!.frequency;
      _totalQuantityController.text = widget.treatment!.totalQuantity.toString();
      _notesController.text = widget.treatment!.notes ?? '';
      _startDate = widget.treatment!.startDate;
      _endDate = widget.treatment!.endDate;
      _consumptionTimes = List.from(widget.treatment!.consumptionTimes);
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _totalQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: index < _consumptionTimes.length 
          ? _consumptionTimes[index].time 
          : TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (index < _consumptionTimes.length) {
          _consumptionTimes[index] = ConsumptionTime(
            time: picked,
            quantity: _consumptionTimes[index].quantity,
          );
        }
      });
    }
  }

  void _addConsumptionTime() {
    setState(() {
      _consumptionTimes.add(ConsumptionTime(
        time: TimeOfDay.now(),
        quantity: 1,
      ));
    });
  }

  void _removeConsumptionTime(int index) {
    setState(() {
      _consumptionTimes.removeAt(index);
    });
  }

  void _updateConsumptionQuantity(int index, int quantity) {
    setState(() {
      _consumptionTimes[index] = ConsumptionTime(
        time: _consumptionTimes[index].time,
        quantity: quantity,
      );
    });
  }

  Future<void> _saveTreatment() async {
    if (_formKey.currentState!.validate() && _startDate != null) {
      setState(() => _isLoading = true);
      
      // Store context before async operations
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final treatment = Treatment(
          id: widget.treatment?.id,
          patientId: widget.patientId,
          medicationName: _medicationNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _frequencyController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate,
          totalQuantity: int.parse(_totalQuantityController.text),
          consumedQuantity: widget.treatment?.consumedQuantity ?? 0,
          consumptionTimes: _consumptionTimes,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        widget.onSave(treatment);
        navigator.pop();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.treatment == null ? 'Ajouter un traitement' : 'Modifier le traitement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _medicationNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du médicament',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du médicament';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.scale),
                  hintText: 'Ex: 500mg, 10ml',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Fréquence',
                  prefixIcon: Icon(Icons.schedule),
                  hintText: 'Ex: 2 fois par jour, chaque 8h',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la fréquence';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité totale',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la quantité totale';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de début',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_startDate != null 
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Sélectionner une date'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de fin (optionnel)',
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(_endDate != null 
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Sélectionner une date'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Horaires de consommation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._consumptionTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final consumptionTime = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, index),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Heure',
                              ),
                              child: Text(consumptionTime.time.format(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: consumptionTime.quantity.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Quantité',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              final quantity = int.tryParse(value) ?? 1;
                              _updateConsumptionQuantity(index, quantity);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeConsumptionTime(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addConsumptionTime,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un horaire'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTreatment,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.treatment == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }
}