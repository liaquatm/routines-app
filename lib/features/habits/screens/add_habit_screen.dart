import 'package:flutter/material.dart';
import '../../../models/habit.dart';

/// The overlay screen that allows users to create a new habit.
/// It uses a Modal Bottom Sheet style to slide up from the bottom.
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  // Controllers manage the text being typed into the fields.
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  // Default values for a new habit.
  Color _selectedColor = Colors.green;
  FrequencyType _freqType = FrequencyType.fixed;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Default: Every day
  int _flexCount = 3;                             // Default: 3 times a week

  // Available colors for the user to pick from.
  final List<Color> _colors = [
    Colors.green, Colors.blue, Colors.red, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo
  ];

  // Labels for the week days.
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Styling the container to look like a modern card.
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        // Shifts the UI up when the keyboard appears.
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Takes only the space needed.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The small "drag handle" icon at the top.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            const Text(
              'Add New Habit',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // HABIT NAME INPUT
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),

            // DESCRIPTION INPUT
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),

            // COLOR PICKER
            const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = _colors[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 40,
                      decoration: BoxDecoration(
                        color: _colors[index],
                        shape: BoxShape.circle,
                        border: _selectedColor == _colors[index] 
                            ? Border.all(width: 3, color: Colors.black) 
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // FREQUENCY SETTINGS
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<FrequencyType>(
              segments: const [
                ButtonSegment(value: FrequencyType.fixed, label: Text('Fixed')),
                ButtonSegment(value: FrequencyType.flexible, label: Text('Flexible')),
              ],
              selected: {_freqType},
              onSelectionChanged: (val) => setState(() => _freqType = val.first),
            ),
            const SizedBox(height: 16),

            // DYNAMIC INPUTS (Shows either Day Picker or Slider)
            if (_freqType == FrequencyType.fixed) ...[
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1; // 1 = Mon, 7 = Sun
                  final isSelected = _selectedDays.contains(day);
                  return ChoiceChip(
                    label: Text(_weekDays[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedDays.add(day) : _selectedDays.remove(day);
                      });
                    },
                  );
                }),
              )
            ] else ...[
              Row(
                children: [
                  const Text('Times per week: '),
                  Expanded(
                    child: Slider(
                      value: _flexCount.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: _flexCount.toString(),
                      onChanged: (val) => setState(() => _flexCount = val.toInt()),
                    ),
                  ),
                  Text('$_flexCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            ],
            const SizedBox(height: 32),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Only save if a name has been entered.
                  if (_nameController.text.isNotEmpty) {
                    final newHabit = Habit(
                      id: DateTime.now().toString(),
                      name: _nameController.text,
                      description: _descController.text,
                      colorValue: _selectedColor.value,
                      frequencyType: _freqType,
                      fixedDays: _freqType == FrequencyType.fixed ? _selectedDays : null,
                      flexibleCount: _freqType == FrequencyType.flexible ? _flexCount : null,
                    );
                    
                    // Closes the overlay and "returns" the new habit to the main screen.
                    Navigator.pop(context, newHabit);
                  }
                },
                child: const Text('Save Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
