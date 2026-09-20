import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';

class LocationResult {
  final String displayName;
  final double lat;
  final double lng;
  final String city;
  final String address;

  LocationResult({
    required this.displayName,
    required this.lat,
    required this.lng,
    required this.city,
    required this.address,
  });
}

/// Drop this widget anywhere you need location search.
/// onSelect returns a LocationResult with lat/lng/city filled.
class LocationSearchField extends StatefulWidget {
  final void Function(LocationResult result) onSelect;
  final String? initialValue;

  const LocationSearchField({
    super.key,
    required this.onSelect,
    this.initialValue,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<LocationResult> _results = [];
  bool _searching = false;
  bool _showDropdown = false;
  bool _hadError = false;
  Timer? _debounce;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) _ctrl.text = widget.initialValue!;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 3) {
      setState(() { _results = []; _showDropdown = false; _hadError = false; });
      return;
    }
    // Debounce so we don't hammer the free Nominatim API on every keystroke —
    // that was causing intermittent "no results" due to rate limiting.
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(v.trim()));
  }

  Future<List<LocationResult>> _query(String q, {bool restrictToPakistan = true}) async {
    final params = restrictToPakistan
        ? '&countrycodes=pk'
        : ''; // fall back to worldwide search when a Pakistan-biased search finds nothing
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(q)}'
      '&format=json&addressdetails=1&limit=8$params',
    );
    final res = await http.get(url, headers: {'User-Agent': 'HumRaahApp/1.0'})
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((item) {
      final addr = item['address'] as Map<String, dynamic>? ?? {};
      final city = addr['city']?.toString() ??
          addr['town']?.toString() ??
          addr['district']?.toString() ??
          addr['county']?.toString() ?? '';
      return LocationResult(
        displayName: item['display_name']?.toString() ?? '',
        lat: double.tryParse(item['lat']?.toString() ?? '0') ?? 0,
        lng: double.tryParse(item['lon']?.toString() ?? '0') ?? 0,
        city: city,
        address: item['display_name']?.toString().split(',').take(3).join(',') ?? '',
      );
    }).where((r) => r.lat != 0 || r.lng != 0).toList();
  }

  Future<void> _search(String q) async {
    final myRequestId = ++_requestId;
    setState(() { _searching = true; _hadError = false; });
    try {
      var results = await _query(q, restrictToPakistan: true);
      if (results.isEmpty) {
        // Nothing found within Pakistan — try again without the country
        // restriction so valid queries (other countries, or names Nominatim
        // doesn't tag as Pakistani) still return something useful.
        results = await _query(q, restrictToPakistan: false);
      }
      // If a newer request started while we were waiting, drop this stale result
      // (prevents "kuch dikha kuch nahi" caused by out-of-order responses).
      if (myRequestId != _requestId || !mounted) return;
      setState(() {
        _results = results;
        _showDropdown = results.isNotEmpty;
        _searching = false;
      });
    } catch (_) {
      if (myRequestId != _requestId || !mounted) return;
      setState(() {
        _results = [];
        _showDropdown = false;
        _searching = false;
        _hadError = true;
      });
    }
  }

  void _select(LocationResult r) {
    _ctrl.text = r.address.isNotEmpty ? r.address : r.displayName;
    setState(() { _results = []; _showDropdown = false; });
    _focus.unfocus();
    widget.onSelect(r);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Search Location',
            hintText: 'e.g. Karachi, Lahore, Peshawar...',
            prefixIcon: const Icon(Icons.search_outlined),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _debounce?.cancel();
                          _ctrl.clear();
                          setState(() { _results = []; _showDropdown = false; _hadError = false; });
                        },
                      )
                    : null,
          ),
        ),
        // Dropdown results
        if (_showDropdown && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
              children: _results.map((r) {
                final parts = r.displayName.split(',');
                final mainText = parts.take(2).join(',').trim();
                final subText = parts.skip(2).take(2).join(',').trim();
                return InkWell(
                  onTap: () => _select(r),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_outlined, size: 17, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(mainText,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (subText.isNotEmpty)
                          Text(subText,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      Text(
                        '${r.lat.toStringAsFixed(4)}, ${r.lng.toStringAsFixed(4)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        if (_hadError && !_searching)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.wifi_off_outlined, size: 13, color: AppColors.warning),
              SizedBox(width: 6),
              Text('Could not reach the location search. Check your connection and try again.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12)),
            ]),
          )
        else if (_results.isEmpty && !_searching && _ctrl.text.trim().length >= 3 && !_showDropdown)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'No results found. Try a different or more specific name.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
