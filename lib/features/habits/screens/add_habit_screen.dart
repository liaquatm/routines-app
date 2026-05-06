import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/habit.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habitToEdit;
  const AddHabitScreen({super.key, this.habitToEdit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  Color _selectedColor = Colors.blueAccent;
  FrequencyType _freqType = FrequencyType.fixed;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  int _flexCount = 3;

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      final h = widget.habitToEdit!;
      _nameController.text = h.name;
      _descController.text = h.description ?? '';
      _selectedColor = Color(h.colorValue);
      _freqType = h.frequencyType;
      _selectedDays = List.from(h.fixedDays ?? [1, 2, 3, 4, 5, 6, 7]);
      _flexCount = h.flexibleCount ?? 3;
    }
  }

  final List<Color> _colors = [
    Colors.blueAccent, Colors.greenAccent, Colors.redAccent, 
    Colors.orangeAccent, Colors.purpleAccent, Colors.tealAccent, 
    Colors.pinkAccent, Colors.indigoAccent
  ];

  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            Text(
              widget.habitToEdit == null ? 'New Habit' : 'Edit Habit',
              style: GoogleFonts.lexend(
                fontSize: 24, 
                fontWeight: FontWeight.w700, 
                color: Colors.white
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(_nameController, 'Habit Name', Icons.edit_rounded),
            const SizedBox(height: 16),
            _buildTextField(_descController, 'Description (Optional)', Icons.notes_rounded),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Color'),
            const SizedBox(height: 12),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedColor == _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = _colors[index]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      width: 40,
                      decoration: BoxDecoration(
                        color: _colors[index],
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(width: 3, color: Colors.white) 
                            : null,
                        boxShadow: isSelected ? [
                          BoxShadow(color: _colors[index].withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)
                        ] : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Frequency'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildFrequencyChip(FrequencyType.fixed, 'Fixed Days'),
                const SizedBox(width: 12),
                _buildFrequencyChip(FrequencyType.flexible, 'Flexible'),
              ],
            ),
            
            const SizedBox(height: 20),
            if (_freqType == FrequencyType.fixed) 
              _buildDayPicker()
            else 
              _buildFlexPicker(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveHabit,
                child: Text(
                  widget.habitToEdit == null ? 'Start Habit' : 'Update Habit',
                  style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: GoogleFonts.lexend(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        labelText: label,
        labelStyle: GoogleFonts.lexend(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _selectedColor.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: 16, 
        fontWeight: FontWeight.w600, 
        color: Colors.white70
      ),
    );
  }

  Widget _buildFrequencyChip(FrequencyType type, String label) {
    final isSelected = _freqType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _freqType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _selectedColor : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.lexend(
              color: isSelected ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              isSelected ? _selectedDays.remove(day) : _selectedDays.add(day);
            });
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected ? _selectedColor.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? _selectedColor : Colors.white12,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _weekDays[index],
              style: GoogleFonts.lexend(
                color: isSelected ? _selectedColor : Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFlexPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Times per week', style: GoogleFonts.lexend(color: Colors.white38)),
            Text('$_flexCount', style: GoogleFonts.lexend(color: _selectedColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Slider(
          value: _flexCount.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          activeColor: _selectedColor,
          inactiveColor: Colors.white12,
          onChanged: (val) => setState(() => _flexCount = val.toInt()),
        ),
      ],
    );
  }

  void _saveHabit() {
    if (_nameController.text.isNotEmpty) {
      final habit = Habit(
        id: widget.habitToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descController.text,
        colorValue: _selectedColor.value,
        frequencyType: _freqType,
        fixedDays: _freqType == FrequencyType.fixed ? _selectedDays : null,
        flexibleCount: _freqType == FrequencyType.flexible ? _flexCount : null,
        completedDays: widget.habitToEdit?.completedDays ?? [],
      );
      Navigator.pop(context, habit);
    }
  }
}
