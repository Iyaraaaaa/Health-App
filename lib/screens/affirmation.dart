import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:health_project/l10n/generated/app_localizations.dart';

class AffirmationPage extends StatefulWidget {
  const AffirmationPage({super.key});

  @override
  State<AffirmationPage> createState() => _AffirmationPageState();
}

class _AffirmationPageState extends State<AffirmationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController serialNumberController = TextEditingController();
  final TextEditingController letterDateController = TextEditingController();
  final TextEditingController officerNameController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final TextEditingController dateConfirmedController = TextEditingController();
  final TextEditingController fileNumberController = TextEditingController();
  final TextEditingController defNotifyController = TextEditingController();
  final TextEditingController defCorrectedController = TextEditingController();
  final TextEditingController sentDateController = TextEditingController();
  final TextEditingController approvalGrantedController = TextEditingController();
  final TextEditingController approvalNotifiedController = TextEditingController();

  String? selectedDesignation;
  String? selectedStation;
  String? selectedResponsibleOfficer;

  final List<String> designations = [
    'Health Technical Officer (Junior)',
    'Health Technical Officer (General)',
    'Nursing Assistant / Support Staff',
    'Store Keeper',
    'Plumber',
    'Medical Supply Assistant',
    'Driver',
    'Mason',
    'Laboratory Attendant',
    'Public Health Inspector (PHI)',
    'Medical Laboratory Technologist',
    'Pharmacist',
    'Medical Superintendent',
    'Nurse',
    'Minor Service Supervisor',
    'Administrative Clerk',
    'Development Officer',
    'Electrician',
    'Elevator Operator',
    'Management Service Officer',
    'Ward Clerk',
  ];

  final List<String> stations = [
    'Base Hospital - Kiribathgoda',
    'Kethumathi Hospital - Panadura',
    'Base Hospital - Panadura',
    'District General Hospital - Horana',
    'Base Hospital - Wattupitiwala',
    'Public Health Inspector\'s Office - Moratuwa',
    'Divisional Hospital - Galpotha',
    'Divisional Hospital - Baduraliya',
    'District Hospital - Ingiriya',
    'Base Hospital - Minuwangoda',
    'Base Hospital - Mirigama',
    'District General Hospital - Gampaha',
    'Medical Supplies Division - Bellapitiya',
    'STD Control Clinic - Meegamuwa',
    'Regional Medical Supply Unit - Ragama',
    'Public Dispensary - Anuragoda',
    'Regional Health Services Division - Kalutara',
    'Public Health Inspector\'s Office - Wadduwa',
    'Public Health Inspector\'s Office - Hanwella',
    'Public Health Inspector\'s Office - Horana',
    'Public Health Inspector\'s Office - Panadura',
    'District Hospital - Maligawatta',
    'District Hospital - Iththapana',
    'District General Hospital - Avissawella',
    'Divisional Hospital - Bulathsinhala',
    'Base Hospital - Pimbura',
    'Divisional Hospital - Pamunugama',
    'Public Dispensary - Meegoda',
    'Divisional Hospital - Kosgama',
    'Divisional Hospital - Nawagamuwa',
    'Berawa Disease Control Unit - Kalutara',
    'Dental Clinic - Nalanda Vidyalaya',
    'Divisional Hospital - Piliyandala',
    'Divisional Hospital - Gonaduwa',
    'Divisional Hospital - Radawana',
    'Divisional Hospital - Malwathuhiripitiya',
    'Divisional Hospital - Padukka',
    'STD Control Unit - Kalubowila',
  ];

  final List<String> responsibleOfficers = ['A05', 'A17', 'A14', 'A11', 'A02'];

  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = dateFormatter.format(picked);
      });
    }
  }

  @override
  void dispose() {
    serialNumberController.dispose();
    letterDateController.dispose();
    officerNameController.dispose();
    nicController.dispose();
    dateConfirmedController.dispose();
    fileNumberController.dispose();
    defNotifyController.dispose();
    defCorrectedController.dispose();
    sentDateController.dispose();
    approvalGrantedController.dispose();
    approvalNotifiedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // AppBar removed
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16), // Added space at the top since app bar is removed
                    buildSectionCard(
                      title: "📝 ${loc?.staffDetails ?? 'Staff Details'}",
                      children: [
                        buildTextField(loc?.serialNumber ?? 'Serial Number', serialNumberController, Icons.numbers),
                        buildTextField(loc?.officerName ?? 'Officer Name', officerNameController, Icons.person),
                        buildTextField(loc?.nicNumber ?? 'NIC Number', nicController, Icons.badge),
                        buildDropdown(loc?.designation ?? 'Designation', designations, selectedDesignation,
                            (val) => selectedDesignation = val, Icons.work),
                        buildDropdown(loc?.serviceStation ?? 'Service Station', stations, selectedStation,
                            (val) => selectedStation = val, Icons.location_city),
                      ],
                    ),
                    buildSectionCard(
                      title: "📅 ${loc?.datesSection ?? 'Dates Section'}",
                      children: [
                        buildDateField(loc?.letterDate ?? 'Letter Date', letterDateController),
                        buildDateField(loc?.dateConfirmed ?? 'Date Confirmed', dateConfirmedController),
                        buildDropdown(loc?.responsibleOfficer ?? 'Responsible Officer', responsibleOfficers,
                            selectedResponsibleOfficer, (val) => selectedResponsibleOfficer = val, Icons.account_circle),
                        buildTextField(loc?.fileNumber ?? 'File Number', fileNumberController, Icons.folder),
                      ],
                    ),
                    buildSectionCard(
                      title: "⚠️ ${loc?.deficiencyTracking ?? 'Deficiency Tracking'}",
                      children: [
                        buildDateField(loc?.defNotifiedDate ?? 'Deficiency Notified Date', defNotifyController),
                        buildDateField(loc?.defCorrectedDate ?? 'Deficiency Corrected Date', defCorrectedController),
                      ],
                    ),
                    buildSectionCard(
                      title: "✅ ${loc?.approvalSection ?? 'Approval Section'}",
                      children: [
                        buildDateField(loc?.sentDate ?? 'Sent Date', sentDateController),
                        buildDateField(loc?.approvalGrantedDate ?? 'Approval Granted Date', approvalGrantedController),
                        buildDateField(loc?.approvalNotifiedDate ?? 'Approval Notified Date', approvalNotifiedController),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(loc?.submitForm ?? 'Submit Form'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.teal, // Button background color
                        foregroundColor: Colors.white, // Text color white
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Larger text size
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showSuccessDialog(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.teal, // Section title color
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) => value == null || value.isEmpty
            ? AppLocalizations.of(context)?.requiredField ?? 'This field is required.'
            : null,
      ),
    );
  }

  Widget buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(controller),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) => value == null || value.isEmpty
            ? AppLocalizations.of(context)?.selectDate ?? 'Please select a date.'
            : null,
      ),
    );
  }

  Widget buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => onChanged(val)),
        validator: (value) =>
            value == null ? AppLocalizations.of(context)?.pleaseSelect ?? 'Please select an option.' : null,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🎉 ${AppLocalizations.of(context)?.success ?? 'Success'}"),
        content: Text(AppLocalizations.of(context)?.formSubmittedSuccess ?? 'Form Submitted Successfully!'),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
