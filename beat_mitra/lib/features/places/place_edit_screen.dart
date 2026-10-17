import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/fuzzy.dart';
import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import '../../core/services/photo_store.dart';
import '../../data/models.dart';
import '../../data/repos/place_repo.dart';
import '../beat/beat_detail_screen.dart';
import '../common/widgets.dart';
import 'gps_capture.dart';
import 'place_detail_screen.dart';

/// Add or edit a place. With [addHere] it is the fast "standing at the
/// door" flow: GPS starts at once, the camera opens, then a short form.
class PlaceEditScreen extends StatefulWidget {
  const PlaceEditScreen({
    super.key,
    required this.beatId,
    this.placeId,
    this.addHere = false,
    this.initialAddress,
    this.onSaved,
  });
  final int beatId;
  final int? placeId;
  final bool addHere;

  /// Prefill from an unmatched article (door no / street / names).
  final ({String door, String street, List<String> names, String pin, String area})? initialAddress;
  final ValueChanged<int>? onSaved;

  @override
  State<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends State<PlaceEditScreen> {
  final _door = TextEditingController();
  final _building = TextEditingController();
  final _flat = TextEditingController();
  final _landmark = TextEditingController();
  final _area = TextEditingController();
  final _pin = TextEditingController();
  final _notes = TextEditingController();
  final _pref = TextEditingController();
  final _newName = TextEditingController();

  Place? _place;
  Street? _street;
  PlaceType _type = PlaceType.house;
  GpsFix? _fix;
  bool _gpsChanged = false;
  List<Addressee> _names = [];
  List<PlacePhoto> _photos = [];
  final List<String> _newPhotos = [];
  final List<PlacePhoto> _removedPhotos = [];
  List<NearbyPlace> _dupes = [];
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;

  late final PhotoStore _store;

  bool get _isNew => widget.placeId == null;

  @override
  void initState() {
    super.initState();
    _store = context.services.photos;
    _load();
  }

  Future<void> _load() async {
    final s = context.services;
    if (!_isNew) {
      final d = await s.places.details(widget.placeId!);
      if (d != null) {
        final p = d.place;
        _place = p;
        _street = d.street;
        _type = p.type;
        _door.text = p.doorNo;
        _building.text = p.building;
        _flat.text = p.floorFlat;
        _landmark.text = p.landmark;
        _area.text = p.area;
        _pin.text = p.pin;
        _notes.text = p.notes;
        _pref.text = p.deliveryPref;
        _names = List.of(d.addressees);
        _photos = List.of(d.photos);
        if (p.point != null) _fix = GpsFix(p.point!, p.gpsAccuracyM ?? 0, DateTime.now());
      }
    } else if (widget.initialAddress != null) {
      final a = widget.initialAddress!;
      _door.text = a.door;
      _pin.text = a.pin;
      _area.text = a.area;
      _names = [for (final n in a.names) Addressee(placeId: 0, name: n)];
      if (a.street.isNotEmpty) {
        final streets = await s.beats.streets(widget.beatId);
        _street = _bestStreet(streets, a.street);
        if (_street == null) _landmark.text = a.street;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (widget.addHere) WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  Street? _bestStreet(List<Street> streets, String q) {
    final idx = SearchIndex([
      for (final s in streets) SearchDoc(id: s.id!, fields: {'street': s.name}),
    ]);
    final hits = idx.search(q, limit: 1, minScore: 0.7);
    return hits.isEmpty ? null : streets.firstWhere((s) => s.id == hits.first.id);
  }

  @override
  void dispose() {
    for (final c in [_door, _building, _flat, _landmark, _area, _pin, _notes, _pref, _newName]) {
      c.dispose();
    }
    // Photos taken but never saved: remove them.
    if (!_saved) {
      for (final f in _newPhotos) {
        _store.delete(f);
      }
    }
    super.dispose();
  }

  int get _photoCount => _photos.length + _newPhotos.length;

  Future<void> _takePhoto() async {
    final l = context.l;
    if (_photoCount >= 3) {
      context.toast(l.maxPhotos);
      return;
    }
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (x == null || !mounted) return;
      final name = await context.services.photos.saveFromCamera(x.path);
      if (!mounted) return;
      setState(() => _newPhotos.add(name));
    } catch (e) {
      if (mounted) context.toast(l.cameraError);
    }
  }

  Future<void> _onGps(GpsFix f) async {
    setState(() {
      _fix = f;
      _gpsChanged = true;
    });
    // Duplicate check: saved places within 30 m.
    final near = await context.services.places.nearby(f.point, beatId: widget.beatId, limit: 5, maxMeters: 30);
    if (!mounted) return;
    setState(() => _dupes = near.where((n) => n.details.place.id != widget.placeId).toList());
  }

  Future<void> _pickStreet() async {
    final picked = await showModalBottomSheet<Street>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StreetPicker(beatId: widget.beatId),
    );
    if (picked != null) setState(() => _street = picked);
  }

  void _addName() {
    final n = _newName.text.trim();
    if (n.isEmpty) return;
    setState(() {
      for (final part in n.split(RegExp(r'\s*[,;]\s*'))) {
        if (part.isNotEmpty) _names.add(Addressee(placeId: widget.placeId ?? 0, name: part));
      }
      _newName.clear();
    });
  }

  Future<void> _editName(int i) async {
    final l = context.l;
    final a = _names[i];
    final name = TextEditingController(text: a.name);
    final aliases = TextEditingController(text: a.aliases);
    final phone = TextEditingController(text: a.phone);
    final note = TextEditingController(text: a.note);
    final r = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.addressee),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceTextField(controller: name, label: l.name),
              const SizedBox(height: 10),
              TextField(
                controller: aliases,
                decoration: InputDecoration(labelText: l.aliases, helperText: l.aliasesHelp),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l.phoneOptional),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration: InputDecoration(labelText: l.noteFlat),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'remove'), child: Text(l.remove)),
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, 'ok'), child: Text(l.ok)),
        ],
      ),
    );
    if (r == 'remove') {
      setState(() => _names.removeAt(i));
    } else if (r == 'ok' && name.text.trim().isNotEmpty) {
      setState(
        () => _names[i] = a.copyWith(
          name: name.text.trim(),
          aliases: aliases.text.trim(),
          phone: phone.text.trim(),
          note: note.text.trim(),
        ),
      );
    }
  }

  Future<void> _save() async {
    final l = context.l;
    _addName();
    if (_door.text.trim().isEmpty && _building.text.trim().isEmpty && _names.isEmpty && _landmark.text.trim().isEmpty) {
      context.toast(l.placeNeedsSomething);
      return;
    }
    setState(() => _saving = true);
    final s = context.services;
    final app = context.app;
    final base = _place ?? Place(beatId: widget.beatId);
    final p = Place(
      id: base.id,
      beatId: base.beatId,
      streetId: _street?.id,
      doorNo: _door.text.trim(),
      building: _building.text.trim(),
      floorFlat: _flat.text.trim(),
      area: _area.text.trim(),
      pin: _pin.text.trim(),
      landmark: _landmark.text.trim(),
      lat: _fix?.point.lat,
      lng: _fix?.point.lng,
      gpsAccuracyM: _fix?.accuracyM,
      type: _type,
      notes: _notes.text.trim(),
      deliveryPref: _pref.text.trim(),
      walkOrder: base.walkOrder,
      createdAt: base.createdAt,
    );
    final id = await s.places.savePlace(p);
    await s.places.setAddressees(id, [for (final a in _names) a.copyWith(placeId: id)]);
    for (final f in _newPhotos) {
      await s.places.addPhoto(PlacePhoto(placeId: id, filePath: f));
    }
    for (final ph in _removedPhotos) {
      await s.places.deletePhoto(ph.id!);
      await s.photos.delete(ph.filePath);
    }
    _saved = true;
    await app.placeChanged(id);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    context.toast(l.saved);
    widget.onSaved?.call(id);
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final threshold = context.services.settings.gpsThresholdM;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? (widget.addHere ? l.addHere : l.addPlace) : l.editPlace),
        actions: [
          IconButton(tooltip: l.save, icon: const Icon(Icons.check, size: 30), onPressed: _saving ? null : _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
        children: [
          GpsCaptureCard(
            thresholdM: threshold,
            autoAccept: _isNew,
            accepted: _gpsChanged || !_isNew ? _fix : null,
            onAccept: _onGps,
          ),
          if (_dupes.isNotEmpty) _dupeCard(),
          const SizedBox(height: 8),
          _photosRow(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _door,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.doorNo, hintText: '12/3'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: _pickStreet,
                  icon: const Icon(Icons.signpost_outlined),
                  label: Text(_street?.name ?? l.pickStreet, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.addressees, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < _names.length; i++)
                InputChip(
                  label: Text(_names[i].name + (_names[i].phone.isNotEmpty ? ' ☎' : '')),
                  onPressed: () => _editName(i),
                  onDeleted: () => setState(() => _names.removeAt(i)),
                  deleteButtonTooltipMessage: l.remove,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: VoiceTextField(
                  controller: _newName,
                  label: l.addName,
                  icon: Icons.person_add_alt,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addName(),
                ),
              ),
              IconButton.filledTonal(tooltip: l.add, onPressed: _addName, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 12),
          VoiceTextField(controller: _landmark, label: l.landmark, icon: Icons.flag_outlined),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in PlaceType.values)
                ChoiceChip(
                  avatar: Icon(placeTypeIcon(t)),
                  label: Text(placeTypeLabel(l, t)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _building,
                  decoration: InputDecoration(labelText: l.building),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _flat,
                  decoration: InputDecoration(labelText: l.floorFlat),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VoiceTextField(controller: _notes, label: l.notesHint, maxLines: 3, appendVoice: true, icon: Icons.notes),
          Wrap(
            spacing: 6,
            children: [
              for (final q in [l.quickDog, l.quickGate, l.quickUpstairs, l.quickMorning, l.quickEvening])
                ActionChip(label: Text(q), onPressed: () => _appendTo(_notes, q)),
            ],
          ),
          const SizedBox(height: 12),
          VoiceTextField(controller: _pref, label: l.deliveryPref, icon: Icons.handshake_outlined),
          Wrap(
            spacing: 6,
            children: [
              for (final q in [l.prefSecurity, l.prefNeighbour, l.prefLetterBox, l.prefShop])
                ActionChip(label: Text(q), onPressed: () => setState(() => _pref.text = q)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _area,
                  decoration: InputDecoration(labelText: l.area),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(labelText: l.pin, counterText: ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: Text(l.save)),
        ],
      ),
    );
  }

  void _appendTo(TextEditingController c, String text) {
    setState(() => c.text = c.text.trim().isEmpty ? text : '${c.text.trim()}, $text');
  }

  Widget _photosRow() {
    final l = context.l;
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final ph in _photos)
            _photoBox(
              ph.filePath,
              () => setState(() {
                _photos.remove(ph);
                _removedPhotos.add(ph);
              }),
            ),
          for (final f in _newPhotos)
            _photoBox(f, () {
              context.services.photos.delete(f);
              setState(() => _newPhotos.remove(f));
            }),
          if (_photoCount < 3)
            Padding(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: 96,
                child: OutlinedButton(
                  onPressed: _takePhoto,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera, size: 32),
                      Text(l.photoCount(_photoCount), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoBox(String file, VoidCallback onRemove) => Padding(
    padding: const EdgeInsets.all(4),
    child: Stack(
      children: [
        PhotoThumb(file, size: 88),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton.filled(
            tooltip: context.l.remove,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    ),
  );

  Widget _dupeCard() {
    final l = context.l;
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.possibleDuplicates, style: Theme.of(context).textTheme.titleMedium),
            for (final n in _dupes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PhotoThumb(n.details.photos.firstOrNull?.filePath, size: 48),
                title: Text(n.details.title),
                subtitle: Text(
                  '${formatDistance(n.distanceM)} · ${n.details.addressees.map((a) => a.name).join(', ')}',
                ),
                trailing: TextButton(
                  child: Text(l.openIt),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: n.details.place.id!)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet: search streets of the beat, or add a new one.
class StreetPicker extends StatefulWidget {
  const StreetPicker({super.key, required this.beatId});
  final int beatId;

  @override
  State<StreetPicker> createState() => _StreetPickerState();
}

class _StreetPickerState extends State<StreetPicker> {
  final _q = TextEditingController();
  List<Street> _all = [];

  @override
  void initState() {
    super.initState();
    context.services.beats.streets(widget.beatId).then((s) {
      if (mounted) setState(() => _all = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final q = _q.text.trim();
    List<Street> shown = _all;
    if (q.isNotEmpty) {
      final idx = SearchIndex([
        for (final s in _all) SearchDoc(id: s.id!, fields: {'street': '${s.name} ${s.area}'}),
      ]);
      final ids = idx.search(q, limit: 50, minScore: 0.3).map((h) => h.id).toList();
      shown = [for (final id in ids) _all.firstWhere((s) => s.id == id)];
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: VoiceTextField(
                controller: _q,
                label: l.searchStreet,
                icon: Icons.search,
                onChanged: (_) => setState(() {}),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_road, size: 30),
              title: Text(q.isEmpty ? l.newStreet : l.newStreetNamed(q)),
              onTap: () async {
                final id = await editStreet(context, widget.beatId, null, initialName: q);
                if (id == null || !context.mounted) return;
                final st = await context.services.beats.street(id);
                if (context.mounted) Navigator.pop(context, st);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final s in shown)
                    ListTile(
                      title: Text(s.name, style: const TextStyle(fontSize: 18)),
                      subtitle: s.area.isEmpty ? null : Text(s.area),
                      onTap: () => Navigator.pop(context, s),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
