import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/map_pin.dart' as model;
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/status_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<model.MapPin> _pins = [];
  bool _loading = true;
  String _typeFilter = '';
  model.MapPin? _selected;
  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.get(
        ApiConstants.mapPins,
        query: {if (_typeFilter.isNotEmpty) 'type': _typeFilter},
      );
      final list = (res['data'] as List)
          .map((e) => model.MapPin.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _pins = list; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _pinColor(model.MapPin p) {
    if (p.isFlag) {
      switch (p.urgencyLevel) {
        case 'critical': return AppColors.danger;
        case 'high':     return AppColors.secondary;
        case 'medium':   return AppColors.warning;
        default:         return AppColors.textMuted;
      }
    }
    if (p.isOffice) return AppColors.primary;
    return AppColors.accent;
  }

  IconData _pinIcon(model.MapPin p) {
    if (p.isFlag)    return Icons.flag;
    if (p.isOffice)  return Icons.apartment;
    return Icons.work_outline;
  }

  Future<void> _respond(model.MapPin pin) async {
    try {
      await ApiService.instance.post('${ApiConstants.mapPins}/${pin.id}/respond');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Marked as responding'),
        backgroundColor: AppColors.success,
      ));
      setState(() => _selected = null);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _markResolved(model.MapPin pin) async {
    try {
      await ApiService.instance.put(
        '${ApiConstants.mapPins}/${pin.id}',
        body: {'status': 'resolved'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Marked as resolved 🎉'),
        backgroundColor: AppColors.success,
      ));
      setState(() => _selected = null);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _verifyPin(model.MapPin pin) async {
    try {
      await ApiService.instance.patch('${ApiConstants.mapPins}/${pin.id}/verify');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pin verified ✅'),
        backgroundColor: AppColors.success,
      ));
      setState(() => _selected = null);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _rejectPin(model.MapPin pin) async {
    try {
      await ApiService.instance.patch('${ApiConstants.mapPins}/${pin.id}/reject');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pin rejected'),
        backgroundColor: AppColors.warning,
      ));
      setState(() => _selected = null);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canCreatePin = user != null && (user.isNgoAdmin || user.isNgoStaff);
    final canRaiseFlag = user != null && user.isPublicUser;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (canRaiseFlag)
            FloatingActionButton.extended(
              heroTag: 'raise_flag',
              onPressed: () => context.go('/report-issue'),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Raise Flag'),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          if (canCreatePin) ...[
            FloatingActionButton.extended(
              heroTag: 'create_pin',
              onPressed: () => context.go('/map/new'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Pin'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap "Add Pin" → choose "Office Location" to pin your NGO\'s location'),
                  backgroundColor: AppColors.primary,
                ),
              ),
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.my_location_outlined, size: 18),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── Header & filters ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GIS Activity Map',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('NGO offices, projects and flags across Pakistan',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  // Legend
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _legend(AppColors.primary, 'Office'),
                    const SizedBox(height: 3),
                    _legend(AppColors.accent, 'Project'),
                    const SizedBox(height: 3),
                    _legend(AppColors.danger, 'Flag'),
                  ]),
                ]),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _typeChip('All', '', Icons.apps),
                    const SizedBox(width: 8),
                    _typeChip('Offices', 'office', Icons.apartment),
                    const SizedBox(width: 8),
                    _typeChip('Projects', 'project', Icons.work_outline),
                    const SizedBox(width: 8),
                    _typeChip('Flags', 'flag', Icons.flag, color: AppColors.danger),
                  ]),
                ),
              ],
            ),
          ),
          // ── Map ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : Stack(children: [
                    FlutterMap(
                      mapController: _mapCtrl,
                      options: const MapOptions(
                        initialCenter: LatLng(30.3753, 69.3451),
                        initialZoom: 5.5,
                        minZoom: 3,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.humraah.app',
                        ),
                        MarkerLayer(
                          markers: _pins.map((p) => Marker(
                            point: LatLng(p.lat, p.lng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => setState(() => _selected = p),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _pinColor(p),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _pinColor(p).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(_pinIcon(p), color: Colors.white, size: 18),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                    // Pin count badge
                    Positioned(
                      bottom: _selected != null ? 230 : 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                          )],
                        ),
                        child: Row(children: [
                          const Icon(Icons.layers_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('${_pins.length} pins',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ]),
                      ),
                    ),
                    // No pins message
                    if (_pins.isEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_off_outlined, color: AppColors.textMuted, size: 36),
                              SizedBox(height: 8),
                              Text('No pins found for this filter',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    // Selected pin detail
                    if (_selected != null)
                      Positioned(
                        left: 12, right: 12, bottom: 12,
                        child: _PinDetailSheet(
                          pin: _selected!,
                          onClose: () => setState(() => _selected = null),
                          onRespond: () => _respond(_selected!),
                          onMarkResolved: () => _markResolved(_selected!),
                          onVerify: () => _verifyPin(_selected!),
                          onReject: () => _rejectPin(_selected!),
                        ),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ],
  );

  Widget _typeChip(String label, String value, IconData icon, {Color? color}) {
    final selected = _typeFilter == value;
    final accent = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () { setState(() => _typeFilter = value); _load(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600, fontSize: 13,
          )),
        ]),
      ),
    );
  }
}

class _PinDetailSheet extends StatelessWidget {
  final model.MapPin pin;
  final VoidCallback onClose;
  final VoidCallback onRespond;
  final VoidCallback onMarkResolved;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  const _PinDetailSheet({
    required this.pin,
    required this.onClose,
    required this.onRespond,
    required this.onMarkResolved,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final canRespond = user != null && (user.isNgoAdmin || user.isNgoStaff || user.isSuperAdmin);
    final myNgoId = user?.ngo?.id;
    final isResponder = myNgoId != null && pin.respondedBy.contains(myNgoId);
    final canResolve = user != null && (user.isSuperAdmin || isResponder);
    final canVerify = user != null && (user.isNgoAdmin || user.isSuperAdmin);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            _tag(pin.type.toUpperCase(),
                pin.isFlag ? AppColors.danger : pin.isOffice ? AppColors.primary : AppColors.accent),
            const SizedBox(width: 8),
            if (pin.isFlag) StatusBadge.urgency(pin.urgencyLevel),
            if (pin.isPending) ...[
              const SizedBox(width: 8),
              _tag('PENDING REVIEW', AppColors.warning),
            ] else if (pin.isInProgress) ...[
              const SizedBox(width: 8),
              _tag('IN PROGRESS ✅', AppColors.success),
            ] else if (pin.isResolved) ...[
              const SizedBox(width: 8),
              _tag('RESOLVED 🎉', AppColors.primary),
            ],
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 10),
          Text(pin.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (pin.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(pin.description, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Flexible(child: Text(
              pin.city.isNotEmpty ? pin.city : '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            )),
            if (pin.ngoName != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.apartment_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(child: Text(pin.ngoName!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              )),
            ],
          ]),
          if (pin.isPending && canVerify) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                  label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                ),
              ),
            ]),
          ],
          if (pin.isFlag && canRespond && !pin.isInProgress && !pin.isResolved && !isResponder && !pin.isPending) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRespond,
                  icon: const Icon(Icons.volunteer_activism_outlined, size: 16),
                  label: const Text('Respond to Flag'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (pin.ngoId != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => context.go('/ngos/${pin.ngoId}'),
                  icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
                  tooltip: 'View NGO',
                ),
              ],
            ]),
          ],
          if (pin.isFlag && canRespond && pin.isInProgress && canResolve) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onMarkResolved,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Mark as Resolved'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(
      color: color, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.6,
    )),
  );
}
