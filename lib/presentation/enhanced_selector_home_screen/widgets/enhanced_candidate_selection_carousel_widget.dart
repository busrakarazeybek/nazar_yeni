import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/user_profile.dart';

class EnhancedCandidateSelectionCarousel extends StatelessWidget {
  final List<UserProfile> candidates;
  final UserProfile? selectedCandidate;
  final ValueChanged<UserProfile> onCandidateSelected;
  final ValueChanged<UserProfile> onRemoveCandidate;

  const EnhancedCandidateSelectionCarousel({
    super.key,
    required this.candidates,
    required this.selectedCandidate,
    required this.onCandidateSelected,
    required this.onRemoveCandidate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110, // veya uygun bir yükseklik
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: candidates.length,
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          final isSelected = selectedCandidate?.id == candidate.id;
          return GestureDetector(
            onTap: () => onCandidateSelected(candidate),
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Adayı kaldır'),
                  content: Text(
                    '${candidate.fullName} listesinden kaldırılsın mı?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Kaldır'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                onRemoveCandidate(candidate);
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? Theme.of(context).primaryColor.withAlpha(26)
                    : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: candidate.imageUrl != null
                          ? NetworkImage(candidate.imageUrl!)
                          : null,
                      radius: 24,
                      child: candidate.imageUrl == null
                          ? Icon(Icons.person)
                          : null,
                    ),
                    SizedBox(height: 8),
                    Text(
                      candidate.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
