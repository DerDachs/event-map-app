import 'package:flutter/material.dart';

class AvatarPicker extends StatefulWidget {
  final void Function(String) onAvatarSelected;

  AvatarPicker({required this.onAvatarSelected});

  @override
  _AvatarPickerState createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final List<String> avatars = [
    'assets/avatars/avatar_1.jpg',
    'assets/avatars/avatar_2.jpg',
    'assets/avatars/avatar_3.jpg',
    'assets/avatars/avatar_4.jpg',
    'assets/avatars/avatar_5.jpg',
    'assets/avatars/avatar_6.jpg',
    'assets/avatars/avatar_7.jpg',
    'assets/avatars/avatar_8.jpg',
    'assets/avatars/avatar_9.jpg',
    'assets/avatars/avatar_10.jpg',
    'assets/avatars/avatar_11.jpg',
    'assets/avatars/avatar_12.jpg',
    'assets/avatars/avatar_13.jpg',
    'assets/avatars/avatar_14.jpg',
    'assets/avatars/avatar_15.jpg',
    'assets/avatars/avatar_16.jpg',
    'assets/avatars/avatar_17.jpg',
    'assets/avatars/avatar_18.jpg',
    'assets/avatars/avatar_19.jpg',
    'assets/avatars/avatar_20.jpg',
    // Add paths to your avatar images
  ];

  String? selectedAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an Avatar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: avatars.length,
          itemBuilder: (context, index) {
            final avatar = avatars[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedAvatar = avatar;
                });
                widget.onAvatarSelected(avatar);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedAvatar == avatar
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(avatar),
              ),
            );
          },
        ),
      ],
    );
  }
}