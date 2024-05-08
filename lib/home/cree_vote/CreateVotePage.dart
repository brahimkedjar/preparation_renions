import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateVotePage extends StatefulWidget {
  const CreateVotePage({Key? key}) : super(key: key);

  @override
  _CreateVotePageState createState() => _CreateVotePageState();
}

class _CreateVotePageState extends State<CreateVotePage> {
  List<String> _selectedParticipants = [];
  DateTime _closingDate = DateTime.now();
  List<Map<String, dynamic>>? _participantsList;
  List<Map<String, dynamic>> _optionsWithKeys = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newOptionController = TextEditingController();

  Future<DateTime?> _selectDateTime(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (selectedTime != null) {
        return DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
            selectedTime.hour, selectedTime.minute);
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchParticipants() async {
    final response = await http
        .get(Uri.parse('http://regestrationrenion.atwebpages.com/api.php'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      // Handle error
      return [];
    }
  }

  Future<void> _saveVote() async {
    Map<String, dynamic> voteData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'options':
          _optionsWithKeys.map((option) => {'value': option['value']}).toList(),
      'participants': _selectedParticipants,
      'closing_date': _closingDate.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://regestrationrenion.atwebpages.com/vots.php'),
        body: jsonEncode(voteData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Vote saved successfully
      } else {
        // Failed to save vote
      }
    } catch (e) {
      // Exception occurred
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a Vote'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter vote title',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Description',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter vote description',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select Options',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _optionsWithKeys.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: TextFormField(
                            initialValue: _optionsWithKeys[index]['value'],
                            onChanged: (newValue) {
                              setState(() {
                                _optionsWithKeys[index]['value'] = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Option ${index + 1}',
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _optionsWithKeys.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newOptionController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'New Option',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              _optionsWithKeys.add({
                                'key':
                                    'option_${DateTime.now().millisecondsSinceEpoch}_${_optionsWithKeys.length}',
                                'value': _newOptionController.text,
                                'voteCount': 0,
                              });
                              _newOptionController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchParticipants(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Participants',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select participants'),
          value: _selectedParticipants.isNotEmpty
              ? _selectedParticipants.first
              : null,
          onChanged: (String? newValue) {
            setState(() {
              if (newValue != null) {
                if (_selectedParticipants.contains(newValue)) {
                  _selectedParticipants.remove(newValue);
                } else {
                  _selectedParticipants.add(newValue);
                }
              }
            });
          },
          items: snapshot.data!.map<DropdownMenuItem<String>>((participant) {
            return DropdownMenuItem<String>(
              value: '${participant['id']}',
              child: Text('${participant['name']} ${participant['prename']}'),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text(
          'Selected Participants:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _selectedParticipants.map<Widget>((selectedId) {
            final selectedParticipant = snapshot.data!.firstWhere(
              (participant) => participant['id'] == selectedId,
              orElse: () => {'name': 'Unknown', 'prename': 'Participant'},
            );
            return Chip(
              label: Text(
                '${selectedParticipant['name']} ${selectedParticipant['prename']}',
              ),
              onDeleted: () {
                setState(() {
                  _selectedParticipants.remove(selectedId);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
                        } else {
                          return Text('No participants found');
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _saveVote(); // Call function to save vote
                      },
                      child: Text('Save Vote'),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vote Closing Date:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${DateFormat('dd/MM/yyyy hh:mm a').format(_closingDate)}',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          Spacer(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final selectedDateTime =
                                  await _selectDateTime(context);
                              if (selectedDateTime != null) {
                                setState(() {
                                  _closingDate = selectedDateTime;
                                });
                              }
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Change'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(),
          Expanded(
            child: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Announcement of Voting Results',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.blue,
        ),
      ),
      SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options and Votes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchOptionVotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData &&
                    snapshot.data!.isNotEmpty) {
                  // Calculate total votes for all options
                  int totalVotes = snapshot.data!.fold(
                    0,
                    (total, option) => total + (int.parse(option['vote_count'].toString()) ?? 0),
                  );

                  // Render option votes
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Votes for All Options: $totalVotes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: snapshot.data!.map<Widget>((option) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option['option_value'] ?? 'Unknown Option',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      'Votes: ${option['vote_count'] ?? 0}',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _viewVotingParticipants(option['option_value']);
                                      },
                                      child: Text('View Participants'),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                // Add any other UI elements you need here
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                } else {
                  return Text(
                    'No option votes found',
                    style: TextStyle(fontSize: 18),
                  );
                }
              },
            ),
          ],
        ),
      ),
      SizedBox(height: 24),
    ],
  ),
),

          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOptionVotes() async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
int userId = prefs.getInt('participant_id') ?? 0; // Retrieve user ID from shared preferences
print("ssssssssssssssssssss: $userId");
    final response = await http.get(
        Uri.parse('http://regestrationrenion.atwebpages.com/option_votes.php'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      // Handle error
      return [];
    }
  }

  void _viewVotingParticipants(String optionValue) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://regestrationrenion.atwebpages.com/show_participants.php'),
        body: {'option_value': optionValue},
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> participants =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Display names and prenames of participants who voted for this option
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Participants who voted for Option $optionValue'),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                    maxHeight: 400), // Adjust the maximum height as needed
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total Participants: ${participants.length}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // Ensure the ListView does not scroll
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          return ListTile(
                            title: Text(
                                '${participant['participant_name']} ${participant['participant_prename']}'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        // Handle error
        print('Failed to fetch participants');
      }
    } catch (e) {
      // Exception occurred
      print('Exception: $e');
    }
  }
}
