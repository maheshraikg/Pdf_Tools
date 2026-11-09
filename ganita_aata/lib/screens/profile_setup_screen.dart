import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/shop_catalog.dart';
import '../models/profile.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';
import 'home_screen.dart';

/// Add or edit a child: first name, class (1–8) and avatar.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.firstRun = false, this.edit});

  final bool firstRun;
  final Profile? edit;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.edit?.name ?? '');
  late int _class = widget.edit?.schoolClass ?? 1;
  late String _avatar = widget.edit?.avatar ?? ShopCatalog.freeAvatars.first.id;
  bool _showError = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final app = context.read<AppState>();
    if (widget.edit != null) {
      app.updateProfile(widget.edit!, name: name, schoolClass: _class, avatar: _avatar);
      Navigator.pop(context);
      return;
    }
    app.createProfile(name: name, schoolClass: _class, avatar: _avatar);
    if (widget.firstRun) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final avatars = [
      for (final a in ShopCatalog.ofKind(ShopKind.avatar))
        if (a.isFree || (widget.edit?.owned.contains(a.id) ?? false)) a,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.edit != null ? l.editProfile : l.profileSetupTitle),
        automaticallyImplyLeading: !widget.firstRun,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l.childName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('name_field'),
              controller: _name,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 26),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                errorText: _showError ? l.nameRequired : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
            ),
            const SizedBox(height: 12),
            Text(l.schoolClass, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var c = 1; c <= 8; c++)
                  ChoiceChip(
                    key: ValueKey('class_$c'),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text('$c', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    ),
                    selected: _class == c,
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    onSelected: (_) => setState(() => _class = c),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.classN(_class), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(l.chooseAvatar, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final a in avatars)
                  GestureDetector(
                    key: ValueKey('avatar_${a.id}'),
                    onTap: () => setState(() => _avatar = a.id),
                    child: AvatarCircle(avatarId: a.id, size: 72, selected: _avatar == a.id),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(key: const ValueKey('save_profile'), onPressed: _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}
