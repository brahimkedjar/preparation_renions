// ignore_for_file: unused_local_variable, camel_case_types, library_private_types_in_public_api, use_super_parameters, avoid_print

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gestion_reunion/home/orgnize_renion/MeetingsScreen.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Orgnize_Renion extends StatefulWidget {
  final String title;

  const Orgnize_Renion({Key? key, required this.title}) : super(key: key);

  @override
  _NewPageState createState() => _NewPageState();
}

class _NewPageState extends State<Orgnize_Renion> {
  DateTime? _selectedDate;
  String? _selectedDocumentOrderJour;
  String? _selectedDocumentConvocation;
  String? _selectedParticipant;
  final List<String> _selectedParticipants = [];
  bool _sendEmail = false;
  List<User> _users = []; // List to store fetched users
  // Define controllers for time and location TextFields
  final TextEditingController _meetingTimeController = TextEditingController();
  final TextEditingController _meetingLocationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the widget initializes
  }

  Future<void> _selectOrderJourDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedDocumentOrderJour = result.files.single.path;
      });
    }
  }

  Future<void> _selectConvocationDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedDocumentConvocation = result.files.single.path;
      });
    }
  }

  Future<void> _fetchUsers() async {
    final response =
        await http.get(Uri.parse('http://regestrationrenion.atwebpages.com/api.php')); // Update with your API URL

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        setState(() {
          _users =
              jsonData.map((userJson) => User.fromJson(userJson)).toList();
        });
      } else {
        // Handle unexpected response format
      }
    } else {
      // Handle HTTP error
    }
  }

  Future<void> _saveMeetingData() async {
    // Check if all required fields are filled
    if (_selectedDate == null ||
        _selectedDocumentOrderJour == null ||
        _selectedDocumentConvocation == null ||
        _selectedParticipants.isEmpty) {
      // Show an error message or handle validation as needed
      return;
    }

    // Convert the selected date to the required format
    String formattedDate =
        '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}';

    // Extract selected values from DropdownButtonFormField for meeting title
    String selectedTitle = 'Conseil d’administration'; // Default value
    if (_selectedParticipant != null) {
      selectedTitle = _selectedParticipant!;
    }

    // Obtain values from TextFields for time and location
    String meetingTime =
        _meetingTimeController.text; // Get the value from the time TextField
    String meetingLocation = _meetingLocationController
        .text; // Get the value from the location TextField

    // Extract values from selected documents
    String documentOrderJour = _selectedDocumentOrderJour!;
    String documentConvocations = _selectedDocumentConvocation!;

    // Extract participant IDs
    List<String> participantIds = [];
    for (var participantName in _selectedParticipants) {
      // Find the User object with the corresponding name
      User user = _users.firstWhere(
        (user) => '${user.name} ${user.prename}' == participantName,
        orElse: () =>
            User(id: 0, name: 'Unknown', prename: 'Unknown'), // Placeholder User object
      );
      participantIds.add(user.id.toString());
    }
    String participantIdsString = participantIds.join(',');

    // Prepare the meeting data to be sent to the server
    final meetingData = {
      'title': selectedTitle,
      'date': formattedDate,
      'time': meetingTime,
      'location': meetingLocation,
      'document_order_jours': documentOrderJour,
      'document_convocations': documentConvocations,
      'email_notification': _sendEmail.toString(),
      'participant_id': participantIdsString, // Pass the comma-separated string of participant IDs
    };

    try {
      // Send a POST request to your PHP endpoint with the meeting data
      final response = await http.post(
        Uri.parse('http://regestrationrenion.atwebpages.com/meetings.php'), // Update with your API URL
        body: meetingData,
      );

      if (response.statusCode == 200) {
        // Meeting data saved successfully
        if (_sendEmail) {
          await _sendMeetingEmail(meetingData);
        }
      } else {
        // Error saving meeting data
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request
    }
  }

  Future<void> _sendMeetingEmail(Map<String, dynamic> meetingData) async {
    // Your email sending logic using mailer package
    // Setup SMTP server details
    final smtpServer = gmail('jemskedjar@gmail.com', 'doyl pyrm uxmf qhqp');

    // Create the email message
    final message = Message()
      ..from = const Address('jemskdjar@gmail.com', 'brahim kedjar')
      ..subject = 'Meeting Information: ${meetingData['title']}'
      ..html = '''
        <h3>Meeting Details:</h3>
        <p><b>Title:</b> ${meetingData['title']}</p>
        <p><b>Date:</b> ${meetingData['date']}</p>
        <p><b>Time:</b> ${meetingData['time']}</p>
        <p><b>Location:</b> ${meetingData['location']}</p>
        <!-- Add more details here as needed -->
      ''';

    // Add participants' email addresses as recipients if available
    if (meetingData['participant_id'] != null &&
        meetingData['participant_id']!.isNotEmpty) {
      for (var participantId in meetingData['participant_id']!.split(',')) {
        // Find the user with this ID
        User? user = _users.firstWhere(
          (user) => user.id.toString() == participantId,
          orElse: () => User(id: 0, name: 'Unknown', prename: 'Unknown'),
        );

        // Add participant's email address to the recipient list if available
        if (user.email.isNotEmpty) {
          message.recipients.add(user.email);
        }
      }
    }

    try {
      // Send the email
      final sendReport = await send(message, smtpServer);
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 20),
            const Text(
              'Nouvelle réunion :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'Conseil d’administration', child: Text('Conseil d’administration')),
                DropdownMenuItem(value: 'Assemblée générale ordinaire', child: Text('Assemblée générale ordinaire')),
                DropdownMenuItem(value: 'Assemblée générale extraordinaire', child: Text('Assemblée générale extraordinaire')),
                DropdownMenuItem(value: 'Assemblée générale mixte', child: Text('Assemblée générale mixte')),
              ],
              onChanged: (value) {
                // Handle dropdown value change
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a type',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a date:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: _selectedDate != null
                    ? Text(
                        '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      )
                    : const Text(
                        'Select Date',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter time and location:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Add your time picker and location input here
            TextField(
  controller: _meetingTimeController,
  decoration: const InputDecoration(
    labelText: 'Time',
    border: OutlineInputBorder(),
  ),
),
const SizedBox(height: 10),
TextField(
  controller: _meetingLocationController,
  decoration: const InputDecoration(
    labelText: 'Location',
    border: OutlineInputBorder(),
  ),
),

            const SizedBox(height: 20),
            const Text(
              'Saisir l\'ordre du jour:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
           ElevatedButton(
  onPressed: _selectOrderJourDocument,
  child: const Text('Select Order Jour Document'),
),
const Text(
              'Saisir la convocation:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
const SizedBox(height: 10),
_selectedDocumentOrderJour != null ? Text('Selected Order Jour Document: $_selectedDocumentOrderJour') : Container(),

ElevatedButton(
  onPressed: _selectConvocationDocument,
  child: const Text('Select Convocation Document'),
),
const SizedBox(height: 10),
_selectedDocumentConvocation != null ? Text('Selected Convocation Document: $_selectedDocumentConvocation') : Container(),
            const SizedBox(height: 20),
            const Text(
              'Invite des participants:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<User>(
                    value: null,
                    onChanged: (value) {
                      setState(() {
                        _selectedParticipant = '${value!.name} ${value.prename}';
                      });
                    },
                    items: _users.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Text('${user.name} ${user.prename}'),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Participant',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_selectedParticipant != null) {
                      setState(() {
                        _selectedParticipants.add(_selectedParticipant!);
                        _selectedParticipant = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              children: _selectedParticipants.map((participant) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(participant),
                    onDeleted: () {
                      setState(() {
                        _selectedParticipants.remove(participant);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
  children: [
  Checkbox(
  value: _sendEmail,
  onChanged: (value) {
    setState(() {
      _sendEmail = value ?? false;
    });
  },
),
    const Text('Send Email'),
  ],
),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveMeetingData, // Call _saveMeetingData when button is pressed
                  child: const Text('Valider'),
                ),
                ElevatedButton(
              onPressed: () {
                // Navigate to a new page to show the meetings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MeetingsScreen()),
                );
              },
              child: const Text('Voir les réunions'),
            ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  

}

class User {
  final int id;
  final String name;
  final String prename;
  String email; // Add email field

  User({
    required this.id,
    required this.name,
    required this.prename,
    this.email="", // Update constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      name: json['name'] as String,
      prename: json['prename'] as String,
      email: json['email'] as String, // Initialize email field
    );
  }
}