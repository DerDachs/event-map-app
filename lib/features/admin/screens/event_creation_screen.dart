import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:market_mates/features/events/providers/event_provider.dart';
import '../../../data/models/eventImage.dart';
import '../../../data/models/event.dart';
import '../../../providers/category_provider.dart';
import '../../../services/image_upload_service.dart';
import '../../events/services/event_service.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  @override
  _EventCreationScreenState createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends ConsumerState<CreateEventScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _uploadedImageUrl = "https://firebasestorage.googleapis.com/v0/b/event-map-app-aab7b.firebasestorage.app/o/events%2F";
  String? _selectedCategory;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMandatoryFieldLabel('Event Name'),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter event name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              _buildMandatoryFieldLabel('Event Description'),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter event description',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMandatoryFieldLabel('Latitude'),
                        TextFormField(
                          controller: _latitudeController,
                          decoration: InputDecoration(
                            hintText: 'Enter latitude',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter latitude';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMandatoryFieldLabel('Longitude'),
                        TextFormField(
                          controller: _longitudeController,
                          decoration: InputDecoration(
                            hintText: 'Enter longitude',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter longitude';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              _buildMandatoryFieldLabel('Category'),
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories
                        .where((category) => category.type == 'event') // Filter categories by type
                        .map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value; // Update the selected category
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Select a category',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  );
                },
                loading: () => CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading categories'),
              ),
              SizedBox(height: 16),
              // Start Time Picker
              Text(
                'Start Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDateTime!(context, isStartTime: true),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _startTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(_startTime!)
                        : 'Select start time',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // End Time Picker
              Text(
                'End Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDateTime(context, isStartTime: false),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _endTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(_endTime!)
                        : 'Select end time',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              //_buildMandatoryFieldLabel('Image'),
              //if (_uploadedImageUrl != null)
              //  Column(
              //    children: [
              //      Image.network(
              //        _uploadedImageUrl!,
              //        height: 150,
              //        fit: BoxFit.cover,
              //      ),
              //      SizedBox(height: 8),
              //    ],
              //  ),
              //ElevatedButton.icon(
              //  onPressed: () async {
              //    final imageUrl = await ImageUploadService().pickAndUploadImage('events');
              //    if (imageUrl != null) {
              //      setState(() {
              //        _uploadedImageUrl = imageUrl;
              //      });
              //    } else {
              //      ScaffoldMessenger.of(context).showSnackBar(
              //        SnackBar(content: Text('Image upload failed')),
              //      );
              //    }
              //  },
              //  icon: Icon(Icons.upload),
              //  label: Text('Upload Image'),
              //),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (_uploadedImageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please upload an image')),
                      );
                      return;
                    }

                    final event = Event(
                      id: '',
                      // Generate ID on Firestore
                      name: _nameController.text,
                      description: _descriptionController.text,
                      latitude: double.parse(_latitudeController.text),
                      longitude: double.parse(_longitudeController.text),
                      images: [
                        EventImage(url: _uploadedImageUrl!, isStandard: true)
                      ],
                      startTime: _startTime!,
                      // Example
                      endTime: _endTime!,
                      // Example
                      teamIds: [],
                      stands: [],
                      category: _selectedCategory!,
                      openingHours: [
                        OpeningHour(
                            days: ['Mo', 'Tu', 'We', 'Th', 'Fr'],
                            open: '08:00',
                            close: '22:00'),
                        OpeningHour(
                            days: ['Sa', 'Su'], open: '10:00', close: '24:00'),
                      ],
                    );

                    // Save event to Firestore
                    _saveEvent(event);
                  }
                },
                child: Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent(Event event) async {
    final eventService = EventService();
    try {
      // Add Firestore saving logic here
      eventService.createEvent(event);
    } catch (e) {
      SnackBar(content: Text('Event not created $e'));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event created successfully')),
    );
    Navigator.pop(context);
  }

  Widget _buildMandatoryFieldLabel(String label) {
    return Text(
      '$label *',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
  }

  // Method to pick date and time
  Future<void> _pickDateTime(BuildContext context,
      {required bool isStartTime}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final pickedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStartTime) {
        _startTime = pickedDateTime;
      } else {
        _endTime = pickedDateTime;
      }
    });
  }
}
